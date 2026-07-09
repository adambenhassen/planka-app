import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// A published release newer than the running build.
class UpdateInfo {
  final String version; // e.g. "1.1.0"
  final String url; // APK download URL (or release page as fallback)
  UpdateInfo(this.version, this.url);

  /// True when [url] points at an installable APK asset rather than the
  /// release web page.
  bool get isApk => url.endsWith('.apk');
}

/// Downloads the release APK to the temp dir and returns its path.
/// [onProgress] receives 0..1 (best effort; stays 0 when length is unknown).
Future<String> downloadUpdate(
  UpdateInfo info, {
  Dio? dio,
  void Function(double progress)? onProgress,
}) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/planka-${info.version}.apk';
  await (dio ?? Dio()).download(
    info.url,
    path,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress?.call(received / total);
    },
  );
  return path;
}

/// Public repo → anonymous access; latest published release.
const _releasesLatest =
    'https://api.github.com/repos/adambenhassen/planka-app/releases/latest';

/// Returns the latest release if it is newer than [currentVersion], else null.
/// A release matching [skippedVersion] (user dismissed the prompt) is ignored.
/// Fails soft: a network/parse error never throws — update checks must not
/// break app start. [dio]/[url] are injectable for tests.
Future<UpdateInfo?> checkForUpdate({
  required String currentVersion,
  String? skippedVersion,
  Dio? dio,
  String url = _releasesLatest,
}) async {
  try {
    final res = await (dio ?? Dio()).get<Map<String, dynamic>>(url);
    final data = res.data ?? const {};
    final tag = (data['tag_name'] as String?)?.replaceFirst('v', '');
    if (tag == null || tag == skippedVersion) return null;
    if (!isNewerVersion(tag, currentVersion)) return null;
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

/// Marker file remembering a version the user dismissed the prompt for.
Future<File> _skipFile() async =>
    File('${(await getApplicationSupportDirectory()).path}/skipped_update');

/// Stops [version] from being offered again (user dismissed the prompt).
Future<void> skipVersion(String version) async {
  try {
    await (await _skipFile()).writeAsString(version);
  } catch (e) {
    developer.log(
      'persisting skipped version failed',
      name: 'update',
      error: e,
    );
  }
}

Future<String?> _skippedVersion() async {
  try {
    final f = await _skipFile();
    return await f.exists() ? (await f.readAsString()).trim() : null;
  } catch (_) {
    return null;
  }
}

/// Checks once per session. Android-only (APK sideload); null elsewhere.
/// Play Store installs are excluded — the store handles their updates.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  final info = await PackageInfo.fromPlatform();
  if (info.installerStore == 'com.android.vending') return null;
  return checkForUpdate(
    currentVersion: info.version,
    skippedVersion: await _skippedVersion(),
  );
});
