import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking.dart';

final mockBookings = [
  Booking(
    id: 'b1',
    bosalId: '1',
    requestedAt: DateTime(2026, 4, 10, 14, 30),
    consultDate: DateTime(2026, 4, 15, 14, 0),
    consultType: '대면 상담',
    price: 40000,
    status: BookingStatus.confirmed,
  ),
  Booking(
    id: 'b2',
    bosalId: '2',
    requestedAt: DateTime(2026, 4, 11, 10, 0),
    consultDate: DateTime(2026, 4, 18, 11, 0),
    consultType: '대면 상담',
    price: 35000,
    status: BookingStatus.pending,
  ),
  Booking(
    id: 'b3',
    bosalId: '4',
    requestedAt: DateTime(2026, 3, 20, 9, 0),
    consultDate: DateTime(2026, 3, 25, 15, 0),
    consultType: '대면 상담',
    price: 45000,
    status: BookingStatus.completed,
  ),
  Booking(
    id: 'b4',
    bosalId: '5',
    requestedAt: DateTime(2026, 3, 1, 13, 0),
    consultDate: DateTime(2026, 3, 5, 13, 0),
    consultType: '대면 상담',
    price: 38000,
    status: BookingStatus.cancelled,
  ),
];

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>(
  (ref) => BookingsNotifier(),
);

class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier() : super(mockBookings);

  void add({
    required String bosalId,
    required DateTime consultDate,
    required String consultType,
    required int price,
  }) {
    final newId = 'b${DateTime.now().millisecondsSinceEpoch}';
    state = [
      Booking(
        id: newId,
        bosalId: bosalId,
        requestedAt: DateTime.now(),
        consultDate: consultDate,
        consultType: consultType,
        price: price,
        status: BookingStatus.pending,
      ),
      ...state,
    ];
  }

  void confirm(String bookingId) => _updateStatus(bookingId, BookingStatus.confirmed);
  void complete(String bookingId) => _updateStatus(bookingId, BookingStatus.completed);
  void reject(String bookingId) => _updateStatus(bookingId, BookingStatus.cancelled);

  void _updateStatus(String bookingId, BookingStatus newStatus) {
    state = state.map((b) {
      if (b.id == bookingId) {
        return Booking(
          id: b.id,
          bosalId: b.bosalId,
          requestedAt: b.requestedAt,
          consultDate: b.consultDate,
          consultType: b.consultType,
          price: b.price,
          status: newStatus,
        );
      }
      return b;
    }).toList();
  }

  void cancel(String bookingId) => _updateStatus(bookingId, BookingStatus.cancelled);
}
