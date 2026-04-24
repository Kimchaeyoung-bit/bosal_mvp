import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/datasources/admin_data_source.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_source_providers.dart';
import '../../providers/region_provider.dart';

/// 관리자 전용: 보살 초대 코드 생성·조회 화면.
///
/// 진입 경로: `/admin/invites`. 관리자 외에는 안내 메시지와 함께 뒤로.
class AdminInvitesScreen extends ConsumerStatefulWidget {
  const AdminInvitesScreen({super.key});

  @override
  ConsumerState<AdminInvitesScreen> createState() => _AdminInvitesScreenState();
}

class _AdminInvitesScreenState extends ConsumerState<AdminInvitesScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _regionCode;
  String? _subRegionCode;
  int _expiresDays = 30;

  bool _submitting = false;
  BosalInviteResult? _justCreated;
  List<BosalInviteSummary> _invites = const [];
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final list = await ref.read(adminDataSourceProvider).listInvites();
      if (!mounted) return;
      setState(() {
        _invites = list;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingList = false);
    }
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보살 이름을 입력해주세요')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref.read(adminDataSourceProvider).createBosalWithInvite(
            name: _nameCtrl.text.trim(),
            phoneDisplay: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            regionCode: _regionCode,
            subRegionCode: _subRegionCode,
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
            expiresDays: _expiresDays,
          );
      if (!mounted) return;
      setState(() {
        _justCreated = result;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
      });
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('생성 실패: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('관리자 초대 코드')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '관리자만 접근 가능합니다.',
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
        ),
      );
    }

    final regions = ref.watch(regionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('관리자 · 초대 코드'),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            title: '새 초대 코드 발급',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('보살 이름 *'),
                _text(_nameCtrl, hint: '예: 김보살'),
                const SizedBox(height: 12),
                _label('연락처 (선택)'),
                _text(_phoneCtrl,
                    hint: '010-1234-5678', keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _label('초대받을 이메일 (선택, 메모용)'),
                _text(_emailCtrl,
                    hint: 'bosal@example.com',
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _label('서비스 지역'),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        value: _regionCode,
                        hint: '시·도',
                        items: regions.map((r) => (r.id, r.name)).toList(),
                        onChanged: (v) => setState(() {
                          _regionCode = v;
                          _subRegionCode = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dropdown(
                        value: _subRegionCode,
                        hint: '세부 지역',
                        items: () {
                          final r = regions.where((r) => r.id == _regionCode).toList();
                          if (r.isEmpty) return <(String, String)>[];
                          return (r.first.subRegions as List)
                              .map((s) => (s.id as String, s.name as String))
                              .toList(growable: false);
                        }(),
                        onChanged: (v) => setState(() => _subRegionCode = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _label('유효 기간 (일)'),
                Slider(
                  value: _expiresDays.toDouble(),
                  min: 1,
                  max: 90,
                  divisions: 89,
                  label: '$_expiresDays일',
                  onChanged: (v) => setState(() => _expiresDays = v.round()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : const Text(
                            '보살 레코드 + 초대 코드 생성',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_justCreated != null) ...[
            const SizedBox(height: 16),
            _card(
              title: '생성 완료',
              titleColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('보살 ID',
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.textSub, fontSize: 12)),
                  SelectableText(_justCreated!.bosalId,
                      style: AppTextStyles.body),
                  const SizedBox(height: 12),
                  Text('초대 코드 (보살에게 전달)',
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.textSub, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SelectableText(
                            _justCreated!.inviteCode,
                            style: AppTextStyles.largeName.copyWith(
                                fontSize: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _justCreated!.inviteCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('복사됨')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _card(
            title: '발급 이력',
            child: _loadingList
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _invites.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('발급된 코드가 없습니다',
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textSub)),
                      )
                    : Column(
                        children: [
                          for (final i in _invites) _InviteRow(invite: i),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    Color? titleColor,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: AppTextStyles.largeName
                    .copyWith(fontSize: 16, color: titleColor)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
      );

  Widget _text(
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSub),
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<(String, String)> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          hint: Text(hint,
              style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
          items: [
            const DropdownMenuItem(value: null, child: Text('선택 안 함')),
            ...items.map(
              (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
            ),
          ],
          onChanged: onChanged,
        ),
      );
}

class _InviteRow extends StatelessWidget {
  final BosalInviteSummary invite;
  const _InviteRow({required this.invite});

  Color get _statusColor {
    switch (invite.status) {
      case 'used':
        return AppColors.textSub;
      case 'expired':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (invite.status) {
      case 'used':
        return '사용됨';
      case 'expired':
        return '만료';
      default:
        return '유효';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        invite.code,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  invite.bosalName ?? invite.bosalId ?? '—',
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invite.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복사됨')),
              );
            },
          ),
        ],
      ),
    );
  }
}
