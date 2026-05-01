import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_client.dart';
import '../data/datasources/admin_data_source.dart';
import '../data/datasources/analytics_data_source.dart';
import '../data/datasources/auth_data_source.dart';
import '../data/datasources/banner_ad_data_source.dart';
import '../data/datasources/bosal_data_source.dart';
import '../data/datasources/category_data_source.dart';
import '../data/datasources/favorite_data_source.dart';
import '../data/datasources/notification_data_source.dart';
import '../data/datasources/region_data_source.dart';
import '../data/datasources/reservation_data_source.dart';
import '../data/datasources/review_data_source.dart';

/// `.env`에 설정된 `DATA_SOURCE` 값. 기본값 `supabase`.
enum DataSourceMode { mock, supabase }

DataSourceMode _mode() {
  final v = (dotenv.env['DATA_SOURCE'] ?? 'supabase').toLowerCase();
  return v == 'mock' ? DataSourceMode.mock : DataSourceMode.supabase;
}

final dataSourceModeProvider = Provider<DataSourceMode>((ref) => _mode());

// ------------------------------------------------------------------
// Domain data-source providers
// ------------------------------------------------------------------
final bosalDataSourceProvider = Provider<BosalDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseBosalDataSource(supabase)
      : MockBosalDataSource();
});

final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseCategoryDataSource(supabase)
      : MockCategoryDataSource();
});

final regionDataSourceProvider = Provider<RegionDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseRegionDataSource(supabase)
      : MockRegionDataSource();
});

final reservationDataSourceProvider = Provider<ReservationDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseReservationDataSource(supabase)
      : MockReservationDataSource();
});

final analyticsDataSourceProvider = Provider<AnalyticsDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseAnalyticsDataSource(supabase)
      : MockAnalyticsDataSource();
});

final favoriteDataSourceProvider = Provider<FavoriteDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseFavoriteDataSource(supabase)
      : MockFavoriteDataSource();
});

final bannerAdDataSourceProvider = Provider<BannerAdDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseBannerAdDataSource(supabase)
      : MockBannerAdDataSource();
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseAuthDataSource(supabase)
      : MockAuthDataSource();
});

final adminDataSourceProvider = Provider<AdminDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseAdminDataSource(supabase)
      : MockAdminDataSource();
});

final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseNotificationDataSource(supabase)
      : MockNotificationDataSource();
});

final reviewDataSourceProvider = Provider<ReviewDataSource>((ref) {
  return ref.watch(dataSourceModeProvider) == DataSourceMode.supabase
      ? SupabaseReviewDataSource(supabase)
      : MockReviewDataSource();
});
