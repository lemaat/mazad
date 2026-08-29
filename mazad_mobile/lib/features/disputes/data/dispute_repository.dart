import 'dart:io';

import '../../../core/network/api_client.dart';

class DisputeException implements Exception {
  const DisputeException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Dispute {
  const Dispute({
    required this.id,
    required this.saleId,
    required this.listingId,
    required this.listingTitle,
    required this.raisedByBidderNumber,
    required this.otherPartyBidderNumber,
    required this.category,
    required this.description,
    required this.status,
    required this.resolutionNote,
    required this.createdAt,
    this.evidenceUrl,
    this.resolvedAt,
  });

  final int id;
  final String saleId;
  final String listingId;
  final String listingTitle;
  final String raisedByBidderNumber;
  final String otherPartyBidderNumber;
  final String category;
  final String description;
  final String? evidenceUrl;
  final String status;
  final String resolutionNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory Dispute.fromJson(Map<String, dynamic> d) => Dispute(
        id: d['id'] as int,
        saleId: d['sale'] as String,
        listingId: d['listing_id'] as String,
        listingTitle: d['listing_title'] as String,
        raisedByBidderNumber: d['raised_by_bidder_number'] as String,
        otherPartyBidderNumber: d['other_party_bidder_number'] as String,
        category: d['category'] as String,
        description: d['description'] as String,
        evidenceUrl: d['evidence'] as String?,
        status: d['status'] as String,
        resolutionNote: (d['resolution_note'] as String?) ?? '',
        createdAt: DateTime.parse(d['created_at'] as String).toLocal(),
        resolvedAt: d['resolved_at'] != null
            ? DateTime.parse(d['resolved_at'] as String).toLocal()
            : null,
      );
}

class DisputeRepository {
  const DisputeRepository({
    required this.host,
    required this.token,
    this.port = 8000,
  });
  final String host;
  final int port;
  final String token;

  ApiClient get _client => ApiClient(host: host, port: port, token: token);

  Future<Dispute> reportDispute({
    required String listingId,
    required String category,
    required String description,
    File? evidence,
  }) async {
    try {
      final data = await _client.postMultipart(
        '/api/listings/$listingId/report_dispute/',
        evidence != null ? {'evidence': evidence} : {},
        fields: {'category': category, 'description': description},
      ) as Map<String, dynamic>;
      return Dispute.fromJson(data);
    } on ApiException catch (e) {
      throw DisputeException(e.message);
    }
  }

  Future<List<Dispute>> fetchMyDisputes() async {
    try {
      final data = await _client.get('/api/disputes/mine/') as List;
      return data
          .map((e) => Dispute.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw DisputeException(e.message);
    }
  }
}
