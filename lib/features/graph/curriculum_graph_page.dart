import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../domain/models/curriculum_catalog.dart';

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
  final _transform = TransformationController();
  final _searchController = TextEditingController();
  String? _selectedCode;
  String _query = '';
  bool _showAllEdges = false;

  @override
  void dispose() {
    _transform.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(.35, 2.2);
    _transform.value = Matrix4.diagonal3Values(target, target, 1);
  }

  @override
  Widget build(BuildContext context) {
    CurriculumCourse? selected;
    for (final course in widget.courses) {
      if (course.code == _selectedCode) selected = course;
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _GraphToolbar(
            controller: _searchController,
            showAllEdges: _showAllEdges,
            selected: selected,
            onSearch: (value) => setState(() => _query = value),
            onShowAllEdges: (value) => setState(() => _showAllEdges = value),
            onZoomOut: () => _zoom(.82),
            onZoomIn: () => _zoom(1.18),
            onReset: () => _transform.value = Matrix4.identity(),
            onClearSelection: () => setState(() => _selectedCode = null),
            onOpenCourse: selected == null
                ? null
                : () => widget.onOpenCourse(selected!),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: _CurriculumGraphCanvas(
              courses: widget.courses,
              query: _query,
              selectedCode: _selectedCode,
              showAllEdges: _showAllEdges,
              transform: _transform,
              onSelect: (course) => setState(() {
                _selectedCode = _selectedCode == course.code
                    ? null
                    : course.code;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphToolbar extends StatelessWidget {
  const _GraphToolbar({
    required this.controller,
    required this.showAllEdges,
    required this.selected,
    required this.onSearch,
    required this.onShowAllEdges,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
    required this.onClearSelection,
    required this.onOpenCourse,
  });

  final TextEditingController controller;
  final bool showAllEdges;
  final CurriculumCourse? selected;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onShowAllEdges;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;
  final VoidCallback onClearSelection;
  final VoidCallback? onOpenCourse;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final controls = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? constraints.maxWidth : 270,
              height: 48,
              child: TextField(
                key: const ValueKey('curriculum-graph-search'),
                controller: controller,
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'Tìm node môn học',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            FilterChip(
              selected: showAllEdges,
              onSelected: onShowAllEdges,
              avatar: const Icon(Icons.route_outlined, size: 18),
              label: const Text('Tất cả liên kết'),
            ),
            IconButton(
              tooltip: 'Thu nhỏ',
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              tooltip: 'Phóng to',
              onPressed: onZoomIn,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'Vừa khung',
              onPressed: onReset,
              icon: const Icon(Icons.center_focus_strong),
            ),
          ],
        );
        final selection = selected == null
            ? const _GraphHint()
            : _SelectedCourse(
                course: selected!,
                onClear: onClearSelection,
                onOpenCourse: onOpenCourse!,
              );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [controls, const SizedBox(height: 10), selection],
          );
        }
        return Row(
          children: [
            Expanded(child: controls),
            const SizedBox(width: 16),
            selection,
          ],
        );
      },
    ),
  );
}

