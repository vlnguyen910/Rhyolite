import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../design_system/app_theme.dart';
import '../models/course_knowledge.dart';
import '../models/curriculum_catalog.dart';
import '../models/personal_note.dart';
import '../models/student_transcript.dart';
import '../services/course_knowledge_service.dart';
import '../services/personal_note_service.dart';
import 'widgets/course_graph_panel.dart';
import 'personal_note_editor.dart';
import 'widgets/markdown_rendering.dart';
import 'widgets/syllabus_markdown_view.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({
    super.key,
    required this.course,
    required this.curriculumCode,
    required this.allCourses,
    this.knowledgeService,
    this.noteService,
    this.transcriptByCode = const {},
  });

  final CurriculumCourse course;
  final String curriculumCode;
  final List<CurriculumCourse> allCourses;
  final ICourseKnowledgeService? knowledgeService;
  final IPersonalNoteService? noteService;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late final ICourseKnowledgeService _knowledgeService;
  late final IPersonalNoteService _noteService;
  late Future<CourseKnowledge> _knowledge;
  late Future<List<PersonalNote>> _notes;

  @override
  void initState() {
    super.initState();
    _knowledgeService = widget.knowledgeService ?? CourseKnowledgeService();
    _noteService = widget.noteService ?? PersonalNoteService();
    _knowledge = _knowledgeService.load(widget.course);
    _notes = _noteService.loadForCourse(widget.course.code);
  }

  CurriculumCourse? _findCourse(String code) {
    for (final course in widget.allCourses) {
      if (course.code.toLowerCase() == code.toLowerCase()) return course;
    }
    return null;
  }

  void _openCourse(CurriculumCourse course) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailPage(
          course: course,
          curriculumCode: widget.curriculumCode,
          allCourses: widget.allCourses,
          knowledgeService: _knowledgeService,
          noteService: _noteService,
          transcriptByCode: widget.transcriptByCode,
        ),
      ),
    );
  }

  Future<void> _editNote([PersonalNote? original]) async {
    final saved = await Navigator.push<PersonalNote>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalNoteEditor(
          course: widget.course,
          service: _noteService,
          original: original,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _notes = _noteService.loadForCourse(widget.course.code);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu note trên máy.')));
  }

  Future<void> _deleteNote(PersonalNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa note?'),
        content: Text('Bạn muốn xóa “${note.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _noteService.delete(note);
    if (!mounted) return;
    setState(() {
      _notes = _noteService.loadForCourse(widget.course.code);
    });
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.code,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.course.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              key: const ValueKey('create-course-note'),
              onPressed: _editNote,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Tạo note'),
            ),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.info_outline), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Syllabus'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Graph'),
            Tab(icon: Icon(Icons.edit_note), text: 'Ghi chú'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _knowledgePanel(_overview),
          _knowledgePanel(_syllabus),
          _graphPanel(),
          _notesPanel(),
        ],
      ),
    ),
  );

  Widget _knowledgePanel(Widget Function(CourseKnowledge) builder) =>
      FutureBuilder<CourseKnowledge>(
        future: _knowledge,
        builder: (context, state) {
          if (state.hasError) {
            return _ErrorPanel(
              message: 'Không đọc được Markdown: ${state.error}',
              onRetry: () => setState(() {
                _knowledge = _knowledgeService.load(widget.course);
              }),
            );
          }
          if (!state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return builder(state.data!);
        },
      );

  Widget _overview(CourseKnowledge knowledge) {
    final transcriptRecord =
        widget.transcriptByCode[widget.course.code.toUpperCase()];
    final prerequisites = widget.course.prerequisiteCodes;
    final dependents = widget.allCourses
        .where(
          (course) => course.prerequisiteCodes.contains(widget.course.code),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('Học kỳ ${widget.course.semester}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.school_outlined, size: 18),
                    label: Text(
                      knowledge.credits == null
                          ? 'Chưa rõ tín chỉ'
                          : '${knowledge.credits} tín chỉ',
                    ),
                  ),
                  Chip(label: Text(widget.curriculumCode)),
                  if (transcriptRecord != null)
                    Chip(
                      avatar: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text(
                        'Điểm ${transcriptRecord.grade.isEmpty ? '—' : transcriptRecord.grade}'
                        '${transcriptRecord.status.isEmpty ? '' : ' · ${transcriptRecord.status}'}'
                        ' · ${transcriptRecord.sourceLabel}',
                      ),
                    ),
                  if (widget.course.isChoice)
                    Chip(
                      avatar: const Icon(Icons.alt_route, size: 18),
                      label: Text(widget.course.groupCodes.join(', ')),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Mô tả môn học',
                icon: Icons.subject,
                child: knowledge.descriptionMarkdown.isEmpty
                    ? const Text('Syllabus chưa có phần mô tả.')
                    : MarkdownBody(
                        selectable: true,
                        data: renderableMarkdown(knowledge.descriptionMarkdown),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Thời lượng',
                icon: Icons.schedule,
                child: Text(
                  knowledge.durationMarkdown.isEmpty
                      ? 'Syllabus chưa ghi thời lượng.'
                      : knowledge.durationMarkdown,
                ),
              ),
              const SizedBox(height: 16),
              _RelationCard(
                title: 'Môn tiên quyết',
                courses: prerequisites
                    .map(_findCourse)
                    .whereType<CurriculumCourse>()
                    .toList(),
                unresolvedCodes: prerequisites
                    .where((code) => _findCourse(code) == null)
                    .toList(),
                emptyMessage: 'Không có môn tiên quyết trong dataset.',
                onOpen: _openCourse,
              ),
              const SizedBox(height: 16),
              _RelationCard(
                title: 'Môn học sử dụng kiến thức này',
                courses: dependents,
                unresolvedCodes: const [],
                emptyMessage: 'Chưa có môn phụ thuộc trong curriculum này.',
                onOpen: _openCourse,
              ),
              if (knowledge.toolsMarkdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Công cụ',
                  icon: Icons.build_outlined,
                  child: MarkdownBody(
                    selectable: true,
                    data: renderableMarkdown(knowledge.toolsMarkdown),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _syllabus(CourseKnowledge knowledge) => SyllabusMarkdownView(
    key: ValueKey('syllabus:${widget.course.code}'),
    source: knowledge.bodyMarkdown,
    onTapLink: (text, href, title) {
      final code = courseCodeFromLink(href);
      final course = code == null ? null : _findCourse(code);
      if (course != null) _openCourse(course);
    },
  );

  Widget _graphPanel() => FutureBuilder<CourseKnowledge>(
    future: _knowledge,
    builder: (context, knowledgeState) {
      if (knowledgeState.hasError) {
        return _ErrorPanel(
          message: 'Không đọc được nội dung graph: ${knowledgeState.error}',
          onRetry: () => setState(() {
            _knowledge = _knowledgeService.load(widget.course);
          }),
        );
      }
      if (!knowledgeState.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return FutureBuilder<List<PersonalNote>>(
        future: _notes,
        builder: (context, notesState) {
          if (notesState.hasError) {
            return _ErrorPanel(
              message: 'Không đọc được note cho graph: ${notesState.error}',
              onRetry: () => setState(() {
                _notes = _noteService.loadForCourse(widget.course.code);
              }),
            );
          }
          if (!notesState.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return CourseGraphPanel(
            course: widget.course,
            allCourses: widget.allCourses,
            knowledge: knowledgeState.data!,
            notes: notesState.data!,
            onOpenCourse: _openCourse,
            onOpenNote: _editNote,
          );
        },
      );
    },
  );

  Widget _notesPanel() => FutureBuilder<List<PersonalNote>>(
    future: _notes,
    builder: (context, state) {
      if (state.hasError) {
        return _ErrorPanel(
          message: 'Không đọc được note: ${state.error}',
          onRetry: () => setState(() {
            _notes = _noteService.loadForCourse(widget.course.code);
          }),
        );
      }
      if (!state.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final notes = state.data!;
      if (notes.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, size: 56),
              const SizedBox(height: 12),
              const Text('Chưa có ghi chú cho môn này.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editNote,
                icon: const Icon(Icons.add),
                label: const Text('Tạo note đầu tiên'),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            child: ListTile(
              key: ValueKey('personal-note:${note.id}'),
              title: Text(note.title),
              subtitle: Text(
                note.body.isEmpty ? 'Note trống' : note.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _editNote(note),
              trailing: IconButton(
                tooltip: 'Xóa note',
                onPressed: () => _deleteNote(note),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        },
      );
    },
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _RelationCard extends StatelessWidget {
  const _RelationCard({
    required this.title,
    required this.courses,
    required this.unresolvedCodes,
    required this.emptyMessage,
    required this.onOpen,
  });

  final String title;
  final List<CurriculumCourse> courses;
  final List<String> unresolvedCodes;
  final String emptyMessage;
  final ValueChanged<CurriculumCourse> onOpen;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: title,
    icon: Icons.account_tree_outlined,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (courses.isEmpty && unresolvedCodes.isEmpty) Text(emptyMessage),
        for (final course in courses)
          ActionChip(
            label: Text(course.code),
            tooltip: course.name,
            onPressed: () => onOpen(course),
          ),
        for (final code in unresolvedCodes)
          Chip(
            avatar: const Icon(Icons.info_outline, size: 18),
            label: Text('$code · ngoài dataset'),
          ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 44,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}
