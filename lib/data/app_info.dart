import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  /// Repository URL opened from Settings → App.
  static const repoUrl = 'https://gitlab.com/octospacc/Fixes';

  static PackageInfo? _info;

  static Future<void> load() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (_) {
      // Fall through — display will just be "unknown".
    }
  }

  static String get version => _info?.version ?? '—';
  static String get buildNumber => _info?.buildNumber ?? '—';

  /// e.g. "1.2.0 (1)"
  static String get display => '${version} ($buildNumber)';
}