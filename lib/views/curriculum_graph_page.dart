import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../models/curriculum_catalog.dart';
import '../services/concept_relation_service.dart';
import 'widgets/obsidian_graph_view.dart';

enum CurriculumGraphFilter { all, prerequisites, concepts }

class CurriculumGraphPage extends StatefulWidget {
  const CurriculumGraphPage({
    super.key,
    required this.curriculumCode,
    required this.courses,
    required this.onOpenCourse,
    this.relationService,
  });

  final String curriculumCode;
  final List<CurriculumCourse> courses;
  final ValueChanged<CurriculumCourse> onOpenCourse;
  final IConceptRelationService? relationService;

  @override
  State<CurriculumGraphPage> createState() => _CurriculumGraphPageState();
}

class _CurriculumGraphPageState extends State<CurriculumGraphPage> {
  final _graphKey = GlobalKey<ObsidianGraphViewState>();
  final _searchController = TextEditingController();
  late final IConceptRelationService _relationService;

  String? _selectedCode;
  String _query = '';
  bool _showAllEdges = true;
  CurriculumGraphFilter _filter = CurriculumGraphFilter.all;
  bool _showConceptNodes = false;

  static const _semesterColors = [
    Color(0xffa78bfa),
    Color(0xff60a5fa),
    Color(0xff38bdf8),
    Color(0xff2dd4bf),
    Color(0xff4ade80),
    Color(0xfffacc15),
    Color(0xfffb923c),
    Color(0xfff472b6),
    Color(0xffc084fc),
    Color(0xfff87171),
  ];

