// 🎯 الكرة العائمة الرئيسية والكرات المنبثقة
// Floating Action Ball Widget

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

/// نوع الإجراء للكرات المنبثقة
enum FloatingAction { favorite, camera, gallery }

/// الكرة العائمة الرئيسية
class MainFloatingBall extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onSaveCurrentImage;
  final VoidCallback onSaveAllImages;

  const MainFloatingBall({
    super.key,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onSaveCurrentImage,
    required this.onSaveAllImages,
  });

  @override
  State<MainFloatingBall> createState() => _MainFloatingBallState();
}

class _MainFloatingBallState extends State<MainFloatingBall> {
  bool _showActionBalls = false;
  OverlayEntry? _actionsOverlay;

  final GlobalKey _mainBallKey = GlobalKey();
  final GlobalKey _heartBallKey = GlobalKey();
  final GlobalKey _cameraBallKey = GlobalKey();
  final GlobalKey _galleryBallKey = GlobalKey();

  @override
  void dispose() {
    _removeActionsOverlay();
    super.dispose();
  }

  void _removeActionsOverlay() {
    _actionsOverlay?.remove();
    _actionsOverlay = null;
  }

  void _showActionsOverlay() {
    _removeActionsOverlay();
    _actionsOverlay = OverlayEntry(builder: (context) => _buildOverlayContent());
    Overlay.of(context).insert(_actionsOverlay!);
  }

  Widget _buildOverlayContent() {
    return const SizedBox.shrink();
  }

  void _handleMainBallTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _showActionBalls = !_showActionBalls;
    });
    if (_showActionBalls) {
      _showActionsOverlay();
    } else {
      _removeActionsOverlay();
    }
  }

  void _handleActionTap(FloatingAction action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case FloatingAction.favorite:
        widget.onToggleFavorite();
        break;
      case FloatingAction.camera:
        widget.onSaveCurrentImage();
        break;
      case FloatingAction.gallery:
        widget.onSaveAllImages();
        break;
    }
    setState(() => _showActionBalls = false);
    _removeActionsOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الكرة الرئيسية
        GestureDetector(key: _mainBallKey, onTap: _handleMainBallTap, child: _buildMainBallVisual(isDark)),

        // الكرات المنبثقة
        if (_showActionBalls) ...[
          // كرة القلب
          Positioned(
            top: -60,
            left: -20,
            child: GestureDetector(
              key: _heartBallKey,
              onTap: () => _handleActionTap(FloatingAction.favorite),
              child: _buildActionBallVisual(
                Icons.favorite,
                widget.isFavorite ? Colors.red : Colors.white,
                widget.isFavorite,
                isDark,
              ),
            ),
          ),
          // كرة الكاميرا
          Positioned(
            top: -100,
            left: 10,
            child: GestureDetector(
              key: _cameraBallKey,
              onTap: () => _handleActionTap(FloatingAction.camera),
              child: _buildActionBallVisual(Icons.photo_camera, Colors.blue, false, isDark),
            ),
          ),
          // كرة المعرض
          Positioned(
            top: -120,
            left: 50,
            child: GestureDetector(
              key: _galleryBallKey,
              onTap: () => _handleActionTap(FloatingAction.gallery),
              child: _buildActionBallVisual(Icons.photo_library, Colors.green, false, isDark),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainBallVisual(bool isDark) {
    return AnimatedRotation(
      turns: _showActionBalls ? 0.125 : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: Icon(_showActionBalls ? Icons.close : Icons.add, color: Colors.black, size: 28)),
      ),
    );
  }

  Widget _buildActionBallVisual(IconData icon, Color iconColor, bool isActive, bool isDark) {
    final ballColor = isActive ? Colors.red.withValues(alpha: 0.9) : (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final borderColor = isActive
        ? Colors.red
        : (icon == Icons.favorite ? Colors.red.withValues(alpha: 0.5) : const Color(0xFFFFD700));

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: ballColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isActive ? 3.0 : 2.0),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isActive && icon == Icons.favorite ? Icons.favorite : icon,
                color: isActive && icon == Icons.favorite ? Colors.white : iconColor,
                size: isActive ? 24 : 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
