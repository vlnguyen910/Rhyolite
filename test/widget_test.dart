import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/main.dart';

class FixtureRepository extends KnowledgeRepository {
  @override
  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async => build({
    'knowledge/Mon hoc/PRO192.md':
        '---\ncourse_code: PRO192\nsemester: "2"\n---\n# PRO192 - OOP',
    'knowledge/Mon hoc/PRM393.md': '''
---
course_code: PRM393
semester: "8"
---
# PRM393 - Mobile Programming
## Mon tien quyet
- [[PRO192]]
## Noi dung de cuong
| Điều kiện tiên quyết: | PRO192 |
''',
  });
}

class SnapshotRepository extends KnowledgeRepository {
  SnapshotRepository(this.snapshot);
  final KnowledgeSnapshot snapshot;

  @override
  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async => snapshot;
}

void main() {
  testWidgets(
    'Actual syllabus renders and its Obsidian link opens another course',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final files = <String, String>{};
      for (final file in Directory(
        'knowledge',
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.md')) {
          files[file.path] = file.readAsStringSync();
        }
      }
      final snapshot = const KnowledgeRepository().build(files);
      await tester.pumpWidget(
        RhyoliteApp(repository: SnapshotRepository(snapshot)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'PRM393');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'PRM393'));
      await tester.pumpAndSettle();
      final reader = find.text('Đọc nội dung Markdown');
      await tester.ensureVisible(reader);
      await tester.tap(reader);
      await tester.pumpAndSettle();
      final link = find.text(
        'PRO192 - Object-Oriented Programming',
        findRichText: true,
      );
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.text('Object-Oriented Programming'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Desktop search, detail and prerequisite navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RhyoliteApp(repository: FixtureRepository()));
    await tester.pumpAndSettle();
    expect(find.text('2 môn · 2 học kỳ'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'prm393');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'PRM393'));
    await tester.pumpAndSettle();
    expect(
      find.text('Điều kiện tiên quyết · nguyên văn syllabus'),
      findsOneWidget,
    );
    expect(find.text('Mobile Programming'), findsWidgets);
    await tester.tap(find.widgetWithText(ActionChip, 'PRO192'));
    await tester.pumpAndSettle();
    expect(find.text('OOP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Narrow window navigates to detail and can go back', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RhyoliteApp(repository: FixtureRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'PRM393'));
    await tester.pumpAndSettle();
    expect(
      find.text('Điều kiện tiên quyết · nguyên văn syllabus'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
