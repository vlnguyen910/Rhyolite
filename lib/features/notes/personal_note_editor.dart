import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../domain/models/curriculum_catalog.dart';
import '../../domain/models/personal_note.dart';
import '../../services/personal_note_service.dart';
import '../knowledge/markdown_rendering.dart';

class PersonalNoteEditor extends StatefulWidget {
  const PersonalNoteEditor({
    super.key,
    required this.course,
    required this.service,
    this.original,
  });

  final CurriculumCourse course;
  final IPersonalNoteService service;
  final PersonalNote? original;

  @override
  State<PersonalNoteEditor> createState() => _PersonalNoteEditorState();
}

class _PersonalNoteEditorState extends State<PersonalNoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final String _initialTitle;
  late final String _initialBody;
  bool _saving = false;
  bool _showPreview = false;
  bool _allowPop = false;
  String? _error;

  bool get _dirty => _title.text != _initialTitle || _body.text != _initialBody;

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.original?.title ?? '${widget.course.code} · Ghi chú';
    _initialBody = widget.original?.body ?? '';
    _title = TextEditingController(text: _initialTitle)..addListener(_changed);
    _body = TextEditingController(text: _initialBody)..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = await widget.service.save(
        title: _title.text,
        body: _body.text,
        courseCode: widget.course.code,
        original: widget.original,
      );
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context, note);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  Future<bool> _canLeave() async {
    if (_allowPop || !_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Note chưa được lưu'),
            content: const Text('Bạn muốn bỏ các thay đổi đang soạn?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tiếp tục soạn'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bỏ thay đổi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _editor() => TextField(
    key: const ValueKey('note-body'),
    controller: _body,
    enabled: !_saving,
    expands: true,
    minLines: null,
    maxLines: null,
    textAlignVertical: TextAlignVertical.top,
    style: const TextStyle(fontFamily: 'monospace', height: 1.5),
    decoration: const InputDecoration(
      labelText: 'Nội dung Markdown',
      alignLabelWithHint: true,
      border: OutlineInputBorder(),
      hintText: '# Điều cần nhớ\n\nVí dụ, câu hỏi và kế hoạch ôn tập…',
    ),
  );

  Widget _preview() => Container(
    key: const ValueKey('note-preview'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: SingleChildScrollView(
      child: MarkdownBody(
        selectable: true,
        data: _body.text.trim().isEmpty
            ? '*Nội dung xem trước sẽ xuất hiện ở đây.*'
            : renderableMarkdown(_body.text),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope<PersonalNote>(
    canPop: _allowPop || !_dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || !await _canLeave() || !context.mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    },
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.original == null ? 'Tạo note' : 'Sửa note'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  key: const ValueKey('save-note'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu note'),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${widget.course.code} · ${widget.course.name}'),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('note-title'),
                  controller: _title,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _editor()),
                            const SizedBox(width: 16),
                            Expanded(child: _preview()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _showPreview = !_showPreview),
                              icon: Icon(
                                _showPreview
                                    ? Icons.edit_outlined
                                    : Icons.visibility_outlined,
                              ),
                              label: Text(
                                _showPreview ? 'Soạn Markdown' : 'Xem trước',
                              ),
                            ),
                          ),
                          Expanded(
                            child: _showPreview ? _preview() : _editor(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
