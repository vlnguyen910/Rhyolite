import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/services/syllabus_section_service.dart';
import 'package:rhyolite/views/widgets/markdown_rendering.dart';
import 'package:rhyolite/views/widgets/syllabus_markdown_view.dart';

void main() {
  test('splits syllabus by heading and keeps code fences intact', () {
    final sections = splitSyllabusSections('''
# PRM393
## Đề cương chi tiết
### Mô tả
Nội dung môn học.
```md
### Heading trong ví dụ
```
### Download All Student Material
| Session | Topic |
| --- | --- |
| 1 | Flutter |
''');

    expect(sections.map((section) => section.title), [
      'Đề cương chi tiết · Mô tả',
      'Đề cương chi tiết · Download All Student Material',
    ]);
    expect(sections[0].markdown, contains('### Heading trong ví dụ'));
    expect(sections[1].markdown, contains('| 1 | Flutter |'));
  });

  test('keeps table rows intact when syllabus cells contain break tags', () {
    final rendered = renderableMarkdown(
      '# Môn học\n\n| Chủ đề | Nội dung |\n| --- | --- |\n'
      '| M1 | Dòng một<br>Dòng hai [[PRF192|Cơ sở lập trình]] |',
    );

    expect(rendered, contains('Dòng một · Dòng hai'));
    expect(rendered, contains('[Cơ sở lập trình](course:PRF192)'));
    expect(
      rendered.split('\n').where((line) => line.startsWith('|')).length,
      3,
    );
  });

  test('splits long tables while preserving every row and its header', () {
    final source = [
      '# Syllabus',
      '',
      '## Nội dung',
      '| Buổi | Chủ đề |',
      '| --- | --- |',
      for (var index = 1; index <= 5; index++) '| $index | Chủ đề $index |',
      '',
      '## Ghi chú',
      'Kết thúc.',
    ].join('\n');

    final chunks = splitMarkdownForDisplay(source, maxTableRows: 2);
    final tableChunks = chunks.where((chunk) => chunk.startsWith('| Buổi'));
    expect(tableChunks.length, 3);
    for (final chunk in tableChunks) {
      expect(chunk, startsWith('| Buổi | Chủ đề |\n| --- | --- |'));
    }
    for (var index = 1; index <= 5; index++) {
      expect(
        chunks.where((chunk) => chunk.contains('| $index | Chủ đề $index |')),
        hasLength(1),
      );
    }
    expect(chunks.last, contains('Kết thúc.'));
  });

  testWidgets('course links remain clickable in the segmented syllabus', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyllabusMarkdownView(
            source: '# Syllabus\n\n## Tiên quyết\n[[PRF192|Cơ sở lập trình]]',
            onTapLink: (_, href, _) => tapped = href,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cơ sở lập trình'));
    expect(tapped, 'course:PRF192');
  });

  testWidgets('renders only the selected syllabus section', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyllabusMarkdownView(
            source:
                '# PRM393\n\n## Mô tả\nNội dung cơ bản.\n\n'
                '## Nội dung buổi học\n| Buổi | Chủ đề |\n| --- | --- |\n'
                '| 1 | Widget tree |',
          ),
        ),
      ),
    );

    expect(find.text('Widget tree'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('syllabus-section-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nội dung buổi học').last);
    await tester.pumpAndSettle();
    expect(find.text('Widget tree'), findsOneWidget);
    expect(find.text('Nội dung cơ bản.'), findsNothing);
  });
}
