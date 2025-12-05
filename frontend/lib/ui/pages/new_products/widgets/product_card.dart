import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system.dart';
import '../../../../models/product.dart';
import '../../../../services/cart_service.dart';
import '../../../../services/favorites_service.dart';
import '../../../../utils/font_helper.dart';
import '../../../../utils/theme_colors.dart';
import 'smart_product_image.dart';
import 'notification_bar.dart';

/// بطاقة المنتج
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;

  const ProductCard({super.key, required this.product, required this.isDark});

  // القياسات الثابتة
  static const double _imageBottomSpacing = 3.0;
  static const double _nameHeight = 24.0;
  static const double _nameBottomSpacing = 2.0;
  static const double _priceBarHeight = 38.0;
  static const double _cardBottomPadding = 10.0;
  static const double _fixedElementsHeight =
      _imageBottomSpacing + _nameHeight + _nameBottomSpacing + _priceBarHeight + _cardBottomPadding;

  // حساب ارتفاع الصورة الذكي
  static double getSmartImageHeight(double cardWidth, double screenWidth) {
    double heightToWidthRatio;
    if (screenWidth <= 400) {
      heightToWidthRatio = 1.15;
    } else if (screenWidth <= 600) {
      heightToWidthRatio = 1.10;
    } else if (screenWidth <= 900) {
      heightToWidthRatio = 1.05;
    } else if (screenWidth <= 1200) {
      heightToWidthRatio = 1.0;
    } else {
      heightToWidthRatio = 0.95;
    }
    return (cardWidth * heightToWidthRatio).clamp(130.0, 300.0);
  }

  static double calculateCardHeight(double screenWidth, double cardWidth) {
    return getSmartImageHeight(cardWidth, screenWidth) + _fixedElementsHeight;
  }

  static double calculateOptimalAspectRatio(BuildContext context, [int? columns]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth > 600 ? 16.0 : (screenWidth > 400 ? 12.0 : 8.0);
    final crossAxisSpacing = screenWidth > 600 ? 14.0 : (screenWidth > 400 ? 10.0 : 6.0);
    int actualColumns = columns ?? getSmartColumnCount(screenWidth);

    final availableWidth = screenWidth - (horizontalMargin * 2);
    final totalSpacing = crossAxisSpacing * (actualColumns - 1);
    final cardWidth = (availableWidth - totalSpacing) / actualColumns;
    return cardWidth / calculateCardHeight(screenWidth, cardWidth);
  }

  static int getSmartColumnCount(double screenWidth) {
    if (screenWidth > 1400) return 5;
    if (screenWidth > 1100) return 4;
    if (screenWidth > 800) return 3;
    return 2;
  }

  /// تنسيق السعر بالنظام العراقي
  /// مثال: 6500 → "6,500 د.ع"
  String _formatPrice(num price) {
    final priceInt = price.toInt();
    final formatted = priceInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * animationValue),
            child: Opacity(
              opacity: animationValue,
              child: GestureDetector(
                onTap: () => context.go('/products/details/${product.id}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final imageHeight = getSmartImageHeight(cardWidth, screenWidth);
                      return _buildCardContent(context, imageHeight);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, double imageHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 5),
      decoration: _cardDecoration(),
      child: Stack(
        children: [
          _buildImage(imageHeight),
          _buildQuantityBadge(),
          if (product.notificationTags.isNotEmpty)
            Positioned(right: 0, top: 0, child: NotificationBar(product: product)),
          _buildProductName(imageHeight),
          _buildPriceBar(context, imageHeight),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: isDark ? null : Colors.white,
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.03),
                const Color(0xFF1A1F2E).withValues(alpha: 0.2),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
        width: 1,
      ),
      boxShadow: isDark
          ? []
          : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
    );
  }

  Widget _buildImage(double imageHeight) {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: SizedBox(
          height: imageHeight,
          child: product.images.isNotEmpty
              ? Container(
                  color: isDark ? Colors.transparent : Colors.white,
                  child: SmartProductImage(imageUrl: product.images.first, height: imageHeight, isDark: isDark),
                )
              : Container(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  child: Icon(Icons.camera_alt_outlined, color: isDark ? Colors.white60 : Colors.grey, size: 50),
                ),
        ),
      ),
    );
  }

  Widget _buildQuantityBadge() {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppDesignSystem.goldColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(17), bottomRight: Radius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_rounded, color: Colors.black, size: 12),
            const SizedBox(width: 4),
            Text(
              '${product.availableFrom}-${product.availableTo}',
              style: GoogleFonts.cairo(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductName(double imageHeight) {
    return Positioned(
      left: 6,
      right: 6,
      top: imageHeight + _imageBottomSpacing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Text(
          product.name,
          style: FontHelper.cairo(
            color: ThemeColors.textColor(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPriceBar(BuildContext context, double imageHeight) {
    return Positioned(
      left: 5,
      right: 5,
      top: imageHeight + _imageBottomSpacing + _nameHeight + _nameBottomSpacing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildPriceLabel(),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: _HeartButton(product: product, isDark: isDark),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: _AddToCartButton(product: product, isDark: isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLabel() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Text(
        _formatPrice(product.wholesalePrice),
        style: FontHelper.cairo(color: isDark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

/// زر القلب
class _HeartButton extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _HeartButton({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, _) {
        final isLiked = favoritesService.isFavorite(product.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            favoritesService.toggleFavoriteSync(product);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLiked
                  ? const Color(0xFFEF4444)
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              size: 17,
            ),
          ),
        );
      },
    );
  }
}

/// زر الإضافة للسلة
class _AddToCartButton extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _AddToCartButton({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, _) {
        final isInCart = cart.hasProduct(product.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (!isInCart) {
              cart.addItemSync(
                productId: product.id,
                name: product.name,
                image: product.images.isNotEmpty ? product.images.first : '',
                minPrice: product.minPrice.toInt(),
                maxPrice: product.maxPrice.toInt(),
                customerPrice: 0,
                wholesalePrice: product.wholesalePrice.toInt(),
                quantity: 1,
              );
            } else {
              cart.removeByProductId(product.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isInCart
                  ? const Color(0xFF22C55E)
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInCart ? Icons.check_rounded : Icons.add_rounded,
              color: isInCart ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
