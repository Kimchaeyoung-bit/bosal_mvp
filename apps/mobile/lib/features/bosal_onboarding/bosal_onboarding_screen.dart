import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bosal.dart';
import '../../data/models/operating_hours.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/data_source_providers.dart';
import '../../providers/region_provider.dart';
import 'widgets/operating_hours_editor.dart';

/// 보살 온보딩·프로필 편집 화면.
///
/// 초대 코드로 role=bosal 승격된 직후 자동 진입한다. `profiles.bosal_id`로
/// 연결된 [bosals] 레코드의 프로필 필드를 작성하고, 완료 시 `is_published=true`
/// 로 공개 전환.
class BosalOnboardingScreen extends ConsumerStatefulWidget {
  const BosalOnboardingScreen({super.key});

  @override
  ConsumerState<BosalOnboardingScreen> createState() =>
      _BosalOnboardingScreenState();
}

class _BosalOnboardingScreenState extends ConsumerState<BosalOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _oneLinerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sidoCtrl = TextEditingController();
  final _sigunguCtrl = TextEditingController();
  final _eupmyeondongCtrl = TextEditingController();
  final _roadAddressCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _discountedPriceCtrl = TextEditingController();
  final _firstVisitPriceCtrl = TextEditingController();
  final _maxPointsCtrl = TextEditingController();

  final List<TextEditingController> _featureCtrls = [];

  String? _consultStyleCode;
  String? _regionCode;
  String? _subRegionCode;
  final Set<String> _selectedCategoryCodes = {};
  List<OperatingHours> _hours = List.generate(
    7,
    (i) => OperatingHours(
      weekday: i,
      opensAt: (i == 0) ? null : '10:00:00',
      closesAt: (i == 0) ? null : '22:00:00',
    ),
  );

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _bosalId;

  @override
  void initState() {
    super.initState();
    _featureCtrls.addAll([TextEditingController(), TextEditingController()]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oneLinerCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    _sidoCtrl.dispose();
    _sigunguCtrl.dispose();
    _eupmyeondongCtrl.dispose();
    _roadAddressCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _originalPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _firstVisitPriceCtrl.dispose();
    _maxPointsCtrl.dispose();
    for (final c in _featureCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hydrate() async {
    final user = ref.read(authProvider);
    final bid = user?.bosalId;
    if (bid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '보살 계정이 아닙니다. 관리자에게 초대 코드를 요청하세요.';
      });
      return;
    }
    _bosalId = bid;
    final Bosal? bosal = await ref.read(bosalDataSourceProvider).byId(bid);
    if (!mounted) return;
    if (bosal == null) {
      setState(() {
        _loading = false;
        _error = '보살 프로필을 찾을 수 없습니다.';
      });
      return;
    }

    _nameCtrl.text = bosal.name;
    _oneLinerCtrl.text = bosal.oneLiner ?? '';
    _descriptionCtrl.text = bosal.description ?? '';
    _phoneCtrl.text = bosal.phoneNumber ?? '';
    _sidoCtrl.text = bosal.sido ?? '';
    _sigunguCtrl.text = bosal.sigungu ?? '';
    _eupmyeondongCtrl.text = bosal.eupmyeondong ?? '';
    _roadAddressCtrl.text = bosal.roadAddress ?? '';
    _experienceYearsCtrl.text = bosal.experienceYears.toString();
    _originalPriceCtrl.text = bosal.originalPrice == 0 ? '' : bosal.originalPrice.toString();
    _discountedPriceCtrl.text =
        bosal.discountedPrice == 0 ? '' : bosal.discountedPrice.toString();
    _firstVisitPriceCtrl.text =
        bosal.firstVisitPrice == 0 ? '' : bosal.firstVisitPrice.toString();
    _maxPointsCtrl.text = bosal.maxPoints == 0 ? '' : bosal.maxPoints.toString();
    _consultStyleCode = bosal.consultStyleCode;
    _regionCode = bosal.regionId.isEmpty ? null : bosal.regionId;
    _subRegionCode = bosal.subRegionIds.isEmpty ? null : bosal.subRegionIds.first;
    _selectedCategoryCodes
      ..clear()
      ..addAll(bosal.categoryIds);
    if (bosal.features.isNotEmpty) {
      _featureCtrls.clear();
      for (final f in bosal.features) {
        _featureCtrls.add(TextEditingController(text: f));
      }
    }
    if (bosal.operatingHours.isNotEmpty) {
      _hours = bosal.operatingHours;
    }
    setState(() => _loading = false);
  }

  int? _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  String? _toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('0')) return '+82${digits.substring(1)}';
    if (digits.startsWith('82')) return '+$digits';
    return '+$digits';
  }

  Future<void> _save({required bool publish}) async {
    final bid = _bosalId;
    if (bid == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '이름은 필수입니다');
      return;
    }
    if (_selectedCategoryCodes.isEmpty ||
        _selectedCategoryCodes.every((c) => c == 'all')) {
      setState(() => _error = '카테고리를 하나 이상 선택해주세요');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ds = ref.read(bosalDataSourceProvider);

      await ds.updateOwnerFields(
        bosalId: bid,
        name: _nameCtrl.text.trim(),
        oneLiner: _oneLinerCtrl.text.trim().isEmpty
            ? null
            : _oneLinerCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        experienceYears: _parseInt(_experienceYearsCtrl.text) ?? 0,
        consultStyleCode: _consultStyleCode,
        phoneDisplay:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        phoneE164: _toE164(_phoneCtrl.text),
        originalPrice: _parseInt(_originalPriceCtrl.text),
        discountedPrice: _parseInt(_discountedPriceCtrl.text),
        firstVisitPrice: _parseInt(_firstVisitPriceCtrl.text),
        maxPoints: _parseInt(_maxPointsCtrl.text),
        sido: _sidoCtrl.text.trim().isEmpty ? null : _sidoCtrl.text.trim(),
        sigungu:
            _sigunguCtrl.text.trim().isEmpty ? null : _sigunguCtrl.text.trim(),
        eupmyeondong: _eupmyeondongCtrl.text.trim().isEmpty
            ? null
            : _eupmyeondongCtrl.text.trim(),
        roadAddress: _roadAddressCtrl.text.trim().isEmpty
            ? null
            : _roadAddressCtrl.text.trim(),
        regionCode: _regionCode,
        subRegionCode: _subRegionCode,
      );

      final features = _featureCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ds.replaceFeatures(bid, features);

      final cats = _selectedCategoryCodes
          .where((c) => c != 'all')
          .toList(growable: false);
      await ds.replaceCategories(bid, cats);

      await ds.replaceOperatingHours(bid, _hours);

      if (publish) {
        await ds.publish(bid, true);
      }

      // refresh list cache
      ref.invalidate(allBosalsAsyncProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(publish ? '프로필을 공개했어요' : '변경 사항을 저장했어요')),
      );
      if (publish) {
        context.go('/bosal-home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    final regions = ref.watch(regionsProvider);

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? 8 : 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      '보살 프로필 설정',
                      style:
                          AppTextStyles.largeName.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _section('기본 정보', [
                    _label('보살 이름 *'),
                    _text(_nameCtrl, hint: '예: 가가 보살'),
                    const SizedBox(height: 12),
                    _label('줄 소개'),
                    _text(_oneLinerCtrl, hint: '한 줄로 나를 소개해보세요'),
                    const SizedBox(height: 12),
                    _label('상세 소개'),
                    _text(_descriptionCtrl, hint: '이력·전문 분야·상담 스타일을 소개', maxLines: 4),
                    const SizedBox(height: 12),
                    _label('경력 (년)'),
                    _text(
                      _experienceYearsCtrl,
                      hint: '예: 10',
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    _label('상담 스타일'),
                    _consultStyleDropdown(),
                  ]),
                  _section('연락처', [
                    _label('전화번호'),
                    _text(
                      _phoneCtrl,
                      hint: '010-1234-5678',
                      keyboard: TextInputType.phone,
                    ),
                  ]),
                  _section('주소', [
                    _label('시/도'),
                    _text(_sidoCtrl, hint: '예: 서울특별시'),
                    const SizedBox(height: 12),
                    _label('시/군/구'),
                    _text(_sigunguCtrl, hint: '예: 강남구'),
                    const SizedBox(height: 12),
                    _label('읍/면/동'),
                    _text(_eupmyeondongCtrl, hint: '예: 역삼동'),
                    const SizedBox(height: 12),
                    _label('도로명 주소'),
                    _text(_roadAddressCtrl, hint: '상세 주소'),
                    const SizedBox(height: 12),
                    _label('서비스 지역'),
                    _regionDropdowns(regions),
                  ]),
                  _section('카테고리 (복수 선택)', [
                    categoriesAsync.isEmpty
                        ? Text('카테고리를 불러오는 중…',
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textSub))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categoriesAsync
                                .where((c) => c.id != 'all')
                                .map((c) {
                              final selected =
                                  _selectedCategoryCodes.contains(c.id);
                              return ChoiceChip(
                                label: Text(c.name),
                                selected: selected,
                                selectedColor: AppColors.primarySoft,
                                labelStyle: AppTextStyles.small.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.text,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side:
                                      const BorderSide(color: AppColors.border),
                                ),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedCategoryCodes.add(c.id);
                                    } else {
                                      _selectedCategoryCodes.remove(c.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ]),
                  _section('특징 (키워드)', [
                    for (var i = 0; i < _featureCtrls.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _text(
                              _featureCtrls[i],
                              hint: '예: 연애 상담 전문',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.textSub),
                            onPressed: _featureCtrls.length <= 1
                                ? null
                                : () => setState(() {
                                      _featureCtrls.removeAt(i).dispose();
                                    }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('특징 추가'),
                        onPressed: _featureCtrls.length >= 6
                            ? null
                            : () => setState(() {
                                  _featureCtrls.add(TextEditingController());
                                }),
                      ),
                    ),
                  ]),
                  _section('상담료 (KRW)', [
                    _label('정가'),
                    _text(
                      _originalPriceCtrl,
                      hint: '예: 80000',
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    _label('할인가'),
                    _text(
                      _discountedPriceCtrl,
                      hint: '예: 55000',
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    _label('첫 방문 상담료'),
                    _text(
                      _firstVisitPriceCtrl,
                      hint: '예: 40000',
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    _label('최대 적립 포인트'),
                    _text(
                      _maxPointsCtrl,
                      hint: '예: 16000',
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ]),
                  _section('운영 요일·시간', [
                    OperatingHoursEditor(
                      value: _hours,
                      onChanged: (v) => _hours = v,
                    ),
                  ]),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.small
                                  .copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _save(publish: false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('저장만'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _save(publish: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                '저장하고 공개',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(title, style: AppTextStyles.largeName.copyWith(fontSize: 16)),
            ),
            ...children,
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
    int maxLines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSub),
          filled: true,
          fillColor: AppColors.surface,
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

  Widget _consultStyleDropdown() {
    const options = {
      'cool': '냉철형',
      'empathetic': '공감형',
      'direct': '직설형',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String?>(
        value: _consultStyleCode,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text('스타일 선택',
            style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
        items: [
          const DropdownMenuItem(value: null, child: Text('선택 안 함')),
          ...options.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              )),
        ],
        onChanged: (v) => setState(() => _consultStyleCode = v),
      ),
    );
  }

  Widget _regionDropdowns(List<dynamic> regions) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String?>(
              value: _regionCode,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text('시·도',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textSub)),
              items: [
                const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                ...regions.map((r) => DropdownMenuItem(
                      value: r.id as String,
                      child: Text(r.name as String),
                    )),
              ],
              onChanged: (v) => setState(() {
                _regionCode = v;
                _subRegionCode = null;
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String?>(
              value: _subRegionCode,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text('세부 지역',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textSub)),
              items: [
                const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                ...() {
                  final matched = regions
                      .where((r) => r.id == _regionCode)
                      .cast<dynamic>()
                      .toList();
                  if (matched.isEmpty) return <DropdownMenuItem<String?>>[];
                  final subs = matched.first.subRegions as List;
                  return subs.map<DropdownMenuItem<String?>>(
                    (s) => DropdownMenuItem(
                      value: s.id as String,
                      child: Text(s.name as String),
                    ),
                  );
                }(),
              ],
              onChanged: (v) => setState(() => _subRegionCode = v),
            ),
          ),
        ),
      ],
    );
  }
}
