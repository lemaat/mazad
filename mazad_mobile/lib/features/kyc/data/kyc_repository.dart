import 'dart:io';

import '../../../core/network/api_client.dart';

class KycRepository {
  const KycRepository({required this.host, required this.token});
  final String host;
  final String token;

  ApiClient get _client => ApiClient(host: host, token: token);

  Future<Map<String, dynamic>> fetchStatus() async {
    return (await _client.get('/api/kyc/')) as Map<String, dynamic>;
  }

  Future<void> submit({
    required File idFront,
    required File idBack,
    required File selfie,
  }) async {
    await _client.postMultipart('/api/kyc/', {
      'id_front': idFront,
      'id_back': idBack,
      'selfie': selfie,
    });
  }
}
