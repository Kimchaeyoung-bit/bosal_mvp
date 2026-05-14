enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  final String id;
  final String bosalId;
  final DateTime requestedAt;
  final DateTime? consultDate;
  final String consultType;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.bosalId,
    required this.requestedAt,
    this.consultDate,
    required this.consultType,
    required this.status,
  });
}
