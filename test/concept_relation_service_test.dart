import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/models/course_concept.dart';
import 'package:rhyolite/models/curriculum_catalog.dart';
import 'package:rhyolite/services/concept_relation_service.dart';

void main() {
  late ConceptRelationService service;

  setUp(() {
    service = ConceptRelationService();
  });

  const sdn302 = CurriculumCourse(
    code: 'SDN302',
    name: 'Server-Side development with NodeJS',
    semester: 7,
    groupCodes: ['SE_COM*2'],
    prerequisiteCodes: ['DBI202', 'FER202'],
    notePath: 'Mon hoc/SDN302.md',
  );

  const prj301 = CurriculumCourse(
    code: 'PRJ301',
    name: 'Java Web Application',
    semester: 4,
    groupCodes: ['PRJ301'],
    prerequisiteCodes: ['DBI202', 'PRO192'],
    notePath: 'Mon hoc/PRJ301.md',
  );

  const prf192 = CurriculumCourse(
    code: 'PRF192',
    name: 'Cơ sở lập trình',
    semester: 1,
    groupCodes: ['PRF192'],
    prerequisiteCodes: [],
    notePath: 'Mon hoc/PRF192.md',
  );

  const pro192 = CurriculumCourse(
    code: 'PRO192',
    name: 'Lập trình hướng đối tượng',
    semester: 2,
    groupCodes: ['PRO192'],
    prerequisiteCodes: ['PRF192'],
    notePath: 'Mon hoc/PRO192.md',
  );

  const csd201 = CurriculumCourse(
    code: 'CSD201',
    name: 'Cấu trúc dữ liệu và giải thuật',
    semester: 3,
    groupCodes: ['CSD201'],
    prerequisiteCodes: ['PRO192'],
    notePath: 'Mon hoc/CSD201.md',
  );

  const mae101 = CurriculumCourse(
    code: 'MAE101',
    name: 'Toán cho ngành kỹ thuật',
    semester: 1,
    groupCodes: ['MAE101'],
    prerequisiteCodes: [],
    notePath: 'Mon hoc/MAE101.md',
  );

  const mad101 = CurriculumCourse(
    code: 'MAD101',
    name: 'Toán rời rạc',
    semester: 2,
    groupCodes: ['MAD101'],
    prerequisiteCodes: [],
    notePath: 'Mon hoc/MAD101.md',
  );

  const mas291 = CurriculumCourse(
    code: 'MAS291',
    name: 'Xác suất thống kê',
    semester: 4,
    groupCodes: ['MAS291'],
    prerequisiteCodes: ['MAE101'],
    notePath: 'Mon hoc/MAS291.md',
  );

  final testCourses = [
    sdn302,
    prj301,
    prf192,
    pro192,
    csd201,
    mae101,
    mad101,
    mas291,
  ];

  test('SDN302 is classified as Backend and connects with PRJ301', () {
    final sdnConcepts = service.getConceptsForCourse('SDN302');
    expect(sdnConcepts, contains('Backend'));

    final related = service.getRelatedCourses('SDN302', testCourses);
    expect(related, isNotEmpty);

    final topRelated = related.firstWhere(
      (r) => r.targetCourseCode == 'PRJ301',
    );
    expect(topRelated.relevanceScore, greaterThanOrEqualTo(0.5));
    expect(topRelated.sharedConcepts, contains('Backend'));
  });

  test(
    'PRF192 is identified as foundational programming for PRO192 and CSD201',
    () {
      final prfConcepts = service.getConceptsForCourse('PRF192');
      expect(prfConcepts, contains('Cơ sở lập trình'));

      final related = service.getRelatedCourses('PRF192', testCourses);
      final proRelation = related.firstWhere(
        (r) => r.targetCourseCode == 'PRO192',
      );

      expect(proRelation.relevanceScore, greaterThan(0.4));
      expect(
        proRelation.relationType == CourseRelationType.foundation ||
            proRelation.relationType == CourseRelationType.prerequisite,
        isTrue,
      );
    },
  );

  test('MAS291, MAD101 and MAE101 are linked via Toán concept', () {
    final maeConcepts = service.getConceptsForCourse('MAE101');
    final madConcepts = service.getConceptsForCourse('MAD101');
    final masConcepts = service.getConceptsForCourse('MAS291');

    expect(maeConcepts, contains('Toán'));
    expect(madConcepts, contains('Toán'));
    expect(masConcepts, contains('Toán'));

    final mathCourses = service.getCoursesForConcept('Toán', testCourses);
    expect(mathCourses, containsAll(['MAE101', 'MAD101', 'MAS291']));

    final relatedToMae = service.getRelatedCourses('MAE101', testCourses);
    final toMas = relatedToMae.firstWhere(
      (r) => r.targetCourseCode == 'MAS291',
    );
    expect(toMas.sharedConcepts, contains('Toán'));
    expect(toMas.relevanceScore, greaterThanOrEqualTo(0.5));
  });

  test('Dynamic concepts from markdown merge with standard catalog', () {
    final concepts = service.getConceptsForCourse(
      'SDN302',
      dynamicConcepts: ['Microservices', 'GraphQL'],
    );
    expect(concepts, containsAll(['Backend', 'Microservices', 'GraphQL']));
  });

  test(
    'Calculates pairwise curriculum concept relations without duplicates',
    () {
      final relations = service.getCurriculumConceptRelations(testCourses);
      expect(relations, isNotEmpty);

      final keys = <String>{};
      for (final rel in relations) {
        final key = '${rel.sourceCourseCode}:${rel.targetCourseCode}';
        expect(keys.add(key), isTrue);
      }
    },
  );
}
