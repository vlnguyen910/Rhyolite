import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/services/curriculum_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled curriculum contains every unique course from the mapping',
    () async {
      final catalog = await CurriculumService().loadCatalog();

      expect(catalog.codes, [
        'BIT_SE_K19B',
        'BIT_SE_K19D_K20A',
        'BIT_SE_K20B',
        'BIT_SE_K21B',
      ]);
      expect(catalog.find('BIT_SE_K19B')?.courses, hasLength(86));
      expect(catalog.find('BIT_SE_K19D_K20A')?.courses, hasLength(86));
      expect(catalog.find('BIT_SE_K20B')?.courses, hasLength(85));
      expect(catalog.find('BIT_SE_K21B')?.courses, hasLength(85));
    },
  );

  test('K21 semesters and choice groups match the imported mapping', () async {
    final catalog = await CurriculumService().loadCatalog();
    final courses = catalog.find('BIT_SE_K21B')!.courses;
    final byCode = {for (final course in courses) course.code: course};

    expect(byCode['SWP391']?.semester, 5);
    expect(byCode['ENW493c']?.semester, 6);
    expect(byCode['SWD392']?.semester, 7);
    expect(byCode['PMG201c']?.semester, 7);
    expect(byCode['ITE302c']?.semester, 8);
    expect(byCode['PRM393']?.prerequisiteCodes, ['PRO192']);
    expect(byCode['AIL304m']?.groupCodes, ['SE_COM*2', 'SE_COM*3']);
    expect(byCode['AIL304m']?.isChoice, isTrue);
    expect(byCode['SWP391']?.isChoice, isFalse);
  });
}