class _GraphHint extends StatelessWidget {
  const _GraphHint();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.touch_app_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 7),
      Text(
        'Chọn một node để xem quan hệ',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _SelectedCourse extends StatelessWidget {
  const _SelectedCourse({
    required this.course,
    required this.onClear,
    required this.onOpenCourse,
  });

  final CurriculumCourse course;
  final VoidCallback onClear;
  final VoidCallback onOpenCourse;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.school_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                course.code,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                course.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onOpenCourse, child: const Text('Chi tiết')),
        IconButton(
          tooltip: 'Bỏ chọn',
          onPressed: onClear,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
}

class _CurriculumGraphCanvas extends StatelessWidget {
  const _CurriculumGraphCanvas({
    required this.courses,
    required this.query,
    required this.selectedCode,
    required this.showAllEdges,
    required this.transform,
    required this.onSelect,
  });

  final List<CurriculumCourse> courses;
  final String query;
  final String? selectedCode;
  final bool showAllEdges;
  final TransformationController transform;
  final ValueChanged<CurriculumCourse> onSelect;

  static const _nodeWidth = 174.0;
  static const _nodeHeight = 58.0;
  static const _columnStep = 236.0;
  static const _rowStep = 74.0;
  static const _left = 120.0;
  static const _top = 112.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final grouped = <int, List<CurriculumCourse>>{};
      for (final course in courses) {
        grouped.putIfAbsent(course.semester, () => []).add(course);
      }
      final semesters = grouped.keys.toList()..sort();
      final maxRows = grouped.values.fold<int>(
        0,
        (current, group) => math.max(current, group.length),
      );
      final size = Size(
        math.max(
          constraints.maxWidth,
          _left * 2 + (semesters.length - 1) * _columnStep + _nodeWidth,
        ),
        math.max(constraints.maxHeight, _top + maxRows * _rowStep + 70),
      );
      final positions = <String, Offset>{};
      for (var column = 0; column < semesters.length; column++) {
        final semesterCourses = grouped[semesters[column]]!;
        for (var row = 0; row < semesterCourses.length; row++) {
          positions[semesterCourses[row].code] = Offset(
            _left + _nodeWidth / 2 + column * _columnStep,
            _top + row * _rowStep,
          );
        }
      }
      final byCode = {for (final course in courses) course.code: course};
      final edges = <_CurriculumEdge>[];
      for (final target in courses) {
        for (final prerequisite in target.prerequisiteCodes) {
          if (byCode.containsKey(prerequisite)) {
            edges.add(_CurriculumEdge(prerequisite, target.code));
          }
        }
      }
      final prerequisites = selectedCode == null
          ? const <String>{}
          : byCode[selectedCode]?.prerequisiteCodes.toSet() ?? const <String>{};
      final dependents = selectedCode == null
          ? const <String>{}
          : courses
                .where(
                  (course) => course.prerequisiteCodes.contains(selectedCode),
                )
                .map((course) => course.code)
                .toSet();
      final normalizedQuery = query.trim().toLowerCase();

      return ClipRect(
        child: InteractiveViewer(
          key: const ValueKey('curriculum-graph-viewer'),
          transformationController: transform,
          constrained: false,
          minScale: .35,
          maxScale: 2.2,
          boundaryMargin: const EdgeInsets.all(220),
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CurriculumEdgePainter(
                      edges: edges,
                      positions: positions,
                      selectedCode: selectedCode,
                      showAllEdges: showAllEdges,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
                for (var index = 0; index < semesters.length; index++)
                  Positioned(
                    left: _left + index * _columnStep,
                    top: 24,
                    width: _nodeWidth,
                    child: _SemesterHeader(
                      semester: semesters[index],
                      courseCount: grouped[semesters[index]]!.length,
                    ),
                  ),
                for (final course in courses)
                  _GraphNode(
                    course: course,
                    center: positions[course.code]!,
                    width: _nodeWidth,
                    height: _nodeHeight,
                    selected: course.code == selectedCode,
                    prerequisite: prerequisites.contains(course.code),
                    dependent: dependents.contains(course.code),
                    dimmed:
                        selectedCode != null &&
                        course.code != selectedCode &&
                        !prerequisites.contains(course.code) &&
                        !dependents.contains(course.code),
                    searchMatch:
                        normalizedQuery.isNotEmpty &&
                        '${course.code} ${course.name}'.toLowerCase().contains(
                          normalizedQuery,
                        ),
                    onTap: () => onSelect(course),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({required this.semester, required this.courseCount});

  final int semester;
  final int courseCount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        semester == 0 ? 'CHUẨN BỊ' : 'HỌC KỲ $semester',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        '$courseCount môn / phương án',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.course,
    required this.center,
    required this.width,
    required this.height,
    required this.selected,
    required this.prerequisite,
    required this.dependent,
    required this.dimmed,
    required this.searchMatch,
    required this.onTap,
  });

  final CurriculumCourse course;
  final Offset center;
  final double width;
  final double height;
  final bool selected;
  final bool prerequisite;
  final bool dependent;
  final bool dimmed;
  final bool searchMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final knowledge = Theme.of(context).extension<KnowledgeColors>()!;
    final accent = prerequisite
        ? knowledge.warning
        : dependent
        ? knowledge.success
        : scheme.primary;
    final background = selected
        ? scheme.primary
        : prerequisite || dependent
        ? accent.withValues(alpha: .16)
        : scheme.surfaceContainerLow;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Opacity(
        opacity: dimmed && !searchMatch ? .34 : 1,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: searchMatch || prerequisite || dependent
                  ? accent
                  : scheme.outlineVariant,
              width: searchMatch || selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('curriculum-graph-node:${course.code}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected ? foreground : accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurriculumEdgePainter extends CustomPainter {
  const _CurriculumEdgePainter({
    required this.edges,
    required this.positions,
    required this.selectedCode,
    required this.showAllEdges,
    required this.colorScheme,
  });

  final List<_CurriculumEdge> edges;
  final Map<String, Offset> positions;
  final String? selectedCode;
  final bool showAllEdges;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final active =
          selectedCode != null &&
          (edge.from == selectedCode || edge.to == selectedCode);
      if (!active && !showAllEdges) continue;
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from == null || to == null) continue;
      final direction = to.dx >= from.dx ? 1.0 : -1.0;
      final start = Offset(from.dx + 87 * direction, from.dy);
      final end = Offset(to.dx - 87 * direction, to.dy);
      final distance = (end.dx - start.dx).abs();
      final control = math.max(28.0, distance * .42);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + control * direction,
          start.dy,
          end.dx - control * direction,
          end.dy,
          end.dx,
          end.dy,
        );
      final color = active
          ? (edge.to == selectedCode
                ? const Color(0xffd97706)
                : const Color(0xff0d9488))
          : colorScheme.outline.withValues(alpha: .26);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = active ? 2.5 : 1.2,
      );
      _drawArrow(canvas, end, direction, color, active ? 7 : 5);
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset end,
    double direction,
    Color color,
    double size,
  ) {
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - size * direction, end.dy - size * .65)
      ..lineTo(end.dx - size * direction, end.dy + size * .65)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CurriculumEdgePainter oldDelegate) =>
      oldDelegate.selectedCode != selectedCode ||
      oldDelegate.showAllEdges != showAllEdges ||
      oldDelegate.edges != edges ||
      oldDelegate.positions != positions ||
      oldDelegate.colorScheme != colorScheme;
}

class _CurriculumEdge {
  const _CurriculumEdge(this.from, this.to);

  final String from;
  final String to;
}

String _curriculumLabel(String code) {
  final cohort = code.replaceFirst('BIT_SE_', '').replaceAll('_', '–');
  return 'Software Engineering · $cohort';
}
