import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../design_system/app_theme.dart';
import 'markdown_rendering.dart';

class SyllabusMarkdownView extends StatefulWidget {
  const SyllabusMarkdownView({super.key, required this.source, this.onTapLink});

  final String source;
  final void Function(String, String?, String)? onTapLink;

  @override
  State<SyllabusMarkdownView> createState() => _SyllabusMarkdownViewState();
}

class _SyllabusMarkdownViewState extends State<SyllabusMarkdownView> {
  late List<String> _chunks;

  @override
  void initState() {
    super.initState();
    _prepareChunks();
  }

  @override
  void didUpdateWidget(covariant SyllabusMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _prepareChunks();
  }

  void _prepareChunks() {
    _chunks = splitMarkdownForDisplay(renderableMarkdown(widget.source));
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppSpacing.xl),
    itemCount: _chunks.length,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MarkdownBody(
        data: _chunks[index],
        selectable: true,
        onTapLink: widget.onTapLink,
      ),
    ),
  );
}
