import '../../../core/network/api_client.dart';

int _price(String s) => double.parse(s).round();

class ListingCategory {
  const ListingCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.listingFee,
    required this.requiresIdVerification,
  });
  final int id;
  final String slug;
  final String name;
  final double listingFee;
  final bool requiresIdVerification;

  factory ListingCategory.fromJson(Map<String, dynamic> d) => ListingCategory(
        id: d['id'] as int,
        slug: d['slug'] as String,
        name: d['name'] as String,
        listingFee: double.parse(d['listing_fee'] as String),
        requiresIdVerification: d['requires_id_verification'] as bool,
      );
}

class ListingSummary {
  const ListingSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.startingPrice,
    required this.auctionStart,
    required this.auctionEnd,
    required this.status,
    this.currentPrice,
    this.primaryImageUrl,
    this.bidCount = 0,
    this.sellerBidderNumber,
    this.isFavorited = false,
  });

  final String id;
  final String title;
  final ListingCategory category;
  final int startingPrice;
  final int? currentPrice;
  final DateTime auctionStart;
  final DateTime auctionEnd;
  final String status;
  final String? primaryImageUrl;
  final int bidCount;
  final String? sellerBidderNumber;
  final bool isFavorited;

  factory ListingSummary.fromJson(Map<String, dynamic> d) => ListingSummary(
        id: d['id'] as String,
        title: d['title'] as String,
        category:
            ListingCategory.fromJson(d['category'] as Map<String, dynamic>),
        startingPrice: _price(d['starting_price'] as String),
        currentPrice: d['current_price'] != null
            ? _price(d['current_price'] as String)
            : null,
        auctionStart: DateTime.parse(d['auction_start'] as String).toLocal(),
        auctionEnd: DateTime.parse(d['auction_end'] as String).toLocal(),
        status: d['status'] as String,
        primaryImageUrl: d['primary_image'] as String?,
        bidCount: d['bid_count'] as int,
        sellerBidderNumber: d['seller_bidder_number'] as String?,
        isFavorited: d['is_favorited'] as bool? ?? false,
      );
}

/// One entry from a listing's `top_bids` — the bid history the server
/// already tracks, independent of whoever happens to have the live
/// auction room's WebSocket open right now.
class TopBid {
  const TopBid({required this.bidderLabel, required this.amount, required this.createdAt});
  final String bidderLabel;
  final int amount;
  final DateTime createdAt;

  factory TopBid.fromJson(Map<String, dynamic> d) => TopBid(
        bidderLabel: (d['bidder_display'] as Map<String, dynamic>)['label'] as String,
        amount: _price(d['amount'] as String),
        createdAt: DateTime.parse(d['created_at'] as String).toLocal(),
      );
}

class ListingDetail {
  const ListingDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startingPrice,
    required this.minIncrement,
    required this.auctionStart,
    required this.auctionEnd,
    required this.softCloseWindowSeconds,
    required this.status,
    required this.sellerBidderNumber,
    this.currentPrice,
    this.imageUrls = const [],
    this.saleInfo,
    this.isFavorited = false,
    this.topBids = const [],
  });

  final String id;
  final String title;
  final String description;
  final ListingCategory category;
  final int startingPrice;
  final int minIncrement;
  final int? currentPrice;
  final DateTime auctionStart;
  final DateTime auctionEnd;
  final int softCloseWindowSeconds;
  final String status;
  final String sellerBidderNumber;
  final List<String> imageUrls;
  final SaleInfo? saleInfo;
  final bool isFavorited;
  final List<TopBid> topBids;

  factory ListingDetail.fromJson(Map<String, dynamic> d) => ListingDetail(
        id: d['id'] as String,
        title: d['title'] as String,
        description: d['description'] as String,
        category:
            ListingCategory.fromJson(d['category'] as Map<String, dynamic>),
        startingPrice: _price(d['starting_price'] as String),
        minIncrement: _price(d['min_increment'] as String),
        currentPrice: d['current_price'] != null
            ? _price(d['current_price'] as String)
            : null,
        auctionStart: DateTime.parse(d['auction_start'] as String).toLocal(),
        auctionEnd: DateTime.parse(d['auction_end'] as String).toLocal(),
        softCloseWindowSeconds: d['soft_close_window_seconds'] as int,
        status: d['status'] as String,
        sellerBidderNumber: d['seller_bidder_number'] as String,
        imageUrls: (d['images'] as List)
            .map((e) => (e as Map<String, dynamic>)['image'] as String)
            .toList(),
        saleInfo: d['sale'] != null
            ? SaleInfo.fromJson(d['sale'] as Map<String, dynamic>)
            : null,
        isFavorited: d['is_favorited'] as bool? ?? false,
        topBids: d['top_bids'] != null
            ? (d['top_bids'] as List)
                .map((e) => TopBid.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
      );
}

