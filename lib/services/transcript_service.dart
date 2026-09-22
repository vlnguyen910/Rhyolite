import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../models/curriculum_catalog.dart';
import '../models/student_transcript.dart';

abstract class ITranscriptParser {
  Future<StudentTranscript> parseFile(
    String path,
    List<CurriculumCourse> courses,
  );
}

class FapTranscriptParser implements ITranscriptParser {
  @override
  Future<StudentTranscript> parseFile(
    String path,
    List<CurriculumCourse> courses,
  ) async {
    final extension = p.extension(path).toLowerCase();
    if (!const {'.xls', '.xlsx'}.contains(extension)) {
      throw const TranscriptImportException(
        'Vui lòng chọn file .xls hoặc .xlsx được xuất từ Academic Transcript trên FAP.',
      );
    }
    try {
      final bytes = await File(path).readAsBytes();
      final text = _decodeText(bytes);
      if (text != null && text.toLowerCase().contains('<table')) {
        final records = _parseHtml(text, courses);
        return StudentTranscript(
          sourceFileName: p.basename(path),
          importedAt: DateTime.now(),
          records: records,
        );
      }
      if (extension != '.xlsx') {
        throw const TranscriptImportException(
          'File .xls này không phải định dạng FAP được hỗ trợ. Hãy export lại từ Academic Transcript.',
        );
      }
      final workbook = SpreadsheetDecoder.decodeBytes(bytes);
      for (final table in workbook.tables.values) {
        try {
          final records = parseRows(table.rows, courses);
          if (records.isNotEmpty) {
            return StudentTranscript(
              sourceFileName: p.basename(path),
              importedAt: DateTime.now(),
              records: records,
            );
          }
        } on TranscriptImportException {
          continue;
        }
      }
    } on TranscriptImportException {
      rethrow;
    } on Object {
      throw const TranscriptImportException(
        'Không thể đọc file Excel. Hãy tải lại file từ FAP và thử lại.',
      );
    }
    throw const TranscriptImportException(
      'Không tìm thấy bảng Academic Transcript trong file Excel.',
    );
  }

  List<TranscriptRecord> _parseHtml(
    String source,
    List<CurriculumCourse> courses,
  ) {
    final document = html_parser.parse(source);
    for (final table in document.querySelectorAll('table')) {
      final rows = <List<dynamic>>[];
      for (final row in table.querySelectorAll('tr')) {
        if (_owningTable(row) != table) continue;
        final cells = row.children
            .where((cell) => cell.localName == 'th' || cell.localName == 'td')
            .map((cell) => cell.text.trim())
            .toList();
        if (cells.isNotEmpty) rows.add(cells);
      }
      try {
        final records = parseRows(rows, courses);
        if (records.isNotEmpty) return records;
      } on TranscriptImportException {
        continue;
      }
    }
    throw const TranscriptImportException(
      'Không tìm thấy bảng Academic Transcript trong file FAP.',
    );
  }

  Element? _owningTable(Element element) {
    Element? current = element.parent;
    while (current != null && current.localName != 'table') {
      current = current.parent;
    }
    return current;
  }

