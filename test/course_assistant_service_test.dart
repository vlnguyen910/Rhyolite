import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rhyolite/domain/models/course_knowledge.dart';
import 'package:rhyolite/domain/models/curriculum_catalog.dart';
import 'package:rhyolite/domain/models/student_transcript.dart';
import 'package:rhyolite/services/course_assistant_service.dart';
import 'package:rhyolite/services/course_knowledge_service.dart';
import 'package:rhyolite/services/groq_course_assistant_service.dart';

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

final _transcript = StudentTranscript(
  sourceFileName: 'AcademicTranscript.xls',
  importedAt: DateTime.utc(2026, 9, 21),
  records: const [
    TranscriptRecord(
      term: 'Fall2025',
      semester: '8',
      subjectCode: 'PRM393',
      subjectName: 'Lập trình di động',
      prerequisite: 'PRO192',
      replacedSubject: '',
      credit: '3',
      grade: '8.5',
      status: 'Passed',
      matchesCurriculum: true,
    ),
    TranscriptRecord(
      term: 'Fall2025',
      semester: '2',
      subjectCode: 'PRO192',
      subjectName: 'Lập trình hướng đối tượng',
      prerequisite: '',
      replacedSubject: '',
      credit: '3',
      grade: '4',
      status: 'Not passed',
      matchesCurriculum: true,
    ),
  ],
);

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

  test('answers a course grade from the imported transcript', () async {
    final answer = await service.answer(
      'Điểm PRM393 của tôi là bao nhiêu?',
      _courses,
      transcript: _transcript,
    );

    expect(answer.course?.code, 'PRM393');
    expect(answer.markdown, contains('8.5'));
    expect(answer.markdown, contains('Passed'));
  });

  test(
    'lists courses that are not passed from the imported transcript',
    () async {
      final answer = await service.answer(
        'Tôi còn môn nào chưa qua?',
        _courses,
        transcript: _transcript,
      );

      expect(answer.markdown, contains('PRO192'));
      expect(answer.markdown, isNot(contains('PRM393')));
    },
  );

  test('uses Groq response with local syllabus as grounding', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-key');
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      expect(requestBody['model'], 'test-model');
      expect(request.body, contains('PRM393'));
      expect(request.body, contains('Học Flutter và Dart'));
      expect(request.body, contains('điểm=8.5'));
      expect(request.body, contains('không yêu cầu người dùng gửi lại'));
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': 'Câu trả lời từ Groq về **PRM393**.'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final groq = GroqCourseAssistantService(
      apiKey: 'test-key',
      model: 'test-model',
      client: client,
      localService: service,
      knowledgeService: _KnowledgeService(),
    );

    final answer = await groq.answer(
      'PRM393 học gì?',
      _courses,
      transcript: _transcript,
    );

    expect(groq.providerLabel, contains('Groq'));
    expect(answer.markdown, contains('Câu trả lời từ Groq'));
    expect(answer.course?.code, 'PRM393');
    expect(answer.sourceUrl, isNotNull);
  });
}
