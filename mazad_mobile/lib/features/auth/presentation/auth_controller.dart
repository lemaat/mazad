import 'package:flutter/foundation.dart';

import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required this.repository, required this.tokenStorage});

  final AuthRepository repository;
  final TokenStorage tokenStorage;

  bool _isLoggedIn = false;
  String? _token;
  String? _username;
  String? _bidderNumber;
  String _verificationTier = 'unverified';

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get username => _username;
  String? get bidderNumber => _bidderNumber;
  String get verificationTier => _verificationTier;

  /// Returns true if stored credentials were found (user is already authenticated).
  Future<bool> initialize() async {
    final stored = await tokenStorage.read();
    if (stored != null) {
      _token = stored.token;
      _username = stored.username.isNotEmpty ? stored.username : null;
      _bidderNumber = stored.bidderNumber.isNotEmpty ? stored.bidderNumber : null;
      _verificationTier = stored.verificationTier;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    final result = await repository.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    await _setAuthenticated(result);
  }

  Future<void> register({
    required String phoneNumber,
    required String username,
    required String password,
  }) async {
    final result = await repository.register(
      phoneNumber: phoneNumber,
      username: username,
      password: password,
    );
    await _setAuthenticated(result);
  }

  Future<void> logout() async {
    await tokenStorage.clear();
    _token = null;
    _username = null;
    _bidderNumber = null;
    _verificationTier = 'unverified';
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> _setAuthenticated(AuthResult result) async {
    await tokenStorage.save(StoredAuth(
      token: result.token,
      username: result.username,
      bidderNumber: result.bidderNumber,
      verificationTier: result.verificationTier,
    ));
    _token = result.token;
    _username = result.username;
    _bidderNumber = result.bidderNumber;
    _verificationTier = result.verificationTier;
    _isLoggedIn = true;
    notifyListeners();
  }
}
