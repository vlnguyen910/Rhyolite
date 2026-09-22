import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/models/app_info.dart';
import 'package:rhyolite/models/curriculum_catalog.dart';
import 'package:rhyolite/services/app_service.dart';
import 'package:rhyolite/services/curriculum_service.dart';
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

class MockCurriculumService implements ICurriculumService {
  @override
  Future<CurriculumCatalog> loadCatalog() async => const CurriculumCatalog(
    schemaVersion: 1,
    source: 'test',
    curricula: [Curriculum(code: 'BIT_SE_K21B', courses: [])],
  );
}

void main() {
  group('HomeViewModel Tests', () {
    test('initial state is correct', () {
      final vm = HomeViewModel(
        appService: MockAppService(),
        curriculumService: MockCurriculumService(),
      );
      expect(vm.selectedTab, NavigationTab.overview);
      expect(vm.isLoading, false);
      expect(vm.appInfo, null);
      expect(vm.errorMessage, null);
    });

    test('init() loads app info successfully', () async {
      final vm = HomeViewModel(
        appService: MockAppService(),
        curriculumService: MockCurriculumService(),
      );
      await vm.init();

      expect(vm.isLoading, false);
      expect(vm.appInfo?.appName, 'TestApp');
      expect(vm.appInfo?.version, '0.0.1');
      expect(vm.catalog?.codes, ['BIT_SE_K21B']);
      expect(vm.errorMessage, null);
    });

    test('init() handles error properly', () async {
      final vm = HomeViewModel(
        appService: MockAppService(shouldThrow: true),
        curriculumService: MockCurriculumService(),
      );
      await vm.init();

      expect(vm.isLoading, false);
      expect(vm.appInfo, null);
      expect(vm.errorMessage, contains('Failed to load app info'));
    });

    test('selectTab() updates selectedTab', () {
      final vm = HomeViewModel(
        appService: MockAppService(),
        curriculumService: MockCurriculumService(),
      );
      expect(vm.selectedTab, NavigationTab.overview);

      vm.selectTab(NavigationTab.transcript);
      expect(vm.selectedTab, NavigationTab.transcript);

      vm.selectTab(NavigationTab.aiChat);
      expect(vm.selectedTab, NavigationTab.aiChat);
    });
  });
}
