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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('course:${course.code}'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.course.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_outlined, color: colors.course),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: TextStyle(
                        color: colors.course,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (course.isChoice) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Lựa chọn · ${course.groupCodes.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (transcriptRecord != null) ...[
                const SizedBox(width: 8),
                _GradeBadge(record: transcriptRecord!),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.record});

  final TranscriptRecord record;

  @override
  Widget build(BuildContext context) {
    final status = record.status.trim().toLowerCase();
    final color = switch (status) {
      'passed' => Theme.of(context).extension<KnowledgeColors>()!.success,
      'not passed' || 'failed' => Theme.of(context).colorScheme.error,
      'studying' => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Tooltip(
      message:
          '${record.status.isEmpty ? 'Chưa rõ trạng thái' : record.status} · ${record.sourceLabel}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 42),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          record.grade.isEmpty ? '—' : record.grade,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
