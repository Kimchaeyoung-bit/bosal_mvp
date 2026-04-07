import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/region.dart';
import '../data/mock/mock_regions.dart';

final regionsProvider = Provider<List<Region>>((ref) => mockRegions);

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
