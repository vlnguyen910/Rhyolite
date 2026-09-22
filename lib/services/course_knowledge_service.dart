import 'package:flutter/services.dart';

import '../models/course_knowledge.dart';
import '../models/curriculum_catalog.dart';

abstract class ICourseKnowledgeService {
  Future<CourseKnowledge> load(CurriculumCourse course);
}

class CourseKnowledgeService implements ICourseKnowledgeService {
  CourseKnowledgeService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const _assetRoot = 'knowledge/New Knowledge/';

  final AssetBundle _bundle;

  @override
  Future<CourseKnowledge> load(CurriculumCourse course) async {
    final source = await _bundle.loadString('$_assetRoot${course.notePath}');
    final normalized = source
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .replaceAll('\r\n', '\n');
    final body = _withoutFrontmatter(normalized);

    return CourseKnowledge(
      code: course.code,
      name: course.name,
      bodyMarkdown: body,
      sourceMarkdown: normalized,
      descriptionMarkdown: _section(body, 'Mô tả'),
      durationMarkdown: _section(body, 'Thời lượng'),
      toolsMarkdown: _section(body, 'Công cụ'),
      topics: _topics(body),
      credits: _tableValue(body, 'NoCredit'),
      sourceUrl: _tableValue(body, 'sourceUrl'),
    );
  }

  String _withoutFrontmatter(String source) {
    if (!source.startsWith('---\n')) return source.trim();
    final end = source.indexOf('\n---\n', 4);
    return end == -1 ? source.trim() : source.substring(end + 5).trim();
  }

  String _section(String source, String heading) {
    final match = RegExp(
      '^### ${RegExp.escape(heading)}\\s*\n([\\s\\S]*?)(?=^### |^## |\$(?![\\s\\S]))',
      multiLine: true,
    ).firstMatch(source);
    return match?.group(1)?.trim() ?? '';
  }

  String? _tableValue(String source, String field) {
    final match = RegExp(
      '^\\|\\s*${RegExp.escape(field)}\\s*\\|\\s*(.*?)\\s*\\|\\s*\$',
      multiLine: true,
    ).firstMatch(source);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<KnowledgeTopic> _topics(String source) {
    final topics = <KnowledgeTopic>[];
    final seen = <String>{};
    final modulePattern = RegExp(
      r'\b(M\d+)\s*[–—-]\s*([^|.\n<]+)',
      caseSensitive: false,
    );
    for (final match in modulePattern.allMatches(source)) {
      final module = match.group(1)!.toUpperCase();
      final title = match.group(2)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      final key = '$module ${title.toLowerCase()}';
      if (title.isEmpty || !seen.add(key)) continue;
      topics.add(KnowledgeTopic(id: module, title: '$module · $title'));
      if (topics.length == 12) break;
    }
    if (topics.isNotEmpty) return topics;

    const excluded = {
      'thông tin đề cương',
      'mô tả',
      'thời lượng',
      'yêu cầu sinh viên',
      'công cụ',
      'ghi chú',
      'điều kiện tiên quyết nguyên văn',
      'download all student material',
    };
    for (final match in RegExp(
      r'^###\s+(.+)$',
      multiLine: true,
    ).allMatches(source)) {
      final title = match.group(1)!.trim();
      final normalized = title.toLowerCase();
      if (excluded.contains(normalized) ||
          RegExp(r'^\d+\s').hasMatch(normalized) ||
          !seen.add(normalized)) {
        continue;
      }
      topics.add(
        KnowledgeTopic(id: 'topic-${topics.length + 1}', title: title),
      );
      if (topics.length == 8) break;
    }
    return topics;
  }
}