  @override
  void initState() {
    super.initState();
    _relationService = widget.relationService ?? ConceptRelationService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byCode = {for (final course in widget.courses) course.code: course};
    final isConceptSelected = _selectedCode?.startsWith('concept:') ?? false;
    final selectedCourse = isConceptSelected ? null : byCode[_selectedCode];

    // Tạo danh sách nodes
    final nodes = <ObsidianGraphNode>[
      for (final course in widget.courses)
        ObsidianGraphNode(
          id: course.code,
          label: course.code,
          subtitle: course.name,
          group: '${course.semester}'.padLeft(2, '0'),
          color:
              _semesterColors[course.semester.abs() % _semesterColors.length],
          keyPrefix: 'curriculum-graph-node',
        ),
    ];

    final activeConcepts = <String>{};
    if (_showConceptNodes) {
      for (final course in widget.courses) {
        activeConcepts.addAll(
          _relationService.getConceptsForCourse(course.code),
        );
      }
      for (final conceptName in activeConcepts) {
        final concept = _relationService.findConcept(conceptName);
        nodes.add(
          ObsidianGraphNode(
            id: 'concept:$conceptName',
            label: '[[$conceptName]]',
            subtitle: concept?.category ?? 'Khái niệm',
            group: 'concept',
            color: const Color(0xff06b6d4),
            keyPrefix: 'curriculum-graph-concept',
          ),
        );
      }
    }

    // Tạo danh sách edges theo bộ lọc
    final edges = <ObsidianGraphEdge>[];

    // 1. Cạnh Tiên quyết
    if (_filter == CurriculumGraphFilter.all ||
        _filter == CurriculumGraphFilter.prerequisites) {
      for (final course in widget.courses) {
        for (final prerequisite in course.prerequisiteCodes) {
          if (byCode.containsKey(prerequisite)) {
            edges.add(
              ObsidianGraphEdge(
                prerequisite,
                course.code,
                color: const Color(0xfff59e0b),
                strokeWidth: 1.5,
              ),
            );
          }
        }
      }
    }

    // 2. Cạnh Concept
    if (_filter == CurriculumGraphFilter.all ||
        _filter == CurriculumGraphFilter.concepts) {
      if (_showConceptNodes) {
        for (final course in widget.courses) {
          final concepts = _relationService.getConceptsForCourse(course.code);
          for (final concept in concepts) {
            edges.add(
              ObsidianGraphEdge(
                course.code,
                'concept:$concept',
                color: const Color(0xff06b6d4),
                strokeWidth: 1.6,
              ),
            );
          }
        }
      } else {
        final relations = _relationService.getCurriculumConceptRelations(
          widget.courses,
          minRelevance: 0.22,
        );
        for (final rel in relations) {
          edges.add(
            ObsidianGraphEdge(
              rel.sourceCourseCode,
              rel.targetCourseCode,
              color: const Color(0xff06b6d4),
              strokeWidth: (rel.relevanceScore * 3.2).clamp(1.0, 3.2),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Graph chương trình',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              _curriculumLabel(widget.curriculumCode),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 44,
                  child: TextField(
                    key: const ValueKey('curriculum-graph-search'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Tìm môn hoặc concept...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                SegmentedButton<CurriculumGraphFilter>(
                  segments: const [
                    ButtonSegment(
                      value: CurriculumGraphFilter.all,
                      label: Text('Tất cả'),
                    ),
                    ButtonSegment(
                      value: CurriculumGraphFilter.prerequisites,
                      label: Text('Tiên quyết'),
                    ),
                    ButtonSegment(
                      value: CurriculumGraphFilter.concepts,
                      label: Text('Concept'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (set) {
                    setState(() => _filter = set.first);
                  },
                ),
                FilterChip(
                  selected: _showConceptNodes,
                  onSelected: (value) =>
                      setState(() => _showConceptNodes = value),
                  avatar: const Icon(Icons.bubble_chart_outlined, size: 18),
                  label: const Text('Node Concept'),
                ),
                FilterChip(
                  selected: _showAllEdges,
                  onSelected: (value) => setState(() => _showAllEdges = value),
                  avatar: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Hiện cạnh'),
                ),
                IconButton(
                  tooltip: 'Thu nhỏ',
                  onPressed: () => _graphKey.currentState?.zoom(.82),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Phóng to',
                  onPressed: () => _graphKey.currentState?.zoom(1.18),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Vừa khung',
                  onPressed: () => _graphKey.currentState?.fit(),
                  icon: const Icon(Icons.center_focus_strong),
                ),
                if (selectedCourse == null && !isConceptSelected)
                  const Text('Chọn node để xem chi tiết & liên kết')
                else if (selectedCourse != null)
                  _SelectedCourse(
                    course: selectedCourse,
                    concepts: _relationService.getConceptsForCourse(
                      selectedCourse.code,
                    ),
                    onClear: () => setState(() => _selectedCode = null),
                    onOpen: () => widget.onOpenCourse(selectedCourse),
                  )
                else if (isConceptSelected)
                  _SelectedConcept(
                    conceptName: _selectedCode!.substring('concept:'.length),
                    courseCount: _relationService
                        .getCoursesForConcept(
                          _selectedCode!.substring('concept:'.length),
                          widget.courses,
                        )
                        .length,
                    onClear: () => setState(() => _selectedCode = null),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ObsidianGraphView(
              key: _graphKey,
              viewerKey: const ValueKey('curriculum-graph-viewer'),
              nodes: nodes,
              edges: edges,
              selectedId: _selectedCode,
              query: _query,
              showEdges: _showAllEdges,
              onTapNode: (code) => setState(() {
                _selectedCode = _selectedCode == code ? null : code;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCourse extends StatelessWidget {
  const _SelectedCourse({
    required this.course,
    required this.concepts,
    required this.onClear,
    required this.onOpen,
  });

  final CurriculumCourse course;
  final List<String> concepts;
  final VoidCallback onClear;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(course.code, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                course.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              if (concepts.isNotEmpty)
                Text(
                  concepts.map((c) => '[[$c]]').join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        TextButton(onPressed: onOpen, child: const Text('Chi tiết')),
        IconButton(
          tooltip: 'Bỏ chọn',
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class _SelectedConcept extends StatelessWidget {
  const _SelectedConcept({
    required this.conceptName,
    required this.courseCount,
    required this.onClear,
  });

  final String conceptName;
  final int courseCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bubble_chart, size: 18),
        const SizedBox(width: 6),
        Text(
          '[[$conceptName]]',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text('($courseCount môn)', style: const TextStyle(fontSize: 12)),
        IconButton(
          tooltip: 'Bỏ chọn',
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

String _curriculumLabel(String code) {
  final cohort = code.replaceFirst('BIT_SE_', '').replaceAll('_', '–');
  return 'Software Engineering · $cohort';
}
