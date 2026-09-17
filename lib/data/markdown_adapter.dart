import 'package:yaml/yaml.dart';

import '../domain/knowledge_document.dart';

/// Converts the existing Obsidian format and demo schema without rewriting files.
class MarkdownAdapter {
  KnowledgeDocument parse(String path, String source) {
    final normalized = source
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    Map metadata = {};
    var body = normalized;
    if (lines.first.trim() == '---') {
      final end = lines.indexWhere((line) => line.trim() == '---', 1);
      if (end == -1) {
        throw const FormatException('Frontmatter chưa đóng bằng ---');
      }
      final parsed = loadYaml(lines.sublist(1, end).join('\n'));
      if (parsed is! Map) {
        throw const FormatException('Frontmatter phải là mapping');
      }
      metadata = parsed;
      body = lines.sublist(end + 1).join('\n').trim();
    }
    final legacyCourse = path.startsWith('knowledge/Mon hoc/');
    final type = legacyCourse || metadata['type'] == 'course'
        ? DocumentType.course
        : metadata['type'] == 'concept'
        ? DocumentType.concept
        : DocumentType.reference;
    if (legacyCourse && metadata.isEmpty) {
      throw const FormatException('Môn học thiếu frontmatter');
    }
    final code = _text(metadata['course_code'] ?? metadata['code'], 'code');
    final heading = RegExp(
      r'^# (.+)$',
      multiLine: true,
    ).firstMatch(body)?.group(1);
    var title =
        _text(metadata['title'], 'title') ??
        heading ??
        path.split('/').last.replaceFirst(RegExp(r'\.md$'), '');
    int? semester;
    if (type == DocumentType.course) {
      if (code == null) throw const FormatException('Môn học thiếu code');
      if (metadata['title'] == null && title.startsWith('$code - ')) {
        title = title.substring(code.length + 3);
      }
      final value = metadata['semester'];
      semester = value is int
          ? value
          : value is String
          ? int.tryParse(value)
          : null;
      if (semester == null || semester < 1 || semester > 20) {
        throw const FormatException('semester phải là số nguyên từ 1 đến 20');
      }
    }
    if (metadata['demo'] != null && metadata['demo'] is! bool) {
      throw const FormatException('demo phải là Boolean');
    }
    final id =
        _text(metadata['id'], 'id') ??
        (type == DocumentType.course ? 'course:$code' : 'reference:$path');
    final sources = <String>{..._list(metadata['sources'], 'sources')};
    for (final match in RegExp(
      r'https://flm\.fpt\.edu\.vn/[^\s)<>|]+',
    ).allMatches(body)) {
      sources.add(match.group(0)!);
    }
    String? condition;
    for (final line in body.split('\n')) {
      if (RegExp(r'^\|\s*Điều kiện tiên quyết:').hasMatch(line)) {
        condition = line.split('|')[2].trim();
        break;
      }
    }
    final prerequisiteSection =
        RegExp(
          r'^## Mon tien quyet\n([\s\S]*?)(?=^## |$(?![\s\S]))',
          multiLine: true,
        ).firstMatch(body)?.group(1) ??
        '';
    return KnowledgeDocument(
      id: id,
      type: type,
      title: title,
      path: path,
      body: body,
      sourceMarkdown: source,
      code: code,
      semester: semester,
      syllabusId: _text(metadata['syllabus_id'], 'syllabus_id'),
      demo: metadata['demo'] == true,
      prerequisiteText: condition,
      prerequisiteTargets: List.unmodifiable([
        ..._list(metadata['prerequisites'], 'prerequisites'),
        ...wikilinks(prerequisiteSection),
      ]),
      links: List.unmodifiable([
        ...wikilinks(body),
        ..._list(metadata['concepts'], 'concepts'),
        ..._list(metadata['related'], 'related'),
      ]),
      sources: List.unmodifiable(sources),
    );
  }

  List<String> wikilinks(String text) =>
      RegExp(r'\[\[([^\]]+)\]\]')
          .allMatches(text)
          .map((match) => match.group(1)!)
          .toList();

  String? _text(Object? value, String field) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$field phải là String không rỗng');
    }
    return value.trim();
  }

  List<String> _list(Object? value, String field) {
    if (value == null) return [];
    if (value is! List ||
        value.any((item) => item is! String || item.trim().isEmpty)) {
      throw FormatException('$field phải là danh sách String không rỗng');
    }
    return value.cast<String>().toList();
  }
}
