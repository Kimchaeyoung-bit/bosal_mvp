import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/bosal_detail/bosal_detail_screen.dart';
import '../../features/bosal_dashboard/bosal_dashboard_screen.dart';
import '../../features/bosal_dashboard/bosal_bookings_screen.dart';
import '../../features/bosal_dashboard/bosal_reviews_screen.dart';
import '../../features/bosal_dashboard/bosal_profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/bosal_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
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
        child: const RegionSelectionScreen(),
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
  ],
);
