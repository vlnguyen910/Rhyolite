class StudentTranscript {
  const StudentTranscript({
    required this.sourceFileName,
    required this.importedAt,
    required this.records,
  });

  factory StudentTranscript.fromJson(Map<String, dynamic> json) =>
      StudentTranscript(
        sourceFileName: json['sourceFileName'] as String? ?? '',
        importedAt:
            DateTime.tryParse(json['importedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        records: [
          for (final item in json['records'] as List? ?? const [])
            TranscriptRecord.fromJson(item as Map<String, dynamic>),
        ],
      );

  final String sourceFileName;
  final DateTime importedAt;
  final List<TranscriptRecord> records;

  Map<String, dynamic> toJson() => {
    'sourceFileName': sourceFileName,
    'importedAt': importedAt.toIso8601String(),
    'records': [for (final record in records) record.toJson()],
  };

  Map<String, TranscriptRecord> get latestBySubjectCode {
    final result = <String, TranscriptRecord>{};
    for (final record in records) {
      result[record.subjectCode.toUpperCase()] = record;
    }
    return result;
  }

  StudentTranscript matchCurriculum(Iterable<String> courseCodes) {
    final normalizedCodes = {
      for (final code in courseCodes) code.trim().toUpperCase(),
    };
    return StudentTranscript(
      sourceFileName: sourceFileName,
      importedAt: importedAt,
      records: [
        for (final record in records)
          record.copyWith(
            matchesCurriculum: normalizedCodes.contains(
              record.subjectCode.trim().toUpperCase(),
            ),
          ),
      ],
    );
  }
}

class TranscriptRecord {
  const TranscriptRecord({
    required this.term,
    required this.semester,
    required this.subjectCode,
    required this.subjectName,
    required this.prerequisite,
    required this.replacedSubject,
    required this.credit,
    required this.grade,
    required this.status,
    required this.matchesCurriculum,
  });

  factory TranscriptRecord.fromJson(Map<String, dynamic> json) =>
      TranscriptRecord(
        term: json['term'] as String? ?? '',
        semester: json['semester'] as String? ?? '',
        subjectCode: json['subjectCode'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        prerequisite: json['prerequisite'] as String? ?? '',
        replacedSubject: json['replacedSubject'] as String? ?? '',
        credit: json['credit'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        status: json['status'] as String? ?? '',
        matchesCurriculum: json['matchesCurriculum'] as bool? ?? false,
      );

  final String term;
  final String semester;
  final String subjectCode;
  final String subjectName;
  final String prerequisite;
  final String replacedSubject;
  final String credit;
  final String grade;
  final String status;
  final bool matchesCurriculum;

  bool get isPassed => status.trim().toLowerCase() == 'passed';

  TranscriptRecord copyWith({bool? matchesCurriculum}) => TranscriptRecord(
    term: term,
    semester: semester,
    subjectCode: subjectCode,
    subjectName: subjectName,
    prerequisite: prerequisite,
    replacedSubject: replacedSubject,
    credit: credit,
    grade: grade,
    status: status,
    matchesCurriculum: matchesCurriculum ?? this.matchesCurriculum,
  );

  Map<String, dynamic> toJson() => {
    'term': term,
    'semester': semester,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'prerequisite': prerequisite,
    'replacedSubject': replacedSubject,
    'credit': credit,
    'grade': grade,
    'status': status,
    'matchesCurriculum': matchesCurriculum,
  };
}
