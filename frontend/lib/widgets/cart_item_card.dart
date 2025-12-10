import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cart_service.dart';

// 🎯 تحويل إلى StatefulWidget للسحب مع animation
class CartItemCard extends StatefulWidget {
  final CartItem item;
  final bool isDark;
  final CartService cartService;
  final TextEditingController priceController;
  final VoidCallback onStateChanged;
  final VoidCallback onDelete;

  const CartItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.cartService,
    required this.priceController,
    required this.onStateChanged,
    required this.onDelete,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  // 🎯 متغيرات السحب
  double _dragOffset = 0;
  static const double _maxDrag = 60; // 🎯 سحب أقصر

  // Getters للوصول السهل
  CartItem get item => widget.item;
  bool get isDark => widget.isDark;
  CartService get cartService => widget.cartService;
  TextEditingController get priceController => widget.priceController;
  VoidCallback get onStateChanged => widget.onStateChanged;
  VoidCallback get onDelete => widget.onDelete;

  Color _parseColor(String hexColor) {
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Map<String, dynamic> _validatePrice(int price) {
    if (price == 0) return {'isValid': false, 'error': 'أدخل السعر'};
    if (price < item.minPrice) return {'isValid': false, 'error': 'أقل من الأدنى'};
    if (price > item.maxPrice) return {'isValid': false, 'error': 'أعلى من الأقصى'};
    final diff = price - item.minPrice;
    if (diff % item.priceStep != 0) return {'isValid': false, 'error': 'سعر غير صحيح'};
    return {'isValid': true, 'error': ''};
  }

  int get _profitPerItem => item.customerPrice > 0 ? (item.customerPrice - item.wholesalePrice) : 0;
  int get _totalProfit => _profitPerItem * item.quantity;

  @override
  Widget build(BuildContext context) {
    final validation = _validatePrice(item.customerPrice);
    final isValid = validation['isValid'] as bool;
    final errorMsg = validation['error'] as String;

    // 🎯 حساب نسبة السحب (0 إلى 1)
    final dragProgress = (_dragOffset / _maxDrag).clamp(0.0, 1.0);
    // 🎯 اللون الأحمر يتقوى مع السحب (من شفاف إلى قوي)
    final deleteButtonOpacity = 0.3 + (dragProgress * 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // 🎯 زر الحذف - ملاصق للبطاقة
          Positioned(
            left: 0, // 🎯 بدون مسافة
            top: 0, // 🎯 بطول البطاقة بالضبط
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onDelete();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 55, // 🎯 عرض أصغر
                decoration: BoxDecoration(
                  // 🎯 لون أخف
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2 + (dragProgress * 0.6)),
                  // 🎯 أطراف مقوسة جميلة
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.trash,
                    color: Colors.white.withValues(alpha: 0.5 + (dragProgress * 0.5)),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          // 🎯 البطاقة الرئيسية - السحب لليمين
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                // 🎯 السحب لليمين (قيمة موجبة)
                _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                if (_dragOffset > _maxDrag / 2) {
                  _dragOffset = _maxDrag;
                } else {
                  _dragOffset = 0;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              // 🎯 تحريك لليمين (قيمة موجبة)
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProductImage(),
                              const SizedBox(width: 12),
                              Expanded(child: _buildProductInfo()),
                            ],
                          ),
                        ),
                        _buildBottomSection(isValid, errorMsg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          item.image,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
            child: const Icon(FontAwesomeIcons.image, color: Colors.grey, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildInfoRow(),
      ],
    );
  }

  // صف المعلومات: لون + جملة + عدد القطع
  Widget _buildInfoRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الصف الأول: اللون + الجملة + الربح
        Row(
          children: [
            if (item.colorName != null && item.colorHex != null) ...[_buildColorBadge(), const SizedBox(width: 6)],
            _buildWholesaleBadge(),
            if (_totalProfit > 0) ...[const SizedBox(width: 6), _buildProfitBadge()],
          ],
        ),
        const SizedBox(height: 6),
        // الصف الثاني: عدد القطع تحت الجملة مباشرة
        _buildQuantityBadge(),
      ],
    );
  }

  // 🎯 عداد الكمية مع أزرار +/- في الوسط (مثل صفحة التفاصيل)
  Widget _buildQuantityBadge() {
    const int maxQuantity = 10;
    const int minQuantity = 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🎯 كلمة الكمية - بدون إطار
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FontAwesomeIcons.cubes, size: 10, color: Color(0xFFFFD700)), // 🎯 ذهبي
            const SizedBox(width: 4),
            Text(
              'الكمية',
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black, // 🎯 أبيض/أسود
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // 🎯 زر النقصان
        _buildQuantityButton(
          icon: FontAwesomeIcons.minus,
          onTap: () {
            if (item.quantity > minQuantity) {
              cartService.updateQuantity(item.id, item.quantity - 1);
              onStateChanged();
              HapticFeedback.selectionClick();
            }
          },
          isEnabled: item.quantity > minQuantity,
        ),
        // 🎯 الرقم
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${item.quantity}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        // 🎯 زر الزيادة (يقفل عند 10)
        _buildQuantityButton(
          icon: FontAwesomeIcons.plus,
          onTap: () {
            if (item.quantity < maxQuantity) {
              cartService.updateQuantity(item.id, item.quantity + 1);
              onStateChanged();
              HapticFeedback.selectionClick();
            }
          },
          isEnabled: item.quantity < maxQuantity,
        ),
      ],
    );
  }

  // 🎯 زر الكمية - مضبب 6 درجات بدون إطار
  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap, required bool isEnabled}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6), // 🎯 6 درجات
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              // 🎯 خلفية شفافة مضببة بدون إطار
              color: isEnabled ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              // 🎯 بدون إطار
            ),
            child: Center(
              child: Icon(
                icon,
                // 🎯 لون ذهبي فقط
                color: isEnabled ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3),
                size: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _parseColor(item.colorHex!).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _parseColor(item.colorHex!).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _parseColor(item.colorHex!),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            item.colorName!,
            style: GoogleFonts.cairo(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 شارة الجملة - مكبرة
  Widget _buildWholesaleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'جملة: ${cartService.formatPrice(item.wholesalePrice)}',
        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE53935)),
      ),
    );
  }

  Widget _buildBottomSection(bool isValid, String errorMsg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🎯 شريط السعر أولاً
          _buildPriceInput(isValid, errorMsg),
          const SizedBox(height: 6),
          // 🎯 الحدود (أدنى وأقصى) - أسفل شريط السعر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLimitBadge('أدنى', item.minPrice, const Color(0xFFFFD700), FontAwesomeIcons.arrowDown),
              const SizedBox(width: 10),
              _buildLimitBadge('أقصى', item.maxPrice, const Color(0xFF4CAF50), FontAwesomeIcons.arrowUp),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 شارة الحد - مصغرة
  Widget _buildLimitBadge(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 3),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          Text(
            cartService.formatPrice(value),
            style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // 🎯 شريط السعر - TextField مباشر للكتابة
  Widget _buildPriceInput(bool isValid, String errorMsg) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🎯 شريط السعر مع TextField مباشر
        Container(
          width: 140,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.7), width: 1.5),
          ),
          child: TextField(
            controller: priceController,
            keyboardType: TextInputType.number, // 🎯 كيبورد أرقام فقط
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 🎯 أرقام فقط
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              // 🎯 بدون أي حدود أو خطوط أو خلفية
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false, // 🎯 بدون خلفية
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              isCollapsed: true, // 🎯 إزالة أي مساحة إضافية
              hintText: 'أدخل السعر',
              hintStyle: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            onChanged: (value) {
              cartService.updatePrice(item.id, value.isEmpty ? 0 : (int.tryParse(value) ?? 0));
              onStateChanged();
            },
          ),
        ),
        // رسالة الخطأ
        if (!isValid && errorMsg.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            errorMsg,
            style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFE53935)),
          ),
        ],
      ],
    );
  }

  // 🎯 شارة الربح - مكبرة
  Widget _buildProfitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.coins, size: 10, color: Color(0xFF4CAF50)),
          const SizedBox(width: 5),
          Text(
            'ربحك: ${cartService.formatPrice(_totalProfit)}',
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4CAF50)),
          ),
          if (item.quantity > 1) ...[
            const SizedBox(width: 4),
            Text(
              '(×${item.quantity})',
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
