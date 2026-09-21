import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/domain/models/curriculum_catalog.dart';
import 'package:rhyolite/services/course_knowledge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads structured PRM393 knowledge from bundled Markdown', () async {
    const course = CurriculumCourse(
      code: 'PRM393',
      name: 'Lập trình di động',
      semester: 8,
      groupCodes: ['PRM393'],
      prerequisiteCodes: ['PRO192'],
      notePath: 'Mon hoc/PRM393 - Lập trình di động.md',
    );

    final knowledge = await CourseKnowledgeService().load(course);

    expect(knowledge.credits, '3');
    expect(knowledge.descriptionMarkdown, contains('Flutter'));
    expect(knowledge.durationMarkdown, contains('150h'));
    expect(knowledge.toolsMarkdown, contains('Android Studio'));
    expect(knowledge.bodyMarkdown, contains('### 7 LO(s)'));
    expect(knowledge.sourceMarkdown, startsWith('---'));
    expect(knowledge.topics, isNotEmpty);
    expect(knowledge.topics.first.title, contains('M1'));
  });
}
