import '../models/app_info.dart';

abstract class IAppService {
  Future<AppInfo> getAppInfo();
}

class AppService implements IAppService {
  @override
  Future<AppInfo> getAppInfo() async {
    // In future milestones, this will connect to configuration/environment or local data.
    return const AppInfo(
      appName: 'Rhyolite',
      version: '0.1.0',
      description: 'FPTU SE Personalized Study Assistant',
    );
  }
}
