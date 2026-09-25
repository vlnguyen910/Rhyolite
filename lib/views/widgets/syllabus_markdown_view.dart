import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../design_system/app_theme.dart';
import '../../services/syllabus_section_service.dart';
import 'markdown_rendering.dart';

class SyllabusMarkdownView extends StatefulWidget {
  const SyllabusMarkdownView({super.key, required this.source, this.onTapLink});

  final String source;
  final void Function(String, String?, String)? onTapLink;

  @override
  State<SyllabusMarkdownView> createState() => _SyllabusMarkdownViewState();
}

class _SyllabusMarkdownViewState extends State<SyllabusMarkdownView> {
  late List<SyllabusSection> _sections;
  late List<String> _chunks;
  int _selectedSection = 0;

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
    _sections = splitSyllabusSections(widget.source);
    _selectedSection = 0;
    _prepareSelectedSection();
  }

  void _prepareSelectedSection() {
    _chunks = _sections.isEmpty
        ? []
        : splitMarkdownForDisplay(
            renderableMarkdown(_sections[_selectedSection].markdown),
            maxTableRows: 4,
          );
  }

  void _selectSection(int? index) {
    if (index == null || index == _selectedSection) return;
    setState(() {
      _selectedSection = index;
      _prepareSelectedSection();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Text('Mục syllabus'),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButton<int>(
                key: const ValueKey('syllabus-section-picker'),
                isExpanded: true,
                value: _sections.isEmpty ? null : _selectedSection,
                items: [
                  for (var index = 0; index < _sections.length; index++)
                    DropdownMenuItem(
                      value: index,
                      child: Text(
                        _sections[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _selectSection,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${_sections.isEmpty ? 0 : _selectedSection + 1}/${_sections.length}',
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          key: ValueKey('syllabus-section-$_selectedSection'),
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
        ),
      ),
    ],
  );
}
