import 'package:flutter/foundation.dart';

import '../domain/models/app_info.dart';
import '../services/app_service.dart';

enum NavigationTab {
  curriculum,
  transcript,
  analysis,
  aiChat,
  studyStrategy,
  settings,
}

class HomeViewModel extends ChangeNotifier {
  final IAppService _appService;

  HomeViewModel({IAppService? appService})
    : _appService = appService ?? AppService();

  NavigationTab _selectedTab = NavigationTab.curriculum;
  NavigationTab get selectedTab => _selectedTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppInfo? _appInfo;
  AppInfo? get appInfo => _appInfo;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appInfo = await _appService.getAppInfo();
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
