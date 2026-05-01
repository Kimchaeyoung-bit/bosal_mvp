import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/region.dart';
import 'data_source_providers.dart';

final regionsAsyncProvider = FutureProvider<List<Region>>((ref) async {
  return ref.watch(regionDataSourceProvider).list();
});

final regionsProvider = Provider<List<Region>>((ref) {
  return ref.watch(regionsAsyncProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <Region>[],
      );
});

final selectedSubRegionsProvider =
    StateNotifierProvider<SelectedSubRegionsNotifier, List<SubRegion>>(
  (ref) => SelectedSubRegionsNotifier(),
);

class SelectedSubRegionsNotifier extends StateNotifier<List<SubRegion>> {
  SelectedSubRegionsNotifier() : super([]);

  void toggle(SubRegion subRegion) {
    if (state.any((s) => s.id == subRegion.id)) {
      state = state.where((s) => s.id != subRegion.id).toList();
    } else {
      state = [...state, subRegion];
    }
  }

  void remove(SubRegion subRegion) {
    state = state.where((s) => s.id != subRegion.id).toList();
  }

  void clear() {
    state = [];
  }
}
