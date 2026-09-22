String renderableMarkdown(String source) {
  final withoutBreakTags = source
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '  \n')
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

String? courseCodeFromLink(String? href) {
  if (href == null || !href.startsWith('course:')) return null;
  return href.substring('course:'.length);
}
