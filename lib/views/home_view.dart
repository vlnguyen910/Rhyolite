import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../domain/models/curriculum_catalog.dart';
import '../features/assistant/study_assistant_page.dart';
import '../features/dashboard/study_dashboard.dart';
import '../features/graph/curriculum_graph_page.dart';
import '../features/knowledge/course_detail_page.dart';
import '../services/course_knowledge_service.dart';
import '../services/course_assistant_service.dart';
import '../services/personal_note_service.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.viewModel,
    this.courseKnowledgeService,
    this.noteService,
  });

  final HomeViewModel? viewModel;
  final ICourseKnowledgeService? courseKnowledgeService;
  final IPersonalNoteService? noteService;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;
  final _searchController = TextEditingController();
  String _curriculum = 'BIT_SE_K21B';
  String _query = '';
  String? _assistantPrompt;
  int _assistantPromptRequest = 0;

  static const _destinations = [
    _Destination(
      'Tổng quan',
      'Tổng quan',
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    _Destination(
      'Curriculum',
      'Chương trình học',
      Icons.menu_book_outlined,
      Icons.menu_book,
    ),
    _Destination(
      'Transcript',
      'Bảng điểm',
      Icons.table_chart_outlined,
      Icons.table_chart,
    ),
    _Destination(
      'Analysis',
      'Phân tích',
      Icons.analytics_outlined,
      Icons.analytics,
    ),
    _Destination(
      'AI Chat',
      'Trợ lý AI',
      Icons.chat_bubble_outline,
      Icons.chat_bubble,
    ),
    _Destination(
      'Strategy',
      'Kế hoạch học',
      Icons.lightbulb_outline,
      Icons.lightbulb,
    ),
    _Destination(
      'Settings',
      'Cài đặt',
      Icons.settings_outlined,
      Icons.settings,
    ),
  ];

  static const _pageDescriptions = [
    'Lộ trình, dữ liệu học tập và công cụ dành cho bạn',
    'Khám phá môn học theo từng khóa và học kỳ',
    'Nhập, kiểm tra và quản lý dữ liệu học tập',
    'Theo dõi kết quả và các môn cần củng cố',
    'Hỏi đáp dựa trên curriculum và dữ liệu môn học',
    'Xây dựng thứ tự ưu tiên cho mục tiêu học tập',
    'Giao diện, dữ liệu local và quyền riêng tư',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HomeViewModel();
    if (_viewModel.catalog == null && !_viewModel.isLoading) {
      _viewModel.init();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) {
      if (_viewModel.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final catalog = _viewModel.catalog;
      if (catalog == null) {
        return Scaffold(
          body: Center(
            child: _LoadError(
              message:
                  _viewModel.errorMessage ??
                  'Không thể tải dữ liệu curriculum.',
              onRetry: _viewModel.init,
            ),
          ),
        );
      }
      final selectedCurriculum = catalog.find(_curriculum) != null
          ? _curriculum
          : catalog.codes.first;
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.compact;
          final extended = constraints.maxWidth >= AppBreakpoints.expandedRail;
          final page = _viewModel.selectedTab.index;
          return Scaffold(
            bottomNavigationBar: compact ? _bottomNavigation(page) : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!compact) _navigationRail(page, extended),
                  if (!compact) const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          title: _destinations[page].longLabel,
                          description: _pageDescriptions[page],
                          showSearch:
                              page == NavigationTab.curriculum.index &&
                              !compact,
                          controller: _searchController,
                          onSearch: (value) => setState(() => _query = value),
                          onRefresh: () => _viewModel.init(),
                          onInfo: _showAbout,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: page,
                            children: [
                              StudyDashboard(
                                curriculum: selectedCurriculum,
                                curriculumCodes: catalog.codes,
                                courses: catalog
                                    .find(selectedCurriculum)!
                                    .courses,
                                noteService: widget.noteService,
                                onCurriculumChanged: (value) {
                                  if (value != null) {
                                    setState(() => _curriculum = value);
                                  }
                                },
                                onImportTranscript: () => _viewModel.selectTab(
                                  NavigationTab.transcript,
                                ),
                                onOpenCurriculum: () => _viewModel.selectTab(
                                  NavigationTab.curriculum,
                                ),
                                onOpenCourse: _showCoursePreview,
                                onOpenChat: (prompt) {
                                  setState(() {
                                    _assistantPrompt = prompt;
                                    _assistantPromptRequest++;
                                  });
                                  _viewModel.selectTab(NavigationTab.aiChat);
                                },
                                onOpenGraph: _showCurriculumGraph,
                              ),
                              _CurriculumOverview(
                                curriculum: selectedCurriculum,
                                curriculumCodes: catalog.codes,
                                courses: catalog
                                    .find(selectedCurriculum)!
                                    .courses,
                                query: _query,
                                onCurriculumChanged: (value) {
                                  if (value != null) {
                                    setState(() => _curriculum = value);
                                  }
                                },
                                onCoursePressed: _showCoursePreview,
                                onGraphPressed: _showCurriculumGraph,
                              ),
                              _placeholder(
                                Icons.table_chart_outlined,
                                'Transcript Management',
                                'Import bảng điểm, xem trước dữ liệu và xác nhận trước khi lưu local.',
                              ),
                              _placeholder(
                                Icons.analytics_outlined,
                                'Academic Analysis',
                                'GPA, tiến độ curriculum và prerequisite context sẽ hiển thị tại đây.',
                              ),
                              StudyAssistantPage(
                                curriculumCode: selectedCurriculum,
                                courses: catalog
                                    .find(selectedCurriculum)!
                                    .courses,
                                service: CourseAssistantService(
                                  knowledgeService:
                                      widget.courseKnowledgeService,
                                ),
                                initialPrompt: _assistantPrompt,
                                promptRequestId: _assistantPromptRequest,
                                onOpenCourse: _showCoursePreview,
                              ),
                              _placeholder(
                                Icons.lightbulb_outline,
                                'Study Strategy',
                                'Goal, topics cần ôn và thứ tự ưu tiên được lưu local.',
                              ),
                              _placeholder(
                                Icons.settings_outlined,
                                'Settings',
                                'Quản lý theme, dữ liệu local, chat history và AI consent.',
                              ),
                            ],
                          ),
                        ),
                        _StatusBar(
                          version: _viewModel.appInfo?.version ?? '0.1.0',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _navigationRail(int page, bool extended) => NavigationRail(
    key: const ValueKey('desktop-navigation'),
    extended: extended,
    minWidth: 80,
    minExtendedWidth: 236,
    selectedIndex: page,
    onDestinationSelected: (index) =>
        _viewModel.selectTab(NavigationTab.values[index]),
    leading: Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhyolite',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text('SE Study Assistant', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    ),
    destinations: [
      for (final destination in _destinations)
        NavigationRailDestination(
          icon: Tooltip(
            message: destination.longLabel,
            child: Icon(destination.icon),
          ),
          selectedIcon: Tooltip(
            message: destination.longLabel,
            child: Icon(destination.selectedIcon),
          ),
          label: Text(destination.longLabel),
        ),
    ],
  );

  Widget _bottomNavigation(int page) => NavigationBar(
    selectedIndex: page,
    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    onDestinationSelected: (index) =>
        _viewModel.selectTab(NavigationTab.values[index]),
    destinations: [
      for (final destination in _destinations)
        NavigationDestination(
          tooltip: destination.longLabel,
          icon: Icon(destination.icon),
          selectedIcon: Icon(destination.selectedIcon),
          label: destination.shortLabel,
        ),
    ],
  );

  Widget _placeholder(IconData icon, String title, String description) =>
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(
                          icon,
                          size: 32,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _message('Màn hình này đang được chuẩn bị.'),
                      icon: const Icon(Icons.construction_outlined),
                      label: const Text('Xem trạng thái'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAbout() => showAboutDialog(
    context: context,
    applicationName: _viewModel.appInfo?.appName ?? 'Rhyolite',
    applicationVersion: _viewModel.appInfo?.version,
    applicationIcon: const Icon(Icons.school, size: 40),
    children: [
      Text(
        _viewModel.appInfo?.description ??
            'FPTU SE Personalized Study Assistant',
      ),
    ],
  );

  void _showCoursePreview(CurriculumCourse course) {
    final catalog = _viewModel.catalog!;
    final selected = catalog.find(_curriculum) ?? catalog.curricula.first;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailPage(
          course: course,
          curriculumCode: selected.code,
          allCourses: selected.courses,
          knowledgeService: widget.courseKnowledgeService,
          noteService: widget.noteService,
        ),
      ),
    );
  }

  void _showCurriculumGraph() {
    final catalog = _viewModel.catalog!;
    final selected = catalog.find(_curriculum) ?? catalog.curricula.first;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CurriculumGraphPage(
          curriculumCode: selected.code,
          courses: selected.courses,
          onOpenCourse: _showCoursePreview,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.description,
    required this.showSearch,
    required this.controller,
    required this.onSearch,
    required this.onRefresh,
    required this.onInfo,
  });

  final String title;
  final String description;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showSearch) ...[
          SizedBox(
            width: 280,
            height: 48,
            child: TextField(
              key: const ValueKey('course-search'),
              controller: controller,
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Tìm mã hoặc tên môn',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          tooltip: 'Tải lại dữ liệu',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Thông tin ứng dụng',
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline),
        ),
      ],
    ),
  );
}

