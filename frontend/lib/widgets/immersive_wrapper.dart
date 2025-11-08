import 'package:flutter/material.dart';

import '../services/immersive_mode_service.dart';

/// 🔥 Widget مخصص للنمط الغامر مع دعم السحب من الأسفل
class ImmersiveWrapper extends StatefulWidget {
  final Widget child;

  const ImmersiveWrapper({super.key, required this.child});

  @override
  State<ImmersiveWrapper> createState() => _ImmersiveWrapperState();
}

class _ImmersiveWrapperState extends State<ImmersiveWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // إخفاء Navigation Bar فقط عند بدء التشغيل - Status Bar يبقى ثابت
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImmersiveModeService.enableImmersiveMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ImmersiveModeService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // إخفاء Navigation Bar فقط عند العودة للتطبيق - Status Bar يبقى ثابت
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        ImmersiveModeService.enableImmersiveMode();
      });
    }
  }

  /// 🎯 التعامل مع السحب من الأسفل
  void _handleBottomSwipe() {
    ImmersiveModeService.showNavigationBarTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // التقاط السحب من الأسفل
      onPanStart: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        final startY = details.globalPosition.dy;

        // إذا بدأ السحب من أسفل 20px من الشاشة (منطقة أصغر)
        if (startY >= screenHeight - 20) {
          _handleBottomSwipe();
        }
      },

      // التقاط السحب للأعلى من الأسفل
      onPanUpdate: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        final currentY = details.globalPosition.dy;

        // إذا كان السحب من الأسفل للأعلى
        if (currentY >= screenHeight - 50 && details.delta.dy < -5) {
          _handleBottomSwipe();
        }
      },

      // التقاط النقر المزدوج في المنطقة السفلية
      onDoubleTapDown: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        final tapY = details.globalPosition.dy;

        // إذا تم النقر المزدوج في أسفل 15px من الشاشة
        if (tapY >= screenHeight - 15) {
          _handleBottomSwipe();
        }
      },

      child: widget.child,
    );
  }
}