  String? _decodeText(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
      return _decodeUtf16(bytes, littleEndian: true, offset: 2);
    }
    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      return _decodeUtf16(bytes, littleEndian: false, offset: 2);
    }
    final prefix = utf8.decode(bytes.take(256).toList(), allowMalformed: true);
    if (prefix.toLowerCase().contains('<table') ||
        prefix.toLowerCase().contains('<html')) {
      return utf8.decode(bytes, allowMalformed: true);
    }
    return null;
  }

  String _decodeUtf16(
    Uint8List bytes, {
    required bool littleEndian,
    required int offset,
  }) {
    final codeUnits = <int>[];
    for (var index = offset; index + 1 < bytes.length; index += 2) {
      final first = bytes[index];
      final second = bytes[index + 1];
      codeUnits.add(
        littleEndian ? first | (second << 8) : (first << 8) | second,
      );
    }
    return String.fromCharCodes(codeUnits);
  }

  List<TranscriptRecord> parseRows(
    List<List<dynamic>> rows,
    List<CurriculumCourse> courses,
  ) {
    final headerIndex = rows.indexWhere(_looksLikeHeader);
    if (headerIndex == -1) {
      throw const TranscriptImportException(
        'Không tìm thấy các cột Subject Code, Grade và Status.',
      );
    }
    final header = rows[headerIndex].map(_cellText).toList();
    final columns = _columnIndexes(header);
    final codeColumn = columns['subjectCode'];
    if (codeColumn == null) {
      throw const TranscriptImportException('Không tìm thấy cột Subject Code.');
    }
    final curriculumCodes = {
      for (final course in courses) course.code.toUpperCase(),
    };
    final records = <TranscriptRecord>[];
    for (final row in rows.skip(headerIndex + 1)) {
      final subjectCode = _value(row, codeColumn).trim();
      if (subjectCode.isEmpty || !_looksLikeSubjectCode(subjectCode)) continue;
      records.add(
        TranscriptRecord(
          term: _valueAt(row, columns['term']),
          semester: _valueAt(row, columns['semester']),
          subjectCode: subjectCode,
          subjectName: _valueAt(row, columns['subjectName']),
          prerequisite: _valueAt(row, columns['prerequisite']),
          replacedSubject: _valueAt(row, columns['replacedSubject']),
          credit: _valueAt(row, columns['credit']),
          grade: _valueAt(row, columns['grade']),
          status: _valueAt(row, columns['status']),
          matchesCurriculum: curriculumCodes.contains(
            subjectCode.toUpperCase(),
          ),
        ),
      );
    }
    if (records.isEmpty) {
      throw const TranscriptImportException(
        'File có tiêu đề nhưng không có dòng môn học hợp lệ.',
      );
    }
    return records;
  }

  bool _looksLikeHeader(List<dynamic> row) {
    final normalized = row.map((cell) => _normalize(_cellText(cell))).toSet();
    return normalized.contains('subjectcode') &&
        (normalized.contains('grade') || normalized.contains('status'));
  }

  Map<String, int> _columnIndexes(List<String> header) {
    const aliases = {
      'term': {'term'},
      'semester': {'semester'},
      'subjectCode': {'subjectcode', 'coursecode', 'mamon'},
      'prerequisite': {'prerequisite', 'prerequisites', 'montienquyet'},
      'replacedSubject': {
        'replacedsubject',
        'replacementsubject',
        'monthaythe',
      },
      'subjectName': {'subjectname', 'coursename', 'tenmon'},
      'credit': {'credit', 'credits', 'sotinchi'},
      'grade': {'grade', 'mark', 'average', 'diem'},
      'status': {'status', 'result', 'trangthai'},
    };
    final result = <String, int>{};
    for (var index = 0; index < header.length; index++) {
      final value = _normalize(header[index]);
      for (final entry in aliases.entries) {
        if (!result.containsKey(entry.key) && entry.value.contains(value)) {
          result[entry.key] = index;
        }
      }
    }
    return result;
  }

  bool _looksLikeSubjectCode(String value) =>
      RegExp(r'^[A-Za-z][A-Za-z0-9*._-]{2,}$').hasMatch(value.trim());

  String _valueAt(List<dynamic> row, int? index) =>
      index == null ? '' : _value(row, index);

  String _value(List<dynamic> row, int index) =>
      index >= row.length ? '' : _cellText(row[index]);

  String _cellText(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }
    return value.toString().trim();
  }

  String _normalize(String value) {
    const accented =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const plain =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = accented.indexOf(character);
      final replacement = index == -1 ? character : plain[index];
      if (RegExp(r'[a-z0-9]').hasMatch(replacement)) buffer.write(replacement);
    }
    return buffer.toString();
  }
}

abstract class ITranscriptRepository {
  Future<StudentTranscript?> load();
  Future<void> save(StudentTranscript transcript);
  Future<void> delete();
}

class TranscriptRepository implements ITranscriptRepository {
  TranscriptRepository({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final directory = await _directoryProvider();
    final transcriptDirectory = Directory(
      p.join(directory.path, 'rhyolite', 'transcript'),
    );
    await transcriptDirectory.create(recursive: true);
    return File(p.join(transcriptDirectory.path, 'student-transcript.json'));
  }

  @override
  Future<StudentTranscript?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) return null;
    return StudentTranscript.fromJson(decoded);
  }

  @override
  Future<void> save(StudentTranscript transcript) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(transcript.toJson()), flush: true);
  }

  @override
  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

class TranscriptImportException implements Exception {
  const TranscriptImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
