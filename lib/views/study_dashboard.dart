import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../models/curriculum_catalog.dart';
import '../models/personal_note.dart';
import '../models/student_transcript.dart';
import '../services/personal_note_service.dart';

class StudyDashboard extends StatefulWidget {
  const StudyDashboard({
    super.key,
    required this.curriculum,
    required this.curriculumCodes,
    required this.courses,
    required this.onCurriculumChanged,
    required this.onImportTranscript,
    required this.onOpenCurriculum,
    required this.onOpenCourse,
    required this.onOpenChat,
    required this.onOpenGraph,
    this.noteService,
    this.transcriptByCode = const {},
  });

  final String curriculum;
  final List<String> curriculumCodes;
  final List<CurriculumCourse> courses;
  final ValueChanged<String?> onCurriculumChanged;
  final VoidCallback onImportTranscript;
  final VoidCallback onOpenCurriculum;
  final ValueChanged<CurriculumCourse> onOpenCourse;
  final ValueChanged<String> onOpenChat;
  final VoidCallback onOpenGraph;
  final IPersonalNoteService? noteService;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  State<StudyDashboard> createState() => _StudyDashboardState();
}

class _StudyDashboardState extends State<StudyDashboard> {
  late final IPersonalNoteService _noteService;
  late int _semester;
  late Future<List<PersonalNote>> _recentNotes;

  @override
  void initState() {
    super.initState();
    _noteService = widget.noteService ?? PersonalNoteService();
    _semester = _initialSemester(widget.courses);
    _recentNotes = _noteService.loadRecent(limit: 4);
  }

  @override
  void didUpdateWidget(covariant StudyDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curriculum != widget.curriculum) {
      _semester = _initialSemester(widget.courses);
    }
  }

  int _initialSemester(List<CurriculumCourse> courses) {
    final semesters = courses.map((course) => course.semester).toSet();
    if (semesters.contains(8)) return 8;
    final ordered = semesters.where((semester) => semester > 0).toList()
      ..sort();
    return ordered.isEmpty ? 0 : ordered.first;
  }

  void _reloadNotes() {
    setState(() => _recentNotes = _noteService.loadRecent(limit: 4));
  }

  @override
  Widget build(BuildContext context) {
    final semesters =
        widget.courses.map((course) => course.semester).toSet().toList()
          ..sort();
    final selectedCourses = widget.courses
        .where((course) => course.semester == _semester)
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('study-dashboard-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          sliver: SliverList.list(
            children: [
              _Hero(
                curriculum: widget.curriculum,
                curriculumCodes: widget.curriculumCodes,
                onCurriculumChanged: widget.onCurriculumChanged,
                onImportTranscript: widget.onImportTranscript,
                onOpenCurriculum: widget.onOpenCurriculum,
              ),
              const SizedBox(height: AppSpacing.lg),
              _OverviewMetrics(
                courseCount: widget.courses.length,
                semesterCount: semesters.length,
                curriculumCount: widget.curriculumCodes.length,
                notes: _recentNotes,
                transcriptCount: widget.transcriptByCode.length,
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 980;
                  final explore = _SemesterExplorer(
                    semester: _semester,
                    semesters: semesters,
                    courses: selectedCourses,
                    onSemesterChanged: (value) =>
                        setState(() => _semester = value),
                    onCoursePressed: widget.onOpenCourse,
                    onOpenCurriculum: widget.onOpenCurriculum,
                    transcriptByCode: widget.transcriptByCode,
                  );
                  final assistant = _AssistantCard(onPrompt: widget.onOpenChat);
                  if (stacked) {
                    return Column(
                      children: [
                        explore,
                        const SizedBox(height: AppSpacing.lg),
                        assistant,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: explore),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: assistant),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 900;
                  final map = _CurriculumMap(
                    semesters: semesters,
                    selectedSemester: _semester,
                    onOpenGraph: widget.onOpenGraph,
                  );
                  final notes = _RecentNotes(
                    notes: _recentNotes,
                    onRefresh: _reloadNotes,
                    onOpenCurriculum: widget.onOpenCurriculum,
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        map,
                        const SizedBox(height: AppSpacing.lg),
                        notes,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: map),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: notes),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.curriculum,
    required this.curriculumCodes,
    required this.onCurriculumChanged,
    required this.onImportTranscript,
    required this.onOpenCurriculum,
  });

  final String curriculum;
  final List<String> curriculumCodes;
  final ValueChanged<String?> onCurriculumChanged;
  final VoidCallback onImportTranscript;
  final VoidCallback onOpenCurriculum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4d2f73), Color(0xff85385f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'SE STUDY ASSISTANT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Học đúng môn, đúng thời điểm.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kết nối chương trình học, bảng điểm và knowledge base để xây dựng lộ trình riêng cho bạn.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: .86),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('dashboard-import-transcript'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                    ),
                    onPressed: onImportTranscript,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Nhập bảng điểm FAP'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .6),
                      ),
                    ),
                    onPressed: onOpenCurriculum,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Xem chương trình'),
                  ),
                ],
              ),
            ],
          );
          final selector = Container(
            width: compact ? double.infinity : 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KHUNG ĐANG XEM',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const ValueKey('dashboard-curriculum-selector'),
                    value: curriculum,
                    isExpanded: true,
                    dropdownColor: scheme.surface,
                    iconEnabledColor: Colors.white,
                    selectedItemBuilder: (_) => [
                      for (final code in curriculumCodes)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _curriculumLabel(code),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                    items: [
                      for (final code in curriculumCodes)
                        DropdownMenuItem(
                          value: code,
                          child: Text(_curriculumLabel(code)),
                        ),
                    ],
                    onChanged: onCurriculumChanged,
                  ),
                ),
                const Divider(color: Colors.white24),
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white70, size: 17),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Dữ liệu cá nhân được lưu trên máy',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 24), selector],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 36),
              selector,
            ],
          );
        },
      ),
    );
  }
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics({
    required this.courseCount,
    required this.semesterCount,
    required this.curriculumCount,
    required this.notes,
    required this.transcriptCount,
  });

  final int courseCount;
  final int semesterCount;
  final int curriculumCount;
  final Future<List<PersonalNote>> notes;
  final int transcriptCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 680 ? 2 : 4;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _DashboardMetric(
            width: width,
            icon: Icons.school_outlined,
            value: '$courseCount',
            label: 'Môn / phương án',
          ),
          _DashboardMetric(
            width: width,
            icon: Icons.calendar_month_outlined,
            value: '$semesterCount',
            label: 'Giai đoạn học',
          ),
          _DashboardMetric(
            width: width,
            icon: Icons.insights_outlined,
            value: transcriptCount == 0 ? '—' : '$transcriptCount',
            label: transcriptCount == 0
                ? 'Kết quả · Chưa nhập'
                : 'Kết quả đã nhập',
            muted: transcriptCount == 0,
          ),
          FutureBuilder<List<PersonalNote>>(
            future: notes,
            builder: (context, snapshot) => _DashboardMetric(
              width: width,
              icon: Icons.note_alt_outlined,
              value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
              label: 'Ghi chú gần đây',
            ),
          ),
        ],
      );
    },
  );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.muted = false,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (muted ? scheme.outline : scheme.primary).withValues(
                    alpha: .1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: muted ? scheme.outline : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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
}

