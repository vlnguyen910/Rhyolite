import 'package:flutter/foundation.dart';

import '../models/app_info.dart';
import '../models/curriculum_catalog.dart';
import '../services/app_service.dart';
import '../services/curriculum_service.dart';

enum NavigationTab {
  overview,
  curriculum,
  transcript,
  analysis,
  aiChat,
  studyStrategy,
  settings,
}

class HomeViewModel extends ChangeNotifier {
  final IAppService _appService;
  final ICurriculumService _curriculumService;

  HomeViewModel({
    IAppService? appService,
    ICurriculumService? curriculumService,
  }) : _appService = appService ?? AppService(),
       _curriculumService = curriculumService ?? CurriculumService();

  NavigationTab _selectedTab = NavigationTab.overview;
  NavigationTab get selectedTab => _selectedTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppInfo? _appInfo;
  AppInfo? get appInfo => _appInfo;

  CurriculumCatalog? _catalog;
  CurriculumCatalog? get catalog => _catalog;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appInfo = await _appService.getAppInfo();
      _catalog = await _curriculumService.loadCatalog();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTab(NavigationTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }
}
