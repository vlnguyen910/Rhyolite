import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'services/course_knowledge_service.dart';
import 'services/personal_note_service.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/home_view.dart';

class RhyoliteApp extends StatelessWidget {
  const RhyoliteApp({
    super.key,
    this.homeViewModel,
    this.courseKnowledgeService,
    this.noteService,
  });

  final HomeViewModel? homeViewModel;
  final ICourseKnowledgeService? courseKnowledgeService;
  final IPersonalNoteService? noteService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhyolite - FPTU SE Study Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeView(
        viewModel: homeViewModel,
        courseKnowledgeService: courseKnowledgeService,
        noteService: noteService,
      ),
    );
  }
}
