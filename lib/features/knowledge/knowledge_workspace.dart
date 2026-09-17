import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/knowledge_repository.dart';
import '../../domain/knowledge_document.dart';
import '../graph/local_graph_screen.dart';

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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loading = widget.repository.load();
  }

  void _reload() => setState(() {
    _selected = null;
    _loading = widget.repository.load();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FPTU SE Knowledge'),
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
                FilledButton(onPressed: _reload, child: const Text('Thử lại')),
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
        final pool = _browseType == DocumentType.course ? courses : concepts;
        final visible = pool
            .where(
              (c) =>
                  '${c.code ?? ''} ${c.title} ${c.type == DocumentType.concept ? c.body : ''}'
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
                  Text('${concepts.length} concept'),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            labelText: _browseType == DocumentType.course
                                ? 'Tìm môn học'
                                : 'Tìm concept',
                            hintText: _browseType == DocumentType.course
                                ? 'Mã môn hoặc tên môn'
                                : 'Tên hoặc nội dung concept',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: const Text('Hiện dữ liệu demo'),
                        value: _showDemo,
                        onChanged: (value) => setState(() => _showDemo = value),
                      ),
                      Expanded(
                        child: visible.isEmpty
                            ? Center(
                                child: Text(
                                  _browseType == DocumentType.course
                                      ? 'Không có môn học phù hợp.'
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
                                          _browseType == DocumentType.course)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
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
                                        selected: _selected?.id == course.id,
                                        selectedTileColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        title: Text(
                                          course.code ?? course.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          course.type == DocumentType.course
                                              ? course.title
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
                                    Icon(Icons.auto_stories_outlined, size: 56),
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
                                includeDemo: _showDemo,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
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

class _DocumentRoute extends StatelessWidget {
  const _DocumentRoute({
    required this.document,
    required this.snapshot,
    this.includeDemo = false,
  });
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  final bool includeDemo;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(document.code ?? document.title)),
    body: DocumentDetail(
      document: document,
      snapshot: snapshot,
      includeDemo: includeDemo,
      onOpen: (next) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _DocumentRoute(
            document: next,
            snapshot: snapshot,
            includeDemo: includeDemo,
          ),
        ),
      ),
    ),
  );
}

class DocumentDetail extends StatelessWidget {
  const DocumentDetail({
    super.key,
    required this.document,
    required this.snapshot,
    required this.onOpen,
    this.includeDemo = false,
  });
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  final ValueChanged<KnowledgeDocument> onOpen;
  final bool includeDemo;

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
          if (issues.isNotEmpty)
            ExpansionTile(
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
            tilePadding: EdgeInsets.zero,
            title: const Text('Xem Markdown gốc'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
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
