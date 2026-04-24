import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FavoriteDataSource {
  Future<Set<String>> listForUser(String userId);
  Future<void> add({required String userId, required String bosalId});
  Future<void> remove({required String userId, required String bosalId});
  Stream<Set<String>> watch(String userId);
}

class MockFavoriteDataSource implements FavoriteDataSource {
  final Map<String, Set<String>> _store = {};

  @override
  Future<Set<String>> listForUser(String userId) async =>
      Set.of(_store[userId] ?? const {});

  @override
  Future<void> add({required String userId, required String bosalId}) async {
    (_store[userId] ??= <String>{}).add(bosalId);
  }

  @override
  Future<void> remove({required String userId, required String bosalId}) async {
    _store[userId]?.remove(bosalId);
  }

  @override
  Stream<Set<String>> watch(String userId) async* {
    yield await listForUser(userId);
  }
}

class SupabaseFavoriteDataSource implements FavoriteDataSource {
  SupabaseFavoriteDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<Set<String>> listForUser(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('bosal_id')
        .eq('user_id', userId);
    return rows.map((r) => r['bosal_id'] as String).toSet();
  }

  @override
  Future<void> add({required String userId, required String bosalId}) async {
    await _client.from('favorites').upsert({
      'user_id': userId,
      'bosal_id': bosalId,
    }, onConflict: 'user_id,bosal_id');
  }

  @override
  Future<void> remove({required String userId, required String bosalId}) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('bosal_id', bosalId);
  }

  @override
  Stream<Set<String>> watch(String userId) {
    return _client
        .from('favorites')
        .stream(primaryKey: ['user_id', 'bosal_id'])
        .eq('user_id', userId)
        .map((rows) => rows.map((r) => r['bosal_id'] as String).toSet());
  }
}
