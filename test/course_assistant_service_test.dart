import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/domain/models/course_knowledge.dart';
import 'package:rhyolite/domain/models/curriculum_catalog.dart';
import 'package:rhyolite/services/course_assistant_service.dart';
import 'package:rhyolite/services/course_knowledge_service.dart';

class _KnowledgeService implements ICourseKnowledgeService {
  @override
  Future<CourseKnowledge> load(CurriculumCourse course) async =>
      CourseKnowledge(
        code: course.code,
        name: course.name,
        bodyMarkdown: '',
        sourceMarkdown: '',
        descriptionMarkdown: 'Học Flutter và Dart.',
        durationMarkdown: '150 giờ',
        toolsMarkdown: 'Flutter SDK',
        topics: const [KnowledgeTopic(id: 'M1', title: 'M1 · Flutter')],
        credits: '3',
        sourceUrl: 'https://example.test/syllabus',
      );
}

const _courses = [
  CurriculumCourse(
    code: 'PRO192',
    name: 'Lập trình hướng đối tượng',
    semester: 2,
    groupCodes: ['PRO192'],
    notePath: 'PRO192.md',
  ),
  CurriculumCourse(
    code: 'PRM393',
    name: 'Lập trình di động',
    semester: 8,
    groupCodes: ['PRM393'],
    prerequisiteCodes: ['PRO192'],
    notePath: 'PRM393.md',
  ),
];

void main() {
  final service = CourseAssistantService(knowledgeService: _KnowledgeService());

  test('answers course credit question from local syllabus', () async {
    final answer = await service.answer(
      'PRM393 có bao nhiêu tín chỉ?',
      _courses,
    );

    expect(answer.course?.code, 'PRM393');
    expect(answer.markdown, contains('3 tín chỉ'));
    expect(answer.sourceUrl, isNotNull);
  });

  test('lists prerequisite context for a semester', () async {
    final answer = await service.answer(
      'Các môn tiên quyết của kỳ 8?',
      _courses,
    );

    expect(answer.markdown, contains('PRM393'));
    expect(answer.markdown, contains('PRO192'));
  });
}
