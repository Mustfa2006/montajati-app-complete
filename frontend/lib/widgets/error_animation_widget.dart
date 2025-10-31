import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ❌ أنيميشن الخطا
class ErrorAnimationWidget extends StatelessWidget {
  const ErrorAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Lottie.asset('assets/animations/error_animation.json', repeat: false, fit: BoxFit.contain),
      ),
    );
  }
}
