import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_real.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      opacity: const AlwaysStoppedAnimation(0.9),
    );
  }
}
