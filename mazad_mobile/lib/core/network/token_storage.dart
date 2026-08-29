import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAuth {
  const StoredAuth({
    required this.token,
    required this.username,
    required this.bidderNumber,
    this.verificationTier = 'unverified',
  });
  final String token;
  final String username;
  final String bidderNumber;
  final String verificationTier;
}

class TokenStorage {
  static const _key = 'auth_data';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(StoredAuth auth) => _storage.write(
        key: _key,
        value: jsonEncode({
          'token': auth.token,
          'username': auth.username,
          'bidder_number': auth.bidderNumber,
          'verification_tier': auth.verificationTier,
        }),
      );

  Future<StoredAuth?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      return StoredAuth(
        token: d['token'] as String,
        username: d['username'] as String? ?? '',
        bidderNumber: d['bidder_number'] as String? ?? '',
        verificationTier: d['verification_tier'] as String? ?? 'unverified',
      );
    } catch (_) {
      // Stored data is in an unreadable format — treat as unauthenticated.
      await clear();
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
