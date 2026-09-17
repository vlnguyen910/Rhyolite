import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../data/personal_note_store.dart';
import '../../domain/knowledge_document.dart';

class PersonalNoteEditor extends StatefulWidget {
  const PersonalNoteEditor({
    super.key,
    required this.store,
    required this.snapshot,
    this.original,
    this.linked,
  });
  final PersonalNoteStore store;
  final KnowledgeSnapshot snapshot;
  final KnowledgeDocument? original;
  final KnowledgeDocument? linked;

  @override
  State<PersonalNoteEditor> createState() => _PersonalNoteEditorState();
}

class _PersonalNoteEditorState extends State<PersonalNoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final Set<String> _related;
  late final Set<String> _initialRelated;
  late final String _initialTitle;
  late final String _initialBody;
  late final AppLifecycleListener _lifecycle;
  bool _saving = false;
  bool _allowPop = false;
  bool _preview = false;
  String? _error;
  Future<bool>? _confirmation;

  bool get _dirty =>
      _title.text != _initialTitle ||
      _body.text != _initialBody ||
      _related.length != _initialRelated.length ||
      !_related.containsAll(_initialRelated);

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.original?.title ?? '';
    _initialBody = widget.original?.body ?? '';
    _title = TextEditingController(text: _initialTitle)..addListener(_changed);
    _body = TextEditingController(text: _initialBody)..addListener(_changed);
    _related = {
      ...?widget.original?.relatedTargets,
      if (widget.linked != null) widget.linked!.id,
    };
    _initialRelated = Set.of(_related);
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async =>
          await _canLeave() ? AppExitResponse.exit : AppExitResponse.cancel,
    );
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _lifecycle.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<bool> _canLeave() async {
    if (_saving) return false;
    if (!_dirty || _allowPop) return true;
    if (_confirmation != null) return _confirmation!;
    _confirmation = showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note chưa được lưu'),
        content: const Text('Bạn muốn bỏ các thay đổi đang soạn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục soạn'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
    final result = await _confirmation!;
    _confirmation = null;
    return result;
  }

  Future<void> _back() async {
    if (await _canLeave() && mounted) {
      setState(() => _allowPop = true);
      // Rebuild PopScope before retrying the pop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.store.save(
        title: _title.text,
        body: _body.text,
        related: _related.toList(),
        original: widget.original,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _allowPop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, saved);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Không lưu được: $error\nNội dung đang soạn vẫn được giữ trong editor.';
        });
      }
    }
  }

  Future<void> _addLink() async {
    var query = '';
    final candidates =
        widget.snapshot.documents
            .where(
              (doc) =>
                  doc.type != DocumentType.reference &&
                  !doc.demo &&
                  doc.id != widget.original?.id &&
                  !_related.contains(doc.id),
            )
            .toList()
          ..sort((a, b) => (a.code ?? a.title).compareTo(b.code ?? b.title));
    final selected = await showDialog<KnowledgeDocument>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final visible = candidates
              .where(
                (doc) => '${doc.code ?? ''} ${doc.title}'
                    .toLowerCase()
                    .contains(query),
              )
              .toList();
          return AlertDialog(
            title: const Text('Liên kết kiến thức'),
            content: SizedBox(
              width: 540,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tìm môn, concept hoặc note',
                    ),
                    onChanged: (value) =>
                        update(() => query = value.trim().toLowerCase()),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('Không có kết quả.'))
                        : ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, index) {
                              final doc = visible[index];
                              return ListTile(
                                title: Text(doc.code ?? doc.title),
                                subtitle: Text(
                                  doc.code == null ? doc.type.name : doc.title,
                                ),
                                onTap: () => Navigator.pop(context, doc),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
    if (selected != null && mounted) setState(() => _related.add(selected.id));
  }

  Widget _editor() => TextField(
    key: const ValueKey('note-body'),
    controller: _body,
    enabled: !_saving,
    expands: true,
    maxLines: null,
    minLines: null,
    textAlignVertical: TextAlignVertical.top,
    style: const TextStyle(fontFamily: 'monospace', height: 1.5),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Nội dung Markdown',
      alignLabelWithHint: true,
      hintText: '# Ghi chú\n\nViết điều bạn đã hiểu, ví dụ và câu hỏi.\nDùng [[concept:flutter|Flutter]] để liên kết trong nội dung.',
    ),
  );

  Widget _markdown() => Container(
    key: const ValueKey('note-preview'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      child: MarkdownBody(
        selectable: true,
        data: _body.text.isEmpty
            ? '*Markdown preview sẽ xuất hiện ở đây.*'
            : _body.text.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (match) {
                final parts = match.group(1)!.split('|');
                return '**${parts.length > 1 ? parts.sublist(1).join('|') : parts.first}**';
              }),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
    },
    child: Focus(
      autofocus: true,
      child: PopScope<KnowledgeDocument>(
        canPop: _allowPop || (!_dirty && !_saving),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay lại',
            ),
            title: Text(
              widget.original == null
                  ? 'Tạo personal note'
                  : 'Sửa personal note',
            ),
            actions: [
              IconButton(
                tooltip: 'Sao chép bản đang soạn',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '# ${_title.text}\n\n${_body.text}'),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép bản đang soạn.'),
                      ),
                    );
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  key: const ValueKey('save-note'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final target in _related)
                      InputChip(
                        label: Text(
                          widget.snapshot.resolve(target)?.code ??
                              widget.snapshot.resolve(target)?.title ??
                              target,
                        ),
                        onDeleted: _saving
                            ? null
                            : () => setState(() => _related.remove(target)),
                      ),
                    ActionChip(
                      label: const Text('Thêm liên kết'),
                      avatar: const Icon(Icons.add_link, size: 18),
                      onPressed: _saving ? null : _addLink,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Ghi chú cá nhân · Ctrl+S để lưu · File Markdown được lưu trên máy này.',
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 900
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _editor()),
                              const SizedBox(width: 16),
                              Expanded(child: _markdown()),
                            ],
                          )
                        : Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _preview = !_preview),
                                  icon: Icon(
                                    _preview
                                        ? Icons.edit_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  label: Text(
                                    _preview ? 'Soạn Markdown' : 'Xem preview',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _preview ? _markdown() : _editor(),
                              ),
                            ],
                          ),
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