class SaleAddress {
  const SaleAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.street,
    required this.city,
    required this.country,
    required this.phone,
  });
  final int id;
  final String label;
  final String fullName;
  final String street;
  final String city;
  final String country;
  final String phone;

  factory SaleAddress.fromJson(Map<String, dynamic> d) => SaleAddress(
        id: d['id'] as int,
        label: d['label'] as String,
        fullName: d['full_name'] as String,
        street: d['street'] as String,
        city: d['city'] as String,
        country: d['country'] as String,
        phone: d['phone'] as String,
      );
}

class SaleInfo {
  const SaleInfo({
    required this.buyerBidderNumber,
    required this.finalPrice,
    required this.saleStatus,
    this.secondChanceDeadline,
    this.runnerUpBidderNumber,
    this.deliveryAddress,
    this.shippedAt,
    this.deliveredAt,
    this.trackingNote,
  });
  final String buyerBidderNumber;
  final int finalPrice;
  final String saleStatus;
  final DateTime? secondChanceDeadline;
  final String? runnerUpBidderNumber;
  final SaleAddress? deliveryAddress;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? trackingNote;

  factory SaleInfo.fromJson(Map<String, dynamic> d) => SaleInfo(
        buyerBidderNumber: d['buyer_bidder_number'] as String,
        finalPrice: _price(d['final_price'] as String),
        saleStatus: d['status'] as String,
        secondChanceDeadline: d['second_chance_deadline'] != null
            ? DateTime.parse(d['second_chance_deadline'] as String).toLocal()
            : null,
        runnerUpBidderNumber: d['runner_up_bidder_number'] as String?,
        deliveryAddress: d['delivery_address'] != null
            ? SaleAddress.fromJson(d['delivery_address'] as Map<String, dynamic>)
            : null,
        shippedAt: d['shipped_at'] != null
            ? DateTime.parse(d['shipped_at'] as String).toLocal()
            : null,
        deliveredAt: d['delivered_at'] != null
            ? DateTime.parse(d['delivered_at'] as String).toLocal()
            : null,
        trackingNote: d['tracking_note'] as String?,
      );
}

class ListingException implements Exception {
  const ListingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ListingRepository {
  const ListingRepository({required this.host, this.port = 8000});
  final String host;
  final int port;

  ApiClient get _client => ApiClient(host: host, port: port);
  ApiClient _authedClient(String token) => ApiClient(host: host, port: port, token: token);

  Future<List<ListingCategory>> fetchCategories() async {
    try {
      final data = await _client.get('/api/categories/') as List;
      return data
          .map((e) => ListingCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ListingException(e.message);
    }
  }

  Future<List<ListingSummary>> fetchListings({String? category, String? status, String? token}) async {
    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (status != null) params['status'] = status;
      final client = token != null ? _authedClient(token) : _client;
      final data = await client.get('/api/listings/', query: params) as List;
      return data
          .map((e) => ListingSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ListingException(e.message);
    }
  }

  Future<ListingDetail> fetchDetail(String listingId, {String? token}) async {
    try {
      final client = token != null ? _authedClient(token) : _client;
      final data = await client.get('/api/listings/$listingId/')
          as Map<String, dynamic>;
      return ListingDetail.fromJson(data);
    } on ApiException catch (e) {
      throw ListingException(e.message);
    }
  }

  Future<List<ListingSummary>> fetchMyListings(String token) async {
    try {
      final data = await _authedClient(token).get('/api/listings/', query: {'mine': 'true'}) as List;
      return data
          .map((e) => ListingSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ListingException(e.message);
    }
  }
}
