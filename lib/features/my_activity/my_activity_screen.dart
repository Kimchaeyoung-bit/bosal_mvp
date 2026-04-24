import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/coming_soon_view.dart';
import '../../shared/widgets/login_required_view.dart';

enum MyActivityType { bookings, favorites, recent, reviews }

class MyActivityScreen extends ConsumerWidget {
  final MyActivityType type;

  const MyActivityScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final title = _titleFor(type);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoggedIn
            ? ComingSoonView(message: '$title 기능은 준비 중입니다')
            : const LoginRequiredView(),
      ),
    );
  }

  String _titleFor(MyActivityType type) {
    switch (type) {
      case MyActivityType.bookings:
        return '예약 내역';
      case MyActivityType.favorites:
        return '찜한 보살';
      case MyActivityType.recent:
        return '최근 본 보살';
      case MyActivityType.reviews:
        return '내 후기';
    }
  }
}
