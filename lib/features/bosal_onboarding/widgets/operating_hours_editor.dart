import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/operating_hours.dart';

/// 요일별 운영 시간 에디터.
///
/// 7개 요일을 스위치 + 시간 선택(opens_at / closes_at)으로 노출한다.
/// 휴무일: 스위치 off → opens/closes null.
/// 상태는 [onChanged]로 상위에 전달하고, 이 위젯은 렌더링만 담당하므로
/// 상위에서 일관된 단일 source-of-truth를 유지하기 쉽다.
class OperatingHoursEditor extends StatefulWidget {
  final List<OperatingHours> value;
  final ValueChanged<List<OperatingHours>> onChanged;

  const OperatingHoursEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<OperatingHoursEditor> createState() => _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends State<OperatingHoursEditor> {
  // 0=Sun, 1=Mon, ..., 6=Sat. UI 순서는 월부터.
  static const _uiOrder = [1, 2, 3, 4, 5, 6, 0];
  static const _labels = {
    0: '일요일',
    1: '월요일',
    2: '화요일',
    3: '수요일',
    4: '목요일',
    5: '금요일',
    6: '토요일',
  };

  late List<OperatingHours> _hours; // 7개, weekday 0..6

  @override
  void initState() {
    super.initState();
    _hours = _normalize(widget.value);
  }

  @override
  void didUpdateWidget(covariant OperatingHoursEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSame(oldWidget.value, widget.value)) {
      _hours = _normalize(widget.value);
    }
  }

  List<OperatingHours> _normalize(List<OperatingHours> input) {
    final map = {for (final h in input) h.weekday: h};
    return List.generate(
      7,
      (i) => map[i] ?? OperatingHours(weekday: i),
    );
  }

  bool _isSame(List<OperatingHours> a, List<OperatingHours> b) {
    if (a.length != b.length) return false;
    final aMap = {for (final h in a) h.weekday: h};
    final bMap = {for (final h in b) h.weekday: h};
    for (final k in aMap.keys) {
      final x = aMap[k]!;
      final y = bMap[k];
      if (y == null) return false;
      if (x.opensAt != y.opensAt || x.closesAt != y.closesAt) return false;
    }
    return true;
  }

  void _setDay(int weekday, OperatingHours newValue) {
    setState(() {
      _hours = [
        for (final h in _hours) if (h.weekday == weekday) newValue else h
      ];
    });
    widget.onChanged(_hours);
  }

  Future<String?> _pickTime(BuildContext context, {String? initial}) async {
    final parts = initial?.split(':') ?? ['10', '00'];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 10,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      helpText: '시간 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatForDisplay(String? t) {
    if (t == null) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h < 12 ? '오전' : '오후';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period ${h12.toString().padLeft(2, '0')}:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final wd in _uiOrder)
          _DayRow(
            label: _labels[wd]!,
            hours: _hours.firstWhere((h) => h.weekday == wd),
            onToggle: (open) {
              if (open) {
                _setDay(
                  wd,
                  OperatingHours(
                    weekday: wd,
                    opensAt: '10:00:00',
                    closesAt: '22:00:00',
                  ),
                );
              } else {
                _setDay(wd, OperatingHours(weekday: wd));
              }
            },
            onPickOpens: () async {
              final t = await _pickTime(context,
                  initial: _hours.firstWhere((h) => h.weekday == wd).opensAt);
              if (t != null) {
                final cur = _hours.firstWhere((h) => h.weekday == wd);
                _setDay(
                  wd,
                  OperatingHours(
                    weekday: wd,
                    opensAt: t,
                    closesAt: cur.closesAt ?? '22:00:00',
                    breakStart: cur.breakStart,
                    breakEnd: cur.breakEnd,
                    note: cur.note,
                  ),
                );
              }
            },
            onPickCloses: () async {
              final t = await _pickTime(context,
                  initial: _hours.firstWhere((h) => h.weekday == wd).closesAt);
              if (t != null) {
                final cur = _hours.firstWhere((h) => h.weekday == wd);
                _setDay(
                  wd,
                  OperatingHours(
                    weekday: wd,
                    opensAt: cur.opensAt ?? '10:00:00',
                    closesAt: t,
                    breakStart: cur.breakStart,
                    breakEnd: cur.breakEnd,
                    note: cur.note,
                  ),
                );
              }
            },
            formatTime: _formatForDisplay,
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final OperatingHours hours;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpens;
  final VoidCallback onPickCloses;
  final String Function(String?) formatTime;

  const _DayRow({
    required this.label,
    required this.hours,
    required this.onToggle,
    required this.onPickOpens,
    required this.onPickCloses,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = !hours.isClosed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: AppTextStyles.bodyBold),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOpen,
            activeColor: AppColors.primary,
            onChanged: onToggle,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: isOpen
                ? Row(
                    children: [
                      Expanded(
                        child: _TimeButton(
                          label: formatTime(hours.opensAt),
                          onTap: onPickOpens,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('~'),
                      ),
                      Expanded(
                        child: _TimeButton(
                          label: formatTime(hours.closesAt),
                          onTap: onPickCloses,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '휴무',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.small
                        .copyWith(color: AppColors.textSub),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label.isEmpty ? '시간 선택' : label,
          style: AppTextStyles.small.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}
