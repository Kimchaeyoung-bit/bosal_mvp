import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class GangnamBosalApp extends StatelessWidget {
  const GangnamBosalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '강남보살',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
