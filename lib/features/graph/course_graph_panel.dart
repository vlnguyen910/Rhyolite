import 'package:flutter/material.dart';

import '../../domain/models/course_knowledge.dart';
import '../../domain/models/curriculum_catalog.dart';
import '../../domain/models/personal_note.dart';
import 'obsidian_graph_view.dart';

class CourseGraphPanel extends StatefulWidget {
  const CourseGraphPanel({
    super.key,
    required this.course,
    required this.allCourses,
    required this.knowledge,
    required this.notes,
    required this.onOpenCourse,
    required this.onOpenNote,
  });

  final CurriculumCourse course;
  final List<CurriculumCourse> allCourses;
  final CourseKnowledge knowledge;
  final List<PersonalNote> notes;
  final ValueChanged<CurriculumCourse> onOpenCourse;
  final ValueChanged<PersonalNote> onOpenNote;

  @override
  State<CourseGraphPanel> createState() => _CourseGraphPanelState();
}

class _CourseGraphPanelState extends State<CourseGraphPanel> {
  final _graphKey = GlobalKey<ObsidianGraphViewState>();
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final byCode = {
      for (final course in widget.allCourses) course.code: course,
    };
    final prerequisites = widget.course.prerequisiteCodes
        .map((code) => byCode[code])
        .whereType<CurriculumCourse>()
        .toList();
    final dependents = widget.allCourses
        .where(
          (course) => course.prerequisiteCodes.contains(widget.course.code),
        )
        .toList();
    final unresolved = widget.course.prerequisiteCodes
        .where((code) => !byCode.containsKey(code))
        .toList();
    final nodes = <ObsidianGraphNode>[
      ObsidianGraphNode(
        id: widget.course.code,
        label: widget.course.code,
        subtitle: widget.course.name,
        group: 'center',
        anchor: const Offset(.5, .5),
        color: const Color(0xffb9a2ff),
        keyPrefix: 'graph-node',
        isFocus: true,
      ),
      for (final course in prerequisites)
        ObsidianGraphNode(
          id: course.code,
          label: course.code,
          subtitle: course.name,
          group: 'prerequisite',
          anchor: const Offset(.24, .52),
          color: const Color(0xfff59e0b),
          keyPrefix: 'graph-node',
        ),
      for (final course in dependents)
        ObsidianGraphNode(
          id: course.code,
          label: course.code,
          subtitle: course.name,
          group: 'dependent',
          anchor: const Offset(.76, .52),
          color: const Color(0xff2dd4bf),
          keyPrefix: 'graph-node',
        ),
      for (final topic in widget.knowledge.topics)
        ObsidianGraphNode(
          id: 'topic:${topic.id}',
          label: topic.title,
          group: 'topic',
          anchor: const Offset(.5, .22),
          color: const Color(0xfffb923c),
          keyPrefix: 'graph-topic',
          keyValue: topic.id,
        ),
      for (final note in widget.notes)
        ObsidianGraphNode(
          id: 'note:${note.id}',
          label: note.title,
          group: 'note',
          anchor: const Offset(.5, .78),
          color: const Color(0xffa78bfa),
          keyPrefix: 'graph-note',
          keyValue: note.id,
        ),
    ];
    final edges = <ObsidianGraphEdge>[
      for (final course in prerequisites)
        ObsidianGraphEdge(
          course.code,
          widget.course.code,
          color: const Color(0xfff59e0b),
        ),
      for (final course in dependents)
        ObsidianGraphEdge(
          widget.course.code,
          course.code,
          color: const Color(0xff2dd4bf),
        ),
      for (final topic in widget.knowledge.topics)
        ObsidianGraphEdge(
          widget.course.code,
          'topic:${topic.id}',
          color: const Color(0xfffb923c),
        ),
      for (final note in widget.notes)
        ObsidianGraphEdge(
          widget.course.code,
          'note:${note.id}',
          color: const Color(0xffa78bfa),
        ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Legend(color: Color(0xfff59e0b), label: 'Tiên quyết'),
              const _Legend(color: Color(0xff2dd4bf), label: 'Phụ thuộc'),
              const _Legend(color: Color(0xfffb923c), label: 'Nội dung'),
              const _Legend(color: Color(0xffa78bfa), label: 'Ghi chú'),
              if (unresolved.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: Text('Ngoài dataset: ${unresolved.join(', ')}'),
                ),
              IconButton(
                tooltip: 'Thu nhỏ',
                onPressed: () => _graphKey.currentState?.zoom(.85),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                tooltip: 'Phóng to',
                onPressed: () => _graphKey.currentState?.zoom(1.15),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Vừa khung',
                onPressed: () => _graphKey.currentState?.fit(),
                icon: const Icon(Icons.center_focus_strong),
              ),
              const Text('Kéo node để sắp xếp · nhấn node để khám phá'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              ObsidianGraphView(
                key: _graphKey,
                viewerKey: const ValueKey('course-graph-viewer'),
                nodes: nodes,
                edges: edges,
                selectedId: _selectedId,
                onTapNode: (id) {
                  if (id.startsWith('note:')) {
                    final noteId = id.substring(5);
                    for (final note in widget.notes) {
                      if (note.id == noteId) {
                        widget.onOpenNote(note);
                        return;
                      }
                    }
                  }
                  if (id != widget.course.code && byCode.containsKey(id)) {
                    widget.onOpenCourse(byCode[id]!);
                    return;
                  }
                  setState(() => _selectedId = _selectedId == id ? null : id);
                },
              ),
              if (widget.knowledge.topics.isEmpty && widget.notes.isEmpty)
                Positioned(
                  bottom: 22,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: Text(
                      'Syllabus chưa có module để tạo node nội dung. Bạn có thể tạo note để mở rộng graph.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}
