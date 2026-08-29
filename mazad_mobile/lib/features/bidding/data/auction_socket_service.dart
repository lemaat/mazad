import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';
import '../domain/auction_event.dart';

enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

class PlaceBidException implements Exception {
  const PlaceBidException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuctionSocketService {
  AuctionSocketService({
    required this.listingId,
    required this.myBidderLabel,
    required this.host,
    required this.authToken,
    this.port = 8000,
  });

  final String listingId;
  final String myBidderLabel;
  final String host;
  final String authToken;
  final int port;

  final _events = StreamController<AuctionEvent>.broadcast();
  final _statusStream = StreamController<ConnectionStatus>.broadcast();

  Stream<AuctionEvent> get events => _events.stream;
  Stream<ConnectionStatus> get connectionStatus => _statusStream.stream;

  static const _maxAttempts = 5;
  static const _backoffSecs = [1, 2, 5, 10, 10];

  WebSocketChannel? _channel;
  bool _disposed = false;
  int _attempt = 0;

  ApiClient get _client => ApiClient(host: host, port: port, token: authToken);

  Future<void> start() async {
    _statusStream.add(ConnectionStatus.connecting);
    try {
      _events.add(await _fetchSnapshot());
    } catch (e) {
      _events.add(ConnectionError(message: _describeError(e)));
    }
    await _connect();
  }

  Future<AuctionSnapshot> _fetchSnapshot() async {
    try {
      final d = await _client.get('/api/listings/$listingId/')
          as Map<String, dynamic>;
      final sale = d['sale'] as Map<String, dynamic>?;
      return AuctionSnapshot(
        currentPrice: d['current_price'] != null
            ? _price(d['current_price'] as String)
            : _price(d['starting_price'] as String),
        auctionEnd: DateTime.parse(d['auction_end'] as String).toLocal(),
        status: d['status'] as String,
        minIncrement: _price(d['min_increment'] as String),
        buyerBidderNumber: sale?['buyer_bidder_number'] as String?,
        finalPrice: sale != null ? _price(sale['final_price'] as String) : null,
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<void> placeBid(int amount) async {
    try {
      await _client.post('/api/listings/$listingId/place_bid/', {
        'amount': amount.toString(),
        'is_anonymous': false,
      });
    } on ApiException catch (e) {
      throw PlaceBidException(e.message);
    }
  }

  Future<void> _connect() async {
    if (_disposed) return;
    final uri = Uri.parse('ws://$host:$port/ws/auctions/$listingId/');
    _channel = WebSocketChannel.connect(uri);
    try {
      // ready completes once the HTTP-upgrade handshake succeeds.
      // It throws WebSocketChannelException on any network/protocol failure —
      // but a dropped connection that never answers at all can leave `ready`
      // pending forever with no error, so bound it explicitly.
      await _channel!.ready.timeout(const Duration(seconds: 15));
    } catch (_) {
      if (!_disposed) _reconnect();
      return;
    }
    if (_disposed) return;
    // Handshake confirmed — connection is genuinely open.
    _attempt = 0;
    _statusStream.add(ConnectionStatus.connected);
    _channel!.stream.listen(
      _onData,
      onError: (_) => _reconnect(),
      onDone: _reconnect,
    );
  }

  void _onData(dynamic raw) {
    final d = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (d['type'] as String) {
      case 'bid_placed':
        final label = (d['bidder_display'] as Map)['label'] as String;
        _events.add(BidPlacedEvent(
          currentPrice: _price(d['current_price'] as String),
          auctionEnd: DateTime.parse(d['auction_end'] as String).toLocal(),
          bidderLabel: label,
          isCurrentUser: label == myBidderLabel,
        ));
      case 'auction_closed':
        final amt = d['winning_amount'];
        _events.add(AuctionClosedEvent(
          status: d['status'] as String,
          winnerBidderNumber: d['winner_bidder_number'] as String?,
          winningAmount: amt != null ? _price(amt as String) : null,
        ));
      case 'second_chance_offered':
        _events.add(SecondChanceOfferedEvent(
          runnerUpBidderNumber: d['runner_up_bidder_number'] as String,
          deadline: DateTime.parse(d['deadline'] as String).toLocal(),
          amount: _price(d['amount'] as String),
        ));
    }
  }

  Future<void> _reconnect() async {
    if (_disposed) return;
    _attempt++;
    if (_attempt > _maxAttempts) {
      _statusStream.add(ConnectionStatus.disconnected);
      return;
    }
    _statusStream.add(ConnectionStatus.reconnecting);
    await Future<void>.delayed(Duration(seconds: _backoffSecs[_attempt - 1]));
    if (_disposed) return;
    try {
      _events.add(await _fetchSnapshot());
    } catch (_) {
      // Server may still be starting; proceed to WS — if that also fails,
      // _reconnect() fires again until _maxAttempts.
    }
    await _connect();
  }

  Future<void> retry() async {
    if (_disposed) return;
    _attempt = 0;
    _statusStream.add(ConnectionStatus.reconnecting);
    try {
      _events.add(await _fetchSnapshot());
    } catch (_) {}
    await _connect();
  }

  static int _price(String s) => double.parse(s).round();

  static String _describeError(Object e) {
    if (e is SocketException) return 'Could not reach the server.';
    if (e is ApiException) return e.message;
    if (e is HttpException) return 'Server returned an unexpected response.';
    if (e is FormatException) return 'Unexpected response format.';
    return 'Connection failed.';
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    _events.close();
    _statusStream.close();
  }
}
