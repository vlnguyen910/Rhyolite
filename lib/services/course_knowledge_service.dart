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
      concepts: _concepts(body, normalized),
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

  List<String> _concepts(String body, String normalized) {
    final concepts = <String>{};
    if (normalized.startsWith('---\n')) {
      final end = normalized.indexOf('\n---\n', 4);
      if (end != -1) {
        final frontmatter = normalized.substring(4, end);
        final inlineMatch = RegExp(
          r'^concepts:\s*\[(.*?)\]',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (inlineMatch != null) {
          final items = inlineMatch.group(1)!.split(',');
          for (final item in items) {
            final cleaned = item
                .trim()
                .replaceAll(RegExp(r'''^["']|["']$'''), '')
                .trim();
            if (cleaned.isNotEmpty) concepts.add(cleaned);
          }
        }
        final listMatches = RegExp(
          r'^concepts:\s*\n((?:\s*-\s*[^\n]+\n?)+)',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (listMatches != null) {
          final lines = listMatches.group(1)!.split('\n');
          for (final line in lines) {
            final cleaned = line
                .replaceFirst(RegExp(r'^\s*-\s*'), '')
                .trim()
                .replaceAll(RegExp(r'''^["']|["']$'''), '')
                .trim();
            if (cleaned.isNotEmpty) concepts.add(cleaned);
          }
        }
      }
    }

    final courseCodePattern = RegExp(r'^[A-Za-z]{2,5}\d{3}[a-zA-Z]?(-OLD)?$');
    final wikilinkPattern = RegExp(r'\[\[([^\]|#]+)(?:\|([^\]]+))?\]\]');
    for (final match in wikilinkPattern.allMatches(body)) {
      final target = match.group(1)!.trim();
      if (target.isEmpty) continue;
      if (target.contains('/') || target.contains(r'\')) continue;
      final firstToken = target.split(' - ').first.trim();
      if (courseCodePattern.hasMatch(firstToken)) continue;
      concepts.add(target);
    }
    return concepts.toList();
  }
}
