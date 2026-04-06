import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

@immutable
class AppVersionInfo {
  const AppVersionInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String version;
  final String buildNumber;

  static Future<AppVersionInfo> load() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return AppVersionInfo(
      appName: packageInfo.appName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}
