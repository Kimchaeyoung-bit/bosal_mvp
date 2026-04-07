enum BookingStatus { pending, confirmed, cancelled }

class Booking {
  final String id;
  final String bosalId;
  final DateTime requestedAt;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.bosalId,
    required this.requestedAt,
    required this.status,
  });
}
