import '../../../core/network/api_client.dart';

class AuthResult {
  const AuthResult({
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

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  const AuthRepository({required this.host, this.port = 8000});
  final String host;
  final int port;

  ApiClient get _client => ApiClient(host: host, port: port);

  Future<AuthResult> login({
    required String phoneNumber,
    required String password,
  }) =>
      _post('/api/auth/login/', {
        'phone_number': phoneNumber,
        'password': password,
      });

  Future<AuthResult> register({
    required String phoneNumber,
    required String username,
    required String password,
  }) =>
      _post('/api/auth/register/', {
        'phone_number': phoneNumber,
        'username': username,
        'password': password,
      });

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    try {
      final d = await _client.post(path, body) as Map<String, dynamic>;
      return AuthResult(
        token: d['token'] as String,
        username: d['username'] as String,
        bidderNumber: d['bidder_number'] as String,
        verificationTier: d['verification_tier'] as String? ?? 'unverified',
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }
}
