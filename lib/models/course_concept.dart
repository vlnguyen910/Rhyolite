enum CourseRelationType { prerequisite, sharedConcept, foundation }

class CourseConcept {
  const CourseConcept({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'Chung',
    this.colorHex,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String? colorHex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseConcept &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CourseRelation {
  const CourseRelation({
    required this.sourceCourseCode,
    required this.targetCourseCode,
    required this.relationType,
    required this.relevanceScore,
    this.sharedConcepts = const [],
    this.explanation = '',
  });

  final String sourceCourseCode;
  final String targetCourseCode;
  final CourseRelationType relationType;
  final double relevanceScore; // 0.0 -> 1.0
  final List<String> sharedConcepts;
  final String explanation;

  int get relevancePercentage => (relevanceScore * 100).round().clamp(0, 100);
}
