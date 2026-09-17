import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/data/markdown_adapter.dart';
import 'package:rhyolite/data/personal_note_store.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/main.dart';

class MemoryNoteStore extends PersonalNoteStore {
  final files = <String, String>{};
  bool fail = false;
  @override
  Future<KnowledgeDocument> save({
    required String title,
    required String body,
    required List<String> related,
    KnowledgeDocument? original,
  }) async {
    if (fail) throw const FileSystemException('Disk unavailable');
    if (title.trim().isEmpty) throw const FormatException('Missing title');
    final id = original?.id ?? 'note:${files.length}';
    final path = original?.path ?? 'notes/${files.length}.md';
    final source =
        '---\nid: "$id"\ntype: note\ntitle: "$title"\n'
        'related: [${related.map((link) => '"$link"').join(', ')}]\n---\n$body';
    files[path] = source;
    return MarkdownAdapter().parse(path, source);
  }
}

class NotesFixtureRepository extends KnowledgeRepository {
  NotesFixtureRepository(MemoryNoteStore store) : super(noteStore: store);
  @override
  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async => build({
    'knowledge/courses/PRM393.md': '---\ntype: course\ncode: PRM393\nsemester: 8\n---\n# Mobile Programming',
    'knowledge/concepts/flutter.md': '---\nid: concept:flutter\ntype: concept\ntitle: Flutter\ncourses: ["course:PRM393"]\n---\n# Flutter',
    ...(noteStore! as MemoryNoteStore).files,
  });
}

void main() {
  Future<void> start(
    WidgetTester tester,
    MemoryNoteStore store, {
    bool narrow = false,
  }) async {
    await tester.binding.setSurfaceSize(
      narrow ? const Size(600, 800) : const Size(1280, 900),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RhyoliteApp(repository: NotesFixtureRepository(store)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Create linked note, preview, search body, edit via Ctrl+S, and reopen app',
    (tester) async {
      final store = MemoryNoteStore();
      await start(tester, store);
      await tester.tap(find.widgetWithText(ListTile, 'PRM393'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi chú về mục này'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'PRM393'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'Bài học hôm nay',
      );
      await tester.enterText(
        find.byKey(const ValueKey('note-body')),
        '# Widget lifecycle\n\n[[concept:flutter|Flutter]]',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('note-preview')),
          matching: find.text('Widget lifecycle', findRichText: true),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save-note')));
      await tester.pumpAndSettle();
      expect(store.files.length, 1);
      expect(find.text('Ghi chú cá nhân'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'lifecycle');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Bài học hôm nay'), findsOneWidget);
      await tester.tap(find.text('Graph cục bộ'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('graph-node:course:PRM393')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('graph-node:concept:flutter')),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa note'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('note-body')))
            .controller!
            .text,
        contains('lifecycle'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'Đã sửa',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(store.files.length, 1);
      expect(find.widgetWithText(ListTile, 'Đã sửa'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RhyoliteApp(repository: NotesFixtureRepository(store)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Notes'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Đã sửa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failed save retains draft and leaving requires confirmation', (
    tester,
  ) async {
    final store = MemoryNoteStore()..fail = true;
    await start(tester, store);
    await tester.tap(find.text('Tạo note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('note-title')), 'Draft');
    await tester.enterText(
      find.byKey(const ValueKey('note-body')),
      'Keep this text',
    );
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không lưu được:'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('note-body')))
          .controller!
          .text,
      'Keep this text',
    );
    expect(store.files, isEmpty);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Note chưa được lưu'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục soạn'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-body')), findsOneWidget);
    store.fail = false;
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(store.files.length, 1);
    expect(find.byKey(const ValueKey('note-body')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Narrow editor supports preview, link picker, and refreshed course backlinks',
    (tester) async {
      final store = MemoryNoteStore();
      await start(tester, store, narrow: true);
      await tester.tap(find.widgetWithText(ListTile, 'PRM393'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi chú về mục này'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'Narrow note',
      );
      await tester.enterText(
        find.byKey(const ValueKey('note-body')),
        'Markdown **preview**',
      );
      await tester.tap(find.text('Xem preview'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('note-preview')), findsOneWidget);
      await tester.tap(find.text('Thêm liên kết'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'flutter');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Flutter'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'Flutter'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-note')));
      await tester.pumpAndSettle();
      expect(find.text('Sửa note'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'PRM393'));
      await tester.pumpAndSettle();
      final backlinks = find.widgetWithText(ActionChip, 'Narrow note');
      await tester.ensureVisible(backlinks);
      expect(backlinks, findsOneWidget);
      await tester.tap(backlinks);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa note'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('note-title')),
        'Renamed note',
      );
      await tester.tap(find.byKey(const ValueKey('save-note')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      final updatedBacklink = find.widgetWithText(ActionChip, 'Renamed note');
      await tester.ensureVisible(updatedBacklink);
      expect(updatedBacklink, findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Narrow note'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      final path = store.files.keys.single;
      store.files[path] = store.files[path]!.replaceFirst(
        'title: "Renamed note"',
        'title: "External title"',
      );
      await tester.tap(find.byTooltip('Đọc lại knowledge base'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'External title'));
      await tester.pumpAndSettle();
      expect(find.text('External title'), findsNWidgets(2));
      expect(find.text('Renamed note'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Cancelable app exit and system back protect unsaved edits', (
    tester,
  ) async {
    final store = MemoryNoteStore();
    await start(tester, store);
    await tester.tap(find.text('Tạo note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('note-title')), 'Unsaved');
    final exitDecision = tester.binding.handleRequestAppExit();
    await tester.pumpAndSettle();
    expect(find.text('Note chưa được lưu'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục soạn'));
    await tester.pumpAndSettle();
    expect(await exitDecision, AppExitResponse.cancel);
    expect(find.byKey(const ValueKey('note-title')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Note chưa được lưu'), findsOneWidget);
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-title')), findsNothing);
    expect(store.files, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
