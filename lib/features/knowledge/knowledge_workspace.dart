import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/knowledge_repository.dart';
import '../../domain/knowledge_document.dart';
import '../graph/local_graph_screen.dart';
import '../graph/overview_graph_view.dart';
import '../notes/personal_note_editor.dart';

typedef NoteEditorCallback =
    Future<({KnowledgeDocument document, KnowledgeSnapshot snapshot})?>
    Function(
      KnowledgeSnapshot snapshot, {
      KnowledgeDocument? original,
      KnowledgeDocument? linked,
    });

class KnowledgeWorkspace extends StatefulWidget {
  const KnowledgeWorkspace({super.key, required this.repository});
  final KnowledgeRepository repository;
  @override
  State<KnowledgeWorkspace> createState() => _KnowledgeWorkspaceState();
}

class _KnowledgeWorkspaceState extends State<KnowledgeWorkspace> {
  late Future<KnowledgeSnapshot> _loading;
  KnowledgeDocument? _selected;
  String _query = '';
  bool _showDemo = false;
  DocumentType _browseType = DocumentType.course;
  final _search = TextEditingController();
  final _updates = ValueNotifier<KnowledgeSnapshot?>(null);
  final _deletingNotes = <String>{};

  @override
  void dispose() {
    _search.dispose();
    _updates.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loading = widget.repository.load();
  }

  void _reload() => setState(() {
    _updates.value = null;
    _selected = null;
    _loading = widget.repository.load();
  });

