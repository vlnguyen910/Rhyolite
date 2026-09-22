String renderableMarkdown(String source) {
  final breakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
  final withoutBreakTags = source
      .split('\n')
      .map(
        (line) => line.trimLeft().startsWith('|')
            ? line.replaceAll(breakTag, ' · ')
            : line.replaceAll(breakTag, '  \n'),
      )
      .join('\n')
      .replaceAll('&amp;', '&');
  return withoutBreakTags.replaceAllMapped(
    RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'),
    (match) {
      final target = match.group(1)!.trim();
      final label = (match.group(2) ?? target).trim();
      final code = RegExp(r'\b[A-Za-z]{2,5}\d{3}[a-z]?\b')
          .firstMatch('$label $target')
          ?.group(0);
      return code == null ? '**$label**' : '[$label](course:$code)';
    },
  );
}

/// Tách syllabus thành các khối nhỏ để ListView chỉ dựng nội dung đang xem.
/// Các bảng dài được chia theo hàng và lặp lại header ở mỗi khối.
List<String> splitMarkdownForDisplay(String source, {int maxTableRows = 12}) {
  assert(maxTableRows > 0);
  final lines = source.split('\n');
  final chunks = <String>[];
  final pending = <String>[];
  var inFence = false;

  void flush() {
    final chunk = pending.join('\n').trim();
    if (chunk.isNotEmpty) chunks.add(chunk);
    pending.clear();
  }

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*(`{3,}|~{3,})').hasMatch(line)) {
      inFence = !inFence;
      pending.add(line);
      continue;
    }
    if (!inFence && RegExp(r'^#{1,6}\s').hasMatch(line)) flush();
    if (!inFence &&
        index + 1 < lines.length &&
        line.trimLeft().startsWith('|') &&
        _isTableDivider(lines[index + 1])) {
      flush();
      final header = line;
      final divider = lines[++index];
      final rows = <String>[];
      var hadRows = false;
      while (index + 1 < lines.length &&
          lines[index + 1].trimLeft().startsWith('|')) {
        hadRows = true;
        rows.add(lines[++index]);
        if (rows.length == maxTableRows) {
          chunks.add([header, divider, ...rows].join('\n'));
          rows.clear();
        }
      }
      if (rows.isNotEmpty || !hadRows) {
        chunks.add([header, divider, ...rows].join('\n'));
      }
      continue;
    }
    pending.add(line);
  }
  flush();
  return chunks;
}

bool _isTableDivider(String line) {
  final trimmed = line.trim();
  return trimmed.startsWith('|') &&
      trimmed.contains('---') &&
      RegExp(r'^[\s|:-]+$').hasMatch(trimmed);
}

String? courseCodeFromLink(String? href) {
  if (href == null || !href.startsWith('course:')) return null;
  return href.substring('course:'.length);
}
