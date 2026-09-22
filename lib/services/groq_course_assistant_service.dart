import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/course_assistant_answer.dart';
import '../models/course_knowledge.dart';
import '../models/curriculum_catalog.dart';
import '../models/student_transcript.dart';
import 'course_assistant_service.dart';
import 'course_knowledge_service.dart';

class GroqCourseAssistantService implements ICourseAssistantService {
  GroqCourseAssistantService({
    String? apiKey,
    String? model,
    http.Client? client,
    ICourseAssistantService? localService,
    ICourseKnowledgeService? knowledgeService,
  }) : _apiKey = apiKey ?? _configurationValue('GROQ_API_KEY'),
       _model =
           model ?? _configurationValue('GROQ_MODEL') ?? 'openai/gpt-oss-20b',
       _client = client ?? http.Client(),
       _localService =
           localService ??
           CourseAssistantService(knowledgeService: knowledgeService),
       _knowledgeService = knowledgeService ?? CourseKnowledgeService();

  static final Uri _endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );

  final String? _apiKey;
  final String _model;
  final http.Client _client;
  final ICourseAssistantService _localService;
  final ICourseKnowledgeService _knowledgeService;

  bool get isConfigured => _apiKey?.trim().isNotEmpty ?? false;

  @override
  String get providerLabel => isConfigured
      ? 'Groq · curriculum, syllabus và bảng điểm đã import'
      : 'Dữ liệu local · chưa cấu hình Groq';

  @override
  Future<CourseAssistantAnswer> answer(
    String question,
    List<CurriculumCourse> courses, {
    StudentTranscript? transcript,
  }) async {
    final localAnswer = await _localService.answer(
      question,
      courses,
      transcript: transcript,
    );
    if (!isConfigured || question.trim().isEmpty) return localAnswer;

    final context = await _buildContext(
      question,
      localAnswer,
      courses,
      transcript,
    );
    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer ${_apiKey!.trim()}',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'temperature': 0.2,
              'max_completion_tokens': 1400,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Bạn là trợ lý học tập cho sinh viên ngành Kỹ thuật phần mềm FPTU. '
                      'Chỉ sử dụng dữ liệu tham chiếu được cung cấp. Nếu dữ liệu chưa đủ, '
                      'hãy nói rõ phần nào chưa có. Không tự tạo tín chỉ, điểm số, điều kiện '
                      'tiên quyết hoặc quy định đào tạo. Nếu phần bảng điểm tham chiếu có dữ liệu, '
                      'hãy dùng trực tiếp và không yêu cầu người dùng gửi lại bảng điểm. '
                      'Trả lời bằng tiếng Việt, Markdown '
                      'ngắn gọn, ưu tiên thông tin thực hành và giữ nguyên mã môn.',
                },
                {
                  'role': 'user',
                  'content':
                      'Câu hỏi:\n${question.trim()}\n\n'
                      'Dữ liệu tham chiếu:\n$context',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback(localAnswer);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final markdown = _messageContent(decoded);
      if (markdown == null || markdown.trim().isEmpty) {
        return _fallback(localAnswer);
      }
      return CourseAssistantAnswer(
        markdown: markdown.trim(),
        course: localAnswer.course,
        sourceUrl: localAnswer.sourceUrl,
      );
    } catch (_) {
      return _fallback(localAnswer);
    }
  }

  Future<String> _buildContext(
    String question,
    CourseAssistantAnswer localAnswer,
    List<CurriculumCourse> courses,
    StudentTranscript? transcript,
  ) async {
    final buffer = StringBuffer()
      ..writeln('Kết quả truy xuất local:')
      ..writeln(localAnswer.markdown);
    final course = localAnswer.course;
    if (course != null) {
      try {
        final knowledge = await _knowledgeService.load(course);
        _writeCourseKnowledge(buffer, course, knowledge);
      } catch (_) {
        // The local answer already contains curriculum-level information.
      }
    } else {
      buffer
        ..writeln('\nDanh mục curriculum đang chọn:')
        ..writeln(
          courses
              .map(
                (item) =>
                    '- ${item.code}: ${item.name}; kỳ ${item.semester}; '
                    'tiên quyết: ${item.prerequisiteCodes.isEmpty ? 'không ghi' : item.prerequisiteCodes.join(', ')}',
              )
              .join('\n'),
        );
    }
    if (transcript != null && transcript.records.isNotEmpty) {
      final allRecords = transcript.latestBySubjectCode;
      final course = localAnswer.course;
      if (course != null) {
        final record = allRecords[course.code.toUpperCase()];
        if (record != null) _writeTranscript(buffer, [record]);
      } else if (_needsFullTranscript(question)) {
        _writeTranscript(buffer, allRecords.values);
      }
    } else if (_needsFullTranscript(question)) {
      buffer.writeln('\nBảng điểm cá nhân: chưa được import.');
    }
    return _limit(buffer.toString(), 18000);
  }

  void _writeTranscript(
    StringBuffer buffer,
    Iterable<TranscriptRecord> source,
  ) {
    final records = source.toList();
    buffer
      ..writeln('\nBảng điểm cá nhân đã import (${records.length} môn):')
      ..writeln(
        records
            .map(
              (record) =>
                  '- ${record.subjectCode}: ${record.subjectName}; '
                  'điểm=${record.grade.isEmpty ? 'chưa có' : record.grade}; '
                  'trạng thái=${record.status.isEmpty ? 'chưa rõ' : record.status}; '
                  'tín chỉ=${record.credit.isEmpty ? 'chưa rõ' : record.credit}; '
                  'term=${record.term.isEmpty ? 'chưa rõ' : record.term}',
            )
            .join('\n'),
      );
  }

  bool _needsFullTranscript(String question) {
    final normalized = _fold(question);
    return const [
      'diem',
      'bang diem',
      'ket qua',
      'gpa',
      'hoc luc',
      'tien do',
      'da qua',
      'chua qua',
      'rot',
      'truot',
      'passed',
      'studying',
      'tu van',
      'lo trinh ca nhan',
    ].any(normalized.contains);
  }

  String _fold(String value) {
    const accented =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const plain =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = accented.indexOf(character);
      buffer.write(index == -1 ? character : plain[index]);
    }
    return buffer.toString();
  }

  void _writeCourseKnowledge(
    StringBuffer buffer,
    CurriculumCourse course,
    CourseKnowledge knowledge,
  ) {
    buffer
      ..writeln('\nThông tin syllabus của ${course.code}:')
      ..writeln('- Tên: ${course.name}')
      ..writeln('- Học kỳ: ${course.semester}')
      ..writeln('- Tín chỉ: ${knowledge.credits ?? 'không ghi'}')
      ..writeln(
        '- Tiên quyết: ${course.prerequisiteCodes.isEmpty ? 'không ghi' : course.prerequisiteCodes.join(', ')}',
      )
      ..writeln('- Mô tả: ${knowledge.descriptionMarkdown}')
      ..writeln('- Thời lượng: ${knowledge.durationMarkdown}')
      ..writeln('- Công cụ: ${knowledge.toolsMarkdown}')
      ..writeln(
        '- Chủ đề: ${knowledge.topics.map((topic) => topic.title).join('; ')}',
      );
  }

  CourseAssistantAnswer _fallback(
    CourseAssistantAnswer localAnswer,
  ) => CourseAssistantAnswer(
    markdown:
        '${localAnswer.markdown}\n\n---\n*Groq hiện không phản hồi; nội dung trên được tạo từ dữ liệu local.*',
    course: localAnswer.course,
    sourceUrl: localAnswer.sourceUrl,
  );

  String? _messageContent(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final message = first['message'];
    if (message is! Map<String, dynamic>) return null;
    return message['content'] as String?;
  }

  String _limit(String source, int maxLength) => source.length <= maxLength
      ? source
      : '${source.substring(0, maxLength)}\n[Đã rút gọn dữ liệu tham chiếu]';
}

String? _configurationValue(String key) {
  final environmentValue = Platform.environment[key]?.trim();
  if (environmentValue?.isNotEmpty ?? false) return environmentValue;
  if (Platform.environment['FLUTTER_TEST'] == 'true') return null;

  final file = File('.env');
  if (!file.existsSync()) return null;
  try {
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0 || line.substring(0, separator).trim() != key) {
        continue;
      }
      final value = line.substring(separator + 1).trim();
      if (value.isNotEmpty) return value;
    }
  } on FileSystemException {
    return null;
  }
  return null;
}
