import 'package:flutter/material.dart';

import '../viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel? viewModel;

  const HomeView({super.key, this.viewModel});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? HomeViewModel();
    _viewModel.init();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _viewModel.selectedTab.index,
                onDestinationSelected: (int index) {
                  _viewModel.selectTab(NavigationTab.values[index]);
                },
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 32,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _viewModel.appInfo?.appName ?? 'Rhyolite',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: Text('Curriculum'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.table_chart_outlined),
                    selectedIcon: Icon(Icons.table_chart),
                    label: Text('Transcript'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: Text('Analysis'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: Text('AI Chat'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.lightbulb_outline),
                    selectedIcon: Icon(Icons.lightbulb),
                    label: Text('Strategy'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildTabContent(_viewModel.selectedTab)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.curriculum:
        return _buildPlaceholder(
          title: 'Curriculum Exploration',
          description: 'Browse FPTU Software Engineering curriculum versions and courses.',
          icon: Icons.menu_book,
        );
      case NavigationTab.transcript:
        return _buildPlaceholder(
          title: 'Transcript Management',
          description: 'Import your academic transcript via browser extension or file upload.',
          icon: Icons.table_chart,
        );
      case NavigationTab.analysis:
        return _buildPlaceholder(
          title: 'Academic Analysis',
          description:
              'Overview of GPA, course performance, and prerequisite tracking.',
          icon: Icons.analytics,
        );
      case NavigationTab.aiChat:
        return _buildPlaceholder(
          title: 'AI Study Assistant',
          description: 'Context-aware study guidance bounded by official course knowledge.',
          icon: Icons.chat_bubble,
        );
      case NavigationTab.studyStrategy:
        return _buildPlaceholder(
          title: 'Study Strategy',
          description:
              'Personalized learning paths tailored to your academic progress.',
          icon: Icons.lightbulb,
        );
      case NavigationTab.settings:
        return _buildPlaceholder(
          title: 'Settings',
          description:
              'Configure offline settings, AI consent, and local data storage.',
          icon: Icons.settings,
        );
    }
  }

  Widget _buildPlaceholder({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
