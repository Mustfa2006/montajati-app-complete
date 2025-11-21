import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ✨ أنيميشن النجاح مع الكونفيتي
class SuccessAnimationWidget extends StatelessWidget {
  const SuccessAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 350,
        height: 350,
        child: Lottie.asset('assets/animations/success_confetti_new.json', repeat: false, fit: BoxFit.contain),
      ),
    );
  }
}
