import 'curriculum_catalog.dart';

class CourseAssistantAnswer {
  const CourseAssistantAnswer({
    required this.markdown,
    this.course,
    this.sourceUrl,
  });

  final String markdown;
  final CurriculumCourse? course;
  final String? sourceUrl;
}
