class CurriculumCatalog {
  const CurriculumCatalog({
    required this.schemaVersion,
    required this.source,
    required this.curricula,
  });

  factory CurriculumCatalog.fromJson(Map<String, dynamic> json) {
    final rawCurricula = json['curricula'];
    if (rawCurricula is! List) {
      throw const FormatException('curricula must be a list');
    }

    return CurriculumCatalog(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      source: json['source'] as String? ?? '',
      curricula: [
        for (final item in rawCurricula)
          Curriculum.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final int schemaVersion;
  final String source;
  final List<Curriculum> curricula;

  List<String> get codes => [
    for (final curriculum in curricula) curriculum.code,
  ];

  Curriculum? find(String code) {
    for (final curriculum in curricula) {
      if (curriculum.code == code) return curriculum;
    }
    return null;
  }
}

class Curriculum {
  const Curriculum({required this.code, required this.courses});

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'];
    if (rawCourses is! List) {
      throw const FormatException('courses must be a list');
    }

    return Curriculum(
      code: json['code'] as String,
      courses: [
        for (final item in rawCourses)
          CurriculumCourse.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String code;
  final List<CurriculumCourse> courses;
}

class CurriculumCourse {
  const CurriculumCourse({
    required this.code,
    required this.name,
    required this.semester,
    required this.groupCodes,
    this.prerequisiteCodes = const [],
    required this.notePath,
  });

  factory CurriculumCourse.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groupCodes'];
    if (rawGroups is! List) {
      throw const FormatException('groupCodes must be a list');
    }

    return CurriculumCourse(
      code: json['code'] as String,
      name: json['name'] as String,
      semester: json['semester'] as int,
      groupCodes: [for (final group in rawGroups) group as String],
      prerequisiteCodes: [
        for (final code in json['prerequisiteCodes'] as List? ?? const [])
          code as String,
      ],
      notePath: json['notePath'] as String,
    );
  }

  final String code;
  final String name;
  final int semester;
  final List<String> groupCodes;
  final List<String> prerequisiteCodes;
  final String notePath;

  bool get isChoice => groupCodes.any((group) => group != code);
}