class _CurriculumOverview extends StatelessWidget {
  const _CurriculumOverview({
    required this.curriculum,
    required this.curriculumCodes,
    required this.courses,
    required this.query,
    required this.onCurriculumChanged,
    required this.onCoursePressed,
    required this.onGraphPressed,
  });

  final String curriculum;
  final List<String> curriculumCodes;
  final List<CurriculumCourse> courses;
  final String query;
  final ValueChanged<String?> onCurriculumChanged;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final VoidCallback onGraphPressed;

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
                  child: _SemesterBoard(
                    groups: semesterGroups,
                    onCoursePressed: onCoursePressed,
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

class _SemesterBoard extends StatelessWidget {
  const _SemesterBoard({required this.groups, required this.onCoursePressed});

  final Map<int, List<CurriculumCourse>> groups;
  final ValueChanged<CurriculumCourse> onCoursePressed;

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
  });

  final int semester;
  final List<CurriculumCourse> courses;
  final ValueChanged<CurriculumCourse> onCoursePressed;
  final bool compact;

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
  const _CourseTile({required this.course, required this.onPressed});

  final CurriculumCourse course;
  final VoidCallback onPressed;

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
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 16,
            color: Theme.of(context).extension<KnowledgeColors>()!.success,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Local-first · Curriculum bundled offline',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Text(
            'v$version',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Destination {
  const _Destination(
    this.shortLabel,
    this.longLabel,
    this.icon,
    this.selectedIcon,
  );
  final String shortLabel;
  final String longLabel;
  final IconData icon;
  final IconData selectedIcon;
}