class _SemesterExplorer extends StatelessWidget {
  const _SemesterExplorer({
    required this.semester,
    required this.semesters,
    required this.courses,
    required this.onSemesterChanged,
    required this.onCoursePressed,
    required this.onOpenCurriculum,
    required this.transcriptByCode,
  });

  final int semester;
  final List<int> semesters;
  final List<CurriculumCourse> courses;
  final ValueChanged<int> onSemesterChanged;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final VoidCallback onOpenCurriculum;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  Widget build(BuildContext context) {
    final sharedCourses = courses.where((course) => !course.isChoice).toList();
    final comboCourses = courses.where((course) => course.isChoice).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.explore_outlined,
              title: 'Khám phá theo học kỳ',
              subtitle:
                  '${courses.length} môn / phương án · Chọn một môn để xem chi tiết.',
              action: TextButton(
                onPressed: onOpenCurriculum,
                child: const Text('Xem toàn bộ lộ trình'),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final value in semesters) ...[
                    ChoiceChip(
                      label: Text(value == 0 ? 'Chuẩn bị' : 'Kỳ $value'),
                      selected: value == semester,
                      onSelected: (_) => onSemesterChanged(value),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const Text('Chưa có môn trong học kỳ này.')
            else ...[
              if (sharedCourses.isNotEmpty)
                _CourseGroup(
                  title: 'Môn chung',
                  courses: sharedCourses,
                  onCoursePressed: onCoursePressed,
                  transcriptByCode: transcriptByCode,
                ),
              if (sharedCourses.isNotEmpty && comboCourses.isNotEmpty)
                const SizedBox(height: 18),
              if (comboCourses.isNotEmpty)
                _CourseGroup(
                  title: 'Môn thuộc nhóm combo',
                  courses: comboCourses,
                  onCoursePressed: onCoursePressed,
                  transcriptByCode: transcriptByCode,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseGroup extends StatelessWidget {
  const _CourseGroup({
    required this.title,
    required this.courses,
    required this.onCoursePressed,
    required this.transcriptByCode,
  });

  final String title;
  final List<CurriculumCourse> courses;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final Map<String, TranscriptRecord> transcriptByCode;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$title (${courses.length})',
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final course in courses)
            _CourseShortcut(
              course: course,
              transcriptRecord: transcriptByCode[course.code.toUpperCase()],
              onPressed: () => onCoursePressed(course),
            ),
        ],
      ),
    ],
  );
}

class _CourseShortcut extends StatelessWidget {
  const _CourseShortcut({
    required this.course,
    required this.onPressed,
    this.transcriptRecord,
  });

