import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/map_screen.dart' as map_tab;
import '../../features/region_tab/region_tab_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/mypage/mypage_screen.dart';
import '../../features/region/region_selection_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/bosal_list/bosal_list_screen.dart';
import '../../features/bosal_list/other_category_screen.dart';
import '../../features/bosal_detail/bosal_detail_screen.dart';
import '../../features/bosal_dashboard/bosal_dashboard_screen.dart';
import '../../features/bosal_dashboard/bosal_bookings_screen.dart';
import '../../features/bosal_dashboard/bosal_reviews_screen.dart';
import '../../features/bosal_dashboard/bosal_profile_screen.dart';
import '../../features/my_activity/my_activity_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/fortune/fortune_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/bosal_onboarding/bosal_onboarding_screen.dart';
import '../../features/review/review_compose_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/bosal_scaffold.dart';

/// 인증 가드가 적용된 GoRouter.
///
/// `authProvider` 변경 시 자동 재평가되도록 Provider로 노출. `app.dart`에서
/// `ref.watch(appRouterProvider)`로 소비. 화면별 자체 가드는 보조 안전장치로
/// 유지하고 있으니 이 redirect는 가장 바깥쪽 첫 단계 방어선이다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1) 보살 전용 탭(`/bosal-home`, `/bosal-bookings`, `/bosal-reviews`,
      //    `/bosal-profile`)은 role=bosal 만 진입 가능.
      //    `/bosal/:id`는 보살 *상세*라 누구나 OK → 정확히 매칭 분기.
      const bosalOnlyPrefixes = [
        '/bosal-home',
        '/bosal-bookings',
        '/bosal-reviews',
        '/bosal-profile',
      ];
      if (bosalOnlyPrefixes.any(loc.startsWith)) {
        if (user == null) return '/login';
        if (user.role != UserRole.bosal) return '/home';
      }

      // 2) 보살 온보딩은 bosalId 미연결 시 차단 (claim 직후만 진입).
      if (loc == '/bosal-onboarding') {
        if (user == null) return '/login';
        if (user.bosalId == null) return '/home';
      }

      // 3) 인증 필요 라우트: 마이 활동·예약·후기 작성·알림.
      const authRequired = [
        '/my-tab',
        '/my/bookings',
        '/my/favorites',
        '/my/recent',
        '/my/reviews',
        '/booking-tab',
        '/review/compose',
        '/notifications',
      ];
      if (authRequired.any((p) => loc == p || loc.startsWith('$p/')) &&
          user == null) {
        return '/login';
      }

      // 4) 이미 로그인한 사용자가 /login·/signup 으로 가면 홈으로.
      if ((loc == '/login' || loc == '/signup') && user != null) {
        return user.role == UserRole.bosal ? '/bosal-home' : '/home';
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),

    // 사용자 앱
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/region-tab',
              builder: (context, state) => const RegionTabScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/booking-tab',
              builder: (context, state) => const BookingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-tab',
              builder: (context, state) => const MypageScreen(),
            ),
          ],
        ),
      ],
    ),

    // 보살 앱
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BosalScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bosal-home',
              builder: (context, state) => const BosalDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bosal-bookings',
              builder: (context, state) => const BosalBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bosal-reviews',
              builder: (context, state) => const BosalReviewsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bosal-profile',
              builder: (context, state) => const BosalProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // 공용 라우트
    GoRoute(
      path: '/chatbot',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ChatbotScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/region-select',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: RegionSelectionScreen(
          goToMapOnConfirm:
              state.uri.queryParameters['redirect'] == 'map',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/bosal-list',
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['category'];
        return BosalListScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/other-categories',
      builder: (context, state) => const OtherCategoryScreen(),
    ),
    GoRoute(
      path: '/bosal/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BosalDetailScreen(bosalId: id);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const map_tab.MapScreen(),
    ),
    GoRoute(
      path: '/my/bookings',
      builder: (context, state) =>
          const MyActivityScreen(type: MyActivityType.bookings),
    ),
    GoRoute(
      path: '/my/favorites',
      builder: (context, state) =>
          const MyActivityScreen(type: MyActivityType.favorites),
    ),
    GoRoute(
      path: '/my/recent',
      builder: (context, state) =>
          const MyActivityScreen(type: MyActivityType.recent),
    ),
    GoRoute(
      path: '/my/reviews',
      builder: (context, state) =>
          const MyActivityScreen(type: MyActivityType.reviews),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/fortune',
      builder: (context, state) => const FortuneScreen(),
    ),

    // 가입 / 온보딩 / 관리자
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/bosal-onboarding',
      builder: (context, state) => const BosalOnboardingScreen(),
    ),
    GoRoute(
      path: '/review/compose',
      builder: (context, state) {
        final qs = state.uri.queryParameters;
        final bosalId = qs['bosalId'];
        if (bosalId == null || bosalId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('보살 정보가 없습니다')),
          );
        }
        return ReviewComposeScreen(
          bosalId: bosalId,
          reservationId: qs['reservationId'],
          bosalName: qs['bosalName'],
        );
      },
    ),
  ],
  );
});
