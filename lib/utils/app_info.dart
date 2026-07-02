import 'package:package_info_plus/package_info_plus.dart';

/// Real app version from the platform, loaded once at startup (main.dart).
/// UI reads [AppInfo.version] synchronously — never hardcode version strings.
class AppInfo {
  AppInfo._();

  static String version = '';

  static Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
  }
}
