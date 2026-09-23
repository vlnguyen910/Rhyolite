import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/models/curriculum_catalog.dart';
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

  test(
    'loads structured SDN302 knowledge and extracts Backend concept wikilink',
    () async {
      const course = CurriculumCourse(
        code: 'SDN302',
        name: 'Server-Side development with NodeJS, Express, and MongoDB',
        semester: 7,
        groupCodes: ['SE_COM*2'],
        prerequisiteCodes: ['DBI202', 'FER202'],
        notePath: 'Mon hoc/SDN302 - Phát triển Server-Side với NodeJS, Express và MongoDB.md',
      );

      final knowledge = await CourseKnowledgeService().load(course);
      expect(knowledge.concepts, contains('Backend'));
    },
  );

  test('loads structured PRF192 knowledge and extracts Cơ sở lập trình concept wikilink', () async {
    const course = CurriculumCourse(
      code: 'PRF192',
      name: 'Cơ sở lập trình',
      semester: 1,
      groupCodes: ['PRF192'],
      prerequisiteCodes: [],
      notePath: 'Mon hoc/PRF192 - Cơ sở lập trình.md',
    );

    final knowledge = await CourseKnowledgeService().load(course);
    expect(knowledge.concepts, contains('Cơ sở lập trình'));
  });
}
