import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/app.dart';
import 'package:rhyolite/design_system/app_theme.dart';
import 'package:rhyolite/models/course_knowledge.dart';
import 'package:rhyolite/models/curriculum_catalog.dart';
import 'package:rhyolite/models/personal_note.dart';
import 'package:rhyolite/models/student_transcript.dart';
import 'package:rhyolite/services/course_knowledge_service.dart';
import 'package:rhyolite/services/curriculum_service.dart';
import 'package:rhyolite/services/personal_note_service.dart';
import 'package:rhyolite/services/transcript_service.dart';
import 'package:rhyolite/viewmodels/home_viewmodel.dart';

class _TestCurriculumService implements ICurriculumService {
  @override
  Future<CurriculumCatalog> loadCatalog() async => _catalog;
}

class _TestKnowledgeService implements ICourseKnowledgeService {
  @override
  Future<CourseKnowledge> load(
    CurriculumCourse course,
  ) async => CourseKnowledge(
    code: course.code,
    name: course.name,
    bodyMarkdown:
        '# ${course.code} - ${course.name}\n\n## Nội dung\n\nDữ liệu syllabus.',
    sourceMarkdown: '# ${course.code}',
    descriptionMarkdown: 'Mô tả kiểm thử cho ${course.code}.',
    durationMarkdown: '150 giờ học',
    toolsMarkdown: 'VS Code',
    topics: const [
      KnowledgeTopic(id: 'M1', title: 'M1 · Flutter fundamentals'),
      KnowledgeTopic(id: 'M2', title: 'M2 · State management'),
    ],
    credits: '3',
    sourceUrl: 'https://example.test/syllabus',
  );
}

class _MemoryNoteService implements IPersonalNoteService {
  final notes = <PersonalNote>[];

  @override
  Future<void> delete(PersonalNote note) async =>
      notes.removeWhere((candidate) => candidate.id == note.id);

  @override
  Future<List<PersonalNote>> loadForCourse(String courseCode) async =>
      notes.where((note) => note.courseCode == courseCode).toList();

