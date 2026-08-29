import '../../../core/network/api_client.dart';
import '../../orders/data/order_repository.dart' show OrderAddress;

export '../../orders/data/order_repository.dart' show OrderAddress;

class AddressException implements Exception {
  const AddressException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AddressRepository {
  const AddressRepository({required this.host, required this.token, this.port = 8000});
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<List<OrderAddress>> fetchAddresses() async {
    try {
      final data = await _client.get('/api/addresses/') as List;
      return data.map((e) => OrderAddress.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw AddressException(e.message);
    }
  }

  Future<OrderAddress> createAddress({
    required String label,
    required String fullName,
    required String street,
    required String city,
    String country = 'Mauritania',
    required String phone,
    bool isDefault = false,
  }) async {
    try {
      final data = await _client.post('/api/addresses/', {
        'label': label,
        'full_name': fullName,
        'street': street,
        'city': city,
        'country': country,
        'phone': phone,
        'is_default': isDefault,
      }) as Map<String, dynamic>;
      return OrderAddress.fromJson(data);
    } on ApiException catch (e) {
      throw AddressException(e.message);
    }
  }

  Future<OrderAddress> updateAddress(
    int id, {
    required String label,
    required String fullName,
    required String street,
    required String city,
    required String country,
    required String phone,
  }) async {
    try {
      final data = await _client.patch('/api/addresses/$id/', {
        'label': label,
        'full_name': fullName,
        'street': street,
        'city': city,
        'country': country,
        'phone': phone,
      }) as Map<String, dynamic>;
      return OrderAddress.fromJson(data);
    } on ApiException catch (e) {
      throw AddressException(e.message);
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await _client.delete('/api/addresses/$id/');
    } on ApiException catch (e) {
      throw AddressException(e.message);
    }
  }

  Future<OrderAddress> setDefault(int id) async {
    try {
      final data = await _client.patch('/api/addresses/$id/', {
        'is_default': true,
      }) as Map<String, dynamic>;
      return OrderAddress.fromJson(data);
    } on ApiException catch (e) {
      throw AddressException(e.message);
    }
  }
}
