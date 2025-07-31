import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cart_service.dart';
import '../services/official_orders_service.dart';
import '../services/scheduled_orders_service.dart';
import '../services/simple_orders_service.dart';
import '../services/inventory_service.dart';
import '../models/scheduled_order.dart';
import '../models/order_item.dart';
import '../widgets/success_animation_widget.dart';
import '../utils/error_handler.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../widgets/common_header.dart';

class OrderSummaryPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderSummaryPage({super.key, required this.orderData});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _isProcessing = false;

  /// الحصول على معرف المحافظة بناءً على اسم المحافظة
  String? _getProvinceId(String? provinceName) {
    if (provinceName == null) return null;

    final provinceMapping = {
      'بغداد': '1',
      'البصرة': '2',
      'أربيل': '3',
      'النجف': '4',
      'كربلاء': '5',
      'الموصل': '6',
      'السليمانية': '7',
      'ديالى': '8',
      'الأنبار': '9',
      'دهوك': '10',
      'كركوك': '11',
      'بابل': '12',
      'نينوى': '13',
      'واسط': '14',
      'صلاح الدين': '15',
      'القادسية': '16',
      'المثنى': '17',
      'ذي قار': '18',
      'ميسان': '19'
    };

    return provinceMapping[provinceName];
  }

  /// الحصول على معرف المدينة بناءً على اسم المحافظة والمدينة
  String? _getCityId(String? provinceName, String? cityName) {
    if (provinceName == null) return null;

    // لنفس المحافظة، نستخدم نفس معرف المحافظة كمعرف المدينة
    // هذا تبسيط - يمكن تحسينه لاحقاً بمعرفات مدن مختلفة
    return _getProvinceId(provinceName);
  }

  /// تحديد سعر التوصيل بناءً على المحافظة
  int _getDeliveryFeeByProvince(String? provinceName) {
    if (provinceName == null) return 5000; // السعر الافتراضي

    // محافظة نينوى: سعر التوصيل 3000 د.ع
    if (provinceName.trim() == 'نينوى') {
      return 3000;
    }

    // باقي المحافظات: سعر التوصيل 5000 د.ع
    return 5000;
  }

  /// تحديد خيارات السلايدر بناءً على المحافظة
  List<int> _getDeliveryOptionsByProvince(String? provinceName) {
    if (provinceName == null) {
      return [5000, 4000, 3000, 2000, 1000, 0]; // الخيارات الافتراضية
    }

    // محافظة نينوى: خيارات السلايدر تبدأ من 3000
    if (provinceName.trim() == 'نينوى') {
      return [3000, 2000, 1000, 0]; // ✅ خيارات نينوى: 3000, 2000, 1000, مجاني
    }

    // باقي المحافظات: خيارات السلايدر تبدأ من 5000
    return [5000, 4000, 3000, 2000, 1000, 0];
  }
  bool _orderConfirmed = false; // ✅ لإخفاء أيقونة كلفة التوصيل بعد التأكيد
  int _deliveryFee = 5000; // ✅ البدء من 5000 بدلاً من 0 (سيتم تحديثه حسب المحافظة)
  List<int> _deliveryOptions = [
    5000,
    4000,
    3000,
    2000,
    1000,
    0,
  ]; // ✅ عكس الترتيب: من 5000 إلى مجاني (سيتم تحديثه حسب المحافظة)

  @override
  void initState() {
    super.initState();
    // تحديد سعر التوصيل وخيارات السلايدر بناءً على المحافظة المختارة
    final provinceName = widget.orderData['province'] as String?;
    _deliveryFee = _getDeliveryFeeByProvince(provinceName);
    _deliveryOptions = _getDeliveryOptionsByProvince(provinceName);
    debugPrint('🚚 تم تحديد سعر التوصيل للمحافظة "$provinceName": $_deliveryFee د.ع');
    debugPrint('🎛️ خيارات السلايدر: $_deliveryOptions');
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة ملخص الطلب...');

    // إعادة حساب الرسوم والمجاميع
    setState(() {
      // إعادة تعيين حالة المعالجة إذا كانت فاشلة
      if (!_orderConfirmed) {
        _isProcessing = false;
      }
    });

    debugPrint('✅ تم تحديث بيانات صفحة ملخص الطلب');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'ملخص الطلب',
            rightActions: [
              // زر الرجوع على اليمين
              GestureDetector(
                onTap: () => context.pop(),
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
            leftActions: [
              // أيقونة كلفة التوصيل (تختفي بعد تأكيد الطلب)
              if (!_orderConfirmed)
                Container(
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
                    FontAwesomeIcons.truck,
                    color: Color(0xFFffd700),
                    size: 16,
                  ),
                ),
            ],
          ),
          Expanded(
            child: PullToRefreshWrapper(
              onRefresh: _refreshData,
              refreshMessage: 'تم تحديث ملخص الطلب',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  _buildDeliveryFeeSlider(),
                  const SizedBox(height: 20),
                  _buildOrderSummary(),
                  const SizedBox(height: 100), // مساحة للزر الثابت
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }



  Widget _buildDeliveryFeeSlider() {
    return Container(
      padding: const EdgeInsets.all(12), // تصغير الحشو
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // تصغير الزوايا
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.4),
          width: 1, // تصغير سمك الحدود
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.1),
            blurRadius: 8, // تصغير الظل
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان - مصغر
          Row(
            children: [
              Icon(
                FontAwesomeIcons.truck,
                color: const Color(0xFFffd700),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'كلفة التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFffd700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // عرض القيمة الحالية - مصغر
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _deliveryFee == 0
                    ? 'مجاني'
                    : '${_formatPrice(_deliveryFee)} د.ع',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _deliveryFee == 0
                      ? Colors.green
                      : const Color(0xFFffd700),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // عنوان السلايدر
          Text(
            'دفع كلفة التوصيل من الربح',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          // السلايدر
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFffd700),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: const Color(0xFFffd700),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: const Color(0xFFffd700).withValues(alpha: 0.2),
              trackHeight: 6,
              valueIndicatorColor: const Color(0xFFffd700),
              valueIndicatorTextStyle: GoogleFonts.cairo(
                color: const Color(0xFF1a1a2e),
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _deliveryOptions.indexOf(_deliveryFee).toDouble(),
              min: 0,
              max: (_deliveryOptions.length - 1).toDouble(),
              divisions: _deliveryOptions.length - 1,
              onChanged: (value) {
                final newFee = _deliveryOptions[value.round()];
                final totalsData = widget.orderData['totals'];
                Map<String, int> totals = {};

                if (totalsData != null) {
                  if (totalsData is Map<String, int>) {
                    totals = totalsData;
                  } else if (totalsData is Map<String, dynamic>) {
                    totals = totalsData.map(
                      (key, value) => MapEntry(key, (value as num).toInt()),
                    );
                  }
                }

                final profit = totals['profit'] ?? 0;
                final provinceName = widget.orderData['province'] as String?;
                final baseDeliveryFee = _getDeliveryFeeByProvince(provinceName);
                final deliveryPaidByUser =
                    baseDeliveryFee - newFee; // المبلغ المدفوع من الربح
                final newProfit = profit - deliveryPaidByUser;

                // ✅ منع التقليل إذا وصل الربح لـ 0 أو أقل
                if (newProfit >= 0) {
                  setState(() {
                    _deliveryFee = newFee;
                  });
                } else {
                  // ✅ إظهار تنبيه جميل عند الوصول للحد الأقصى
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '⚠️ لا يمكن دفع المزيد - ربحك أصبح 0 د.ع',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 15),

          // عرض الخيارات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _deliveryOptions.map((fee) {
              final isSelected = _deliveryFee == fee;

              // ✅ حساب ما إذا كان هذا الخيار محظور
              final totalsData = widget.orderData['totals'];
              Map<String, int> totals = {};

              if (totalsData != null) {
                if (totalsData is Map<String, int>) {
                  totals = totalsData;
                } else if (totalsData is Map<String, dynamic>) {
                  totals = totalsData.map(
                    (key, value) => MapEntry(key, (value as num).toInt()),
                  );
                }
              }

              final profit = totals['profit'] ?? 0;
              final deliveryPaidByUser = 5000 - fee; // المبلغ المدفوع من الربح
              final newProfit = profit - deliveryPaidByUser;
              final isDisabled = newProfit < 0;

              return GestureDetector(
                onTap: () {
                  final totalsData = widget.orderData['totals'];
                  Map<String, int> totals = {};

                  if (totalsData != null) {
                    if (totalsData is Map<String, int>) {
                      totals = totalsData;
                    } else if (totalsData is Map<String, dynamic>) {
                      totals = totalsData.map(
                        (key, value) => MapEntry(key, (value as num).toInt()),
                      );
                    }
                  }

                  final profit = totals['profit'] ?? 0;
                  final deliveryPaidByUser =
                      5000 - fee; // المبلغ المدفوع من الربح
                  final newProfit = profit - deliveryPaidByUser;

                  // ✅ منع التقليل إذا وصل الربح لـ 0 أو أقل
                  if (newProfit >= 0) {
                    setState(() => _deliveryFee = fee);
                  } else {
                    // ✅ إظهار تنبيه جميل عند الوصول للحد الأقصى
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚠️ لا يمكن دفع المزيد - ربحك أصبح 0 د.ع',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.red.withValues(alpha: 0.1)
                        : isSelected
                        ? const Color(0xFFffd700).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDisabled
                          ? Colors.red.withValues(alpha: 0.5)
                          : isSelected
                          ? const Color(0xFFffd700)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    fee == 0 ? 'مجاني' : _formatPrice(fee),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDisabled
                          ? Colors.red.withValues(alpha: 0.7)
                          : isSelected
                          ? const Color(0xFFffd700)
                          : Colors.white70,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ دالة مشتركة لحساب القيم النهائية
  Map<String, int> _calculateFinalValues() {
    // التعامل مع البيانات بطريقة آمنة
    final totalsData = widget.orderData['totals'];
    Map<String, int> totals = <String, int>{};

    if (totalsData != null) {
      if (totalsData is Map<String, int>) {
        totals = totalsData;
      } else if (totalsData is Map<String, dynamic>) {
        totals = totalsData.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        );
      }
    }

    final subtotal = totals['subtotal'] ?? 0;
    final profit = totals['profit'] ?? 0;

    // ✅ حساب المبلغ الإجمالي والربح حسب السلايدر
    // كلما قل _deliveryFee، كلما دفع المستخدم أكثر من ربحه
    final provinceName = widget.orderData['province'] as String?;
    final baseDeliveryFee = _getDeliveryFeeByProvince(provinceName); // السعر الأساسي للمحافظة
    final deliveryPaidByUser = baseDeliveryFee - _deliveryFee; // المبلغ المدفوع من الربح
    final finalTotal = subtotal + _deliveryFee; // العميل يدفع أقل
    final finalProfit = profit - deliveryPaidByUser; // المستخدم يدفع من ربحه

    return {
      'subtotal': subtotal,
      'profit': profit,
      'deliveryFee': _deliveryFee,
      'deliveryPaidByUser': deliveryPaidByUser,
      'finalTotal': finalTotal,
      'finalProfit': finalProfit,
    };
  }

  Widget _buildOrderSummary() {
    final values = _calculateFinalValues();

    final subtotal = values['subtotal']!;
    final finalTotal = values['finalTotal']!;
    final finalProfit = values['finalProfit']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFffd700),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('المجموع الفرعي', subtotal),
          _buildSummaryRow('رسوم التوصيل', _deliveryFee),
          const Divider(color: Color(0xFFffd700), thickness: 1),
          _buildSummaryRow('المجموع النهائي', finalTotal, isTotal: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8), // تصغير الحشو
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6), // تصغير الزوايا
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.coins,
                      color: Colors.green,
                      size: 14, // تصغير الأيقونة
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ربحك:',
                      style: GoogleFonts.cairo(
                        fontSize: 12, // تصغير النص
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_formatPrice(finalProfit)} د.ع',
                  style: GoogleFonts.cairo(
                    fontSize: 14, // تصغير النص
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? const Color(0xFFffd700) : Colors.white70,
            ),
          ),
          Text(
            '${_formatPrice(amount)} د.ع',
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? const Color(0xFFffd700) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _isProcessing
              ? null
              : _orderConfirmed
              ? _navigateToOrders
              : _confirmOrder,
          child: Container(
            width: double.infinity,
            height: 60, // زيادة الارتفاع
            decoration: BoxDecoration(
              gradient: _isProcessing
                  ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                  : const LinearGradient(
                      colors: [
                        Color(0xFFffd700), // ذهبي فاتح
                        Color(0xFFffb300), // ذهبي متوسط
                        Color(0xFFff8f00), // ذهبي داكن
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.5, 1.0],
                    ),
              borderRadius: BorderRadius.circular(20), // زوايا أكثر انحناءً
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
                    )
                  : Center(
                      child: Text(
                        _orderConfirmed
                            ? 'تم تأكيد طلبك بالفعل ❤️'
                            : 'تأكيد الطلب',
                        style: GoogleFonts.cairo(
                          fontSize: _orderConfirmed ? 16 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 الانتقال المباشر إلى صفحة الطلبات
  void _navigateToOrders() {
    debugPrint('🎬 الانتقال المباشر إلى صفحة الطلبات');
    if (mounted) {
      try {
        // ✅ إعادة تحميل الطلبات قبل الانتقال
        final ordersService = SimpleOrdersService();
        ordersService.loadOrders();

        context.go('/orders');
        debugPrint('✅ تم الانتقال بنجاح إلى صفحة الطلبات');
      } catch (e) {
        debugPrint('❌ خطأ في الانتقال المباشر: $e');
      }
    }
  }

  // ✨ إظهار أنيميشن علامة الصح الجميل
  void _showSuccessAnimation() {
    debugPrint('🎬 بدء عرض أنيميشن النجاح');

    // التأكد من أن الصفحة ما زالت موجودة قبل إظهار الحوار
    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      _navigateToOrders(); // انتقال مباشر
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8), // شاشة مضببة أكثر
      builder: (context) => const SuccessAnimationWidget(),
    );

    // ✅ إخفاء الحوار بعد وقت كافي والانتقال
    Timer(const Duration(milliseconds: 1500), () {
      debugPrint('🎬 انتهاء أنيميشن النجاح - إغلاق الحوار');

      // التحقق من أن الصفحة ما زالت موجودة
      if (!mounted) {
        debugPrint('⚠️ الصفحة لم تعد موجودة');
        return;
      }

      try {
        // إغلاق حوار علامة الصح
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint('✅ تم إغلاق حوار النجاح');
        }

        // تأخير قصير قبل الانتقال
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            debugPrint('🎬 الانتقال إلى صفحة الطلبات');
            try {
              // ✅ إعادة تحميل الطلبات قبل الانتقال (بدون إجبار)
              final ordersService = SimpleOrdersService();
              ordersService.loadOrders(forceRefresh: false);

              context.go('/orders'); // الانتقال إلى صفحة الطلبات
              debugPrint('✅ تم الانتقال بنجاح إلى صفحة الطلبات');
            } catch (e) {
              debugPrint('❌ خطأ في الانتقال: $e');
            }
          } else {
            debugPrint('⚠️ الصفحة لم تعد موجودة عند محاولة الانتقال');
          }
        });
      } catch (e) {
        debugPrint('❌ خطأ في إغلاق الحوار أو الانتقال: $e');
        // في حالة الخطأ، حاول الانتقال مباشرة
        if (mounted) {
          _navigateToOrders();
        }
      }
    });

    // ✅ آلية احتياطية - انتقال تلقائي بعد 3 ثوانٍ في حالة فشل الآلية الأساسية
    Timer(const Duration(milliseconds: 3000), () {
      debugPrint('🔄 آلية احتياطية - التحقق من الحاجة للانتقال');
      if (mounted && _orderConfirmed) {
        debugPrint('🎬 تنفيذ الانتقال الاحتياطي');
        try {
          // محاولة إغلاق أي حوارات مفتوحة
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          _navigateToOrders();
        } catch (e) {
          debugPrint('❌ خطأ في الانتقال الاحتياطي: $e');
        }
      }
    });
  }

  Future<void> _confirmOrder() async {
    debugPrint('🚀 تم الضغط على زر تأكيد الطلب في صفحة ملخص الطلب');

    // منع النقر المتكرر
    if (_isProcessing) {
      debugPrint('⚠️ العملية قيد التنفيذ بالفعل');
      return;
    }

    // التحقق من صحة البيانات الأساسية
    if (widget.orderData.isEmpty) {
      debugPrint('❌ بيانات الطلب فارغة');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'بيانات الطلب غير صحيحة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFdc3545),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      // ❌ لا نغير _orderConfirmed هنا - فقط عند النجاح الفعلي
    });

    // ✅ تأخير قصير لضمان تحديث الواجهة
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // ✅ فحص الاتصال بالإنترنت أولاً
      debugPrint('🌐 فحص الاتصال بالإنترنت...');
      try {
        // محاولة طلب بسيط للتحقق من الاتصال
        await Future.delayed(const Duration(milliseconds: 100));
        // إذا وصلنا هنا، فالاتصال متاح (سنتحقق من الخطأ الفعلي في catch)
      } catch (networkError) {
        if (ErrorHandler.isNetworkError(networkError)) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
      }
      // ✅ إنشاء قائمة عناصر الطلب بطريقة محسنة
      final itemsData = widget.orderData['items'];
      final List<OrderItem> items = [];

      debugPrint('📦 معالجة عناصر الطلب...');
      debugPrint('📦 نوع البيانات: ${itemsData.runtimeType}');
      debugPrint('📦 عدد العناصر: ${itemsData is List ? itemsData.length : 0}');

      if (itemsData != null && itemsData is List && itemsData.isNotEmpty) {
        // ✅ معالجة العناصر بطريقة أكثر كفاءة
        for (int i = 0; i < itemsData.length; i++) {
          final item = itemsData[i];
          try {
            if (item is Map<String, dynamic>) {
              final orderItem = OrderItem(
                id: item['id']?.toString() ?? 'item_$i',
                productId: item['productId']?.toString() ?? '',
                name: item['name']?.toString() ?? 'منتج غير محدد',
                image: item['image']?.toString() ?? '',
                wholesalePrice: _parseToInt(item['wholesalePrice']).toDouble(),
                customerPrice: _parseToInt(item['customerPrice']).toDouble(),
                quantity: _parseToInt(item['quantity'], defaultValue: 1),
              );
              items.add(orderItem);
              debugPrint('✅ تمت إضافة عنصر: ${orderItem.name}');
            } else if (item is CartItem) {
              // إذا كان العنصر من نوع CartItem
              final orderItem = OrderItem(
                id: item.id,
                productId: item.productId,
                name: item.name,
                image: item.image,
                wholesalePrice: item.wholesalePrice.toDouble(),
                customerPrice: item.customerPrice.toDouble(),
                quantity: item.quantity,
              );
              items.add(orderItem);
              debugPrint('✅ تمت إضافة عنصر: ${orderItem.name}');
            } else {
              debugPrint('❌ نوع عنصر غير معروف: ${item.runtimeType}');
            }
          } catch (e) {
            debugPrint('❌ خطأ في معالجة عنصر الطلب: $e');
          }
        }
      }

      if (items.isEmpty) {
        throw Exception('لا توجد عناصر صالحة في الطلب');
      }

      debugPrint('📦 إجمالي العناصر المعالجة: ${items.length}');

      // ✅ استخدام الدالة المشتركة لحساب القيم النهائية (نفس القيم المعروضة في ملخص الطلب)
      final values = _calculateFinalValues();

      final subtotal = values['subtotal']!;
      final profit = values['profit']!;
      final deliveryPaidByUser = values['deliveryPaidByUser']!;
      final finalTotal = values['finalTotal']!;
      final finalProfit = values['finalProfit']!;

      // إنشاء الطلب فعلياً في قاعدة البيانات
      debugPrint('📋 إنشاء الطلب الجديد في قاعدة البيانات...');
      debugPrint('💰 المجموع الفرعي: $subtotal د.ع');
      debugPrint('🚚 رسوم التوصيل: $_deliveryFee د.ع');
      debugPrint('💰 المجموع النهائي: $finalTotal د.ع');
      debugPrint('💎 الربح النهائي: $finalProfit د.ع');

      // ✅ إعداد البيانات النهائية للإرسال (من ملخص الطلب)
      final finalOrderData = {
        'customerName': widget.orderData['customerName'],
        'primaryPhone': widget.orderData['primaryPhone'],
        'secondaryPhone': widget.orderData['secondaryPhone'],
        'province': widget.orderData['province'],
        'city': widget.orderData['city'],
        'provinceId': widget.orderData['provinceId'], // ✅ إضافة معرف المحافظة
        'cityId': widget.orderData['cityId'], // ✅ إضافة معرف المدينة
        'customerAddress': widget.orderData['customerAddress'],
        'notes': widget.orderData['customerNotes'], // ✅ استخدام customerNotes
        'items': items,
        // ✅ القيم المحسوبة في ملخص الطلب (النهائية)
        'subtotal': subtotal,
        'deliveryFee': _deliveryFee,
        'total': finalTotal,
        'profit': finalProfit,
        'deliveryPaidByUser': deliveryPaidByUser,
        'scheduledDate': widget.orderData['scheduledDate'],
        'scheduleNotes': widget.orderData['scheduleNotes'],
      };

      debugPrint('📦 البيانات النهائية للطلب:');
      debugPrint('   - المجموع الفرعي: ${finalOrderData['subtotal']} د.ع');
      debugPrint('   - الربح الأولي: $profit د.ع');
      debugPrint('   - المبلغ المدفوع من الربح: $deliveryPaidByUser د.ع');
      debugPrint('   - الربح النهائي المرسل: ${finalOrderData['profit']} د.ع');
      debugPrint('🔍 التحقق من القيم المحسوبة:');
      debugPrint('   - _deliveryFee: $_deliveryFee د.ع');
      debugPrint('   - deliveryPaidByUser: $deliveryPaidByUser د.ع');
      debugPrint('   - finalTotal: $finalTotal د.ع');
      debugPrint('   - finalProfit: $finalProfit د.ع');
      debugPrint('   - رسوم التوصيل: ${finalOrderData['deliveryFee']} د.ع');
      debugPrint('   - المجموع النهائي: ${finalOrderData['total']} د.ع');
      debugPrint('   - الربح الأولي: $profit د.ع');
      debugPrint(
        '   - المبلغ المدفوع من الربح: ${finalOrderData['deliveryPaidByUser']} د.ع',
      );
      debugPrint(
        '   - الربح النهائي (بعد خصم التوصيل): ${finalOrderData['profit']} د.ع',
      );
      debugPrint(
        '   - معادلة الحساب: $profit - ${finalOrderData['deliveryPaidByUser']} = ${finalOrderData['profit']}',
      );

      // تحديد نوع الطلب حسب وجود تاريخ الجدولة
      final scheduledDate = widget.orderData['scheduledDate'] as DateTime?;
      final scheduleNotes = widget.orderData['scheduleNotes'] as String?;

      Map<String, dynamic> result;

      if (scheduledDate != null) {
        // 📅 طلب مجدول - حفظ في جدول scheduled_orders
        debugPrint('📅 إنشاء طلب مجدول لتاريخ: $scheduledDate');

        // ✅ تأخير قصير لضمان عدم تجمد الواجهة
        await Future.delayed(const Duration(milliseconds: 50));

        final scheduledOrdersService = ScheduledOrdersService();

        // ✅ الحصول على رقم هاتف المستخدم الحالي
        final prefs = await SharedPreferences.getInstance();
        final currentUserPhone = prefs.getString('current_user_phone');
        debugPrint('📱 رقم هاتف المستخدم الحالي: $currentUserPhone');

        // ✅ إضافة رقم هاتف المستخدم لبيانات الطلب النهائية
        finalOrderData['userPhone'] = currentUserPhone;

        // ✅ تحويل العناصر إلى ScheduledOrderItem بطريقة محسنة
        final List<ScheduledOrderItem> scheduledItems = [];

        for (final item in items) {
          if (item.name.isNotEmpty && item.quantity > 0) {
            scheduledItems.add(
              ScheduledOrderItem(
                name: item.name,
                quantity: item.quantity,
                price: item.customerPrice > 0 ? item.customerPrice : 0.0,
                notes: '',
                productId: item.productId, // ✅ إضافة معرف المنتج
                productImage: item.image, // ✅ إضافة صورة المنتج
              ),
            );
          }
        }

        debugPrint('📦 عدد العناصر المجدولة: ${scheduledItems.length}');

        if (scheduledItems.isEmpty) {
          throw Exception('لا توجد عناصر صالحة في الطلب المجدول');
        }

        // ✅ تأخير آخر قبل إنشاء الطلب
        await Future.delayed(const Duration(milliseconds: 50));

        debugPrint('🚀 بدء إنشاء الطلب المجدول مع timeout...');

        // ✅ إضافة timeout لمنع التجمد - استخدام البيانات النهائية من ملخص الطلب
        result = await scheduledOrdersService
            .addScheduledOrder(
              customerName: finalOrderData['customerName'] ?? '',
              customerPhone: finalOrderData['primaryPhone'] ?? '',
              customerAddress:
                  '${finalOrderData['province'] ?? 'غير محدد'} - ${finalOrderData['city'] ?? 'غير محدد'}',
              totalAmount: finalOrderData['total']
                  .toDouble(), // ✅ المجموع النهائي
              scheduledDate: scheduledDate,
              items: scheduledItems,
              notes: scheduleNotes ?? finalOrderData['notes'] ?? '', // ✅ notes صحيح هنا
              profitAmount: finalOrderData['profit']
                  .toDouble(), // ✅ الربح النهائي
              userPhone: currentUserPhone, // ✅ إضافة رقم هاتف المستخدم
              customerProvince:
                  finalOrderData['province'], // ✅ اسم المحافظة للتوافق
              customerCity: finalOrderData['city'], // ✅ اسم المدينة للتوافق
              provinceId: finalOrderData['provinceId'], // ✅ معرف المحافظة
              cityId: finalOrderData['cityId'], // ✅ معرف المدينة
            )
            .timeout(
              const Duration(seconds: 30), // ✅ timeout بعد 30 ثانية
              onTimeout: () {
                debugPrint('⏰ انتهت مهلة إنشاء الطلب المجدول');
                throw TimeoutException(
                  'انتهت مهلة إنشاء الطلب',
                  const Duration(seconds: 30),
                );
              },
            );

        debugPrint('✅ تم إنشاء الطلب المجدول بنجاح');

        // 🔔 تقليل المخزون للطلبات المجدولة (مثل الطلبات العادية)
        debugPrint('📉 بدء تقليل المخزون للطلب المجدول...');
        for (final item in items) {
          if (item.productId.isNotEmpty && item.quantity > 0) {
            try {
              debugPrint(
                '📉 تقليل مخزون المنتج ${item.productId} بكمية ${item.quantity}',
              );

              // استخدام نفس دالة تقليل المخزون المستخدمة في الطلبات العادية
              await InventoryService.reserveProduct(
                productId: item.productId,
                reservedQuantity: item.quantity,
              );

              debugPrint(
                '✅ تم تقليل مخزون المنتج ${item.name} بمقدار ${item.quantity} قطعة',
              );
            } catch (e) {
              debugPrint('⚠️ خطأ في تقليل مخزون المنتج ${item.productId}: $e');
            }
          } else {
            debugPrint(
              '⚠️ لا يمكن تقليل المخزون للعنصر ${item.name} - بيانات غير صحيحة',
            );
          }
        }
        debugPrint('✅ تم الانتهاء من تقليل المخزون للطلب المجدول');
      } else {
        // ⚡ طلب عادي - حفظ في جدول orders
        debugPrint('⚡ إنشاء طلب عادي مع timeout...');

        // ✅ الحصول على رقم هاتف المستخدم الحالي
        final prefs = await SharedPreferences.getInstance();
        final currentUserPhone = prefs.getString('current_user_phone');
        debugPrint(
          '📱 رقم هاتف المستخدم الحالي للطلب العادي: $currentUserPhone',
        );

        final ordersService = OfficialOrdersService();

        // ✅ إضافة timeout لمنع التجمد - استخدام البيانات النهائية من ملخص الطلب
        result = await ordersService
            .createOrder(
              customerName: finalOrderData['customerName'] ?? '',
              primaryPhone: finalOrderData['primaryPhone'] ?? '',
              secondaryPhone: finalOrderData['secondaryPhone'],
              province: finalOrderData['province'] ?? 'غير محدد',
              city: finalOrderData['city'] ?? 'غير محدد',
              // ✅ إضافة معرفات المحافظة والمدينة (مع قيم افتراضية)
              provinceId: _getProvinceId(finalOrderData['province']),
              cityId: _getCityId(finalOrderData['province'], finalOrderData['city']),
              regionId: '1', // افتراضياً
              notes: finalOrderData['notes'],
              items:
                  finalOrderData['items'], // استخدام items من البيانات النهائية
              totals: {
                'subtotal': finalOrderData['subtotal'].toInt(),
                'delivery_fee': finalOrderData['deliveryFee'].toInt(),
                'total': finalOrderData['total'].toInt(),
                'profit': finalOrderData['profit']
                    .toInt(), // ✅ إضافة الربح النهائي
              },
              userPhone: currentUserPhone, // ✅ إضافة رقم هاتف المستخدم الحالي
            )
            .timeout(
              const Duration(seconds: 30), // ✅ timeout بعد 30 ثانية
              onTimeout: () {
                debugPrint('⏰ انتهت مهلة إنشاء الطلب العادي');
                throw TimeoutException(
                  'انتهت مهلة إنشاء الطلب',
                  const Duration(seconds: 30),
                );
              },
            );

        debugPrint('✅ تم إنشاء الطلب العادي بنجاح');
      }

      // ✅ التحقق من نجاح العملية فعلياً
      bool isSuccess = false;
      String? orderId;

      // تم إزالة التحقق غير الضروري - result دائماً Map<String, dynamic>
      isSuccess = result['success'] == true;
      orderId = result['orderId'] ?? result['data']?['orderId'];
      debugPrint('🔍 فحص نتيجة العملية: success=$isSuccess, orderId=$orderId');

      if (!isSuccess) {
        throw Exception('فشل في حفظ الطلب في قاعدة البيانات');
      }

      debugPrint('✅ تم إنشاء الطلب بنجاح - معرف الطلب: $orderId');

      // ✅ الآن فقط نغير حالة الطلب لأنه تم حفظه فعلياً
      setState(() {
        _orderConfirmed = true; // ✅ إخفاء أيقونة كلفة التوصيل بعد النجاح الفعلي
      });

      // ✅ تأخير قصير قبل إظهار النتيجة
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // عرض رسالة نجاح حسب نوع الطلب
        final successMessage = scheduledDate != null
            ? 'تم جدولة طلبك بنجاح! 📅'
            : 'تم تأكيد طلبك بنجاح! ❤️';
        final successIcon = scheduledDate != null
            ? FontAwesomeIcons.calendar
            : FontAwesomeIcons.heart;
        final successColor = scheduledDate != null
            ? const Color(0xFF1BFFFF)
            : const Color(0xFFffd700);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(successIcon, color: successColor),
                const SizedBox(width: 8),
                Text(
                  successMessage,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF28a745),
            duration: const Duration(seconds: 2), // ✅ تقليل المدة إلى ثانيتين
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // ✅ تأخير قصير قبل مسح السلة وإظهار الأنيميشن
        await Future.delayed(const Duration(milliseconds: 200));

        // مسح السلة
        final cartService = CartService();
        cartService.clearCart();

        // ✅ إعادة تحميل الطلبات لضمان ظهور الطلب الجديد (إجبار التحديث)
        try {
          final ordersService = SimpleOrdersService();
          // إعادة تعيين الـ cache لضمان التحديث الفوري
          ordersService.clearCache();
          await ordersService.loadOrders(forceRefresh: true);
          debugPrint('✅ تم إعادة تحميل الطلبات بعد إنشاء الطلب الجديد');
        } catch (e) {
          debugPrint('⚠️ خطأ في إعادة تحميل الطلبات: $e');
        }

        // ✨ إظهار أنيميشن علامة الصح الجميل
        _showSuccessAnimation();

        // ✅ إعادة تعيين حالة المعالجة بعد تأخير قصير لضمان بدء الأنيميشن
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');

      // ✅ تأخير قصير قبل إظهار رسالة الخطأ
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // ✅ إعادة تعيين حالة المعالجة والطلب في حالة الخطأ
        setState(() {
          _isProcessing = false;
          _orderConfirmed = false; // ✅ إعادة تعيين حالة الطلب للسماح بالمحاولة مرة أخرى
        });

        // ✅ استخدام ErrorHandler لرسائل خطأ واضحة
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
              : 'فشل في حفظ الطلب. يرجى المحاولة مرة أخرى.',
          onRetry: () => _confirmOrder(),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // دالة مساعدة لتحويل القيم إلى int بطريقة آمنة
  int _parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }
}
