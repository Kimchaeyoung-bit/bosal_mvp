/// 보살 운영 시간 (요일별 1 row).
///
/// DB 스키마: [supabase/migrations/20260424000300_bosals.sql]의 `operating_hours` 테이블.
/// - weekday: 0=Sun, 1=Mon, ..., 6=Sat (Postgres `extract(dow from ...)` 호환)
/// - opens_at/closes_at: null이면 휴무일. closes_at < opens_at이면 익일 영업(야간).
/// - break_start/break_end: 선택. 둘 다 있거나 둘 다 없어야 함.
class OperatingHours {
  final int weekday;
  final String? opensAt;       // 'HH:mm' 또는 'HH:mm:ss'
  final String? closesAt;
  final String? breakStart;
  final String? breakEnd;
  final String? note;

  const OperatingHours({
    required this.weekday,
    this.opensAt,
    this.closesAt,
    this.breakStart,
    this.breakEnd,
    this.note,
  });

  bool get isClosed => opensAt == null || closesAt == null;

  factory OperatingHours.fromMap(Map<String, dynamic> m) => OperatingHours(
        weekday: (m['weekday'] as num).toInt(),
        opensAt: m['opens_at'] as String?,
        closesAt: m['closes_at'] as String?,
        breakStart: m['break_start'] as String?,
        breakEnd: m['break_end'] as String?,
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap({required String bosalId}) => {
        'bosal_id': bosalId,
        'weekday': weekday,
        'opens_at': opensAt,
        'closes_at': closesAt,
        'break_start': breakStart,
        'break_end': breakEnd,
        'note': note,
      };
}
