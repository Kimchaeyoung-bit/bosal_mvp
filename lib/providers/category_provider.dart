import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/mock/mock_categories.dart';

final categoriesProvider = Provider<List<Category>>((ref) => mockCategories);

final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
