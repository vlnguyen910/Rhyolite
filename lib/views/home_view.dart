import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../domain/models/curriculum_catalog.dart';
import '../domain/models/student_transcript.dart';
import '../features/assistant/study_assistant_page.dart';
import '../features/curriculum/curriculum_overview.dart';
import '../features/dashboard/study_dashboard.dart';
import '../features/graph/curriculum_graph_page.dart';
import '../features/knowledge/course_detail_page.dart';
import '../features/transcript/transcript_page.dart';
import '../services/course_knowledge_service.dart';
import '../services/groq_course_assistant_service.dart';
import '../services/personal_note_service.dart';
import '../services/transcript_service.dart';
import '../viewmodels/home_viewmodel.dart';
import 'home_shell_widgets.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.viewModel,
    this.courseKnowledgeService,
    this.noteService,
    this.transcriptParser,
    this.transcriptRepository,
  });

  final HomeViewModel? viewModel;
  final ICourseKnowledgeService? courseKnowledgeService;
  final IPersonalNoteService? noteService;
  final ITranscriptParser? transcriptParser;
  final ITranscriptRepository? transcriptRepository;

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
  StudentTranscript? _transcript;

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
      'AI Chat',
      'Trợ lý AI',
      Icons.chat_bubble_outline,
      Icons.chat_bubble,
    ),
  ];

  static const _pageDescriptions = [
    'Lộ trình, dữ liệu học tập và công cụ dành cho bạn',
    'Khám phá môn học theo từng khóa và học kỳ',
    'Nhập, kiểm tra và quản lý dữ liệu học tập',
    'Hỏi đáp dựa trên curriculum và dữ liệu môn học',
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
            child: HomeLoadError(
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
      final selectedCourses = catalog.find(selectedCurriculum)!.courses;
      final transcriptByCode =
          _transcript?.latestBySubjectCode ??
          const <String, TranscriptRecord>{};
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
                        HomeTopBar(
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
                                courses: selectedCourses,
                                transcriptByCode: transcriptByCode,
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
                              CurriculumOverview(
                                curriculum: selectedCurriculum,
                                curriculumCodes: catalog.codes,
                                courses: selectedCourses,
                                transcriptByCode: transcriptByCode,
                                query: _query,
                                onCurriculumChanged: (value) {
                                  if (value != null) {
                                    setState(() => _curriculum = value);
                                  }
                                },
                                onCoursePressed: _showCoursePreview,
                                onGraphPressed: _showCurriculumGraph,
                              ),
                              TranscriptPage(
                                courses: selectedCourses,
                                parser: widget.transcriptParser,
                                repository: widget.transcriptRepository,
                                onTranscriptChanged: (transcript) {
                                  if (!mounted ||
                                      identical(_transcript, transcript)) {
                                    return;
                                  }
                                  setState(() => _transcript = transcript);
                                },
                              ),
                              StudyAssistantPage(
                                curriculumCode: selectedCurriculum,
                                courses: selectedCourses,
                                transcript: _transcript,
                                service: GroqCourseAssistantService(
                                  knowledgeService:
                                      widget.courseKnowledgeService,
                                ),
                                initialPrompt: _assistantPrompt,
                                promptRequestId: _assistantPromptRequest,
                                onOpenCourse: _showCoursePreview,
                              ),
                            ],
                          ),
                        ),
                        HomeStatusBar(
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
          transcriptByCode:
              _transcript?.latestBySubjectCode ??
              const <String, TranscriptRecord>{},
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
