import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../models/curriculum_catalog.dart';
import '../../models/student_transcript.dart';

class SemesterBoard extends StatelessWidget {
  const SemesterBoard({
    super.key,
    required this.groups,
    required this.onCoursePressed,
    required this.transcriptByCode,
  });

  final Map<int, List<CurriculumCourse>> groups;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  Widget build(BuildContext context) {
    final semesters = groups.keys.toList()..sort();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final columns = [
          for (final semester in semesters)
            _SemesterColumn(
              semester: semester,
              courses: groups[semester]!,
              onCoursePressed: onCoursePressed,
              compact: compact,
              transcriptByCode: transcriptByCode,
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lộ trình theo học kỳ',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!compact)
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cuộn ngang để xem các kỳ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (compact)
              ...columns.expand(
                (column) => [column, const SizedBox(height: 12)],
              )
            else
              SingleChildScrollView(
                key: const ValueKey('semester-horizontal-scroll'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns
                      .expand((column) => [column, const SizedBox(width: 16)])
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SemesterColumn extends StatelessWidget {
  const _SemesterColumn({
    required this.semester,
    required this.courses,
    required this.onCoursePressed,
    required this.compact,
    required this.transcriptByCode,
  });

  final int semester;
  final List<CurriculumCourse> courses;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final bool compact;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey('semester:$semester'),
    width: compact ? double.infinity : 292,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    semester == 0 ? 'P' : '$semester',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semester == 0
                            ? 'Giai đoạn chuẩn bị'
                            : 'Học kỳ $semester',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${courses.length} môn / phương án',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            for (var index = 0; index < courses.length; index++) ...[
              _CourseTile(
                course: courses[index],
                transcriptRecord:
                    transcriptByCode[courses[index].code.toUpperCase()],
                onPressed: () => onCoursePressed(courses[index]),
              ),
              if (index != courses.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.onPressed,
    this.transcriptRecord,
  });

  final CurriculumCourse course;
  final VoidCallback onPressed;
  final TranscriptRecord? transcriptRecord;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<KnowledgeColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 270;
        final small = constraints.maxWidth < 218;
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: ValueKey('course:${course.code}'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.all(
                small
                    ? 10
                    : compact
                    ? 11
                    : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.course.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 19,
                          color: colors.course,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          course.code,
                          style: TextStyle(
                            color: colors.course,
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(
                        record: transcriptRecord,
                        iconOnly: small,
                        compact: compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    course.name,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: _GradeValue(
                      record: transcriptRecord,
                      compact: compact,
                    ),
                  ),
                  if (course.isChoice) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Lựa chọn · ${course.groupCodes.join(', ')}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _SemesterMeta(semester: course.semester),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SemesterMeta extends StatelessWidget {
  const _SemesterMeta({required this.semester});

  final int semester;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.menu_book_outlined,
        size: 15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 4),
      Text(
        'Học kỳ ${semester == 0 ? 'chuẩn bị' : semester}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 2),
      Icon(
        Icons.chevron_right,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ],
  );
}

class _GradeValue extends StatelessWidget {
  const _GradeValue({required this.record, required this.compact});

  final TranscriptRecord? record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            'Điểm',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          record?.grade.isNotEmpty == true ? record!.grade : '—',
          style: TextStyle(
            color: color,
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.record,
    required this.iconOnly,
    required this.compact,
  });

  final TranscriptRecord? record;
  final bool iconOnly;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = _statusState(record?.status);
    final showText = !iconOnly && state != _CourseStatus.studying;
    final color = switch (state) {
      _CourseStatus.completed => Theme.of(
        context,
      ).extension<KnowledgeColors>()!.success,
      _CourseStatus.notPassed => Theme.of(context).colorScheme.error,
      _CourseStatus.studying ||
      _CourseStatus.inProgress => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };
    final label = switch (state) {
      _CourseStatus.completed => 'Completed',
      _CourseStatus.notPassed => 'Not passed',
      _CourseStatus.studying => 'Studying',
      _CourseStatus.inProgress => 'In Progress',
      _ => 'Not Started',
    };
    final icon = switch (state) {
      _CourseStatus.completed => Icons.check_circle_outline,
      _CourseStatus.notPassed => Icons.cancel_outlined,
      _CourseStatus.studying => Icons.schedule_outlined,
      _CourseStatus.inProgress => Icons.menu_book_outlined,
      _ => Icons.radio_button_unchecked,
    };
    return Tooltip(
      message: '$label${record == null ? '' : ' · ${record!.sourceLabel}'}',
      child: Semantics(
        label: label,
        button: true,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly
                ? 7
                : compact
                ? 8
                : 9,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 14 : 15, color: color),
              if (showText) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CourseStatus { studying, inProgress, completed, notStarted, notPassed }

_CourseStatus _statusState(String? rawStatus) {
  switch (rawStatus?.trim().toLowerCase()) {
    case 'passed':
    case 'completed':
      return _CourseStatus.completed;
    case 'studying':
      return _CourseStatus.studying;
    case 'in progress':
      return _CourseStatus.inProgress;
    case 'not passed':
    case 'failed':
      return _CourseStatus.notPassed;
    default:
      return _CourseStatus.notStarted;
  }
}
