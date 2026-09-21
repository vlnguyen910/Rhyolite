import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/course_knowledge.dart';
import '../../domain/models/curriculum_catalog.dart';
import '../../domain/models/personal_note.dart';

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
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final scale = (_transform.value.getMaxScaleOnAxis() * factor).clamp(
      .45,
      2.5,
    );
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final byCode = {
      for (final course in widget.allCourses) course.code: course,
    };
    final prerequisites = widget.course.prerequisiteCodes
        .map((code) => byCode[code])
        .whereType<CurriculumCourse>()
        .toSet()
        .toList();
    final dependents = widget.allCourses
        .where(
          (course) => course.prerequisiteCodes.contains(widget.course.code),
        )
        .toList();
    final unresolved = widget.course.prerequisiteCodes
        .where((code) => !byCode.containsKey(code))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Legend(color: Color(0xffd97706), label: 'Tiên quyết'),
              const _Legend(color: Color(0xff0d9488), label: 'Phụ thuộc'),
              const _Legend(color: Color(0xffc2410c), label: 'Nội dung'),
              const _Legend(color: Color(0xff7c3aed), label: 'Ghi chú'),
              if (unresolved.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: Text('Ngoài dataset: ${unresolved.join(', ')}'),
                ),
              IconButton(
                tooltip: 'Thu nhỏ',
                onPressed: () => _zoom(.85),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                tooltip: 'Phóng to',
                onPressed: () => _zoom(1.15),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Vừa khung',
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                math.max(1080, constraints.maxWidth),
                math.max(720, constraints.maxHeight),
              );
              final center = Offset(size.width / 2, size.height / 2);
              final coursePositions = <String, Offset>{
                widget.course.code: center,
              };
              _placeColumn(
                prerequisites,
                x: 120,
                top: size.height * .36,
                bottom: size.height * .72,
                positions: coursePositions,
              );
              _placeColumn(
                dependents,
                x: size.width - 120,
                top: size.height * .36,
                bottom: size.height * .72,
                positions: coursePositions,
              );
              final topicPositions = _placeRows(
                count: widget.knowledge.topics.length,
                width: size.width,
                top: 78,
                maxPerRow: 6,
              );
              final notePositions = _placeRows(
                count: widget.notes.length,
                width: size.width,
                top: size.height - 78,
                maxPerRow: 6,
                upwards: true,
              );

              return ClipRect(
                child: InteractiveViewer(
                  key: const ValueKey('course-graph-viewer'),
                  transformationController: _transform,
                  constrained: false,
                  minScale: .45,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(180),
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CourseGraphPainter(
                              center: center,
                              prerequisites: prerequisites,
                              dependents: dependents,
                              coursePositions: coursePositions,
                              topicPositions: topicPositions,
                              notePositions: notePositions,
                              colorScheme: Theme.of(context).colorScheme,
                            ),
                          ),
                        ),
                        _courseNode(
                          context,
                          widget.course,
                          center,
                          selected: true,
                        ),
                        for (final course in prerequisites)
                          _courseNode(
                            context,
                            course,
                            coursePositions[course.code]!,
                            accent: const Color(0xffd97706),
                          ),
                        for (final course in dependents)
                          _courseNode(
                            context,
                            course,
                            coursePositions[course.code]!,
                            accent: const Color(0xff0d9488),
                          ),
                        for (
                          var index = 0;
                          index < widget.knowledge.topics.length;
                          index++
                        )
                          _smallNode(
                            context,
                            key: ValueKey(
                              'graph-topic:${widget.knowledge.topics[index].id}',
                            ),
                            icon: Icons.lightbulb_outline,
                            label: widget.knowledge.topics[index].title,
                            center: topicPositions[index],
                            color: const Color(0xffc2410c),
                          ),
                        for (
                          var index = 0;
                          index < widget.notes.length;
                          index++
                        )
                          _smallNode(
                            context,
                            key: ValueKey(
                              'graph-note:${widget.notes[index].id}',
                            ),
                            icon: Icons.note_alt_outlined,
                            label: widget.notes[index].title,
                            center: notePositions[index],
                            color: const Color(0xff7c3aed),
                            onPressed: () =>
                                widget.onOpenNote(widget.notes[index]),
                          ),
                        if (widget.knowledge.topics.isEmpty &&
                            widget.notes.isEmpty)
                          Positioned(
                            left: center.dx - 190,
                            top: center.dy + 72,
                            width: 380,
                            child: Text(
                              'Syllabus chưa có module để tạo node nội dung. Bạn có thể tạo note để mở rộng graph.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _placeColumn(
    List<CurriculumCourse> courses, {
    required double x,
    required double top,
    required double bottom,
    required Map<String, Offset> positions,
  }) {
    if (courses.isEmpty) return;
    final step = (bottom - top) / math.max(1, courses.length - 1);
    for (var index = 0; index < courses.length; index++) {
      positions[courses[index].code] = Offset(
        x,
        courses.length == 1 ? (top + bottom) / 2 : top + step * index,
      );
    }
  }

  List<Offset> _placeRows({
    required int count,
    required double width,
    required double top,
    required int maxPerRow,
    bool upwards = false,
  }) {
    if (count == 0) return const [];
    final positions = <Offset>[];
    final rows = (count / maxPerRow).ceil();
    for (var row = 0; row < rows; row++) {
      final start = row * maxPerRow;
      final inRow = math.min(maxPerRow, count - start);
      final step = width / (inRow + 1);
      for (var column = 0; column < inRow; column++) {
        positions.add(
          Offset(step * (column + 1), top + (upwards ? -row * 62 : row * 62)),
        );
      }
    }
    return positions;
  }

  Widget _courseNode(
    BuildContext context,
    CurriculumCourse course,
    Offset center, {
    bool selected = false,
    Color? accent,
  }) {
    final width = selected ? 212.0 : 174.0;
    final height = selected ? 76.0 : 62.0;
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Material(
        color: selected ? scheme.primary : color.withValues(alpha: .14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: selected ? 2 : 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('graph-node:${course.code}'),
          onTap: selected ? null : () => widget.onOpenCourse(course),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  course.code,
                  style: TextStyle(
                    color: selected ? scheme.onPrimary : color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallNode(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required Offset center,
    required Color color,
    VoidCallback? onPressed,
  }) {
    const width = 154.0;
    const height = 48.0;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Material(
        color: color.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: color.withValues(alpha: .75)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}

class _CourseGraphPainter extends CustomPainter {
  const _CourseGraphPainter({
    required this.center,
    required this.prerequisites,
    required this.dependents,
    required this.coursePositions,
    required this.topicPositions,
    required this.notePositions,
    required this.colorScheme,
  });

  final Offset center;
  final List<CurriculumCourse> prerequisites;
  final List<CurriculumCourse> dependents;
  final Map<String, Offset> coursePositions;
  final List<Offset> topicPositions;
  final List<Offset> notePositions;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    for (final course in prerequisites) {
      _line(
        canvas,
        coursePositions[course.code]!,
        center,
        const Color(0xffd97706),
        2.2,
      );
    }
    for (final course in dependents) {
      _line(
        canvas,
        center,
        coursePositions[course.code]!,
        const Color(0xff0d9488),
        2.2,
      );
    }
    for (final position in topicPositions) {
      _line(
        canvas,
        center,
        position,
        const Color(0xffc2410c).withValues(alpha: .56),
        1.4,
      );
    }
    for (final position in notePositions) {
      _line(
        canvas,
        center,
        position,
        const Color(0xff7c3aed).withValues(alpha: .66),
        1.6,
      );
    }
  }

  void _line(Canvas canvas, Offset from, Offset to, Color color, double width) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(center.dx, (from.dy + to.dy) / 2, to.dx, to.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(covariant _CourseGraphPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.prerequisites != prerequisites ||
      oldDelegate.dependents != dependents ||
      oldDelegate.coursePositions != coursePositions ||
      oldDelegate.topicPositions != topicPositions ||
      oldDelegate.notePositions != notePositions ||
      oldDelegate.colorScheme != colorScheme;
}
