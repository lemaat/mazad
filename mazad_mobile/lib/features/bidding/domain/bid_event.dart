class BidEvent {
  const BidEvent({
    required this.bidderNumber,
    required this.amount,
    required this.timestamp,
    required this.isCurrentUser,
  });

  final String bidderNumber;
  final int amount;
  final DateTime timestamp;
  final bool isCurrentUser;
}
