/// 예약 상태머신. DB enum `reservation_status`와 1:1 대응.
enum ReservationStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow,
}

extension ReservationStatusX on ReservationStatus {
  String get dbValue {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending';
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.completed:
        return 'completed';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.noShow:
        return 'no_show';
    }
  }

  static ReservationStatus fromDb(String s) {
    switch (s) {
      case 'pending':
        return ReservationStatus.pending;
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'no_show':
        return ReservationStatus.noShow;
      default:
        return ReservationStatus.pending;
    }
  }
}

/// 결제 상태 (DB `payment_status`).
enum PaymentStatus { unpaid, authorized, captured, refunded, failed }

extension PaymentStatusX on PaymentStatus {
  String get dbValue => toString().split('.').last;
  static PaymentStatus fromDb(String s) => PaymentStatus.values.firstWhere(
        (v) => v.dbValue == s,
        orElse: () => PaymentStatus.unpaid,
      );
}

/// 상담 채널 (DB `consult_channel`).
enum ConsultChannel { inPerson, phone, video, chat }

extension ConsultChannelX on ConsultChannel {
  String get dbValue {
    switch (this) {
      case ConsultChannel.inPerson:
        return 'in_person';
      case ConsultChannel.phone:
        return 'phone';
      case ConsultChannel.video:
        return 'video';
      case ConsultChannel.chat:
        return 'chat';
    }
  }

  static ConsultChannel fromDb(String s) {
    switch (s) {
      case 'in_person':
        return ConsultChannel.inPerson;
      case 'phone':
        return ConsultChannel.phone;
      case 'video':
        return ConsultChannel.video;
      case 'chat':
        return ConsultChannel.chat;
      default:
        return ConsultChannel.inPerson;
    }
  }
}

/// 예약 레코드. DB `reservations` 테이블과 대응.
class Reservation {
  final String id;
  final String bosalId;
  final String userId;
  final ConsultChannel channel;
  final DateTime requestedAt;
  final DateTime? consultAt;
  final int durationMin;

  final ReservationStatus status;
  final String? cancellationReason;

  final int priceAmount;
  final String priceCurrency;

  final PaymentStatus paymentStatus;
  final String? paymentProvider;
  final String? paymentProviderTxnId;

  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    required this.bosalId,
    required this.userId,
    this.channel = ConsultChannel.inPerson,
    required this.requestedAt,
    this.consultAt,
    this.durationMin = 60,
    this.status = ReservationStatus.pending,
    this.cancellationReason,
    this.priceAmount = 0,
    this.priceCurrency = 'KRW',
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentProvider,
    this.paymentProviderTxnId,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> m) => Reservation(
        id: m['id'] as String,
        bosalId: m['bosal_id'] as String,
        userId: m['user_id'] as String,
        channel: ConsultChannelX.fromDb(m['channel'] as String? ?? 'in_person'),
        requestedAt: DateTime.parse(m['requested_at'] as String),
        consultAt: m['consult_at'] == null
            ? null
            : DateTime.parse(m['consult_at'] as String),
        durationMin: (m['duration_min'] as num?)?.toInt() ?? 60,
        status: ReservationStatusX.fromDb(m['status'] as String? ?? 'pending'),
        cancellationReason: m['cancellation_reason'] as String?,
        priceAmount: (m['price_amount'] as num?)?.toInt() ?? 0,
        priceCurrency: m['price_currency'] as String? ?? 'KRW',
        paymentStatus: PaymentStatusX.fromDb(m['payment_status'] as String? ?? 'unpaid'),
        paymentProvider: m['payment_provider'] as String?,
        paymentProviderTxnId: m['payment_provider_txn_id'] as String?,
        metadata: Map<String, dynamic>.from(m['metadata'] as Map? ?? const {}),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: m['updated_at'] == null
            ? null
            : DateTime.parse(m['updated_at'] as String),
      );

  /// 사용자가 새 예약을 생성할 때 insert payload. 서버가 채워야 하는 필드는 제외.
  Map<String, dynamic> toInsertRow() => {
        'bosal_id': bosalId,
        'user_id': userId,
        'channel': channel.dbValue,
        if (consultAt != null) 'consult_at': consultAt!.toUtc().toIso8601String(),
        'duration_min': durationMin,
        'price_amount': priceAmount,
        'price_currency': priceCurrency,
        'metadata': metadata,
      };
}
