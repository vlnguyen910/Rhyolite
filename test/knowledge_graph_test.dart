import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/domain/knowledge_graph.dart';

String course(
  String code, {
  String prerequisites = '[]',
  String concepts = '[]',
  String body = '',
}) =>
    '---\ntype: course\ncode: $code\nsemester: 1\nprerequisites: $prerequisites\nconcepts: $concepts\n---\n# $code\n$body';
String concept(
  String id, {
  String courses = '[]',
  String related = '[]',
  bool demo = false,
}) =>
    '---\nid: concept:$id\ntype: concept\ntitle: $id\ncourses: $courses\nrelated: $related\ndemo: $demo\n---\n# $id';

void main() {
  const repository = KnowledgeRepository();

  test(
    'Typed course/concept links are deduplicated across both schema directions',
    () {
      final snapshot = repository.build({
        'knowledge/courses/A.md': course(
          'A',
          prerequisites: '["course:B"]',
          concepts: '["concept:dart"]',
          body: '[[B]]',
        ),
        'knowledge/courses/B.md': course('B', body: '[[A]]'),
        'knowledge/concepts/dart.md': concept('dart', courses: '["course:A"]'),
      });
      final graph = KnowledgeGraphService(snapshot);
      expect(graph.edges, hasLength(2));
      final required = graph.edges.singleWhere(
        (e) => e.relation == GraphRelation.prerequisite,
      );
      expect((required.sourceId, required.targetId), ('course:A', 'course:B'));
      final topic = graph.edges.singleWhere(
        (e) => e.relation == GraphRelation.topic,
      );
      expect((topic.sourceId, topic.targetId), ('course:A', 'concept:dart'));
      expect(
        snapshot.conceptsFor(snapshot.resolve('course:A')!).single.id,
        'concept:dart',
      );
      expect(
        snapshot.coursesFor(snapshot.resolve('concept:dart')!).single.id,
        'course:A',
      );
    },
  );

  test('Generic reciprocal links form one undirected reference; missing targets create no nodes', () {
    final snapshot = repository.build({
      'knowledge/concepts/a.md': concept(
        'a',
        related: '["concept:b", "concept:missing"]',
      ),
      'knowledge/concepts/b.md': concept('b', related: '["concept:a"]'),
    });
    final graph = KnowledgeGraphService(snapshot);
    expect(graph.edges.single.relation, GraphRelation.related);
    expect(snapshot.issues.single.message, contains('missing'));
    final local = graph.localGraph(snapshot.resolve('concept:a')!);
    expect(local.nodes, hasLength(2));
  });

  test('Depth-one graph excludes hubs, limits nodes deterministically and reports omitted neighbors', () {
    final files = <String, String>{
      'knowledge/courses/A.md': course(
        'A',
        concepts: '[${List.generate(35, (i) => '"concept:c$i"').join(',')}]',
        body: '[[Hub]]',
      ),
      'knowledge/Hub.md': '# Hub\n[[A]]',
      for (var i = 0; i < 35; i++) 'knowledge/concepts/c$i.md': concept('c$i'),
    };
    final snapshot = repository.build(files);
    final service = KnowledgeGraphService(snapshot);
    final focus = snapshot.resolve('course:A')!;
    final local = service.localGraph(focus);
    expect(local.nodes, hasLength(24));
    expect(local.omittedCount, 12);
    expect(
      local.nodes.where((node) => node.type == DocumentType.reference),
      isEmpty,
    );
    expect(
      service.localGraph(focus).nodes.map((n) => n.id),
      local.nodes.map((n) => n.id),
    );
    expect(() => service.localGraph(focus, maxNodes: 0), throwsRangeError);
  });

  test('Demo neighbors are hidden by default and isolated concepts still produce a focus node', () {
    final snapshot = repository.build({
      'knowledge/concepts/a.md': concept('a', related: '["concept:demo"]'),
      'knowledge/concepts/demo.md': concept('demo', demo: true),
    });
    final service = KnowledgeGraphService(snapshot);
    final focus = snapshot.resolve('concept:a')!;
    expect(service.localGraph(focus).nodes, [focus]);
    expect(service.localGraph(focus, includeDemo: true).nodes, hasLength(2));
  });

  test(
    'Wrong relationship target type is warned and not presented as a topic',
    () {
      final snapshot = repository.build({
        'knowledge/courses/A.md': course('A', concepts: '["course:A"]'),
      });
      expect(
        snapshot.issues.any((issue) => issue.message.contains('sai loại node')),
        isTrue,
      );
      expect(KnowledgeGraphService(snapshot).edges, isEmpty);
    },
  );

  test('Actual PRM393 graph contains PRO192 and four sourced concepts; sources stay intact', () {
    final files = <String, String>{};
    for (final file in Directory(
      'knowledge',
    ).listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.md')) files[file.path] = file.readAsStringSync();
    }
    final snapshot = repository.build(files);
    final focus = snapshot.resolve('course:PRM393')!;
    final local = KnowledgeGraphService(snapshot).localGraph(focus);
    expect(local.nodes, hasLength(6));
    expect(
      local.edges.where((e) => e.relation == GraphRelation.topic),
      hasLength(4),
    );
    expect(
      local.edges
          .where((e) => e.relation == GraphRelation.prerequisite)
          .single
          .targetId,
      'course:PRO192',
    );
    expect(snapshot.concepts.where((c) => !c.demo), hasLength(4));
    expect(
      snapshot.issues.where((i) => i.severity == IssueSeverity.error),
      isEmpty,
    );
  });
}
