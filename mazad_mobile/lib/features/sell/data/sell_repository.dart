import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../listings/data/listing_repository.dart';

class SellException implements Exception {
  const SellException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CreatedListing {
  const CreatedListing({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
  });
  final String id;
  final String title;
  final String status;
  final ListingCategory category;

  factory CreatedListing.fromJson(Map<String, dynamic> d) => CreatedListing(
        id: d['id'] as String,
        title: d['title'] as String,
        status: d['status'] as String,
        category:
            ListingCategory.fromJson(d['category'] as Map<String, dynamic>),
      );
}

class SellRepository {
  const SellRepository({required this.host, required this.token, this.port = 8000});
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<CreatedListing> createListing({
    required int categoryId,
    required String title,
    required String description,
    required int startingPrice,
    required int reservePrice,
    required int minIncrement,
    required DateTime auctionStart,
    required DateTime auctionEnd,
    int softCloseWindowSeconds = 120,
  }) async {
    try {
      final data = await _client.post('/api/listings/', {
        'category_id': categoryId,
        'title': title,
        'description': description,
        'starting_price': startingPrice.toStringAsFixed(2),
        'reserve_price': reservePrice.toStringAsFixed(2),
        'min_increment': minIncrement.toStringAsFixed(2),
        'auction_start': auctionStart.toUtc().toIso8601String(),
        'auction_end': auctionEnd.toUtc().toIso8601String(),
        'soft_close_window_seconds': softCloseWindowSeconds,
      }) as Map<String, dynamic>;
      return CreatedListing.fromJson(data);
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }

  Future<void> payListingFee(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/pay_listing_fee/', {});
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }

  Future<Map<String, dynamic>> offerSecondChance(String listingId) async {
    try {
      return await _client.post('/api/listings/$listingId/offer_second_chance/', {})
          as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }

  Future<void> acceptSecondChance(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/accept_second_chance/', {});
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }

  Future<void> endUnsold(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/end_unsold/', {});
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }

  Future<Map<String, dynamic>> uploadListingImage(String listingId, File image) async {
    try {
      return await _client.postMultipart(
        '/api/listings/$listingId/upload_image/',
        {'image': image},
      ) as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw SellException(e.message);
    }
  }
}
