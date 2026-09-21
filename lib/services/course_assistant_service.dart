import '../domain/models/course_assistant_answer.dart';
import '../domain/models/course_knowledge.dart';
import '../domain/models/curriculum_catalog.dart';
import 'course_knowledge_service.dart';

abstract class ICourseAssistantService {
  Future<CourseAssistantAnswer> answer(
    String question,
    List<CurriculumCourse> courses,
  );
}

class CourseAssistantService implements ICourseAssistantService {
  CourseAssistantService({ICourseKnowledgeService? knowledgeService})
    : _knowledgeService = knowledgeService ?? CourseKnowledgeService();

  final ICourseKnowledgeService _knowledgeService;

  @override
  Future<CourseAssistantAnswer> answer(
    String question,
    List<CurriculumCourse> courses,
  ) async {
    final clean = question.trim();
    if (clean.isEmpty) {
      return const CourseAssistantAnswer(
        markdown: 'Hãy nhập mã môn hoặc câu hỏi bạn muốn tìm hiểu.',
      );
    }
    final normalized = _fold(clean);
    final semester = _semesterFrom(normalized);
    final course = _findCourse(clean, courses);

    if (course == null && semester != null) {
      return _semesterAnswer(semester, normalized, courses);
    }
    if (course == null) {
      return const CourseAssistantAnswer(
        markdown: 'Mình chưa xác định được môn học trong câu hỏi. Hãy thêm mã môn, ví dụ **PRM393**, **SWD392** hoặc hỏi “Các môn kỳ 8?”.',
      );
    }

    CourseKnowledge? knowledge;
    try {
      knowledge = await _knowledgeService.load(course);
    } catch (_) {
      return CourseAssistantAnswer(
        course: course,
        markdown:
            '## ${course.code} · ${course.name}\n\n'
            '- Học kỳ: **${course.semester}**\n'
            '- Tiên quyết: **${_prerequisiteText(course)}**\n\n'
            'Không đọc được syllabus chi tiết của môn này.',
      );
    }

    if (_containsAny(normalized, ['tin chi', 'credit'])) {
      return _answer(
        course,
        knowledge,
        '## Tín chỉ của ${course.code}\n\n'
        '${knowledge.credits == null ? 'Syllabus chưa ghi rõ số tín chỉ.' : '**${knowledge.credits} tín chỉ**.'}',
      );
    }
    if (_containsAny(normalized, ['thoi luong', 'bao lau', 'thoi gian'])) {
      return _answer(
        course,
        knowledge,
        '## Thời lượng ${course.code}\n\n'
        '${knowledge.durationMarkdown.isEmpty ? 'Syllabus chưa ghi rõ thời lượng.' : knowledge.durationMarkdown}',
      );
    }
    if (_containsAny(normalized, ['tien quyet', 'hoc truoc'])) {
      return _answer(
        course,
        knowledge,
        '## Môn tiên quyết của ${course.code}\n\n'
        '${course.prerequisiteCodes.isEmpty ? 'Không có môn tiên quyết được ghi trong curriculum.' : course.prerequisiteCodes.map((code) => '- **$code**').join('\n')}',
      );
    }
    if (_containsAny(normalized, ['cong cu', 'phan mem', 'cai dat'])) {
      return _answer(
        course,
        knowledge,
        '## Công cụ cho ${course.code}\n\n'
        '${knowledge.toolsMarkdown.isEmpty ? 'Syllabus chưa có danh sách công cụ.' : knowledge.toolsMarkdown}',
      );
    }
    if (_containsAny(normalized, ['noi dung', 'chu de', 'module'])) {
      return _answer(
        course,
        knowledge,
        '## Nội dung chính của ${course.code}\n\n'
        '${knowledge.topics.isEmpty ? 'Chưa trích xuất được module nội dung.' : knowledge.topics.map((topic) => '- ${topic.title}').join('\n')}',
      );
    }

    final description = knowledge.descriptionMarkdown.isEmpty
        ? 'Syllabus chưa có phần mô tả.'
        : knowledge.descriptionMarkdown;
    final topicPreview = knowledge.topics.take(5).toList();
    return _answer(
      course,
      knowledge,
      '## ${course.code} · ${course.name}\n\n'
      '$description\n\n'
      '### Thông tin nhanh\n\n'
      '- Học kỳ: **${course.semester}**\n'
      '- Tín chỉ: **${knowledge.credits ?? 'chưa rõ'}**\n'
      '- Tiên quyết: **${_prerequisiteText(course)}**'
      '${topicPreview.isEmpty ? '' : '\n\n### Module tiêu biểu\n\n${topicPreview.map((topic) => '- ${topic.title}').join('\n')}'}',
    );
  }

  CourseAssistantAnswer _semesterAnswer(
    int semester,
    String normalized,
    List<CurriculumCourse> courses,
  ) {
    final semesterCourses = courses
        .where((course) => course.semester == semester)
        .toList();
    if (semesterCourses.isEmpty) {
      return CourseAssistantAnswer(
        markdown: 'Curriculum đang chọn không có dữ liệu cho học kỳ $semester.',
      );
    }
    final prerequisitesOnly = _containsAny(normalized, [
      'tien quyet',
      'hoc truoc',
    ]);
    final rows = semesterCourses
        .map((course) {
          final prerequisite = _prerequisiteText(course);
          return prerequisitesOnly
              ? '- **${course.code}** · ${course.name}: $prerequisite'
              : '- **${course.code}** · ${course.name}';
        })
        .join('\n');
    return CourseAssistantAnswer(
      markdown:
          '## Học kỳ $semester\n\n'
          'Có **${semesterCourses.length} môn / phương án** trong curriculum đang chọn.\n\n'
          '$rows',
    );
  }

  CourseAssistantAnswer _answer(
    CurriculumCourse course,
    CourseKnowledge knowledge,
    String markdown,
  ) => CourseAssistantAnswer(
    course: course,
    markdown: markdown,
    sourceUrl: knowledge.sourceUrl,
  );

  CurriculumCourse? _findCourse(
    String question,
    List<CurriculumCourse> courses,
  ) {
    for (final course in courses) {
      if (RegExp(
        '(^|[^A-Za-z0-9])${RegExp.escape(course.code)}([^A-Za-z0-9]|\$)',
        caseSensitive: false,
      ).hasMatch(question)) {
        return course;
      }
    }
    final normalized = _fold(question);
    for (final course in courses) {
      final name = _fold(course.name);
      if (name.length >= 5 && normalized.contains(name)) return course;
    }
    return null;
  }

  int? _semesterFrom(String question) {
    final match = RegExp(r'(?:hoc\s*)?ky\s*(\d{1,2})').firstMatch(question);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String _prerequisiteText(CurriculumCourse course) =>
      course.prerequisiteCodes.isEmpty
      ? 'không có trong dataset'
      : course.prerequisiteCodes.join(', ');

  bool _containsAny(String source, List<String> values) =>
      values.any(source.contains);

  String _fold(String value) {
    const accented =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const plain =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final character = String.fromCharCode(rune);
      final index = accented.indexOf(character);
      buffer.write(index == -1 ? character : plain[index]);
    }
    return buffer.toString();
  }
}
