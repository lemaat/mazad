import '../../../core/network/api_client.dart';

class OrderAddress {
  const OrderAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.street,
    required this.city,
    required this.country,
    required this.phone,
    required this.isDefault,
  });
  final int id;
  final String label;
  final String fullName;
  final String street;
  final String city;
  final String country;
  final String phone;
  final bool isDefault;

  factory OrderAddress.fromJson(Map<String, dynamic> d) => OrderAddress(
        id: d['id'] as int,
        label: d['label'] as String,
        fullName: d['full_name'] as String,
        street: d['street'] as String,
        city: d['city'] as String,
        country: d['country'] as String,
        phone: d['phone'] as String,
        isDefault: d['is_default'] as bool,
      );
}

class OrderException implements Exception {
  const OrderException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OrderRepository {
  const OrderRepository({required this.host, required this.token, this.port = 8000});
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<List<OrderAddress>> fetchAddresses() async {
    try {
      final data = await _client.get('/api/addresses/') as List;
      return data.map((e) => OrderAddress.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw OrderException(e.message);
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
      throw OrderException(e.message);
    }
  }

  Future<void> setDeliveryAddress(String listingId, int addressId) async {
    try {
      await _client.post('/api/listings/$listingId/set_delivery_address/', {
        'address_id': addressId,
      });
    } on ApiException catch (e) {
      throw OrderException(e.message);
    }
  }

  Future<void> confirmPayment(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/confirm_payment/', {});
    } on ApiException catch (e) {
      throw OrderException(e.message);
    }
  }

  Future<void> markShipped(String listingId, {String? trackingNote}) async {
    try {
      await _client.post('/api/listings/$listingId/mark_shipped/', {
        if (trackingNote != null && trackingNote.isNotEmpty) 'tracking_note': trackingNote,
      });
    } on ApiException catch (e) {
      throw OrderException(e.message);
    }
  }

  Future<void> confirmReceived(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/confirm_received/', {});
    } on ApiException catch (e) {
      throw OrderException(e.message);
    }
  }
}
