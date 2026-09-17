import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/domain/knowledge_graph.dart';
import 'package:rhyolite/domain/overview_graph_layout.dart';

String course(
  String code,
  int semester, [
  List<String> prerequisites = const [],
]) =>
    '---\ntype: course\ncode: $code\nsemester: $semester\n'
    'prerequisites: [${prerequisites.map((id) => '"course:$id"').join(', ')}]\n---\n# $code';

KnowledgeSnapshot fixture() => const KnowledgeRepository().build({
  'knowledge/courses/A.md': course('A', 1),
  'knowledge/courses/B.md': course('B', 1),
  'knowledge/courses/C.md': course('C', 2, ['B']),
  'knowledge/courses/D.md': course('D', 2, ['A']),
  'knowledge/courses/E.md': course('E', 3, ['A']),
  'knowledge/courses/F.md': course('F', 3, ['E']),
  'knowledge/concepts/topic.md': '---\ntype: concept\nid: concept:topic\ntitle: Topic\ncourses: ["course:C"]\n---\n# Topic',
  'notes/one.md': '---\ntype: note\nid: note:one\ntitle: Note\nrelated: ["course:C", "concept:topic"]\n---\n# Note',
  'knowledge/courses/demo.md': course(
    'DEMO',
    1,
  ).replaceFirst('type: course', 'type: course\ndemo: true'),
  'knowledge/hub.md': '# Hub\n[[course:A]]',
});

void assertGeometry(OverviewKnowledgeGraph graph, OverviewGraphLayout layout) {
  expect(layout.positions.length, graph.nodes.length);
  expect(layout.routes.length, graph.edges.length);
  for (final a in graph.nodes) {
    final position = layout.positions[a.id]!;
    expect(position.x, greaterThanOrEqualTo(0));
    expect(position.y, greaterThanOrEqualTo(0));
    expect(
      position.x + OverviewGraphLayout.nodeWidth,
      lessThanOrEqualTo(layout.width),
    );
    expect(
      position.y + OverviewGraphLayout.nodeHeight,
      lessThanOrEqualTo(layout.height),
    );
    for (final b in graph.nodes.where((node) => node.id != a.id)) {
      final other = layout.positions[b.id]!;
      final overlap =
          position.x < other.x + OverviewGraphLayout.nodeWidth &&
          position.x + OverviewGraphLayout.nodeWidth > other.x &&
          position.y < other.y + OverviewGraphLayout.nodeHeight &&
          position.y + OverviewGraphLayout.nodeHeight > other.y;
      expect(overlap, isFalse, reason: '${a.id} overlaps ${b.id}');
    }
  }
  for (final route in layout.routes) {
    final samples = <GraphPoint>[];
    if (route.bezier) {
      for (var step = 0; step <= 40; step++) {
        final t = step / 40;
        final p = route.points;
        double at(List<double> values) =>
            math.pow(1 - t, 3) * values[0] +
            3 * math.pow(1 - t, 2) * t * values[1] +
            3 * (1 - t) * t * t * values[2] +
            t * t * t * values[3];
        samples.add((
          x: at(p.map((point) => point.x).toList()),
          y: at(p.map((point) => point.y).toList()),
        ));
      }
    } else {
      for (var i = 1; i < route.points.length; i++) {
        final start = route.points[i - 1];
        final end = route.points[i];
        for (var step = 0; step <= 40; step++) {
          samples.add((
            x: start.x + (end.x - start.x) * step / 40,
            y: start.y + (end.y - start.y) * step / 40,
          ));
        }
      }
    }
    for (final point in samples) {
      expect(point.x.isFinite && point.y.isFinite, isTrue);
      expect(point.x, inInclusiveRange(0, layout.width));
      expect(point.y, inInclusiveRange(0, layout.height));
      for (final node in graph.nodes) {
        final box = layout.positions[node.id]!;
        final inside =
            point.x > box.x + .001 &&
            point.x < box.x + OverviewGraphLayout.nodeWidth - .001 &&
            point.y > box.y + .001 &&
            point.y < box.y + OverviewGraphLayout.nodeHeight - .001;
        expect(
          inside,
          isFalse,
          reason:
              '${route.edge.sourceId} → ${route.edge.targetId} enters ${node.id}',
        );
      }
    }
  }
}

void main() {
  test('Overview defaults to courses/prerequisites; filters include extras without hubs or dangling edges', () {
    final service = KnowledgeGraphService(fixture());
    final defaults = service.overviewGraph();
    expect(defaults.nodes.length, 6);
    expect(
      defaults.nodes.every((node) => node.type == DocumentType.course),
      isTrue,
    );
    expect(defaults.edges.length, 4);
    expect(
      defaults.edges.every(
        (edge) => edge.relation == GraphRelation.prerequisite,
      ),
      isTrue,
    );
    final all = service.overviewGraph(
      includeConcepts: true,
      includeNotes: true,
      includeDemo: true,
    );
    expect(all.nodes.length, 9);
    expect(all.edges.length, 7);
    expect(
      all.nodes.any((node) => node.type == DocumentType.reference),
      isFalse,
    );
    final notesOnly = service.overviewGraph(includeNotes: true);
    expect(notesOnly.nodes.length, 7);
    expect(notesOnly.edges.length, 5);
    expect(
      notesOnly.edges.any((edge) => edge.targetId == 'concept:topic'),
      isFalse,
    );
  });

  test(
    'Semester columns reduce crossings and routing avoids every node box',
    () {
      final graph = KnowledgeGraphService(fixture())
          .overviewGraph(includeConcepts: true, includeNotes: true);
      final layout = OverviewGraphLayout(graph);
      expect(layout.columns.map((column) => column.label), [
        'Học kỳ 1',
        'Học kỳ 2',
        'Học kỳ 3',
        'Concept',
        'My Notes',
      ]);
      expect(layout.crossings, lessThan(layout.initialCrossings));
      assertGeometry(graph, layout);
      final reversed = OverviewGraphLayout(
        OverviewKnowledgeGraph(
          graph.nodes.reversed.toList(),
          graph.edges.reversed.toList(),
        ),
      );
      expect(reversed.positions, layout.positions);
      expect(reversed.crossings, layout.crossings);
    },
  );

  test(
    'Cycles, same-semester links and empty graph produce finite layouts',
    () {
      final snapshot = const KnowledgeRepository().build({
        'knowledge/courses/A.md': course('A', 1, ['B']),
        'knowledge/courses/B.md': course('B', 1, ['A']),
      });
      final graph = KnowledgeGraphService(snapshot).overviewGraph();
      assertGeometry(graph, OverviewGraphLayout(graph));
      final empty = OverviewGraphLayout(const OverviewKnowledgeGraph([], []));
      expect(empty.width.isFinite && empty.height.isFinite, isTrue);
      expect(empty.positions, isEmpty);
      expect(empty.routes, isEmpty);
    },
  );

  test('Real dataset shows 76 courses, 59 prerequisite edges with non-overlapping geometry', () {
    final files = <String, String>{};
    for (final file in Directory(
      'knowledge',
    ).listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.md')) files[file.path] = file.readAsStringSync();
    }
    final snapshot = const KnowledgeRepository().build(files);
    final graph = KnowledgeGraphService(snapshot).overviewGraph();
    expect(graph.nodes.length, 76);
    expect(graph.edges.length, 59);
    final layout = OverviewGraphLayout(graph);
    expect(layout.columns.length, 9);
    expect(layout.crossings, lessThanOrEqualTo(layout.initialCrossings));
    assertGeometry(graph, layout);
  });
}
