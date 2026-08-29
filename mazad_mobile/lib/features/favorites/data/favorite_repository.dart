import '../../../core/network/api_client.dart';
import '../../listings/data/listing_repository.dart';

class FavoriteException implements Exception {
  const FavoriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FavoriteRepository {
  const FavoriteRepository({
    required this.host,
    required this.token,
    this.port = 8000,
  });
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<void> favorite(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/favorite/', {});
    } on ApiException catch (e) {
      throw FavoriteException(e.message);
    }
  }

  Future<void> unfavorite(String listingId) async {
    try {
      await _client.post('/api/listings/$listingId/unfavorite/', {});
    } on ApiException catch (e) {
      throw FavoriteException(e.message);
    }
  }

  Future<void> toggleFavorite(String listingId, {required bool currentlyFavorited}) async {
    if (currentlyFavorited) {
      await unfavorite(listingId);
    } else {
      await favorite(listingId);
    }
  }

  Future<List<ListingSummary>> fetchFavorites() async {
    try {
      final data = await _client.get('/api/favorites/') as List;
      return data
          .map((e) => ListingSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw FavoriteException(e.message);
    }
  }
}
