import 'package:flutter/services.dart';

import '../domain/knowledge_document.dart';
import 'markdown_adapter.dart';
import 'personal_note_store.dart';

class KnowledgeRepository {
  const KnowledgeRepository({this.noteStore});
  final PersonalNoteStore? noteStore;

  Future<KnowledgeSnapshot> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final manifest = await AssetManifest.loadFromAssetBundle(assets);
    final paths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('knowledge/') &&
                  path.endsWith('.md') &&
                  !path.split('/').any((part) => part.startsWith('.')),
            )
            .toList()
          ..sort();
    final sourceFiles = <String, String>{};
    final issues = <ValidationIssue>[];
    for (final path in paths) {
      try {
        sourceFiles[path] = await assets.loadString(path, cache: false);
      } catch (error) {
        issues.add(
          ValidationIssue(
            path,
            'Không đọc được file: $error',
            IssueSeverity.error,
          ),
        );
      }
    }
    if (noteStore != null) {
      final personal = await noteStore!.load();
      sourceFiles.addAll(personal.files);
      issues.addAll(personal.issues);
    }
    final snapshot = build(sourceFiles);
    return KnowledgeSnapshot(
      snapshot.documents,
      List.unmodifiable([...issues, ...snapshot.issues]),
    );
  }

  /// Pure pipeline used both by bundled assets and fixture tests.
  KnowledgeSnapshot build(Map<String, String> files) {
    final adapter = MarkdownAdapter();
    final documents = <KnowledgeDocument>[];
    final issues = <ValidationIssue>[];
    final ids = <String>{};
    final codes = <String>{};
    final basenames = <String, String>{};
    for (final entry in files.entries) {
      try {
        final document = adapter.parse(entry.key, entry.value);
        if (!ids.add(document.id)) {
          issues.add(
            ValidationIssue(
              entry.key,
              'ID trùng: ${document.id}',
              IssueSeverity.error,
            ),
          );
          continue;
        }
        if (document.code != null && !codes.add(document.code!)) {
          issues.add(
            ValidationIssue(
              entry.key,
              'Mã môn trùng: ${document.code}',
              IssueSeverity.error,
            ),
          );
          continue;
        }
        final basename = entry.key.split('/').last;
        if (basenames.containsKey(basename)) {
          issues.add(
            ValidationIssue(
              entry.key,
              'Tên file trùng với ${basenames[basename]}',
              IssueSeverity.warning,
            ),
          );
        }
        basenames[basename] = entry.key;
        documents.add(document);
      } catch (error) {
        issues.add(
          ValidationIssue(
            entry.key,
            'Không parse được: $error',
            IssueSeverity.error,
          ),
        );
      }
    }
    final snapshot = KnowledgeSnapshot(List.unmodifiable(documents), issues);
    for (final document in documents) {
      for (final target in {
        ...document.links,
        ...document.prerequisiteTargets,
        ...document.conceptTargets,
        ...document.courseTargets,
      }) {
        if (snapshot.resolve(target, fromPath: document.path) == null) {
          issues.add(
            ValidationIssue(
              document.path,
              'Liên kết không resolve được: $target',
              IssueSeverity.warning,
            ),
          );
        }
      }
      for (final relationship in [
        (document.conceptTargets, DocumentType.concept, 'concepts'),
        (document.courseTargets, DocumentType.course, 'courses'),
        (document.prerequisiteTargets, DocumentType.course, 'prerequisites'),
      ]) {
        for (final target in relationship.$1) {
          final resolved = snapshot.resolve(target, fromPath: document.path);
          if (resolved != null && resolved.type != relationship.$2) {
            issues.add(
              ValidationIssue(
                document.path,
                '${relationship.$3} tham chiếu sai loại node: $target',
                IssueSeverity.warning,
              ),
            );
          }
        }
      }
      if (document.type != DocumentType.course || document.demo) continue;
      if (document.sources.isEmpty) {
        issues.add(
          ValidationIssue(
            document.path,
            'Chưa có nguồn syllabus',
            IssueSeverity.warning,
          ),
        );
      }
      final condition = document.prerequisiteText;
      if (condition != null) {
        final mentionedCodes = RegExp(r'\b[A-Z]{2,4}\d{3}[a-z]?\b')
            .allMatches(condition)
            .map((match) => match.group(0)!)
            .toSet();
        final absent = mentionedCodes
            .where((code) => !codes.contains(code))
            .toList();
        if (absent.isNotEmpty) {
          issues.add(
            ValidationIssue(
              document.path,
              'Điều kiện gốc nhắc mã môn ngoài dataset: ${absent.join(', ')}. Giữ nguyên điều kiện để review.',
              IssueSeverity.warning,
            ),
          );
        }
      }
    }
    return KnowledgeSnapshot(snapshot.documents, List.unmodifiable(issues));
  }
}
