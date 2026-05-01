import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'data_source_providers.dart';

/// 현재 사용자의 찜 bosal 코드 집합 (Realtime 스트림).
///
/// 로그인하지 않았으면 빈 Set 스트림을 즉시 방출.
final favoritesStreamProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authProvider);
  final ds = ref.watch(favoriteDataSourceProvider);
  if (user == null) return Stream.value(const <String>{});
  return ds.watch(user.id);
});

/// UI 편의: AsyncValue을 unwrap해 동기 Set 반환 (로딩 시 빈 Set).
final favoritesProvider = Provider<Set<String>>((ref) {
  return ref.watch(favoritesStreamProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <String>{},
      );
});

/// 찜 토글 액션.
final favoriteToggleProvider = Provider<Future<void> Function(String)>((ref) {
  return (String bosalId) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final ds = ref.read(favoriteDataSourceProvider);
    final current = ref.read(favoritesProvider);
    if (current.contains(bosalId)) {
      await ds.remove(userId: user.id, bosalId: bosalId);
    } else {
      await ds.add(userId: user.id, bosalId: bosalId);
    }
  };
});
