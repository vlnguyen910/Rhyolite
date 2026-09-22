import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/domain/models/curriculum_catalog.dart';
import 'package:rhyolite/domain/models/student_transcript.dart';
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

  test('manual edit preserves original FAP values and can restore them', () {
    final original = StudentTranscript(
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
          grade: '7',
          status: 'Passed',
          matchesCurriculum: true,
        ),
      ],
    );

    final edited = original.editRecord(0, grade: '8.5', status: 'Passed');
    final restoredFromStorage = StudentTranscript.fromJson(edited.toJson());
    final record = restoredFromStorage.records.single;
    expect(record.grade, '8.5');
    expect(record.sourceLabel, 'Tự nhập');
    expect(record.importedGrade, '7');
    expect(record.editedAt, isNotNull);
    expect(restoredFromStorage.restoreRecord(0).records.single.grade, '7');
    expect(
      restoredFromStorage.restoreRecord(0).records.single.isManual,
      isFalse,
    );
  });

  test('reimport can preserve or overwrite manual grades and merge rows', () {
    TranscriptRecord row(String code, String grade) => TranscriptRecord(
      term: 'Fall2025',
      semester: '1',
      subjectCode: code,
      subjectName: code,
      prerequisite: '',
      replacedSubject: '',
      credit: '3',
      grade: grade,
      status: 'Passed',
      matchesCurriculum: true,
    );
    final old = StudentTranscript(
      sourceFileName: 'old.xls',
      importedAt: DateTime.utc(2026, 9, 1),
      records: [row('PRF192', '7'), row('PRO192', '6')],
    ).editRecord(0, grade: '8.5', status: 'Passed');
    final incoming = StudentTranscript(
      sourceFileName: 'new.xls',
      importedAt: DateTime.utc(2026, 9, 22),
      records: [row('PRF192', '9'), row('CSD201', '7')],
    );

    final kept = old.reimport(incoming, merge: true, overwriteManual: false);
    expect(kept.latestBySubjectCode['PRF192']?.grade, '8.5');
    expect(kept.latestBySubjectCode['PRF192']?.importedGrade, '9');
    expect(kept.latestBySubjectCode['PRO192']?.grade, '6');
    expect(kept.latestBySubjectCode['CSD201']?.grade, '7');

    final replaced = old.reimport(
      incoming,
      merge: false,
      overwriteManual: true,
    );
    expect(replaced.latestBySubjectCode['PRF192']?.grade, '9');
    expect(replaced.latestBySubjectCode['PRF192']?.isManual, isFalse);
    expect(replaced.latestBySubjectCode.containsKey('PRO192'), isFalse);
  });

  test('manual-only grade remains until explicitly removed or overwritten', () {
    final original = StudentTranscript(
      sourceFileName: 'old.xls',
      importedAt: DateTime.utc(2026, 9, 21),
      records: const [],
    );
    final manual = original.addManualRecord(
      const TranscriptRecord(
        term: '',
        semester: '2',
        subjectCode: 'PRO192',
        subjectName: 'Object Oriented Programming',
        prerequisite: '',
        replacedSubject: '',
        credit: '',
        grade: '8',
        status: 'Passed',
        matchesCurriculum: true,
        isManual: true,
      ),
    );
    final incoming = StudentTranscript(
      sourceFileName: 'new.xls',
      importedAt: DateTime.utc(2026, 9, 22),
      records: const [],
    );

    expect(
      manual
          .reimport(incoming, merge: false, overwriteManual: false)
          .latestBySubjectCode['PRO192']
          ?.grade,
      '8',
    );
    expect(manual.restoreRecord(0).records, isEmpty);
  });
}
