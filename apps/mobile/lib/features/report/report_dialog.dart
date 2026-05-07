import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// 신고 대상 종류. DB enum `public.report_target` 와 매칭.
enum ReportTargetKind { review, bosal, user }

extension ReportTargetKindX on ReportTargetKind {
  String get dbValue => toString().split('.').last;
  String get label {
    switch (this) {
      case ReportTargetKind.review:
        return '후기';
      case ReportTargetKind.bosal:
        return '보살';
      case ReportTargetKind.user:
        return '사용자';
    }
  }
}

const _reasonOptions = <String>[
  '욕설·비방·혐오 표현',
  '허위·과장된 정보',
  '음란·선정적인 내용',
  '광고·홍보·스팸',
  '개인정보 노출',
  '기타',
];

/// 신고 다이얼로그. 사유 선택 + 상세 입력 → reports 테이블 insert.
/// 후기 신고 시 백엔드 트리거가 즉시 비공개 처리.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetKind kind,
  required String targetId,
}) async {
  final user = ref.read(authProvider);
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고하려면 로그인이 필요합니다.')),
    );
    return;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(kind: kind, targetId: targetId),
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 처리됩니다.')),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final ReportTargetKind kind;
  final String targetId;
  const _ReportDialog({required this.kind, required this.targetId});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;
  final _detailCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _error = '신고 사유를 선택해주세요');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await supabase.from('reports').insert({
        'reporter_id': supabase.auth.currentUser!.id,
        'target_kind': widget.kind.dbValue,
        'target_id': widget.targetId,
        'reason': _reason,
        'description': _detailCtrl.text.trim().isEmpty
            ? null
            : _detailCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.contains('duplicate')
            ? '이미 신고하셨습니다.'
            : '신고 접수에 실패했습니다.';
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '신고 접수에 실패했습니다.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.kind.label} 신고'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('신고 사유를 선택해주세요',
                style: AppTextStyles.small),
            const SizedBox(height: 8),
            ..._reasonOptions.map(
              (r) => RadioListTile<String>(
                value: r,
                groupValue: _reason,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() {
                          _reason = v;
                          _error = null;
                        }),
                title: Text(r, style: AppTextStyles.body),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              maxLines: 3,
              maxLength: 500,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: '상세 내용 (선택)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.danger,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('신고'),
        ),
      ],
    );
  }
}
