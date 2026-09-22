import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../models/curriculum_catalog.dart';
import 'widgets/obsidian_graph_view.dart';

class CurriculumGraphPage extends StatefulWidget {
  const CurriculumGraphPage({
    super.key,
    required this.curriculumCode,
    required this.courses,
    required this.onOpenCourse,
  });

  final String curriculumCode;
  final List<CurriculumCourse> courses;
  final ValueChanged<CurriculumCourse> onOpenCourse;

  @override
  State<CurriculumGraphPage> createState() => _CurriculumGraphPageState();
}

class _CurriculumGraphPageState extends State<CurriculumGraphPage> {
  final _graphKey = GlobalKey<ObsidianGraphViewState>();
  final _searchController = TextEditingController();
  String? _selectedCode;
  String _query = '';
  bool _showAllEdges = true;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byCode = {for (final course in widget.courses) course.code: course};
    final selected = byCode[_selectedCode];
    final nodes = [
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
    final edges = [
      for (final course in widget.courses)
        for (final prerequisite in course.prerequisiteCodes)
          if (byCode.containsKey(prerequisite))
            ObsidianGraphEdge(prerequisite, course.code),
    ];
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
                  width: 260,
                  height: 48,
                  child: TextField(
                    key: const ValueKey('curriculum-graph-search'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Tìm node môn học',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                FilterChip(
                  selected: _showAllEdges,
                  onSelected: (value) => setState(() => _showAllEdges = value),
                  avatar: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Tất cả liên kết'),
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
                if (selected == null)
                  const Text('Chọn hoặc kéo một node để khám phá liên kết')
                else
                  _SelectedCourse(
                    course: selected,
                    onClear: () => setState(() => _selectedCode = null),
                    onOpen: () => widget.onOpenCourse(selected),
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
    required this.onClear,
    required this.onOpen,
  });

  final CurriculumCourse course;
  final VoidCallback onClear;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 380),
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
          child: Text(
            course.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

String _curriculumLabel(String code) {
  final cohort = code.replaceFirst('BIT_SE_', '').replaceAll('_', '–');
  return 'Software Engineering · $cohort';
}
