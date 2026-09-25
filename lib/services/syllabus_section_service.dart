class SyllabusSection {
  const SyllabusSection({required this.title, required this.markdown});

  final String title;
  final String markdown;
}

/// Separate the source at syllabus headings so a view can render one part at a
/// time. Heading-only parents remain in section labels instead of becoming
/// empty pages.
List<SyllabusSection> splitSyllabusSections(String source) {
  final sections = <SyllabusSection>[];
  final lines = <String>[];
  final heading = RegExp(r'^(#{1,3})\s+(.+?)\s*$');
  String title = 'Giới thiệu';
  String? parent;
  String? fence;

  void flush() {
    final markdown = lines.join('\n').trim();
    if (markdown.isNotEmpty &&
        !(heading.hasMatch(markdown) && !markdown.contains('\n'))) {
      sections.add(SyllabusSection(title: title, markdown: markdown));
    }
    lines.clear();
  }

  for (final line in source.split('\n')) {
    final marker = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line)?.group(1);
    if (marker != null) {
      if (fence == null) {
        fence = marker[0];
      } else if (fence == marker[0]) {
        fence = null;
      }
    }
    final match = fence == null ? heading.firstMatch(line) : null;
    if (match != null) {
      flush();
      final level = match.group(1)!.length;
      final label = match.group(2)!;
      if (level == 1) {
        parent = null;
        title = label;
      } else if (level == 2) {
        parent = label;
        title = label;
      } else {
        title = parent == null ? label : '$parent · $label';
      }
    }
    lines.add(line);
  }
  flush();
  return sections;
}
