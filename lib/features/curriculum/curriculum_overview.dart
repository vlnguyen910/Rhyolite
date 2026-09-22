import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../domain/models/curriculum_catalog.dart';
import '../../domain/models/student_transcript.dart';
import 'semester_board.dart';

class CurriculumOverview extends StatelessWidget {
  const CurriculumOverview({
    super.key,
    required this.curriculum,
    required this.curriculumCodes,
    required this.courses,
    required this.query,
    required this.onCurriculumChanged,
    required this.onCoursePressed,
    required this.onGraphPressed,
    required this.transcriptByCode,
  });

  final String curriculum;
  final List<String> curriculumCodes;
  final List<CurriculumCourse> courses;
  final String query;
  final ValueChanged<String?> onCurriculumChanged;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final VoidCallback onGraphPressed;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final filteredCourses = courses
        .where(
          (course) => '${course.code} ${course.name}'.toLowerCase().contains(
            normalized,
          ),
        )
        .toList();
    final semesterGroups = <int, List<CurriculumCourse>>{};
    for (final course in filteredCourses) {
      semesterGroups.putIfAbsent(course.semester, () => []).add(course);
    }
    final semesters = courses.map((course) => course.semester).toSet().length;
    final choices = courses.where((course) => course.isChoice).length;
    return CustomScrollView(
      key: const PageStorageKey('curriculum-preview-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Software Engineering',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Xem lộ trình học và quan hệ tiên quyết theo từng curriculum.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<String>(
                      key: const ValueKey('curriculum-selector'),
                      initialSelection: curriculum,
                      width: 210,
                      label: const Text('Khung chương trình'),
                      onSelected: onCurriculumChanged,
                      dropdownMenuEntries: [
                        for (final code in curriculumCodes)
                          DropdownMenuEntry(
                            value: code,
                            label: _curriculumLabel(code),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onGraphPressed,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: const Text('Xem graph'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  icon: Icons.menu_book_outlined,
                  value: '${courses.length}',
                  label: 'môn / phương án',
                ),
                _MetricCard(
                  icon: Icons.calendar_view_month_outlined,
                  value: '$semesters',
                  label: 'học kỳ',
                ),
                _MetricCard(
                  icon: Icons.alt_route_outlined,
                  value: '$choices',
                  label: 'phương án lựa chọn',
                ),
                _MetricCard(
                  icon: Icons.layers_outlined,
                  value: '${curriculumCodes.length}',
                  label: 'curriculum',
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          sliver: filteredCourses.isEmpty
              ? SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Không tìm thấy môn phù hợp với “$query”.'),
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: SemesterBoard(
                    groups: semesterGroups,
                    onCoursePressed: onCoursePressed,
                    transcriptByCode: transcriptByCode,
                  ),
                ),
        ),
      ],
    );
  }

  static String _curriculumLabel(String code) {
    final cohort = code.replaceFirst('BIT_SE_', '').replaceAll('_', '–');
    return 'SE · $cohort';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: SizedBox(
      width: 176,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
