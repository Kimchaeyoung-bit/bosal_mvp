import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bosal.dart';
import '../data/mock/mock_bosals.dart';
import 'region_provider.dart';
import 'category_provider.dart';

final allBosalsProvider = Provider<List<Bosal>>((ref) => mockBosals);

final filteredBosalsProvider = Provider<List<Bosal>>((ref) {
  final bosals = ref.watch(allBosalsProvider);
  final selectedRegions = ref.watch(selectedSubRegionsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  var filtered = bosals;

  if (selectedRegions.isNotEmpty) {
    final regionIds = selectedRegions.map((r) => r.id).toSet();
    filtered = filtered
        .where((b) => b.subRegionIds.any((id) => regionIds.contains(id)))
        .toList();
  }

  if (selectedCategory != null && selectedCategory.id != 'all') {
    filtered = filtered
        .where((b) => b.categoryIds.contains(selectedCategory.id))
        .toList();
  }

  return filtered;
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
      .toList();
});
