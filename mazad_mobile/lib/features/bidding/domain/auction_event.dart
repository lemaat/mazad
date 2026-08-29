sealed class AuctionEvent {}

class AuctionSnapshot extends AuctionEvent {
  AuctionSnapshot({
    required this.currentPrice,
    required this.auctionEnd,
    required this.status,
    required this.minIncrement,
    this.buyerBidderNumber,
    this.finalPrice,
  });

  final int currentPrice;
  final DateTime auctionEnd;
  final String status;
  final int minIncrement;
  // Non-null only when status == 'ended_sold'.
  final String? buyerBidderNumber;
  final int? finalPrice;
}

class BidPlacedEvent extends AuctionEvent {
  BidPlacedEvent({
    required this.currentPrice,
    required this.auctionEnd,
    required this.bidderLabel,
    required this.isCurrentUser,
  });

  final int currentPrice;
  final DateTime auctionEnd;
  final String bidderLabel;
  final bool isCurrentUser;
}

class AuctionClosedEvent extends AuctionEvent {
  AuctionClosedEvent({
    required this.status,
    this.winnerBidderNumber,
    this.winningAmount,
  });

  final String status;
  final String? winnerBidderNumber;
  final int? winningAmount;
}

class SecondChanceOfferedEvent extends AuctionEvent {
  SecondChanceOfferedEvent({
    required this.runnerUpBidderNumber,
    required this.deadline,
    required this.amount,
  });
  final String runnerUpBidderNumber;
  final DateTime deadline;
  final int amount;
}

class ConnectionError extends AuctionEvent {
  ConnectionError({this.message});
  final String? message;
}
