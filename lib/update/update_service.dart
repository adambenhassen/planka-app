import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A published release newer than the running build.
class UpdateInfo {
  final String version; // e.g. "1.1.0"
  final String url; // APK download URL (or release page as fallback)
  UpdateInfo(this.version, this.url);
}

/// Public repo → anonymous access; latest published release.
const _releasesLatest =
    'https://api.github.com/repos/adambenhassen/planka-app/releases/latest';

/// Returns the latest release if it is newer than [currentVersion], else null.
/// Fails soft: a network/parse error never throws — update checks must not
/// break app start. [dio]/[url] are injectable for tests.
Future<UpdateInfo?> checkForUpdate({
  required String currentVersion,
  Dio? dio,
  String url = _releasesLatest,
}) async {
  try {
    final res = await (dio ?? Dio()).get<Map<String, dynamic>>(url);
    final data = res.data ?? const {};
    final tag = (data['tag_name'] as String?)?.replaceFirst('v', '');
    if (tag == null || !isNewerVersion(tag, currentVersion)) return null;
    final assets = (data['assets'] as List?)?.cast<Map>() ?? const [];
    final apk = assets.firstWhere(
      (a) => (a['name'] as String?)?.endsWith('.apk') ?? false,
      orElse: () => const {},
    );
    final downloadUrl =
        (apk['browser_download_url'] ?? data['html_url']) as String?;
    if (downloadUrl == null) return null;
    return UpdateInfo(tag, downloadUrl);
  } catch (e) {
    developer.log('update check failed', name: 'update', error: e);
    return null;
  }
}

/// True when dotted [latest] (e.g. "1.2.0") is greater than [current].
bool isNewerVersion(String latest, String current) {
  final a = latest.split('.');
  final b = current.split('.');
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? int.tryParse(a[i]) ?? 0 : 0;
    final y = i < b.length ? int.tryParse(b[i]) ?? 0 : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Checks once per session. Android-only (APK sideload); null elsewhere.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  final info = await PackageInfo.fromPlatform();
  return checkForUpdate(currentVersion: info.version);
});
