import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal secure-storage surface so tests can inject an in-memory fake.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;
  const FlutterSecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Desktop store that keeps each value in an owner-only file under [_dir],
/// avoiding the OS keychain — which on a local desktop build needs code-signing
/// entitlements the build doesn't have. Filesystem permissions are the
/// protection (real at-rest encryption would need a key with nowhere safe to
/// live without a keychain).
class FileKeyValueStore implements SecureKeyValueStore {
  final Directory _dir;
  FileKeyValueStore(this._dir);

  File _fileFor(String key) => File('${_dir.path}/$key');

  @override
  Future<String?> read(String key) async {
    final f = _fileFor(key);
    return f.existsSync() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    await _dir.create(recursive: true);
    _restrict(_dir.path, '700');
    final f = _fileFor(key);
    await f.writeAsString(value);
    _restrict(f.path, '600');
  }

  @override
  Future<void> delete(String key) async {
    final f = _fileFor(key);
    if (f.existsSync()) await f.delete();
  }

  // ponytail: Dart's stdlib has no chmod, so shell out. Best-effort — a failure
  // just leaves default perms, it must not crash session restore. No-op on
  // Windows (different permission model).
  void _restrict(String path, String mode) {
    if (Platform.isWindows) return;
    try {
      Process.runSync('chmod', [mode, path]);
    } catch (_) {}
  }
}

class Account {
  final String serverUrl;
  final String token;
  final String userId;
  final String displayName;

  Account({
    required this.serverUrl,
    required this.token,
    required this.userId,
    required this.displayName,
  });

  String get id => '$serverUrl#$userId';

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'token': token,
        'userId': userId,
        'displayName': displayName,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        serverUrl: json['serverUrl'] as String,
        token: json['token'] as String,
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
      );

  Account copyWith({String? token}) => Account(
        serverUrl: serverUrl,
        token: token ?? this.token,
        userId: userId,
        displayName: displayName,
      );
}

class AccountStore {
  static const _key = 'accounts';
  final SecureKeyValueStore _storage;
  AccountStore(this._storage);

  Future<List<Account>> load() async {
    final raw = await _storage.read(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Account.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      // Corrupt or schema-evolved storage must not crash app start (this runs
      // during boot via session restore): treat it as no saved accounts and
      // let the user re-authenticate. Log it — a decrypt failure here is a
      // silent forced-relogin, indistinguishable from "no saved accounts"
      // without this line.
      debugPrint('AccountStore.load failed, treating as no accounts: $e');
      return [];
    }
  }

  Future<void> save(List<Account> accounts) => _storage.write(
      _key, jsonEncode(accounts.map((a) => a.toJson()).toList()));

  static const _currentKey = 'currentAccountId';

  Future<String?> readCurrentId() => _storage.read(_currentKey);

  Future<void> writeCurrentId(String? id) =>
      id == null ? _storage.delete(_currentKey) : _storage.write(_currentKey, id);
}
