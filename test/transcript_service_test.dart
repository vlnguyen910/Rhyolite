import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/models/curriculum_catalog.dart';
import 'package:rhyolite/models/student_transcript.dart';
import 'package:rhyolite/services/transcript_service.dart';

const _courses = [
  CurriculumCourse(
    code: 'PRF192',
    name: 'Programming Fundamentals',
    semester: 1,
    groupCodes: ['PRF192'],
    notePath: 'PRF192.md',
  ),
];

void main() {
  group('FapTranscriptParser', () {
    test('maps FAP columns and marks curriculum matches', () {
      final records = FapTranscriptParser().parseRows(const [
        [
          'No',
          'Term',
          'Semester',
          'Subject Code',
          'Prerequisite',
          'Replaced Subject',
          'Subject Name',
          'Credit',
          'Grade',
          'Status',
        ],
        [
          1,
          'Fall2025',
          '1',
          'PRF192',
          '',
          '',
          'Programming Fundamentals',
          3,
          8.5,
          'Passed',
        ],
        [2, 'Fall2025', '1', 'VOV114', '', '', 'Vovinam', 0, 7, 'Passed'],
      ], _courses);

      expect(records, hasLength(2));
      expect(records.first.subjectCode, 'PRF192');
      expect(records.first.grade, '8.5');
      expect(records.first.matchesCurriculum, isTrue);
      expect(records.last.grade, '7');
      expect(records.last.matchesCurriculum, isFalse);
    });

    test('reads the UTF-16 HTML workbook format exported by FAP', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rhyolite-transcript-parser-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/AcademicTranscript.xls');
      const html = '''
<html><body><table>
  <tr><th>Subject Code</th><th>Subject Name</th><th>Grade</th><th>Status</th></tr>
  <tr><td>PRF192</td><td>Programming Fundamentals</td><td>8.5</td><td>Passed</td></tr>
</table></body></html>
''';
      final bytes = <int>[0xff, 0xfe];
      for (final codeUnit in html.codeUnits) {
        bytes.add(codeUnit & 0xff);
        bytes.add(codeUnit >> 8);
      }
      await file.writeAsBytes(bytes);

      final transcript = await FapTranscriptParser().parseFile(
        file.path,
        _courses,
      );

      expect(transcript.records, hasLength(1));
      expect(transcript.records.single.subjectCode, 'PRF192');
      expect(transcript.records.single.isPassed, isTrue);
    });
  });

  test('TranscriptRepository persists and removes local data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'rhyolite-transcript-repository-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = TranscriptRepository(
      directoryProvider: () async => directory,
    );
    final transcript = StudentTranscript(
      sourceFileName: 'AcademicTranscript.xls',
      importedAt: DateTime.utc(2026, 9, 21),
      records: const [
        TranscriptRecord(
          term: 'Fall2025',
          semester: '1',
          subjectCode: 'PRF192',
          subjectName: 'Programming Fundamentals',
          prerequisite: '',
          replacedSubject: '',
          credit: '3',
          grade: '8.5',
          status: 'Passed',
          matchesCurriculum: true,
        ),
      ],
    );

    await repository.save(transcript);
    final restored = await repository.load();
    expect(restored?.sourceFileName, 'AcademicTranscript.xls');
    expect(restored?.records.single.grade, '8.5');

    await repository.delete();
    expect(await repository.load(), isNull);
  });
}
