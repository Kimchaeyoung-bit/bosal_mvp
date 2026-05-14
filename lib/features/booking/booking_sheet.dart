import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bosal.dart';
import '../../providers/booking_provider.dart';

// 시간대 옵션
class _TimeSlot {
  final String label;
  final int hour;
  final int minute;
  _TimeSlot(this.label, this.hour, this.minute);
}

final _timeSlots = [
  _TimeSlot('오전 10:00', 10, 0),
  _TimeSlot('오후 1:00', 13, 0),
  _TimeSlot('오후 3:00', 15, 0),
  _TimeSlot('오후 5:30', 17, 30),
  _TimeSlot('오후 8:00', 20, 0),
];

void showBookingSheet(BuildContext context, Bosal bosal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(bosal: bosal),
  );
}

class _BookingSheet extends ConsumerStatefulWidget {
  final Bosal bosal;
  const _BookingSheet({required this.bosal});

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  _TimeSlot? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('예약 일시', style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 월 네비게이션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.text),
                ),
                Text(
                  '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.text),
                ),
              ],
            ),
          ),

          // 캘린더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _Calendar(
              focusedMonth: _focusedMonth,
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedSlot = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 구분선
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // 시간대 칩
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  final isDisabled = _selectedDate == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () => setState(() => _selectedSlot = slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isDisabled
                                  ? AppColors.bg
                                  : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          slot.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : isDisabled
                                    ? AppColors.textSub
                                    : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 담기 버튼
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedDate != null && _selectedSlot != null)
                    ? () => _confirm()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppTextStyles.bodyBold
                      .copyWith(fontSize: 16),
                ),
                child: Text(
                  (_selectedDate != null && _selectedSlot != null)
                      ? '${_formatDateShort(_selectedDate!)} ${_selectedSlot!.label} 예약하기'
                      : '날짜와 시간을 선택해주세요',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: (_selectedDate != null && _selectedSlot != null)
                        ? AppColors.white
                        : AppColors.textSub,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final consultDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedSlot!.hour,
      _selectedSlot!.minute,
    );

    ref.read(bookingsProvider.notifier).add(
          bosalId: widget.bosal.id,
          consultDate: consultDate,
          consultType: '대면 상담',
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${widget.bosal.name} · ${_formatDateShort(consultDate)} ${_selectedSlot!.label} 예약 완료!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    const weeks = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}/${date.day}(${weeks[date.weekday - 1]})';
  }
}

// ─── 캘린더 위젯 ─────────────────────────────────────────────────────────────

class _Calendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const _Calendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월...

    const dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: dayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: AppTextStyles.caption.copyWith(
                        color: d == '일'
                            ? const Color(0xFFE74C3C)
                            : d == '토'
                                ? const Color(0xFF3498DB)
                                : AppColors.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, index) {
            if (index < startWeekday) return const SizedBox.shrink();

            final day = index - startWeekday + 1;
            final date =
                DateTime(focusedMonth.year, focusedMonth.month, day);
            final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected = selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
            final isSunday = date.weekday == 7;
            final isSaturday = date.weekday == 6;

            return GestureDetector(
              onTap: isPast ? null : () => onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primarySoft
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.body.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : isPast
                              ? AppColors.border
                              : isToday
                                  ? AppColors.primary
                                  : isSunday
                                      ? const Color(0xFFE74C3C)
                                      : isSaturday
                                          ? const Color(0xFF3498DB)
                                          : AppColors.text,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