  @override
  Future<List<PersonalNote>> loadRecent({int limit = 5}) async {
    final sorted = [...notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<PersonalNote> save({
    required String title,
    required String body,
    required String courseCode,
    PersonalNote? original,
  }) async {
    final note = PersonalNote(
      id: original?.id ?? 'test-note-${notes.length}',
      title: title.trim(),
      body: body.trim(),
      courseCode: courseCode,
      updatedAt: DateTime.utc(2026, 9, 21),
      path: '/tmp/test-note.md',
    );
    notes.removeWhere((candidate) => candidate.id == note.id);
    notes.add(note);
    return note;
  }
}

class _MemoryTranscriptRepository implements ITranscriptRepository {
  _MemoryTranscriptRepository([this.transcript]);

  StudentTranscript? transcript;

  @override
  Future<void> delete() async => transcript = null;

  @override
  Future<StudentTranscript?> load() async => transcript;

  @override
  Future<void> save(StudentTranscript value) async => transcript = value;
}

const _sharedCourses = [
  CurriculumCourse(
    code: 'OTP101',
    name: 'Định hướng',
    semester: 0,
    groupCodes: ['OTP101'],
    notePath: 'Mon hoc/OTP101.md',
  ),
  CurriculumCourse(
    code: 'PRF192',
    name: 'Cơ sở lập trình',
    semester: 1,
    groupCodes: ['PRF192'],
    notePath: 'Mon hoc/PRF192.md',
  ),
  CurriculumCourse(
    code: 'PRO192',
    name: 'Lập trình hướng đối tượng',
    semester: 2,
    groupCodes: ['PRO192'],
    notePath: 'Mon hoc/PRO192.md',
  ),
  CurriculumCourse(
    code: 'SWP391',
    name: 'Dự án phát triển phần mềm',
    semester: 5,
    groupCodes: ['SWP391'],
    notePath: 'Mon hoc/SWP391.md',
  ),
  CurriculumCourse(
    code: 'ENW493c',
    name: 'Phương pháp nghiên cứu',
    semester: 6,
    groupCodes: ['ENW493c'],
    notePath: 'Mon hoc/ENW493c.md',
  ),
  CurriculumCourse(
    code: 'SWD392',
    name: 'Kiến trúc và thiết kế phần mềm',
    semester: 7,
    groupCodes: ['SWD392'],
    notePath: 'Mon hoc/SWD392.md',
  ),
  CurriculumCourse(
    code: 'PMG201c',
    name: 'Quản trị dự án',
    semester: 7,
    groupCodes: ['PMG201c'],
    notePath: 'Mon hoc/PMG201c.md',
  ),
  CurriculumCourse(
    code: 'ITE302c',
    name: 'Đạo đức trong CNTT',
    semester: 8,
    groupCodes: ['ITE302c'],
    notePath: 'Mon hoc/ITE302c.md',
  ),
  CurriculumCourse(
    code: 'PRM393',
    name: 'Lập trình di động',
    semester: 8,
    groupCodes: ['PRM393'],
    prerequisiteCodes: ['PRO192'],
    notePath: 'Mon hoc/PRM393.md',
  ),
  CurriculumCourse(
    code: 'SEP490',
    name: 'Đồ án tốt nghiệp KTPM',
    semester: 9,
    groupCodes: ['SEP490'],
    notePath: 'Mon hoc/SEP490.md',
  ),
];

const _catalog = CurriculumCatalog(
  schemaVersion: 1,
  source: 'test',
  curricula: [
    Curriculum(
      code: 'BIT_SE_K19B',
      courses: [
        ..._sharedCourses,
        CurriculumCourse(
          code: 'CSD201',
          name: 'Cấu trúc dữ liệu và giải thuật',
          semester: 3,
          groupCodes: ['CSD201'],
          notePath: 'Mon hoc/CSD201.md',
        ),
        CurriculumCourse(
          code: 'SWR302',
          name: 'Yêu cầu phần mềm',
          semester: 5,
          groupCodes: ['SWR302'],
          notePath: 'Mon hoc/SWR302.md',
        ),
      ],
    ),
    Curriculum(code: 'BIT_SE_K19D_K20A', courses: _sharedCourses),
    Curriculum(code: 'BIT_SE_K20B', courses: _sharedCourses),
    Curriculum(
      code: 'BIT_SE_K21B',
      courses: [
        ..._sharedCourses,
        CurriculumCourse(
          code: 'CSD201',
          name: 'Cấu trúc dữ liệu và giải thuật',
          semester: 4,
          groupCodes: ['CSD201'],
          notePath: 'Mon hoc/CSD201.md',
        ),
        CurriculumCourse(
          code: 'SWE202c',
          name: 'Nhập môn kỹ thuật phần mềm',
          semester: 3,
          groupCodes: ['SWE202c'],
          notePath: 'Mon hoc/SWE202c.md',
        ),
      ],
    ),
  ],
);

RhyoliteApp _testApp({
  _MemoryNoteService? noteService,
  ITranscriptRepository? transcriptRepository,
}) => RhyoliteApp(
  homeViewModel: HomeViewModel(curriculumService: _TestCurriculumService()),
  courseKnowledgeService: _TestKnowledgeService(),
  noteService: noteService ?? _MemoryNoteService(),
  transcriptRepository: transcriptRepository ?? _MemoryTranscriptRepository(),
);

void main() {
  testWidgets('Desktop shell navigates with accessible controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Học đúng môn, đúng thời điểm.'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Chương trình học'), findsWidgets);
    expect(find.text('Bảng điểm'), findsOneWidget);
    expect(find.byTooltip('Tải lại dữ liệu'), findsOneWidget);
    expect(find.byTooltip('Thông tin ứng dụng'), findsOneWidget);
    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();
    expect(find.text('Software Engineering'), findsOneWidget);
    expect(find.byKey(const ValueKey('semester:0')), findsOneWidget);
    expect(find.byKey(const ValueKey('semester:9')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('semester-horizontal-scroll')),
      findsOneWidget,
    );
    final lastSemester = find.byKey(const ValueKey('semester:9'));
    final initialLastSemesterX = tester.getTopLeft(lastSemester).dx;
    await tester.drag(
      find.byKey(const ValueKey('semester-horizontal-scroll')),
      const Offset(-1800, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(lastSemester).dx, lessThan(initialLastSemesterX));

    final refresh = find.byTooltip('Tải lại dữ liệu');
    expect(tester.getSize(refresh).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(refresh).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Bảng điểm'));
    await tester.pumpAndSettle();
    expect(find.text('Bảng điểm học tập'), findsOneWidget);
    expect(find.text('Chọn file Excel'), findsOneWidget);
    expect(find.text('Software Engineering'), findsNothing);
  });

  testWidgets(
    'Curriculum search filters cards and course target opens detail',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chương trình học'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('course-search')),
        'PRF192',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('course:PRF192')), findsOneWidget);
      expect(find.byKey(const ValueKey('course:CSD201')), findsNothing);
      expect(find.byKey(const ValueKey('semester:1')), findsOneWidget);
      expect(find.byKey(const ValueKey('semester:3')), findsNothing);
      final target = find.byKey(const ValueKey('course:PRF192'));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));

      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Syllabus'), findsOneWidget);
      expect(find.text('Graph'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.textContaining('Mô tả kiểm thử cho PRF192'), findsOneWidget);
    },
  );

  testWidgets('Imported grades are pinned to curriculum and course detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final transcript = StudentTranscript(
      sourceFileName: 'AcademicTranscript.xls',
      importedAt: DateTime.utc(2026, 9, 21),
      records: const [
        TranscriptRecord(
          term: 'Fall2025',
          semester: '1',
          subjectCode: 'PRF192',
          subjectName: 'Cơ sở lập trình',
          prerequisite: '',
          replacedSubject: '',
          credit: '3',
          grade: '8.5',
          status: 'Passed',
          matchesCurriculum: true,
        ),
      ],
    );
    await tester.pumpWidget(
      _testApp(transcriptRepository: _MemoryTranscriptRepository(transcript)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();
    expect(find.text('8.5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('course:PRF192')));
    await tester.pumpAndSettle();
    expect(find.text('Điểm 8.5 · Passed'), findsOneWidget);
  });

  testWidgets('Curriculum graph selects a node and opens course detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem graph'));
    await tester.pumpAndSettle();

    expect(find.text('Graph chương trình'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curriculum-graph-viewer')),
      findsOneWidget,
    );
    final graphNode = find
        .byKey(const ValueKey('curriculum-graph-node:PRF192'))
        .hitTestable();
    expect(graphNode, findsOneWidget);
    await tester.tap(graphNode);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết'), findsOneWidget);

    await tester.tap(find.text('Chi tiết'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mô tả kiểm thử cho PRF192'), findsOneWidget);
  });

  testWidgets('Local study assistant answers a course question', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trợ lý AI'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'PRM393 có bao nhiêu tín chỉ?',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 tín chỉ'), findsOneWidget);
    expect(find.text('Mở chi tiết môn'), findsOneWidget);
    expect(find.text('Nguồn: syllabus FPT'), findsOneWidget);
  });

  testWidgets('Course detail graph opens a prerequisite course', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('course-search')),
      'PRM393',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('course:PRM393')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graph'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('graph-node:PRM393')), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-node:PRO192')), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-topic:M1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('graph-node:PRO192')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mô tả kiểm thử cho PRO192'), findsOneWidget);
  });

  testWidgets('Course note is created and appears in its note tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notes = _MemoryNoteService();
    await tester.pumpWidget(_testApp(noteService: notes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('course-search')),
      'PRM393',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('course:PRM393')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-course-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title')),
      'Ôn tập Flutter',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-body')),
      '# Widget tree\n\nÔn StatelessWidget và StatefulWidget.',
    );
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghi chú'));
    await tester.pumpAndSettle();
    expect(find.text('Ôn tập Flutter'), findsOneWidget);
    expect(notes.notes, hasLength(1));
    expect(notes.notes.single.courseCode, 'PRM393');

    await tester.tap(find.text('Graph'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('graph-note:test-note-0')),
      findsOneWidget,
    );
  });

  testWidgets('K21 preview follows imported semester mapping', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();

    Finder inSemester(String code, int semester) => find.descendant(
      of: find.byKey(ValueKey('semester:$semester')),
      matching: find.byKey(ValueKey('course:$code')),
    );

    expect(inSemester('SWP391', 5), findsOneWidget);
    expect(inSemester('ENW493c', 6), findsOneWidget);
    expect(inSemester('SWD392', 7), findsOneWidget);
    expect(inSemester('PMG201c', 7), findsOneWidget);
    expect(inSemester('ITE302c', 8), findsOneWidget);
    expect(inSemester('PRM393', 8), findsOneWidget);
    expect(inSemester('SWP391', 8), findsNothing);
  });

  testWidgets('Curriculum switch applies curriculum-specific semesters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chương trình học'));
    await tester.pumpAndSettle();

    Finder inSemester(String code, int semester) => find.descendant(
      of: find.byKey(ValueKey('semester:$semester')),
      matching: find.byKey(ValueKey('course:$code')),
    );

    expect(inSemester('CSD201', 4), findsOneWidget);
    expect(inSemester('SWE202c', 3), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('curriculum-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SE · K19B').last);
    await tester.pumpAndSettle();

    expect(inSemester('CSD201', 3), findsOneWidget);
    expect(inSemester('SWR302', 5), findsOneWidget);
    expect(find.byKey(const ValueKey('course:SWE202c')), findsNothing);
  });

  testWidgets('Compact shell replaces rail with bottom navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('course-search')), findsNothing);
    await tester.tap(find.text('Curriculum'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('semester-horizontal-scroll')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('semester:0')), findsOneWidget);
    expect(find.byKey(const ValueKey('semester:9')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Light theme primary text contrast exceeds 4.5 to 1', () {
    final theme = AppTheme.light();
    final ratio = _contrastRatio(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    );
    expect(ratio, greaterThanOrEqualTo(4.5));
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background
      : foreground;
  return (lighter.computeLuminance() + .05) / (darker.computeLuminance() + .05);
}
