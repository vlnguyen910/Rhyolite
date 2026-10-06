import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/views/widgets/markdown_rendering.dart';
import 'package:rhyolite/views/widgets/syllabus_markdown_view.dart';

void main() {
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
}
