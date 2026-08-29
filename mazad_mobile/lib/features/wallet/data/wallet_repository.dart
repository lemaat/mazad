import '../../../core/network/api_client.dart';

class WalletException implements Exception {
  const WalletException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WalletBalance {
  const WalletBalance({required this.balance, required this.availableBalance});
  final double balance;
  final double availableBalance;

  factory WalletBalance.fromJson(Map<String, dynamic> d) => WalletBalance(
        balance: double.parse(d['balance'] as String),
        availableBalance: double.parse(d['available_balance'] as String),
      );
}

class DepositInfo {
  const DepositInfo({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.amountHeld,
    required this.bidCeiling,
    required this.status,
  });
  final String id;
  final String listingId;
  final String listingTitle;
  final double amountHeld;
  final double bidCeiling;
  final String status;

  factory DepositInfo.fromJson(Map<String, dynamic> d) => DepositInfo(
        id: d['id'] as String,
        listingId: d['listing_id'] as String,
        listingTitle: d['listing_title'] as String,
        amountHeld: double.parse(d['amount_held'] as String),
        bidCeiling: double.parse(d['bid_ceiling'] as String),
        status: d['status'] as String,
      );
}

class WalletRepository {
  const WalletRepository({
    required this.host,
    required this.token,
    this.port = 8000,
  });
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<WalletBalance> fetchBalance() async {
    try {
      final data = await _client.get('/api/wallet/') as Map<String, dynamic>;
      return WalletBalance.fromJson(data);
    } on ApiException catch (e) {
      throw WalletException(e.message);
    }
  }

  Future<List<DepositInfo>> fetchDeposits({String? listingId}) async {
    try {
      final params = listingId != null
          ? {'listing_id': listingId}
          : const <String, String>{};
      final data =
          await _client.get('/api/deposits/', query: params) as List;
      return data
          .map((e) => DepositInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw WalletException(e.message);
    }
  }

  Future<DepositInfo> createDeposit({
    required String listingId,
    required double amountHeld,
  }) async {
    try {
      final data = await _client.post('/api/deposits/', {
        'listing_id': listingId,
        'amount_held': amountHeld.toStringAsFixed(2),
      }) as Map<String, dynamic>;
      return DepositInfo.fromJson(data);
    } on ApiException catch (e) {
      throw WalletException(e.message);
    }
  }
}
