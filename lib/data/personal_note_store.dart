import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/knowledge_document.dart';
import 'markdown_adapter.dart';

class NoteFiles {
  const NoteFiles(this.files, this.issues);
  final Map<String, String> files;
  final List<ValidationIssue> issues;
}

/// User-owned Markdown, separate from the read-only bundled knowledge vault.
class PersonalNoteStore {
  const PersonalNoteStore({this.directory});
  final Directory? directory;
  static final _filename = RegExp(r'^[a-f0-9]{32}\.md$');

  Future<Directory> get notesDirectory async =>
      directory ??
      Directory(p.join((await getApplicationSupportDirectory()).path, 'notes'));

  Future<NoteFiles> load() async {
    final files = <String, String>{};
    final issues = <ValidationIssue>[];
    try {
      final folder = await notesDirectory;
      if (!await folder.exists()) return NoteFiles(files, issues);
      final entries = await folder.list(followLinks: false).toList();
      // If replacement was interrupted after removing the target, restore it.
      for (final backup in entries.whereType<File>()) {
        final name = p.basename(backup.path);
        if (!name.endsWith('.md.bak')) continue;
        final targetName = name.substring(0, name.length - 4);
        if (!_filename.hasMatch(targetName)) continue;
        final target = File(p.join(folder.path, targetName));
        if (!await target.exists()) {
          await backup.copy(target.path);
          issues.add(
            ValidationIssue(
              'notes/$targetName',
              'Đã khôi phục bản lưu trước từ backup.',
              IssueSeverity.warning,
            ),
          );
        }
      }
      final notes =
          (await folder.list(followLinks: false).toList())
              .whereType<File>()
              .where((file) => file.path.endsWith('.md'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in notes) {
        final name = p.basename(file.path);
        final logicalPath = 'notes/$name';
        try {
          if (!_filename.hasMatch(name)) {
            throw const FormatException('Tên file note phải là ID do app tạo');
          }
          final source = await file.readAsString();
          final doc = MarkdownAdapter().parse(logicalPath, source);
          _checkIdentity(doc);
          files[logicalPath] = source;
        } catch (error) {
          issues.add(
            ValidationIssue(
              logicalPath,
              'Không đọc được note: $error',
              IssueSeverity.error,
            ),
          );
        }
      }
    } catch (error) {
      issues.add(
        ValidationIssue(
          'notes/',
          'Không đọc được thư mục My Notes: $error',
          IssueSeverity.error,
        ),
      );
    }
    return NoteFiles(files, issues);
  }

  void _checkIdentity(KnowledgeDocument document) {
    final name = document.path.replaceFirst('notes/', '');
    if (document.type != DocumentType.note ||
        document.path != 'notes/$name' ||
        !_filename.hasMatch(name) ||
        document.id != 'note:${name.substring(0, name.length - 3)}') {
      throw const FormatException('ID, loại và đường dẫn note không hợp lệ');
    }
  }

  Future<KnowledgeDocument> save({
    required String title,
    required String body,
    required List<String> related,
    KnowledgeDocument? original,
  }) async {
    if (title.trim().isEmpty) {
      throw const FormatException('Hãy nhập tiêu đề note.');
    }
    if (original != null) _checkIdentity(original);
    final token =
        original?.id.substring(5) ??
        List.generate(
          16,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    final logicalPath = 'notes/$token.md';
    final source =
        '---\nid: ${jsonEncode('note:$token')}\ntype: note\n'
        'title: ${jsonEncode(title.trim())}\nrelated: ${jsonEncode(related.toSet().toList())}\n'
        '---\n\n$body\n';
    final document = MarkdownAdapter().parse(logicalPath, source);
    final folder = await notesDirectory;
    await folder.create(recursive: true);
    final target = File(p.join(folder.path, '$token.md'));
    if (original != null) {
      if (!await target.exists() ||
          await target.readAsString() != original.sourceMarkdown) {
        throw const FileSystemException(
          'Note đã thay đổi hoặc bị xóa bên ngoài app. Nội dung đang soạn được giữ lại; hãy sao chép trước khi tải lại.',
        );
      }
    } else if (await target.exists()) {
      throw const FileSystemException('ID note đã tồn tại; hãy thử lưu lại.');
    }
    await writeAtomically(target, source);
    return document;
  }

  /// Flush new content first. Keep the previous version even if rename fails.
  Future<void> writeAtomically(File target, String content) async {
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final backup = File('${target.path}.bak');
    try {
      await temporary.writeAsString(content, flush: true);
      if (await target.exists()) await target.copy(backup.path);
      try {
        await temporary.rename(target.path);
      } catch (_) {
        if (!await target.exists() && await backup.exists()) {
          await backup.copy(target.path);
        }
        rethrow;
      }
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
