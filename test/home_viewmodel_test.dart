import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/domain/models/app_info.dart';
import 'package:rhyolite/services/app_service.dart';
import 'package:rhyolite/viewmodels/home_viewmodel.dart';

class MockAppService implements IAppService {
  final bool shouldThrow;

  MockAppService({this.shouldThrow = false});

  @override
  Future<AppInfo> getAppInfo() async {
    if (shouldThrow) {
      throw Exception('Failed to load app info');
    }
    return const AppInfo(
      appName: 'TestApp',
      version: '0.0.1',
      description: 'Test Description',
    );
  }
}

void main() {
  group('HomeViewModel Tests', () {
    test('initial state is correct', () {
      final vm = HomeViewModel(appService: MockAppService());
      expect(vm.selectedTab, NavigationTab.curriculum);
      expect(vm.isLoading, false);
      expect(vm.appInfo, null);
      expect(vm.errorMessage, null);
    });

    test('init() loads app info successfully', () async {
      final vm = HomeViewModel(appService: MockAppService());
      await vm.init();

      expect(vm.isLoading, false);
      expect(vm.appInfo?.appName, 'TestApp');
      expect(vm.appInfo?.version, '0.0.1');
      expect(vm.errorMessage, null);
    });

    test('init() handles error properly', () async {
      final vm = HomeViewModel(appService: MockAppService(shouldThrow: true));
      await vm.init();

      expect(vm.isLoading, false);
      expect(vm.appInfo, null);
      expect(vm.errorMessage, contains('Failed to load app info'));
    });

    test('selectTab() updates selectedTab', () {
      final vm = HomeViewModel(appService: MockAppService());
      expect(vm.selectedTab, NavigationTab.curriculum);

      vm.selectTab(NavigationTab.transcript);
      expect(vm.selectedTab, NavigationTab.transcript);

      vm.selectTab(NavigationTab.aiChat);
      expect(vm.selectedTab, NavigationTab.aiChat);
    });
  });
}
