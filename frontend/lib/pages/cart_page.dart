import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/cart_service.dart';
import '../services/scheduled_orders_service.dart';
import '../services/inventory_service.dart';
import '../widgets/pull_to_refresh_wrapper.dart';

import 'customer_info_page.dart';
import '../utils/number_formatter.dart';
import '../widgets/common_header.dart';

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
  final ScheduledOrdersService _scheduledOrdersService =
      ScheduledOrdersService();

  // لا نحسب رسوم التوصيل في السلة - تُحسب في ملخص الطلب فقط

  @override
  void initState() {
    super.initState();
    _cartIconController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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
      final convertedCount = await _scheduledOrdersService
          .convertScheduledOrdersToActive();
      if (convertedCount > 0) {
        debugPrint('✅ تم تحويل $convertedCount طلب مجدول إلى نشط');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في التحويل التلقائي: $e');
    }
  }

  @override
  void dispose() {
    _cartIconController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _startCartIconAnimation() {
    _cartIconController.repeat(reverse: true);
  }

  // حساب المجاميع (بدون رسوم توصيل - تُحسب في ملخص الطلب)
  Map<String, int> _calculateTotals() {
    return _cartService.calculateTotals(
      deliveryFee: 0, // لا رسوم توصيل في السلة
      discount: 0, // لا خصم في السلة
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: ListenableBuilder(
        listenable: _cartService,
        builder: (context, child) {
          final totals = _calculateTotals();

          return Column(
            children: [
              // الشريط العلوي الموحد
              CommonHeader(
                title: 'السلة',
                leftActions: [
                  // زر مسح السلة
                  GestureDetector(
                    onTap: () => _showClearCartDialog(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFff2d55).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFff2d55).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        FontAwesomeIcons.trash,
                        color: Color(0xFFff2d55),
                        size: 16,
                      ),
                    ),
                  ),
                ],
                rightActions: [
                  GestureDetector(
                    onTap: () => context.go('/products'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        FontAwesomeIcons.arrowRight,
                        color: Color(0xFFffd700),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              // محتوى السلة
              Expanded(
                child: _cartService.items.isEmpty
                    ? _buildEmptyCart()
                    : _buildCartContent(totals),
              ),

              // القسم السفلي الثابت (المجموع والأزرار)
              if (_cartService.items.isNotEmpty) _buildBottomSection(totals),
            ],
          );
        },
      ),
    );
  }

  // حالة السلة الفارغة
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.cartShopping,
            size: 80,
            color: const Color(0xFF6c757d),
          ),
          const SizedBox(height: 20),
          Text(
            'سلتك فارغة',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6c757d),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ابدأ بإضافة منتجات إلى سلتك',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6c757d),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007bff),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.bagShopping, size: 16),
                const SizedBox(width: 10),
                Text(
                  'تصفح المنتجات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // محتوى السلة
  Widget _buildCartContent(Map<String, int> totals) {
    return PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: 'تم تحديث السلة',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // منتجات السلة
            ..._cartService.items.map((item) => _buildCartItem(item)),

            const SizedBox(height: 20), // مساحة صغيرة للقسم السفلي الثابت
          ],
        ),
      ),
    );
  }

  // مسح السلة
  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'مسح السلة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع المنتجات من السلة؟',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc3545),
            ),
            child: Text('مسح', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🏷️ بطاقة منتج في السلة
  Widget _buildCartItem(CartItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: const Color(0xFF28a745).withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                        border: Border.all(
                          color: const Color(0xFFe9ecef),
                          width: 1,
                        ),
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
                              child: const Icon(
                                FontAwesomeIcons.image,
                                color: Colors.white,
                                size: 18,
                              ),
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
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // الأسعار في صف واحد
                          Row(
                            children: [
                              // سعر الجملة
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFdc3545,
                                    ).withValues(alpha: 0.1),
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

                              const SizedBox(width: 6),

                              // سعر الزبون
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF28a745,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'زبون: ${_cartService.formatPrice(item.customerPrice)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF28a745),
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
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
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
                            Text(
                              'سعر الزبون',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFffd700),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: _getPriceFieldBorderColor(item),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                initialValue: item.customerPrice > 0
                                    ? item.customerPrice.toString()
                                    : '', // حقل فارغ إذا لم يتم تحديد سعر
                                keyboardType: TextInputType.number,
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
                                  final newPrice = int.tryParse(value);
                                  if (newPrice != null) {
                                    // تحديث السعر مباشرة بدون رسائل
                                    _cartService.updatePrice(
                                      item.productId,
                                      newPrice,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            // الحد الأدنى والأقصى من البيانات المحفوظة
                            Column(
                              children: [
                                // الحد الأدنى
                                Text(
                                  'الحد الأدنى: ${_cartService.formatPrice(item.minPrice)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                // الحد الأقصى
                                Text(
                                  'الحد الأقصى: ${_cartService.formatPrice(item.maxPrice)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // تعديل الكمية
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'الكمية',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // زر تقليل
                                GestureDetector(
                                  onTap: () {
                                    if (item.quantity > 1) {
                                      _cartService.updateQuantity(
                                        item.productId,
                                        item.quantity - 1,
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFdc3545),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      FontAwesomeIcons.minus,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                  ),
                                ),

                                // عرض الكمية
                                Container(
                                  width: 28,
                                  height: 20,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFf8f9fa),
                                    border: Border.all(
                                      color: const Color(0x000ffddd),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),

                                // زر زيادة
                                GestureDetector(
                                  onTap: () async {
                                    // ✅ التحقق من المخزون المتاح قبل الزيادة
                                    final availabilityCheck = await InventoryService.checkAvailability(
                                      productId: item.productId,
                                      requestedQuantity: item.quantity + 1,
                                    );

                                    if (availabilityCheck['success'] && availabilityCheck['is_available']) {
                                      _cartService.updateQuantity(
                                        item.productId,
                                        item.quantity + 1,
                                      );
                                    } else {
                                      // عرض رسالة نفاد المخزون
                                      final maxAvailable = availabilityCheck['max_available'] ?? 0;
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            maxAvailable <= 0
                                              ? '❌ نفذ المخزون - لا يمكنك إضافة المزيد'
                                              : '⚠️ متوفر حتى $maxAvailable قطعة فقط',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: maxAvailable <= 0
                                            ? const Color(0xFFdc3545)
                                            : const Color(0xFFff8c00),
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF28a745),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      FontAwesomeIcons.plus,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // المجاميع
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // المجموع
                            Text(
                              'المجموع',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _cartService.formatPrice(
                                item.customerPrice * item.quantity,
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF007bff),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 3),

                            // الربح الإجمالي
                            Text(
                              'ربح إجمالي',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _cartService.formatPrice(
                                (item.customerPrice - item.wholesalePrice) *
                                    item.quantity,
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF28a745),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
              onTap: () => _cartService.removeItem(item.productId),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFdc3545),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  FontAwesomeIcons.xmark,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 القسم السفلي الثابت (المجموع والأزرار)
  Widget _buildBottomSection(Map<String, int> totals) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1a1a2e),
        border: Border(
          top: BorderSide(
            color: Color(0xFFffd700).withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // المجموع والربح جنباً إلى جنب
              Row(
                children: [
                  // المجموع النهائي
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF16213e),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Color(0xFFffd700).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFffd700).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'المجموع النهائي',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            NumberFormatter.formatCurrency(
                              totals['total'] ?? 0,
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFffd700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // الربح المتوقع
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF16213e),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'الربح المتوقع',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            NumberFormatter.formatCurrency(
                              totals['profit'] ?? 0,
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // الأزرار
              Row(
                children: [
                  // زر إتمام الطلب
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => _completeOrder(totals),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF28a745), Color(0xFF20c997)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF28a745).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'إتمام الطلب',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // زر جدولة الطلب
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _showScheduleDialog(totals),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFffd700).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFffd700).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.calendar,
                                color: Color(0xFF1a1a2e),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'جدولة',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1a1a2e),
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
        invalidProducts.add(
          '${item.name} - السعر أقل من الحد الأدنى (${_cartService.formatPrice(item.minPrice)})',
        );
      } else if (item.customerPrice > item.maxPrice) {
        hasInvalidPrices = true;
        invalidProducts.add(
          '${item.name} - السعر أعلى من الحد الأقصى (${_cartService.formatPrice(item.maxPrice)})',
        );
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
              const Icon(
                FontAwesomeIcons.triangleExclamation,
                color: Color(0xFFdc3545),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'أسعار غير صحيحة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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
                      const Icon(
                        FontAwesomeIcons.circleXmark,
                        color: Color(0xFFdc3545),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'حسناً',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
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
                  border: Border.all(
                    color: const Color(0xFF007bff).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
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
                          const Icon(
                            FontAwesomeIcons.calendar,
                            color: Color(0xFFffd700),
                            size: 24,
                          ),
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
                              child: const Icon(
                                FontAwesomeIcons.xmark,
                                color: Colors.white,
                                size: 14,
                              ),
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاريخ التسليم',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF007bff),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.calendarDay,
                                      color: Color(0xFF007bff),
                                      size: 16,
                                    ),
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ملاحظات إضافية',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF007bff),
                                  width: 1,
                                ),
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
                                  hintStyle: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
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
                                      color: const Color(
                                        0xFFdc3545,
                                      ).withValues(alpha: 0.3),
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
                              onTap: () => _scheduleOrder(
                                totals,
                                selectedDate,
                                notesController.text,
                              ),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF007bff),
                                      Color(0xFF0056b3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF007bff,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
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
  Color _getPriceFieldBorderColor(CartItem item) {
    if (item.customerPrice <= 0) {
      return Colors.grey; // لم يتم تحديد السعر
    } else if (item.customerPrice < item.minPrice ||
        item.customerPrice > item.maxPrice) {
      return Colors.red; // سعر خاطئ
    } else {
      return Colors.green; // سعر صحيح
    }
  }

  // ✅ إتمام الطلب
  void _completeOrder(Map<String, int> totals) {
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
        invalidProducts.add(
          '${item.name} - السعر أقل من الحد الأدنى (${_cartService.formatPrice(item.minPrice)})',
        );
      } else if (item.customerPrice > item.maxPrice) {
        hasInvalidPrices = true;
        invalidProducts.add(
          '${item.name} - السعر أعلى من الحد الأقصى (${_cartService.formatPrice(item.maxPrice)})',
        );
      }
    }

    if (hasInvalidPrices) {
      // عرض رسالة خطأ
      _showPriceValidationDialog(invalidProducts);
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
  void _showPriceValidationDialog(List<String> invalidProducts) {
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
            const Icon(
              FontAwesomeIcons.triangleExclamation,
              color: Color(0xFFdc3545),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'أسعار غير صحيحة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يرجى تصحيح الأسعار التالية قبل إتمام الطلب:',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 15),
            ...invalidProducts.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      FontAwesomeIcons.circleXmark,
                      color: Color(0xFFdc3545),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حسناً',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 جدولة الطلب - الانتقال لصفحة معلومات العميل مع تاريخ الجدولة
  void _scheduleOrder(
    Map<String, int> totals,
    DateTime scheduledDate,
    String notes,
  ) {
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
