import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/bosal_data_source.dart';
import '../data/models/bosal.dart';
import 'category_provider.dart';
import 'data_source_providers.dart';
import 'region_provider.dart';
import 'search_provider.dart';

/// 비동기 소스 — DB에서 로드. 로딩·에러 상태가 필요한 화면에서 사용.
final allBosalsAsyncProvider = FutureProvider<List<Bosal>>((ref) async {
  return ref.watch(bosalDataSourceProvider).list();
});

/// UI 호환 sync provider. async 미해석 시 빈 리스트 반환.
final allBosalsProvider = Provider<List<Bosal>>((ref) {
  return ref.watch(allBosalsAsyncProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <Bosal>[],
      );
});

/// 지역/카테고리/검색어 필터 적용본.
///
/// 참고: 서버 필터링으로 내려보낼 수도 있으나 현재는 총 레코드 수가 작고
/// 카테고리·지역·검색어가 UI에서 자주 토글되므로 client-side 필터가 UX상 유리.
/// 레코드 수가 수천 이상으로 커지면 [SupabaseBosalDataSource]에 filter를 넘기는
/// 쪽으로 마이그레이션할 것.
final filteredBosalsProvider = Provider<List<Bosal>>((ref) {
  final bosals = ref.watch(allBosalsProvider);
  final selectedRegions = ref.watch(selectedSubRegionsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  var filtered = bosals;

  if (selectedRegions.isNotEmpty) {
    final regionIds = selectedRegions.map((r) => r.id).toSet();
    filtered = filtered
        .where((b) => b.subRegionIds.any(regionIds.contains))
        .toList(growable: false);
  }

  if (selectedCategory != null && selectedCategory.id != 'all') {
    filtered = filtered
        .where((b) => b.categoryIds.contains(selectedCategory.id))
        .toList(growable: false);
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((b) {
      if (b.name.toLowerCase().contains(query)) return true;
      if (b.consultStyle.toLowerCase().contains(query)) return true;
      if ((b.description ?? '').toLowerCase().contains(query)) return true;
      if ((b.oneLiner ?? '').toLowerCase().contains(query)) return true;
      if (b.features.any((f) => f.toLowerCase().contains(query))) return true;
      return false;
    }).toList(growable: false);
  }

  return filtered;
});

/// 단일 bosal 상세.
final bosalByIdProvider =
    FutureProvider.family.autoDispose<Bosal?, String>((ref, id) async {
  return ref.watch(bosalDataSourceProvider).byId(id);
});

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<String>>(
  (ref) => RecentlyViewedNotifier(),
);

class RecentlyViewedNotifier extends StateNotifier<List<String>> {
  RecentlyViewedNotifier() : super([]);

  void add(String bosalId) {
    state = [bosalId, ...state.where((id) => id != bosalId)].take(10).toList();
  }
}

final recentlyViewedBosalsProvider = Provider<List<Bosal>>((ref) {
  final ids = ref.watch(recentlyViewedProvider);
  final bosals = ref.watch(allBosalsProvider);
  return ids
      .map((id) => bosals.where((b) => b.id == id).firstOrNull)
      .whereType<Bosal>()
      .toList(growable: false);
});
