import 'dart:convert';

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
    return (jsonDecode(raw) as List)
        .map((e) => Account.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> save(List<Account> accounts) => _storage.write(
      _key, jsonEncode(accounts.map((a) => a.toJson()).toList()));

  static const _currentKey = 'currentAccountId';

  Future<String?> readCurrentId() => _storage.read(_currentKey);

  Future<void> writeCurrentId(String? id) =>
      id == null ? _storage.delete(_currentKey) : _storage.write(_currentKey, id);
}
