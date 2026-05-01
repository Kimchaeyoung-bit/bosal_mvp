import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/datasources/admin_data_source.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_source_providers.dart';
import '../../shared/widgets/app_shadow.dart';

/// 보살별 분석 카운터 시각화 — admin 전용.
///
/// 데이터: `adminDataSourceProvider.listBosalAnalytics()` (`admin_list_bosal_analytics()` RPC).
/// 윈도우: 24h / 7d / 30d 토글. 정렬: call 또는 resv_btn 기준.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

enum _SortKey { call, resv, rating, requests }

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  AnalyticsWindow _window = AnalyticsWindow.h24;
  _SortKey _sortBy = _SortKey.call;

  Future<List<BosalAnalytics>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(adminDataSourceProvider).listBosalAnalytics();
    if (mounted) setState(() {});
  }

  List<BosalAnalytics> _sort(List<BosalAnalytics> rows) {
    final list = List<BosalAnalytics>.from(rows);
    switch (_sortBy) {
      case _SortKey.call:
        list.sort((a, b) => _window.call(b).compareTo(_window.call(a)));
        break;
      case _SortKey.resv:
        list.sort((a, b) => _window.resv(b).compareTo(_window.resv(a)));
        break;
      case _SortKey.rating:
        list.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
        break;
      case _SortKey.requests:
        list.sort(
            (a, b) => b.consultRequestCount.compareTo(a.consultRequestCount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('보살 분석'),
        ),
        body: const Center(child: Text('관리자만 접근 가능합니다.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('보살 분석'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Toolbar(
              window: _window,
              sortBy: _sortBy,
              onWindow: (w) => setState(() => _window = w),
              onSort: (s) => setState(() => _sortBy = s),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: FutureBuilder<List<BosalAnalytics>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrorBody(
                      message: '${snap.error}',
                      onRetry: _reload,
                    );
                  }
                  final rows = snap.data ?? const <BosalAnalytics>[];
                  if (rows.isEmpty) {
                    return const _EmptyBody();
                  }
                  final sorted = _sort(rows);
                  return _SummaryAndList(
                    rows: sorted,
                    window: _window,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AnalyticsWindow window;
  final _SortKey sortBy;
  final ValueChanged<AnalyticsWindow> onWindow;
  final ValueChanged<_SortKey> onSort;

  const _Toolbar({
    required this.window,
    required this.sortBy,
    required this.onWindow,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 토글
          Row(
            children: [
              Text('기간',
                  style: AppTextStyles.smallBold
                      .copyWith(color: AppColors.textSub, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<AnalyticsWindow>(
                  segments: AnalyticsWindow.values
                      .map((w) => ButtonSegment(value: w, label: Text(w.label)))
                      .toList(),
                  selected: {window},
                  onSelectionChanged: (s) => onWindow(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 정렬
          Row(
            children: [
              Text('정렬',
                  style: AppTextStyles.smallBold
                      .copyWith(color: AppColors.textSub, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: '전화탭',
                        selected: sortBy == _SortKey.call,
                        onTap: () => onSort(_SortKey.call),
                      ),
                      const SizedBox(width: 6),
                      _SortChip(
                        label: '예약버튼',
                        selected: sortBy == _SortKey.resv,
                        onTap: () => onSort(_SortKey.resv),
                      ),
                      const SizedBox(width: 6),
                      _SortChip(
                        label: '평점',
                        selected: sortBy == _SortKey.rating,
                        onTap: () => onSort(_SortKey.rating),
                      ),
                      const SizedBox(width: 6),
                      _SortChip(
                        label: '예약수',
                        selected: sortBy == _SortKey.requests,
                        onTap: () => onSort(_SortKey.requests),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: selected ? AppColors.white : AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryAndList extends StatelessWidget {
  final List<BosalAnalytics> rows;
  final AnalyticsWindow window;
  const _SummaryAndList({required this.rows, required this.window});

  @override
  Widget build(BuildContext context) {
    final totalCalls =
        rows.fold<int>(0, (sum, r) => sum + window.call(r));
    final totalResv = rows.fold<int>(0, (sum, r) => sum + window.resv(r));
    final published = rows.where((r) => r.isPublished).length;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: rows.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SummaryCard(
            window: window,
            totalCalls: totalCalls,
            totalResv: totalResv,
            published: published,
            total: rows.length,
          );
        }
        final r = rows[index - 1];
        return _AnalyticsRow(row: r, window: window);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AnalyticsWindow window;
  final int totalCalls;
  final int totalResv;
  final int published;
  final int total;

  const _SummaryCard({
    required this.window,
    required this.totalCalls,
    required this.totalResv,
    required this.published,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${window.label} 요약',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Kpi(label: '전화탭', value: '$totalCalls'),
              _Kpi(label: '예약버튼', value: '$totalResv'),
              _Kpi(label: '공개', value: '$published / $total'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.textSub, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.priceDiscount.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final BosalAnalytics row;
  final AnalyticsWindow window;
  const _AnalyticsRow({required this.row, required this.window});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.bosalName, style: AppTextStyles.cardTitle),
              ),
              if (!row.isPublished)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSub.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      Text('비공개', style: AppTextStyles.tag.copyWith(color: AppColors.textSub)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Cell(label: '전화탭', value: '${window.call(row)}'),
              _Cell(label: '예약버튼', value: '${window.resv(row)}'),
              _Cell(label: '예약요청', value: '${row.consultRequestCount}'),
              _Cell(
                  label: '평점',
                  value:
                      '${row.ratingAvg.toStringAsFixed(1)} (${row.reviewCount})'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '전체  전화 ${row.callTotal}  ·  예약버튼 ${row.resvBtnTotal}',
            style: AppTextStyles.small.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.textSub, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text('데이터가 아직 없어요',
              style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('분석 데이터를 불러오지 못했습니다',
                style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text(message,
                style:
                    AppTextStyles.small.copyWith(color: AppColors.textSub),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