  Future<({KnowledgeDocument document, KnowledgeSnapshot snapshot})?> _editNote(
    KnowledgeSnapshot snapshot, {
    KnowledgeDocument? original,
    KnowledgeDocument? linked,
  }) async {
    final store = widget.repository.noteStore;
    if (store == null) return null;
    final saved = await Navigator.push<KnowledgeDocument>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalNoteEditor(
          store: store,
          snapshot: snapshot,
          original: original,
          linked: linked,
        ),
      ),
    );
    if (saved == null || !mounted) return null;
    try {
      final updated = await widget.repository.load();
      if (!mounted) return null;
      _updates.value = updated;
      setState(() {
        _loading = Future.value(updated);
        _selected = updated.resolve(saved.id) ?? saved;
        _browseType = DocumentType.note;
        _query = '';
        _search.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu personal note.')));
      return (document: _selected!, snapshot: updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File note đã lưu, nhưng chưa tải lại được danh sách: $error',
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<bool> _deleteNote(KnowledgeDocument note) async {
    final store = widget.repository.noteStore;
    if (store == null || !_deletingNotes.add(note.id)) return false;
    setState(() {});
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa note?'),
          content: Text(
            'Bạn muốn xóa “${note.title}”?\n\n'
            'Note sẽ được chuyển vào thùng rác nội bộ. '
            'App chưa có giao diện khôi phục. Các liên kết tới note này sẽ không còn đích.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return false;
      await store.delete(note);
      if (!mounted) return true;
      try {
        final updated = await widget.repository.load();
        if (!mounted) return true;
        _updates.value = updated;
        setState(() {
          _loading = Future.value(updated);
          if (_selected?.id == note.id) _selected = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chuyển note vào thùng rác nội bộ.')),
        );
      } catch (error) {
        if (!mounted) return true;
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note đã xóa, nhưng chưa tải lại được danh sách: $error',
            ),
          ),
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xóa được note: $error')));
      }
      return false;
    } finally {
      _deletingNotes.remove(note.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showNoteFolder() async {
    try {
      final directory = await widget.repository.noteStore!.notesDirectory;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thư mục My Notes'),
          content: SelectableText(directory.path),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('FPTU SE Knowledge'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Thư viện'),
            Tab(
              key: ValueKey('overview-tab'),
              icon: Icon(Icons.account_tree_outlined),
              text: 'Graph tổng quan',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Đọc lại knowledge base',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<KnowledgeSnapshot>(
        future: _loading,
        builder: (context, state) {
          if (state.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không đọc được knowledge base.'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText('${state.error}'),
                  ),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (!state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final snapshot = state.data!;
          final courses =
              snapshot.courses.where((c) => _showDemo || !c.demo).toList()
                ..sort((a, b) {
                  final semester = a.semester!.compareTo(b.semester!);
                  return semester != 0 ? semester : a.code!.compareTo(b.code!);
                });
          final query = _query.trim().toLowerCase();
          final concepts =
              snapshot.concepts.where((c) => _showDemo || !c.demo).toList()
                ..sort((a, b) => a.title.compareTo(b.title));
          final notes = snapshot.notes
            ..sort((a, b) => a.title.compareTo(b.title));
          final pool = switch (_browseType) {
            DocumentType.course => courses,
            DocumentType.note => notes,
            _ => concepts,
          };
          final visible = pool
              .where(
                (c) =>
                    '${c.code ?? ''} ${c.title} ${c.type != DocumentType.course ? c.body : ''}'
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${courses.length} môn · ${courses.map((c) => c.semester).toSet().length} học kỳ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Chip(
                      avatar: Icon(Icons.offline_bolt, size: 18),
                      label: Text('Offline workspace'),
                    ),
                    ActionChip(
                      key: const ValueKey('validation-report'),
                      avatar: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text('${snapshot.issues.length} vấn đề dữ liệu'),
                      onPressed: () => _showIssues(snapshot),
                    ),
                    Text(
                      '${concepts.length} concept · ${notes.length} personal note',
                    ),
                    if (widget.repository.noteStore != null) ...[
                      FilledButton.icon(
                        onPressed: () => _editNote(snapshot),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Tạo note'),
                      ),
                      TextButton.icon(
                        onPressed: _showNoteFolder,
                        icon: const Icon(Icons.folder_outlined),
                        label: const Text('Thư mục lưu'),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 850;
                        void open(KnowledgeDocument document) {
                          if (wide) {
                            setState(() => _selected = document);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => _DocumentRoute(
                                  document: document,
                                  snapshot: snapshot,
                                  updates: _updates,
                                  deleteNote:
                                      widget.repository.noteStore == null
                                      ? null
                                      : _deleteNote,
                                  editNote: widget.repository.noteStore == null
                                      ? null
                                      : _editNote,
                                  includeDemo: _showDemo,
                                ),
                              ),
                            );
                          }
                        }

                        final courseList = Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: SegmentedButton<DocumentType>(
                                segments: const [
                                  ButtonSegment(
                                    value: DocumentType.course,
                                    label: Text('Môn học'),
                                    icon: Icon(Icons.school_outlined),
                                  ),
                                  ButtonSegment(
                                    value: DocumentType.concept,
                                    label: Text('Concept'),
                                    icon: Icon(Icons.lightbulb_outline),
                                  ),
                                  ButtonSegment(
                                    value: DocumentType.note,
                                    label: Text('My Notes'),
                                    icon: Icon(Icons.edit_note),
                                  ),
                                ],
                                selected: {_browseType},
                                onSelectionChanged: (selection) => setState(() {
                                  _browseType = selection.single;
                                  _query = '';
                                  _search.clear();
                                  _selected = null;
                                }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _search,
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                decoration: InputDecoration(
                                  labelText: _browseType == DocumentType.course
                                      ? 'Tìm môn học'
                                      : _browseType == DocumentType.note
                                      ? 'Tìm personal note'
                                      : 'Tìm concept',
                                  hintText: _browseType == DocumentType.course
                                      ? 'Mã môn hoặc tên môn'
                                      : 'Tên hoặc nội dung Markdown',
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SwitchListTile(
                              dense: true,
                              title: const Text('Hiện dữ liệu demo'),
                              value: _showDemo,
                              onChanged: (value) =>
                                  setState(() => _showDemo = value),
                            ),
                            Expanded(
                              child: visible.isEmpty
                                  ? Center(
                                      child: Text(
                                        _browseType == DocumentType.course
                                            ? 'Không có môn học phù hợp.'
                                            : _browseType == DocumentType.note
                                            ? 'Chưa có note. Bấm Tạo note để bắt đầu.'
                                            : 'Chưa có concept phù hợp.',
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: visible.length,
                                      itemBuilder: (context, index) {
                                        final course = visible[index];
                                        final first =
                                            index == 0 ||
                                            visible[index - 1].semester !=
                                                course.semester;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (first &&
                                                _browseType ==
                                                    DocumentType.course)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      20,
                                                      16,
                                                      16,
                                                      6,
                                                    ),
                                                child: Text(
                                                  'HỌC KỲ ${course.semester}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                ),
                                              ),
                                            ListTile(
                                              selected:
                                                  _selected?.id == course.id,
                                              selectedTileColor: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                              title: Text(
                                                course.code ?? course.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                course.type ==
                                                        DocumentType.course
                                                    ? course.title
                                                    : course.type ==
                                                          DocumentType.note
                                                    ? 'Ghi chú cá nhân · ${course.links.toSet().length} liên kết'
                                                    : '${course.sources.length} nguồn · ${snapshot.coursesFor(course).length} môn liên quan',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: const Icon(
                                                Icons.chevron_right,
                                                size: 18,
                                              ),
                                              onTap: () => open(course),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                        if (!wide) return courseList;
                        return Row(
                          children: [
                            SizedBox(width: 330, child: courseList),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _selected == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_stories_outlined,
                                            size: 56,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Khám phá kiến thức SE',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Chọn một môn để đọc syllabus và các liên kết.',
                                          ),
                                        ],
                                      ),
                                    )
                                  : DocumentDetail(
                                      key: ValueKey(_selected!.id),
                                      document: _selected!,
                                      snapshot: snapshot,
                                      onOpen: open,
                                      onCreateNote:
                                          widget.repository.noteStore == null
                                          ? null
                                          : () => _editNote(
                                              snapshot,
                                              linked: _selected,
                                            ),
                                      onEditNote:
                                          widget.repository.noteStore == null
                                          ? null
                                          : () => _editNote(
                                              snapshot,
                                              original: _selected,
                                            ),
                                      includeDemo: _showDemo,
                                      onDeleteNote:
                                          widget.repository.noteStore == null
                                          ? null
                                          : () => _deleteNote(_selected!),
                                      deletingNote: _deletingNotes.contains(
                                        _selected!.id,
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                    OverviewGraphView(
                      snapshot: snapshot,
                      includeDemo: _showDemo,
                      onDemoChanged: (value) =>
                          setState(() => _showDemo = value),
                      onOpen: (document) => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => _DocumentRoute(
                            document: document,
                            snapshot: snapshot,
                            updates: _updates,
                            deleteNote: widget.repository.noteStore == null
                                ? null
                                : _deleteNote,
                            includeDemo: _showDemo,
                            editNote: widget.repository.noteStore == null
                                ? null
                                : _editNote,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _showIssues(KnowledgeSnapshot snapshot) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Validation · ${snapshot.issues.length} vấn đề'),
      content: SizedBox(
        width: 720,
        height: 440,
        child: snapshot.issues.isEmpty
            ? const Text('Không phát hiện vấn đề trong các kiểm tra hiện có.')
            : ListView.builder(
                itemCount: snapshot.issues.length,
                itemBuilder: (_, index) {
                  final issue = snapshot.issues[index];
                  return ListTile(
                    leading: Icon(
                      issue.severity == IssueSeverity.error
                          ? Icons.error_outline
                          : Icons.warning_amber,
                    ),
                    title: Text(issue.message),
                    subtitle: SelectableText(issue.path),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

class _DocumentRoute extends StatefulWidget {
  const _DocumentRoute({
    required this.document,
    required this.snapshot,
    required this.updates,
    this.includeDemo = false,
    this.editNote,
    this.deleteNote,
  });
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  final bool includeDemo;
  final NoteEditorCallback? editNote;
  final Future<bool> Function(KnowledgeDocument)? deleteNote;
  final ValueNotifier<KnowledgeSnapshot?> updates;
  @override
  State<_DocumentRoute> createState() => _DocumentRouteState();
}

class _DocumentRouteState extends State<_DocumentRoute> {
  late KnowledgeDocument _document = widget.document;
  late KnowledgeSnapshot _snapshot = widget.snapshot;
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    final deleted = await widget.deleteNote!(_document);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (deleted) Navigator.pop(context);
  }

  Future<void> _edit({bool existing = false}) async {
    final result = await widget.editNote!(
      _snapshot,
      original: existing ? _document : null,
      linked: existing ? null : _document,
    );
    if (result != null && mounted) {
      setState(() {
        _document = result.document;
        _snapshot = result.snapshot;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<KnowledgeSnapshot?>(
        valueListenable: widget.updates,
        builder: (context, updated, _) {
          _snapshot = updated ?? _snapshot;
          if (_document.type == DocumentType.note &&
              _snapshot.resolve(_document.id) == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Note không còn tồn tại')),
              body: const Center(
                child: Text('Note này đã bị xóa hoặc không còn trong dữ liệu.'),
              ),
            );
          }
          _document = _snapshot.resolve(_document.id) ?? _document;
          return Scaffold(
            appBar: AppBar(title: Text(_document.code ?? _document.title)),
            body: DocumentDetail(
              document: _document,
              snapshot: _snapshot,
              includeDemo: widget.includeDemo,
              onDeleteNote: widget.deleteNote == null ? null : _delete,
              deletingNote: _deleting,
              onCreateNote: widget.editNote == null ? null : () => _edit(),
              onEditNote: widget.editNote == null
                  ? null
                  : () => _edit(existing: true),
              onOpen: (next) => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _DocumentRoute(
                    document: next,
                    snapshot: _snapshot,
                    updates: widget.updates,
                    includeDemo: widget.includeDemo,
                    editNote: widget.editNote,
                    deleteNote: widget.deleteNote,
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class DocumentDetail extends StatelessWidget {
  const DocumentDetail({
    super.key,
    required this.document,
    required this.snapshot,
    required this.onOpen,
    this.includeDemo = false,
    this.onCreateNote,
    this.onEditNote,
    this.onDeleteNote,
    this.deletingNote = false,
  });
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  final ValueChanged<KnowledgeDocument> onOpen;
  final bool includeDemo;
  final VoidCallback? onCreateNote;
  final VoidCallback? onEditNote;
  final VoidCallback? onDeleteNote;
  final bool deletingNote;

  @override
  Widget build(BuildContext context) {
    final issues = snapshot.issues
        .where((i) => i.path == document.path)
        .toList();
    return SingleChildScrollView(
      key: PageStorageKey('${document.id}:detail-scroll'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.code ?? document.type.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            document.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (document.type == DocumentType.note)
                const Chip(
                  avatar: Icon(Icons.edit_note, size: 18),
                  label: Text('Ghi chú cá nhân'),
                ),
              if (document.type != DocumentType.reference &&
                  onCreateNote != null)
                ActionChip(
                  avatar: const Icon(Icons.note_add_outlined, size: 18),
                  label: const Text('Ghi chú về mục này'),
                  onPressed: onCreateNote,
                ),
              if (document.type == DocumentType.note && onEditNote != null)
                ActionChip(
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa note'),
                  onPressed: onEditNote,
                ),
              if (document.type == DocumentType.note && onDeleteNote != null)
                ActionChip(
                  key: const ValueKey('delete-note'),
                  avatar: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(deletingNote ? 'Đang xóa…' : 'Xóa note'),
                  onPressed: deletingNote ? null : onDeleteNote,
                ),
              if (document.semester != null)
                Chip(label: Text('Học kỳ ${document.semester}')),
              if (document.syllabusId != null)
                Chip(label: Text('Syllabus ${document.syllabusId}')),
              if (document.demo)
                const Chip(label: Text('DEMO · dữ liệu minh họa')),
              if (document.type != DocumentType.reference)
                ActionChip(
                  avatar: const Icon(Icons.hub_outlined, size: 18),
                  label: const Text('Graph cục bộ'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (graphContext) => LocalGraphScreen(
                        snapshot: snapshot,
                        focus: document,
                        includeDemo: includeDemo,
                        onOpen: (node) {
                          Navigator.pop(graphContext);
                          onOpen(node);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (document.prerequisiteText != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điều kiện tiên quyết · nguyên văn syllabus',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      document.prerequisiteText!.replaceAll(
                        RegExp(r'<br\s*/?>', caseSensitive: false),
                        '\n',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (document.type == DocumentType.course) ...[
            _relations(
              context,
              'Concept trong syllabus',
              snapshot
                  .conceptsFor(document)
                  .where((c) => includeDemo || document.demo || !c.demo)
                  .toList(),
              'Chưa có concept note được liên kết với môn này.',
            ),
            _relations(
              context,
              'Môn tiên quyết có liên kết',
              snapshot.prerequisites(document),
              'Chưa có liên kết môn tiên quyết trong dataset.',
            ),
            _relations(
              context,
              'Môn tham chiếu môn này làm tiên quyết',
              snapshot.dependents(document),
              'Chưa có môn tham chiếu trong dataset.',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Liên kết giúp điều hướng; hãy đọc điều kiện gốc để biết các lựa chọn và yêu cầu đầy đủ.',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          ],
          if (document.type == DocumentType.concept) ...[
            _relations(
              context,
              'Môn học liên quan',
              snapshot
                  .coursesFor(document)
                  .where((c) => includeDemo || document.demo || !c.demo)
                  .toList(),
              'Chưa liên kết với môn học.',
            ),
            _relations(
              context,
              'Concept liên quan',
              document.links
                  .map(
                    (link) => snapshot.resolve(link, fromPath: document.path),
                  )
                  .whereType<KnowledgeDocument>()
                  .where(
                    (node) =>
                        node.type == DocumentType.concept &&
                        node.id != document.id &&
                        (includeDemo || document.demo || !node.demo),
                  )
                  .toSet()
                  .toList(),
              'Chưa có concept liên quan.',
            ),
          ],
          if (document.type == DocumentType.note)
            _relations(
              context,
              'Kiến thức được liên kết',
              document.links
                  .map(
                    (link) => snapshot.resolve(link, fromPath: document.path),
                  )
                  .whereType<KnowledgeDocument>()
                  .where(
                    (node) =>
                        node.id != document.id && (includeDemo || !node.demo),
                  )
                  .toSet()
                  .toList(),
              'Chưa có liên kết. Bạn có thể thêm trong editor.',
            ),
          if (document.type != DocumentType.reference)
            _relations(
              context,
              'Personal notes liên quan',
              snapshot.notesFor(document),
              'Chưa có ghi chú cá nhân liên kết tới mục này.',
            ),
          if (issues.isNotEmpty)
            ExpansionTile(
              key: PageStorageKey('${document.id}:issues'),
              tilePadding: EdgeInsets.zero,
              title: Text('${issues.length} vấn đề dữ liệu cần review'),
              children: issues
                  .map(
                    (issue) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.warning_amber),
                      title: Text(issue.message),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Text(
            document.type == DocumentType.course
                ? 'Nguồn syllabus'
                : 'Nguồn tham khảo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (document.sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Chưa có nguồn tham khảo.'),
            ),
          for (final source in document.sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => _openExternal(context, source),
                child: Text(
                  source,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ExpansionTile(
            key: PageStorageKey('${document.id}:content'),
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: document.type != DocumentType.course,
            title: const Text('Đọc nội dung Markdown'),
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  key: PageStorageKey('${document.id}:reader-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: document.type == DocumentType.course
                        ? math.max(960, constraints.maxWidth)
                        : constraints.maxWidth,
                    child: MarkdownBody(
                      selectable: true,
                      data: _readableMarkdown(),
                      onTapLink: (text, href, title) {
                        if (href == null) return;
                        if (href.startsWith('knowledge-node:')) {
                          final raw = Uri.decodeComponent(
                            href.substring('knowledge-node:'.length),
                          );
                          final target = snapshot.resolve(
                            raw,
                            fromPath: document.path,
                          );
                          if (target != null) {
                            onOpen(target);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Không tìm thấy: $raw')),
                            );
                          }
                        } else {
                          _openExternal(context, href);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            key: PageStorageKey('${document.id}:raw-markdown'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Xem Markdown gốc'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  // Its internal scroll offset must not share the tile's bool state.
                  key: PageStorageKey('${document.id}:raw-markdown-text'),
                  document.sourceMarkdown,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relations(
    BuildContext context,
    String title,
    List<KnowledgeDocument> nodes,
    String empty,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (nodes.isEmpty) Text(empty),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nodes
              .map(
                (node) => ActionChip(
                  label: Text(node.code ?? node.title),
                  onPressed: () => onOpen(node),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  String _readableMarkdown() => document.body
      .replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (match) {
        final parts = match.group(1)!.split('|');
        final label = parts.length > 1
            ? parts.sublist(1).join('|')
            : parts.first;
        return '[$label](knowledge-node:${Uri.encodeComponent(parts.first)})';
      })
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' · ');

  Future<void> _openExternal(BuildContext context, String source) async {
    final uri = Uri.tryParse(source);
    var opened = false;
    try {
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // A missing desktop URL handler must not break the offline reader.
    }
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: source));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép nguồn để bạn mở trong trình duyệt.'),
          ),
        );
      }
    }
  }
}
