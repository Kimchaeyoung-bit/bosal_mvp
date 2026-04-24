import 'reservation.dart';

/// UI 호환 레이어. 내부적으로는 [Reservation]으로 마이그레이션됐지만
/// 기존 화면들이 `Booking`/`BookingStatus`를 기대하므로 얇은 뷰 모델로 유지한다.
///
/// 새 화면은 [Reservation]을 직접 사용할 것.
enum BookingStatus { pending, confirmed, completed, cancelled }

BookingStatus _statusFromReservation(ReservationStatus s) {
  switch (s) {
    case ReservationStatus.pending:
      return BookingStatus.pending;
    case ReservationStatus.confirmed:
      return BookingStatus.confirmed;
    case ReservationStatus.completed:
      return BookingStatus.completed;
    case ReservationStatus.cancelled:
    case ReservationStatus.noShow:
      return BookingStatus.cancelled;
  }
}

class Booking {
  final String id;
  final String bosalId;
  final DateTime requestedAt;
  final DateTime? consultDate;
  final String consultType;
  final int price;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.bosalId,
    required this.requestedAt,
    this.consultDate,
    required this.consultType,
    required this.price,
    required this.status,
  });

  factory Booking.fromReservation(Reservation r) {
    String typeLabel;
    switch (r.channel) {
      case ConsultChannel.inPerson:
        typeLabel = '대면 상담';
        break;
      case ConsultChannel.phone:
        typeLabel = '전화 상담';
        break;
      case ConsultChannel.video:
        typeLabel = '화상 상담';
        break;
      case ConsultChannel.chat:
        typeLabel = '채팅 상담';
        break;
    }
    return Booking(
      id: r.id,
      bosalId: r.bosalId,
      requestedAt: r.requestedAt,
      consultDate: r.consultAt,
      consultType: typeLabel,
      price: r.priceAmount,
      status: _statusFromReservation(r.status),
    );
  }
}
