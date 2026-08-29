import '../../../core/network/api_client.dart';

int _price(String s) => double.parse(s).round();

class MyBid {
  const MyBid({
    required this.listingId,
    required this.listingTitle,
    required this.listingStatus,
    required this.categoryName,
    required this.myAmount,
    required this.auctionEnd,
    this.currentPrice,
    this.isLeading = false,
  });
  final String listingId;
  final String listingTitle;
  final String listingStatus;
  final String categoryName;
  final int myAmount;
  final int? currentPrice;
  final DateTime auctionEnd;
  final bool isLeading;

  factory MyBid.fromJson(Map<String, dynamic> d) => MyBid(
        listingId: d['listing_id'] as String,
        listingTitle: d['listing_title'] as String,
        listingStatus: d['listing_status'] as String,
        categoryName: d['category_name'] as String,
        myAmount: _price(d['my_amount'] as String),
        currentPrice: d['current_price'] != null
            ? _price(d['current_price'] as String)
            : null,
        isLeading: d['is_leading'] as bool,
        auctionEnd: DateTime.parse(d['auction_end'] as String).toLocal(),
      );
}

class BidException implements Exception {
  const BidException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BidRepository {
  const BidRepository({required this.host, this.port = 8000});
  final String host;
  final int port;

  Future<List<MyBid>> fetchMyBids(String token) async {
    try {
      final client = ApiClient(host: host, port: port, token: token);
      final data = await client.get('/api/bids/mine/') as List;
      return data
          .map((e) => MyBid.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw BidException(e.message);
    }
  }
}
