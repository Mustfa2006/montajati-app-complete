import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/cart_service.dart';
import '../services/inventory_service.dart';
import '../services/scheduled_orders_service.dart';
import '../utils/number_formatter.dart';
import '../widgets/app_background.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import 'customer_info_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  late AnimationController _cartIconController;
  late AnimationController _headerController;
  // تم إزالة _isProcessingOrder غير المستخدم

  // خدمة السلة
  final CartService _cartService = CartService();
  final ScheduledOrdersService _scheduledOrdersService = ScheduledOrdersService();

  // ✅ Map لتخزين controllers لكل عنصر في السلة (لحل مشكلة فقدان التركيز)
  final Map<String, TextEditingController> _priceControllers = {};

  // لا نحسب رسوم التوصيل في السلة - تُحسب في ملخص الطلب فقط

  @override
  void initState() {
    super.initState();
    _cartIconController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _headerController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _headerController.forward();
    _startCartIconAnimation();

    // تشغيل التحويل التلقائي للطلبات المجدولة عند فتح الصفحة
    _runAutoConversion();
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة السلة...');

    // إعادة تشغيل التحويل التلقائي
    await _runAutoConversion();

    // تحديث حالة الصفحة
    if (mounted) {
      setState(() {});
    }

    debugPrint('✅ تم تحديث بيانات صفحة السلة');
  }

  // تشغيل التحويل التلقائي للطلبات المجدولة
  Future<void> _runAutoConversion() async {
    try {
      debugPrint('🔄 تشغيل التحويل التلقائي للطلبات المجدولة...');
      final convertedCount = await _scheduledOrdersService.convertScheduledOrdersToActive();
      if (convertedCount > 0) {
        debugPrint('✅ تم تحويل $convertedCount طلب مجدول إلى نشط');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في التحويل التلقائي: $e');
    }
  }

  @override
  void dispose() {
    // ✅ التخلص من جميع price controllers
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    _priceControllers.clear();

    _cartIconController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _startCartIconAnimation() {
    _cartIconController.repeat(reverse: true);
  }

  // ✅ الحصول على أو إنشاء controller للعنصر (لحل مشكلة فقدان التركيز)
  TextEditingController _getOrCreateController(CartItem item) {
    if (!_priceControllers.containsKey(item.id)) {
      _priceControllers[item.id] = TextEditingController(
        text: item.customerPrice > 0 ? item.customerPrice.toString() : '',
      );
    }
    // ✅ لا نحدث النص تلقائياً لتجنب مشاكل الكتابة
    return _priceControllers[item.id]!;
  }

  // ✅ دالة التحقق الذكية من صحة السعر
  Map<String, dynamic> _validatePrice(int price, CartItem item) {
    // إذا كان السعر 0 (فارغ)
    if (price == 0) {
      return {
        'isValid': false,
        'error': 'لم يتم تحديد السعر',
        'errorType': 'empty', // empty, belowMin, aboveMax, invalidStep
      };
    }

    // التحقق من أن السعر أقل من الحد الأدنى
    if (price < item.minPrice) {
      return {'isValid': false, 'error': 'السعر أقل من الحد الأدنى', 'errorType': 'belowMin'};
    }

    // التحقق من أن السعر أعلى من الحد الأقصى
    if (price > item.maxPrice) {
      return {'isValid': false, 'error': 'السعر أعلى من الحد الأقصى', 'errorType': 'aboveMax'};
    }

    // التحقق من أن السعر يتبع خطوات محددة
    // الصيغة: price = minPrice + (n * priceStep) حيث n = 0, 1, 2, 3...
    final difference = price - item.minPrice;
    if (difference % item.priceStep != 0) {
      return {'isValid': false, 'error': 'السعر غير صحيح', 'errorType': 'invalidStep'};
    }

    // السعر صحيح تماماً
    return {'isValid': true, 'error': '', 'errorType': 'none'};
  }

  // حساب المجاميع (بدون رسوم توصيل - تُحسب في ملخص الطلب)
  Map<String, int> _calculateTotals() {
    return _cartService.calculateTotals(
      deliveryFee: 0, // لا رسوم توصيل في السلة
      discount: 0, // لا خصم في السلة
    );
  }

  // 🎨 تحويل كود اللون السادس عشري إلى Color
  Color _parseColor(String hexColor) {
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: ListenableBuilder(
          listenable: _cartService,
          builder: (context, child) {
            final totals = _calculateTotals();

            return Column(
              children: [
                // الشريط العلوي
                const SizedBox(height: 25),
                _buildHeader(isDark),
                const SizedBox(height: 20),

                // المحتوى الرئيسي
                Expanded(
                  child: _cartService.items.isEmpty
                      ? _buildEmptyCart(isDark)
                      : Stack(
                          children: [
                            // محتوى السلة القابل للتمرير
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 200),
                                child: _buildCartContent(totals, isDark),
                              ),
                            ),

                            // القسم السفلي الثابت
                            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomSection(totals, isDark)),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🎨 الشريط العلوي ضمن المحتوى
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع
          GestureDetector(
            onTap: () => context.go('/products'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(FontAwesomeIcons.arrowRight, color: isDark ? Colors.white : Colors.black, size: 18),
            ),
          ),

          // العنوان
          Text(
            'السلة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // زر مسح السلة
          GestureDetector(
            onTap: () => _showClearCartDialog(isDark),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFff2d55).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFff2d55).withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(FontAwesomeIcons.trash, color: Color(0xFFff2d55), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // حالة السلة الفارغة
  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.cartShopping,
            size: 80,
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'سلتك فارغة',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ابدأ بإضافة منتجات إلى سلتك',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.bagShopping, size: 16),
                const SizedBox(width: 10),
                Text('تصفح المنتجات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // محتوى السلة
  Widget _buildCartContent(Map<String, int> totals, bool isDark) {
    return PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: 'تم تحديث السلة',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            // منتجات السلة
            ..._cartService.items.map((item) => _buildCartItem(item, isDark)),

            const SizedBox(height: 20), // مساحة صغيرة للقسم السفلي الثابت
          ],
        ),
      ),
    );
  }

  // مسح السلة
  void _showClearCartDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        title: Text(
          'مسح السلة',
          style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع المنتجات من السلة؟',
          style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFdc3545)),
            child: Text('مسح', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🏷️ بطاقة منتج في السلة
  Widget _buildCartItem(CartItem item, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, // 🎯 شفافة في الليلي، بيضاء في النهاري
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.3 : 0.5),
          width: isDark ? 1.5 : 2,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الجزء العلوي - الصورة والمعلومات الأساسية
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة المنتج
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFe9ecef), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF6c757d),
                              child: const Icon(FontAwesomeIcons.image, color: Colors.white, size: 18),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // معلومات المنتج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          Text(
                            item.name,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black, // 🎯 متكيف
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // 🎨 عرض اللون إذا كان موجوداً
                          if (item.colorName != null && item.colorHex != null)
                            Row(
                              children: [
                                // دائرة اللون
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _parseColor(item.colorHex!),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // اسم اللون
                                Text(
                                  item.colorName!,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFffd700),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 6),

                          // الأسعار في صف واحد
                          Row(
                            children: [
                              // سعر الجملة
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFdc3545).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'جملة: ${_cartService.formatPrice(item.wholesalePrice)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFdc3545),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // الجزء السفلي - التحكم في السعر والكمية
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // تعديل سعر الزبون
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ نص الخطأ فوق الشريط (إن وجد)
                            Builder(
                              builder: (context) {
                                final validation = _validatePrice(item.customerPrice, item);
                                return validation['isValid']
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          validation['error'] ?? '',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFdc3545), // أحمر
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                              },
                            ),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: _validatePrice(item.customerPrice, item)['isValid']
                                      ? const Color(0xFF28a745) // أخضر
                                      : const Color(0xFFdc3545), // أحمر
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _getOrCreateController(item), // ✅ استخدام controller ثابت
                                keyboardType: TextInputType.number, // ✅ كيبورد أرقام فقط
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // ✅ قبول أرقام فقط
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  hintText: 'أدخل السعر',
                                  hintStyle: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    _cartService.updatePrice(item.id, 0);
                                    setState(() {});
                                    return;
                                  }

                                  final newPrice = int.tryParse(value);
                                  if (newPrice != null) {
                                    // ✅ نقبل أي رقم ونحدث السعر مباشرة (السماح بالكتابة بحرية)
                                    _cartService.updatePrice(item.id, newPrice);
                                    setState(() {}); // ✅ لتحديث لون الإطار فقط
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            // ✅ الحد الأدنى والأقصى منفصلين أفقياً
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // الحد الأدنى
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Text(
                                    'أدنى: ${_cartService.formatPrice(item.minPrice)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // الحد الأقصى
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Text(
                                    'أقصى: ${_cartService.formatPrice(item.maxPrice)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ✅ الكمية في أقصى اليسار (عمودي: + ثم العدد ثم -)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // زر زيادة (+) في الأعلى
                          GestureDetector(
                            onTap: () {
                              // ✅ زيادة فورية بدون انتظار
                              if (item.quantity >= 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('الحد الأقصى 10 قطع', style: GoogleFonts.cairo(fontSize: 13)),
                                    backgroundColor: const Color(0xFFdc3545),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }

                              // ✅ تحديث فوري
                              _cartService.updateQuantity(item.id, item.quantity + 1);

                              // ✅ التحقق من المخزون في الخلفية (بدون انتظار)
                              InventoryService.checkAvailability(
                                productId: item.productId,
                                requestedQuantity: item.quantity + 1,
                                colorId: item.colorId,
                              ).then((availabilityCheck) {
                                if (!availabilityCheck['success'] || !availabilityCheck['is_available']) {
                                  // إذا لم يكن متوفر، نرجع الكمية
                                  _cartService.updateQuantity(item.id, item.quantity);
                                  final maxAvailable = availabilityCheck['max_available'] ?? 0;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          maxAvailable <= 0 ? '❌ نفذ المخزون' : '⚠️ متوفر $maxAvailable قطعة فقط',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                        backgroundColor: maxAvailable <= 0
                                            ? const Color(0xFFdc3545)
                                            : const Color(0xFFff8c00),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF28a745),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(FontAwesomeIcons.plus, color: Colors.white, size: 11),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // عرض الكمية في الوسط
                          Container(
                            width: 36,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFf8f9fa),
                              border: Border.all(color: const Color(0xFF007bff), width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // زر تقليل (-) في الأسفل
                          GestureDetector(
                            onTap: () {
                              if (item.quantity > 1) {
                                _cartService.updateQuantity(item.id, item.quantity - 1);
                              }
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFdc3545),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(FontAwesomeIcons.minus, color: Colors.white, size: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // زر حذف المنتج
          Positioned(
            top: 6,
            left: 6,
            child: GestureDetector(
              onTap: () => _cartService.removeItem(item.id), // 🎯 استخدام item.id بدلاً من productId
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: const Color(0xFFdc3545), borderRadius: BorderRadius.circular(9)),
                child: const Icon(FontAwesomeIcons.xmark, color: Colors.white, size: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 القسم السفلي الثابت (المجموع والأزرار) - مع تقويس من الأعلى
  Widget _buildBottomSection(Map<String, int> totals, bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
            border: Border(
              top: BorderSide(color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.5), width: 2),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ المجموع والربح بتصميم بسيط وأنيق
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // المجموع
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المجموع',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الربح',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // الأرقام
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormatter.formatCurrency(totals['total'] ?? 0),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFffd700),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormatter.formatCurrency(totals['profit'] ?? 0),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF28a745),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // الأزرار
                  Row(
                    children: [
                      // زر إتمام الطلب
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => completeOrder(totals),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF28a745), Color(0xFF20c997)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.check, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'إتمام الطلب',
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // زر جدولة الطلب
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _showScheduleDialog(totals),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.5), width: 1),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.calendar, color: Color(0xFF1a1a2e), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'جدولة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1a1a2e),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📅 نافذة جدولة الطلب
  void _showScheduleDialog(Map<String, int> totals) {
    // ✅ التحقق من أسعار العملاء قبل فتح نافذة الجدولة
    bool hasInvalidPrices = false;
    List<String> invalidProducts = [];

    for (var item in _cartService.items) {
      // التحقق من أن سعر العميل ضمن الحد الأدنى والأعلى
      if (item.customerPrice <= 0) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - لم يتم تحديد السعر');
      } else if (item.customerPrice < item.minPrice) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - السعر أقل من الحد الأدنى (${_cartService.formatPrice(item.minPrice)})');
      } else if (item.customerPrice > item.maxPrice) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - السعر أعلى من الحد الأقصى (${_cartService.formatPrice(item.maxPrice)})');
      }
    }

    // إذا كانت هناك أسعار غير صحيحة، عرض رسالة خطأ
    if (hasInvalidPrices) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFdc3545), width: 2),
          ),
          title: Row(
            children: [
              const Icon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFdc3545), size: 24),
              const SizedBox(width: 10),
              Text(
                'أسعار غير صحيحة',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يرجى تصحيح الأسعار التالية قبل جدولة الطلب:',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 15),
              ...invalidProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(FontAwesomeIcons.circleXmark, color: Color(0xFFdc3545), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(product, style: GoogleFonts.cairo(fontSize: 13, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFdc3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      return; // إيقاف تنفيذ باقي الدالة
    }

    // إذا كانت جميع الأسعار صحيحة، فتح نافذة الجدولة
    DateTime selectedDate = DateTime.now();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF007bff).withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان النافذة
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.calendar, color: Color(0xFFffd700), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'جدولة الطلب',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFffd700),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFdc3545),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(FontAwesomeIcons.xmark, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // اختيار التاريخ
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاريخ التسليم',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF007bff),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF1a1a2e),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF007bff), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(FontAwesomeIcons.calendarDay, color: Color(0xFF007bff), size: 16),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ملاحظات
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ملاحظات إضافية',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF007bff), width: 1),
                              ),
                              child: TextFormField(
                                controller: notesController,
                                maxLines: 3,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل أي ملاحظات خاصة بالطلب...',
                                  hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // أزرار العمليات
                      Row(
                        children: [
                          // زر الإلغاء
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFdc3545),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFdc3545).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'إلغاء',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // زر التأكيد
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => scheduleOrder(totals, selectedDate, notesController.text),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF007bff).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(FontAwesomeIcons.check, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'تأكيد الجدولة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎨 تحديد لون حقل السعر بناءً على صحة السعر
  Color getPriceFieldBorderColor(CartItem item) {
    if (item.customerPrice <= 0) {
      return Colors.grey; // لم يتم تحديد السعر
    } else if (item.customerPrice < item.minPrice || item.customerPrice > item.maxPrice) {
      return Colors.red; // سعر خاطئ
    } else {
      return Colors.green; // سعر صحيح
    }
  }

  // ✅ إتمام الطلب
  void completeOrder(Map<String, int> totals) {
    // التحقق من أن جميع المنتجات لها سعر عميل محدد
    bool hasInvalidPrices = false;
    List<String> invalidProducts = [];

    for (var item in _cartService.items) {
      // التحقق من أن سعر العميل ضمن الحد الأدنى والأعلى
      if (item.customerPrice <= 0) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - لم يتم تحديد السعر');
      } else if (item.customerPrice < item.minPrice) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - السعر أقل من الحد الأدنى (${_cartService.formatPrice(item.minPrice)})');
      } else if (item.customerPrice > item.maxPrice) {
        hasInvalidPrices = true;
        invalidProducts.add('${item.name} - السعر أعلى من الحد الأقصى (${_cartService.formatPrice(item.maxPrice)})');
      }
    }

    if (hasInvalidPrices) {
      // عرض رسالة خطأ
      showPriceValidationDialog(invalidProducts);
      return;
    }

    // طباعة بيانات السلة للتحقق من productId
    debugPrint('🔍 فحص بيانات السلة قبل الإرسال:');
    for (var item in _cartService.items) {
      debugPrint('📦 منتج: ${item.name}');
      debugPrint('🆔 productId: "${item.productId}"');
      debugPrint('🏷️ id: "${item.id}"');
    }

    // الانتقال إلى صفحة معلومات الزبون
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerInfoPage(
          orderTotals: totals,
          cartItems: _cartService.items
              .map(
                (item) => {
                  'id': item.id,
                  'productId': item.productId,
                  'name': item.name,
                  'image': item.image,
                  'wholesalePrice': item.wholesalePrice,
                  'customerPrice': item.customerPrice,
                  'quantity': item.quantity,
                  'color': null, // يمكن إضافة اللون لاحقاً
                },
              )
              .toList(),
        ),
      ),
    );
  }

  // عرض نافذة تحذير للأسعار غير الصحيحة
  void showPriceValidationDialog(List<String> invalidProducts) {
    // ✅ الحصول على حالة الوضع (نهاري/ليلي)
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // ✅ تحديد الألوان بناءً على الوضع
    final backgroundColor = isDark ? const Color(0xFF1a1a2e) : Colors.white; // أسود في الليل، أبيض في النهار
    final titleColor = isDark ? Colors.white : Colors.black; // أبيض في الليل، أسود في النهار
    final contentColor = isDark ? Colors.white70 : Colors.black87; // أبيض شفاف في الليل، أسود في النهار
    final itemColor = isDark ? Colors.white : Colors.black; // أبيض في الليل، أسود في النهار

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor, // ✅ خلفية متكيفة
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFdc3545), width: 2), // ✅ إطار أحمر ثابت
        ),
        title: Row(
          children: [
            const Icon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFdc3545), size: 24),
            const SizedBox(width: 10),
            Text(
              'أسعار غير صحيحة',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: titleColor), // ✅ لون متكيف
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يرجى تصحيح الأسعار التالية قبل إتمام الطلب:',
              style: GoogleFonts.cairo(fontSize: 14, color: contentColor), // ✅ لون متكيف
            ),
            const SizedBox(height: 15),
            ...invalidProducts.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(FontAwesomeIcons.circleXmark, color: Color(0xFFdc3545), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(product, style: GoogleFonts.cairo(fontSize: 13, color: itemColor)), // ✅ لون متكيف
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc3545),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // 📅 جدولة الطلب - الانتقال لصفحة معلومات العميل مع تاريخ الجدولة
  void scheduleOrder(Map<String, int> totals, DateTime scheduledDate, String notes) {
    Navigator.of(context).pop(); // إغلاق النافذة

    // الانتقال إلى صفحة معلومات العميل مع بيانات الجدولة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerInfoPage(
          orderTotals: totals,
          cartItems: _cartService.items,
          scheduledDate: scheduledDate, // تمرير تاريخ الجدولة
          scheduleNotes: notes, // تمرير ملاحظات الجدولة
        ),
      ),
    );
  }
}
