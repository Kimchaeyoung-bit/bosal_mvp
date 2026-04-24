import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_categories.dart';
import '../models/category.dart';

abstract class CategoryDataSource {
  Future<List<Category>> list();
}

class MockCategoryDataSource implements CategoryDataSource {
  @override
  Future<List<Category>> list() async => List<Category>.from(mockCategories);
}

class SupabaseCategoryDataSource implements CategoryDataSource {
  SupabaseCategoryDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Category>> list() async {
    final rows = await _client
        .from('categories')
        .select('code,name,icon_key,sort_order')
        .eq('is_active', true)
        .order('sort_order');
    return rows.cast<Map<String, dynamic>>().map(Category.fromMap).toList();
  }
}