  final CurriculumCourse course;
  final VoidCallback onPressed;
  final TranscriptRecord? transcriptRecord;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<KnowledgeColors>()!.course;
    final record = transcriptRecord;
    final studying = record?.status.trim().toLowerCase() == 'studying';
    final statusColor = record?.isPassed == true
        ? Theme.of(context).extension<KnowledgeColors>()!.success
        : Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 230,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('dashboard-course:${course.code}'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.school_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        course.name,
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (course.isChoice) ...[
                        const SizedBox(height: 2),
                        Text(
                          _comboSlotLabel(course.groupCodes),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (record != null) ...[
                        const SizedBox(height: 5),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Điểm ${record.grade.isEmpty ? '—' : record.grade}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              if (studying)
                                Tooltip(
                                  message: 'Studying',
                                  child: Semantics(
                                    label: 'Studying',
                                    child: Icon(
                                      Icons.schedule_outlined,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                )
                              else if (record.status.isNotEmpty)
                                Text(
                                  record.status,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _comboSlotLabel(List<String> groups) {
  final slots = <String>[];
  if (groups.contains('SE_COM*1')) slots.add('1');
  if (groups.contains('SE_COM*2')) slots.add('2');
  if (groups.contains('SE_COM*3')) slots.add('3');
  if (groups.contains('SE_COM*4_ELE')) slots.add('4');
  if (slots.isEmpty) return 'Môn tự chọn';
  return 'Học phần combo ${slots.join(' hoặc ')}';
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'Môn PRM393 học gì?',
      'Các môn tiên quyết của kỳ 8?',
      'Gợi ý thứ tự ôn tập',
    ];
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: .45),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.auto_awesome_outlined,
              title: 'Hỏi trợ lý học tập',
              subtitle: 'Bắt đầu từ một câu hỏi về chương trình.',
            ),
            const SizedBox(height: 16),
            for (final prompt in prompts) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onPrompt(prompt),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(14),
                    backgroundColor: scheme.surface.withValues(alpha: .7),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(prompt)),
                      const Icon(Icons.arrow_forward, size: 17),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 4),
            Text(
              'Câu trả lời sẽ sử dụng curriculum và syllabus đã lưu trong ứng dụng.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurriculumMap extends StatelessWidget {
  const _CurriculumMap({
    required this.semesters,
    required this.selectedSemester,
    required this.onOpenGraph,
  });

  final List<int> semesters;
  final int selectedSemester;
  final VoidCallback onOpenGraph;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.account_tree_outlined,
              title: 'Bản đồ chương trình',
              subtitle:
                  'Tổng quan hành trình từ nền tảng đến đồ án tốt nghiệp.',
              action: TextButton.icon(
                onPressed: onOpenGraph,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text('Mở graph'),
              ),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < semesters.length; index++) ...[
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: semesters[index] == selectedSemester
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: semesters[index] == selectedSemester
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        semesters[index] == 0 ? 'P' : '${semesters[index]}',
                        style: TextStyle(
                          color: semesters[index] == selectedSemester
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (index != semesters.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        color: scheme.outlineVariant,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'P: chuẩn bị · 1–9: học kỳ chính',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentNotes extends StatelessWidget {
  const _RecentNotes({
    required this.notes,
    required this.onRefresh,
    required this.onOpenCurriculum,
  });

  final Future<List<PersonalNote>> notes;
  final VoidCallback onRefresh;
  final VoidCallback onOpenCurriculum;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.note_alt_outlined,
            title: 'Ghi chú gần đây',
            subtitle: 'Các note Markdown được lưu trên máy.',
            action: IconButton(
              tooltip: 'Tải lại ghi chú',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PersonalNote>>(
            future: notes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.edit_note, size: 30),
                      const SizedBox(height: 6),
                      const Text('Bạn chưa có ghi chú nào.'),
                      TextButton(
                        onPressed: onOpenCurriculum,
                        child: const Text('Chọn môn để tạo note'),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final note in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(note.courseCode),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      ?action,
    ],
  );
}

String _curriculumLabel(String code) {
  final cohort = code.replaceFirst('BIT_SE_', '').replaceAll('_', '–');
  return 'SE · $cohort';
}
