class PersonalNote {
  const PersonalNote({
    required this.id,
    required this.title,
    required this.body,
    required this.courseCode,
    required this.updatedAt,
    required this.path,
  });

  final String id;
  final String title;
  final String body;
  final String courseCode;
  final DateTime updatedAt;
  final String path;
}
