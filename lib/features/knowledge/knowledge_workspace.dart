import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/knowledge_repository.dart';
import '../../domain/knowledge_document.dart';

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
        final visible = courses
            .where((c) => '${c.code} ${c.title}'.toLowerCase().contains(query))
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
                    avatar: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text('${snapshot.issues.length} vấn đề dữ liệu'),
                    onPressed: () => _showIssues(snapshot),
                  ),
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
                          ),
                        ),
                      );
                    }
                  }

                  final courseList = Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            labelText: 'Tìm môn học',
                            hintText: 'Mã môn hoặc tên môn',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
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
                            ? const Center(
                                child: Text('Không có môn học phù hợp.'),
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
                                      if (first)
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
                                          course.code!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          course.title,
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
  const _DocumentRoute({required this.document, required this.snapshot});
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(document.code ?? document.title)),
    body: DocumentDetail(
      document: document,
      snapshot: snapshot,
      onOpen: (next) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _DocumentRoute(document: next, snapshot: snapshot),
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
  });
  final KnowledgeDocument document;
  final KnowledgeSnapshot snapshot;
  final ValueChanged<KnowledgeDocument> onOpen;

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
            'Nguồn syllabus',
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
                    width: math.max(960, constraints.maxWidth),
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
