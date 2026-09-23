import 'package:flutter/material.dart';

import '../../models/course_knowledge.dart';
import '../../models/curriculum_catalog.dart';
import '../../models/personal_note.dart';
import '../../services/concept_relation_service.dart';
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
    this.relationService,
  });

  final CurriculumCourse course;
  final List<CurriculumCourse> allCourses;
  final CourseKnowledge knowledge;
  final List<PersonalNote> notes;
  final ValueChanged<CurriculumCourse> onOpenCourse;
  final ValueChanged<PersonalNote> onOpenNote;
  final IConceptRelationService? relationService;

  @override
  State<CourseGraphPanel> createState() => _CourseGraphPanelState();
}

class _CourseGraphPanelState extends State<CourseGraphPanel> {
  final _graphKey = GlobalKey<ObsidianGraphViewState>();
  late final IConceptRelationService _relationService;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _relationService = widget.relationService ?? ConceptRelationService();
  }

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

    final concepts = _relationService.getConceptsForCourse(
      widget.course.code,
      dynamicConcepts: widget.knowledge.concepts,
    );

    final relatedCourses = _relationService
        .getRelatedCourses(
          widget.course.code,
          widget.allCourses,
          dynamicConcepts: widget.knowledge.concepts,
          minRelevance: 0.20,
        )
        .where((rel) {
          // Chỉ lấy môn chưa nằm trong tiên quyết hoặc phụ thuộc trực tiếp
          final target = rel.targetCourseCode;
          final isPrereq = widget.course.prerequisiteCodes.contains(target);
          final isDep = dependents.any((c) => c.code == target);
          return !isPrereq && !isDep && byCode.containsKey(target);
        })
        .take(6)
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
          anchor: const Offset(.20, .52),
          color: const Color(0xfff59e0b),
          keyPrefix: 'graph-node',
        ),
      for (final course in dependents)
        ObsidianGraphNode(
          id: course.code,
          label: course.code,
          subtitle: course.name,
          group: 'dependent',
          anchor: const Offset(.80, .52),
          color: const Color(0xff2dd4bf),
          keyPrefix: 'graph-node',
        ),
      for (final concept in concepts)
        ObsidianGraphNode(
          id: 'concept:$concept',
          label: '[[$concept]]',
          subtitle: 'Concept',
          group: 'concept',
          anchor: const Offset(.5, .16),
          color: const Color(0xff06b6d4),
          keyPrefix: 'graph-concept',
          keyValue: concept,
        ),
      for (final rel in relatedCourses)
        ObsidianGraphNode(
          id: rel.targetCourseCode,
          label: rel.targetCourseCode,
          subtitle: '${rel.relevancePercentage}% liên quan',
          group: 'related',
          anchor: const Offset(.5, .84),
          color: const Color(0xffd946ef),
          keyPrefix: 'graph-related',
          keyValue: rel.targetCourseCode,
        ),
      for (final topic in widget.knowledge.topics)
        ObsidianGraphNode(
          id: 'topic:${topic.id}',
          label: topic.title,
          group: 'topic',
          anchor: const Offset(.32, .26),
          color: const Color(0xfffb923c),
          keyPrefix: 'graph-topic',
          keyValue: topic.id,
        ),
      for (final note in widget.notes)
        ObsidianGraphNode(
          id: 'note:${note.id}',
          label: note.title,
          group: 'note',
          anchor: const Offset(.68, .74),
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
          strokeWidth: 2.0,
        ),
      for (final course in dependents)
        ObsidianGraphEdge(
          widget.course.code,
          course.code,
          color: const Color(0xff2dd4bf),
          strokeWidth: 2.0,
        ),
      for (final concept in concepts)
        ObsidianGraphEdge(
          widget.course.code,
          'concept:$concept',
          color: const Color(0xff06b6d4),
          strokeWidth: 2.5,
        ),
      for (final rel in relatedCourses)
        ObsidianGraphEdge(
          widget.course.code,
          rel.targetCourseCode,
          color: const Color(0xffd946ef),
          strokeWidth: (rel.relevanceScore * 3.5).clamp(1.2, 3.8),
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
              const _Legend(color: Color(0xff06b6d4), label: '[[Concept]]'),
              const _Legend(color: Color(0xffd946ef), label: 'Môn liên quan'),
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
                  if (id.startsWith('concept:')) {
                    setState(() => _selectedId = _selectedId == id ? null : id);
                    return;
                  }
                  if (id != widget.course.code && byCode.containsKey(id)) {
                    widget.onOpenCourse(byCode[id]!);
                    return;
                  }
                  setState(() => _selectedId = _selectedId == id ? null : id);
                },
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
