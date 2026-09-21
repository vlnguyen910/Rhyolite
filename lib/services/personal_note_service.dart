import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/models/personal_note.dart';

abstract class IPersonalNoteService {
  Future<List<PersonalNote>> loadForCourse(String courseCode);

  Future<List<PersonalNote>> loadRecent({int limit = 5});

  Future<PersonalNote> save({
    required String title,
    required String body,
    required String courseCode,
    PersonalNote? original,
  });

  Future<void> delete(PersonalNote note);
}

class PersonalNoteService implements IPersonalNoteService {
  PersonalNoteService({Directory? rootDirectory})
    : _providedRoot = rootDirectory;

  final Directory? _providedRoot;

  Future<Directory> get notesDirectory async {
    final base =
        _providedRoot ??
        Directory(
          path.join(
            (await getApplicationDocumentsDirectory()).path,
            'Rhyolite',
          ),
        );
    final directory = Directory(path.join(base.path, 'My Notes'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<List<PersonalNote>> loadForCourse(String courseCode) async {
    final notes = await _loadAll();
    return notes.where((note) => note.courseCode == courseCode).toList();
  }

  @override
  Future<List<PersonalNote>> loadRecent({int limit = 5}) async {
    if (limit <= 0) return const [];
    final notes = await _loadAll();
    return notes.take(limit).toList();
  }

  @override
  Future<PersonalNote> save({
    required String title,
    required String body,
    required String courseCode,
    PersonalNote? original,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const FormatException('Tiêu đề note không được để trống.');
    }
    final now = DateTime.now().toUtc();
    final id = original?.id ?? 'note-${now.microsecondsSinceEpoch}';
    final directory = await notesDirectory;
    final file = File(path.join(directory.path, '$id.md'));
    final markdown =
        '''---
id: ${jsonEncode(id)}
type: "note"
title: ${jsonEncode(cleanTitle)}
courseCode: ${jsonEncode(courseCode)}
updatedAt: ${jsonEncode(now.toIso8601String())}
---

${body.trim()}
''';
    await file.writeAsString(markdown, flush: true);
    return PersonalNote(
      id: id,
      title: cleanTitle,
      body: body.trim(),
      courseCode: courseCode,
      updatedAt: now,
      path: file.path,
    );
  }

  @override
  Future<void> delete(PersonalNote note) async {
    final file = File(note.path);
    if (await file.exists()) await file.delete();
  }

  Future<List<PersonalNote>> _loadAll() async {
    final directory = await notesDirectory;
    final notes = <PersonalNote>[];
    await for (final entry in directory.list()) {
      if (entry is! File || !entry.path.endsWith('.md')) continue;
      try {
        notes.add(_parse(entry.path, await entry.readAsString()));
      } on FormatException {
        // A malformed personal file is ignored here and remains on disk.
      }
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  PersonalNote _parse(String filePath, String source) {
    final normalized = source.replaceAll('\r\n', '\n');
    if (!normalized.startsWith('---\n')) {
      throw const FormatException('Personal note thiếu frontmatter.');
    }
    final end = normalized.indexOf('\n---\n', 4);
    if (end == -1) {
      throw const FormatException('Personal note có frontmatter chưa đóng.');
    }
    final metadata = <String, String>{};
    for (final line in normalized.substring(4, end).split('\n')) {
      final separator = line.indexOf(':');
      if (separator < 1) continue;
      final key = line.substring(0, separator).trim();
      final encoded = line.substring(separator + 1).trim();
      if (encoded.isEmpty) continue;
      final value = jsonDecode(encoded);
      if (value is String) metadata[key] = value;
    }
    final id = metadata['id'];
    final title = metadata['title'];
    final courseCode = metadata['courseCode'];
    final updatedAt = DateTime.tryParse(metadata['updatedAt'] ?? '');
    if (id == null ||
        title == null ||
        courseCode == null ||
        updatedAt == null) {
      throw const FormatException('Personal note thiếu metadata bắt buộc.');
    }
    return PersonalNote(
      id: id,
      title: title,
      body: normalized.substring(end + 5).trim(),
      courseCode: courseCode,
      updatedAt: updatedAt,
      path: filePath,
    );
  }
}
