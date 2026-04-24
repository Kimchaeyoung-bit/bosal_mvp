import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import 'data_source_providers.dart';

/// 카테고리 async 소스 — DB에서 비동기 로드.
final categoriesAsyncProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryDataSourceProvider).list();
});

/// UI 호환 sync provider. async가 아직 해석되지 않았으면 빈 리스트 반환.
/// 첫 프레임에서 빈 UI로 렌더되다가 async가 도착하면 자동 리빌드.
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesAsyncProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <Category>[],
      );
});

final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
