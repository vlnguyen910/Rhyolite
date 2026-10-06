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

  int get manualRecordCount =>
      records.where((record) => record.isManual).length;

  StudentTranscript editRecord(
    int index, {
    required String grade,
    required String status,
  }) {
    if (index < 0 || index >= records.length) {
      throw RangeError.index(index, records);
    }
    return StudentTranscript(
      sourceFileName: sourceFileName,
      importedAt: importedAt,
      records: [
        for (var current = 0; current < records.length; current++)
          current == index
              ? records[current].withManualValues(grade: grade, status: status)
              : records[current],
      ],
    );
  }

  StudentTranscript restoreRecord(int index) {
    if (index < 0 || index >= records.length) {
      throw RangeError.index(index, records);
    }
    final record = records[index];
    if (!record.hasFapOriginal) {
      return StudentTranscript(
        sourceFileName: sourceFileName,
        importedAt: importedAt,
        records: [
          for (var current = 0; current < records.length; current++)
            if (current != index) records[current],
        ],
      );
    }
    return StudentTranscript(
      sourceFileName: sourceFileName,
      importedAt: importedAt,
      records: [
        for (var current = 0; current < records.length; current++)
          current == index ? record.restoreFromFap() : records[current],
      ],
    );
  }

  StudentTranscript addManualRecord(TranscriptRecord record) {
    if (!record.isManual) {
      throw ArgumentError('New transcript record must be marked manual.');
    }
    if (records.any((existing) => _recordKey(existing) == _recordKey(record))) {
      throw ArgumentError(
        'This course record already exists for the semester.',
      );
    }
    return StudentTranscript(
      sourceFileName: sourceFileName,
      importedAt: importedAt,
      records: [...records, record],
    );
  }

  StudentTranscript reimport(
    StudentTranscript incoming, {
    required bool merge,
    required bool overwriteManual,
  }) {
    final existingByRecord = {
      for (final record in records) _recordKey(record): record,
    };
    final incomingKeys = <String>{};
    final updated = <TranscriptRecord>[];
    for (final record in incoming.records) {
      final key = _recordKey(record);
      incomingKeys.add(key);
      final existing = existingByRecord[key];
      updated.add(
        existing != null && existing.isManual && !overwriteManual
            ? record.withManualValues(
                grade: existing.grade,
                status: existing.status,
                editedAt: existing.editedAt,
              )
            : record,
      );
    }
    for (final record in records) {
      if (incomingKeys.contains(_recordKey(record))) continue;
      if (merge || (record.isManual && !overwriteManual)) {
        updated.add(record);
      }
    }
    return StudentTranscript(
      sourceFileName: incoming.sourceFileName,
      importedAt: incoming.importedAt,
      records: updated,
    );
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

String _recordKey(TranscriptRecord record) => [
  record.subjectCode.trim().toUpperCase(),
  record.semester.trim().toUpperCase(),
  record.term.trim().toUpperCase(),
].join('|');

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
    this.isManual = false,
    this.importedGrade,
    this.importedStatus,
    this.editedAt,
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
        isManual: json['isManual'] as bool? ?? false,
        importedGrade: json['importedGrade'] as String?,
        importedStatus: json['importedStatus'] as String?,
        editedAt: DateTime.tryParse(json['editedAt'] as String? ?? ''),
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
  final bool isManual;
  final String? importedGrade;
  final String? importedStatus;
  final DateTime? editedAt;

  bool get isPassed => status.trim().toLowerCase() == 'passed';
  bool get hasFapOriginal => !isManual || importedGrade != null;
  String get sourceLabel => isManual ? 'Tự nhập' : 'Từ FAP';

  TranscriptRecord withManualValues({
    required String grade,
    required String status,
    DateTime? editedAt,
  }) => TranscriptRecord(
    term: term,
    semester: semester,
    subjectCode: subjectCode,
    subjectName: subjectName,
    prerequisite: prerequisite,
    replacedSubject: replacedSubject,
    credit: credit,
    grade: grade.trim(),
    status: status.trim(),
    matchesCurriculum: matchesCurriculum,
    isManual: true,
    importedGrade: isManual ? importedGrade : this.grade,
    importedStatus: isManual ? importedStatus : this.status,
    editedAt: editedAt ?? DateTime.now(),
  );

  TranscriptRecord restoreFromFap() {
    if (!hasFapOriginal) {
      throw StateError('This record has no FAP value to restore.');
    }
    return TranscriptRecord(
      term: term,
      semester: semester,
      subjectCode: subjectCode,
      subjectName: subjectName,
      prerequisite: prerequisite,
      replacedSubject: replacedSubject,
      credit: credit,
      grade: importedGrade ?? grade,
      status: importedStatus ?? status,
      matchesCurriculum: matchesCurriculum,
    );
  }

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
    isManual: isManual,
    importedGrade: importedGrade,
    importedStatus: importedStatus,
    editedAt: editedAt,
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
    'isManual': isManual,
    'importedGrade': importedGrade,
    'importedStatus': importedStatus,
    'editedAt': editedAt?.toIso8601String(),
  };
}
