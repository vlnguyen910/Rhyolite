import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/data/markdown_adapter.dart';
import 'package:rhyolite/domain/knowledge_document.dart';

String course(
  String code, {
  String semester = '"8"',
  String condition = '',
  String links = '',
}) =>
    '''
---
course_code: "$code"
semester: $semester
syllabus_id: "13822"
---
# $code - Course $code
## Mon tien quyet
$links
## Noi dung de cuong
| Điều kiện tiên quyết: | $condition |
[Nguồn](https://flm.fpt.edu.vn/gui/role/student/SyllabusDetails?sylID=13822)
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final adapter = MarkdownAdapter();
  const repository = KnowledgeRepository();

  test(
    'Adapter normalizes legacy metadata and preserves original OR conditions',
    () {
      final source = course(
        'SWR302',
        condition: 'SWE102 or SWE201c or SWE202c',
      );
      final node = adapter.parse(
        'knowledge/Mon hoc/SWR302 - Requirement.md',
        source,
      );
      expect(node.id, 'course:SWR302');
      expect(node.title, 'Course SWR302');
      expect(node.semester, 8);
      expect(node.prerequisiteText, 'SWE102 or SWE201c or SWE202c');
      expect(node.sourceMarkdown, source);
      expect(node.sources.single, contains('sylID=13822'));
    },
  );

  test(
    'Invalid YAML, missing code and fractional semester fail validation',
    () {
      expect(
        () => adapter.parse(
          'knowledge/Mon hoc/A.md',
          '---\ncourse_code: [\n---\n# A',
        ),
        throwsA(anything),
      );
      expect(
        () => adapter.parse(
          'knowledge/Mon hoc/A.md',
          '---\nsemester: 1\n---\n# A',
        ),
        throwsFormatException,
      );
      expect(
        () => adapter.parse(
          'knowledge/Mon hoc/A.md',
          course('A', semester: '8.5'),
        ),
        throwsFormatException,
      );
    },
  );

  test('One invalid document does not stop valid courses from loading', () {
    final snapshot = repository.build({
      'knowledge/Mon hoc/BAD.md': course('BAD', semester: '"eight"'),
      'knowledge/Mon hoc/PRM393.md': course('PRM393'),
    });
    expect(snapshot.courses.single.code, 'PRM393');
    expect(snapshot.issues.single.path, 'knowledge/Mon hoc/BAD.md');
    expect(snapshot.issues.single.severity, IssueSeverity.error);
  });

  test('Resolver supports aliases, paths, anchors and dots in basenames', () {
    final snapshot = repository.build({
      'knowledge/Mon hoc/PRN212 - .NET.md': course('PRN212'),
      'knowledge/Mon hoc/JPD113 - A1.1.md': course('JPD113'),
    });
    expect(snapshot.resolve('PRN212 - .NET|Dotnet')?.code, 'PRN212');
    expect(snapshot.resolve('Mon hoc/JPD113 - A1.1#Topics')?.code, 'JPD113');
    expect(snapshot.resolve('course:PRN212')?.code, 'PRN212');
    expect(
      snapshot
          .resolve('#Topics', fromPath: 'knowledge/Mon hoc/JPD113 - A1.1.md')
          ?.code,
      'JPD113',
    );
  });

  test('Duplicate IDs and missing links produce path-specific issues', () {
    final snapshot = repository.build({
      'knowledge/Mon hoc/A.md': course('A', links: '- [[Missing]]'),
      'knowledge/Mon hoc/Duplicate.md': course('A'),
    });
    expect(snapshot.courses, hasLength(1));
    expect(
      snapshot.issues.any((issue) => issue.message.contains('ID trùng')),
      isTrue,
    );
    expect(
      snapshot.issues.any((issue) => issue.message.contains('Missing')),
      isTrue,
    );
  });

  test('Prerequisite direction and reverse view are computed from metadata/sections', () {
    final snapshot = repository.build({
      'knowledge/Mon hoc/PRO192.md': course('PRO192'),
      'knowledge/Mon hoc/PRM393.md': course(
        'PRM393',
        links: '- [[PRO192|OOP]]',
      ),
    });
    final prm = snapshot.resolve('course:PRM393')!;
    final pro = snapshot.resolve('course:PRO192')!;
    expect(snapshot.prerequisites(prm), [pro]);
    expect(snapshot.dependents(pro), [prm]);
    expect(snapshot.prerequisites(pro), isEmpty);
  });

  test('Ambiguous bare basenames are not resolved arbitrarily', () {
    final snapshot = repository.build({
      'knowledge/a/Shared.md': '# First',
      'knowledge/b/Shared.md': '# Second',
    });
    expect(snapshot.resolve('Shared'), isNull);
    expect(snapshot.resolve('a/Shared')?.title, 'First');
    expect(snapshot.issues.single.message, contains('Tên file trùng'));
  });

  test(
    'Full imported dataset loads 76 courses without changing source files',
    () {
      final files = <String, String>{};
      for (final file in Directory(
        'knowledge',
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.md')) {
          files[file.path] = file.readAsStringSync();
        }
      }
      final snapshot = repository.build(files);
      expect(snapshot.courses.where((c) => !c.demo), hasLength(76));
      expect(
        snapshot.issues.where((i) => i.severity == IssueSeverity.error),
        isEmpty,
      );
      expect(
        snapshot.issues.where(
          (i) => i.message.contains('Liên kết không resolve'),
        ),
        isEmpty,
      );
      final prm = snapshot.resolve('course:PRM393')!;
      expect(snapshot.prerequisites(prm).single.code, 'PRO192');
      expect(
        snapshot.resolve('course:SWR302')!.prerequisiteText,
        contains(' or '),
      );
      expect(
        snapshot.resolve('course:WDP301')!.prerequisiteText,
        'FER201m, SDN301m',
      );
      expect(
        snapshot.issues.where((i) => i.message.contains('ngoài dataset')),
        hasLength(13),
      );
    },
  );

  test(
    'Asset bundle includes imported courses, hub and demo concept',
    () async {
      final snapshot = await repository.load();
      expect(snapshot.courses.where((c) => !c.demo), hasLength(76));
      expect(snapshot.resolve('sql-join')?.type, DocumentType.concept);
      expect(snapshot.resolve('00 - Danh mục các môn học theo kì'), isNotNull);
    },
  );
}
