import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/main.dart';

class OverviewFixtureRepository extends KnowledgeRepository {
  @override
  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async => build({
    'knowledge/courses/PRO192.md':
        '---\ntype: course\ncode: PRO192\nsemester: 2\n---\n# OOP',
    'knowledge/courses/PRM393.md': '---\ntype: course\ncode: PRM393\nsemester: 8\nprerequisites: ["course:PRO192"]\n---\n# Mobile Programming',
    'knowledge/courses/ISO301.md':
        '---\ntype: course\ncode: ISO301\nsemester: 5\n---\n# Isolated course',
    'knowledge/concepts/flutter.md': '---\ntype: concept\nid: concept:flutter\ntitle: Flutter\ncourses: ["course:PRM393"]\nrelated: ["concept:dart"]\n---\n# Flutter',
    'knowledge/concepts/dart.md': '---\ntype: concept\nid: concept:dart\ntitle: Dart\ncourses: ["course:PRM393"]\n---\n# Dart',
    'notes/one.md': '---\ntype: note\nid: note:one\ntitle: My Flutter notes\nrelated: ["course:PRM393", "concept:flutter"]\n---\n# Personal notes',
    'knowledge/courses/demo.md': '---\ntype: course\ncode: DEMO\nsemester: 1\ndemo: true\n---\n# Demo course',
  });
}

class FixedOverviewRepository extends KnowledgeRepository {
  FixedOverviewRepository(this.snapshot);
  final KnowledgeSnapshot snapshot;
  @override
  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async => snapshot;
}

void main() {
  Future<void> openGraph(
    WidgetTester tester, {
    KnowledgeRepository? repository,
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RhyoliteApp(repository: repository ?? OverviewFixtureRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overview-tab')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Overview tab filters extras/demo, finds nodes and opens details',
    (tester) async {
      await openGraph(tester);
      expect(find.text('3 node · 1/1 liên kết'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('overview-node:course:ISO301')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('overview-node:concept:flutter')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('overview-node:note:one')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('overview-concepts')));
      await tester.pumpAndSettle();
      expect(find.text('5 node · 4/4 liên kết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('overview-notes')));
      await tester.pumpAndSettle();
      expect(find.text('6 node · 6/6 liên kết'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('overview-search')),
        'PRM393',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('overview-result:course:PRM393')),
      );
      await tester.pumpAndSettle();
      expect(find.text('6 node · 4/6 liên kết'), findsOneWidget);
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const ValueKey('overview-graph-viewer')),
      );
      expect(
        viewer.transformationController!.value.storage[0],
        closeTo(1, .001),
      );
      await tester.tap(find.text('Chỉ dây liên quan'));
      await tester.pumpAndSettle();
      expect(find.text('6 node · 6/6 liên kết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('overview-open')));
      await tester.pumpAndSettle();
      expect(find.text('Môn tiên quyết có liên kết'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('overview-demo')));
      await tester.pumpAndSettle();
      expect(find.text('7 node · 6/6 liên kết'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('overview-node:course:DEMO')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('overview-demo')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('overview-node:course:DEMO')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Overview pan/zoom works in narrow windows and selection survives tab changes',
    (tester) async {
      await openGraph(tester, size: const Size(600, 800));
      final viewerKey = find.byKey(const ValueKey('overview-graph-viewer'));
      final transform = tester
          .widget<InteractiveViewer>(viewerKey)
          .transformationController!;
      final scale = transform.value.storage[0];
      await tester.tap(find.byTooltip('Phóng to graph tổng quan'));
      await tester.pumpAndSettle();
      expect(transform.value.storage[0], greaterThan(scale));
      final translation = transform.value.storage[12];
      await tester.drag(viewerKey, const Offset(60, 20));
      await tester.pumpAndSettle();
      expect(transform.value.storage[12], isNot(translation));
      await tester.enterText(
        find.byKey(const ValueKey('overview-search')),
        'Mobile',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('overview-result:course:PRM393')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('overview-selection')), findsOneWidget);
      expect(transform.value.storage[0], closeTo(1, .001));
      await tester.tap(find.text('Thư viện'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('overview-tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('overview-selection')), findsOneWidget);
      await tester.tap(find.byTooltip('Vừa khung graph tổng quan'));
      await tester.pumpAndSettle();
      final current = tester
          .widget<InteractiveViewer>(viewerKey)
          .transformationController!;
      expect(current.value.storage[0], lessThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Real dataset renders all courses and focus highlights connected nodes',
    (tester) async {
      final files = <String, String>{};
      for (final file in Directory(
        'knowledge',
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.md')) {
          files[file.path] = file.readAsStringSync();
        }
      }
      await openGraph(
        tester,
        repository: FixedOverviewRepository(
          const KnowledgeRepository().build(files),
        ),
      );
      expect(find.text('76 node · 59/59 liên kết'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('overview-search')),
        'PRM393',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('overview-result:course:PRM393')),
      );
      await tester.pumpAndSettle();
      expect(find.text('76 node · 1/59 liên kết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('overview-concepts')));
      await tester.pumpAndSettle();
      expect(find.text('80 node · 5/67 liên kết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('overview-open')));
      await tester.pumpAndSettle();
      expect(find.text('Mobile Programming'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
