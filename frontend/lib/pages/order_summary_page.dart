import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // ✅ For ImageFilter

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_item.dart';
import '../models/scheduled_order.dart';
import '../providers/theme_provider.dart';
import '../services/cart_service.dart';
import '../services/inventory_service.dart';
import '../services/official_orders_service.dart';
import '../services/order_calculator_service.dart'; // 🧮 خدمة الحساب من السيرفر
import '../services/scheduled_orders_service.dart';
import '../services/simple_orders_service.dart';
import '../widgets/app_background.dart';
import '../widgets/error_animation_widget.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../widgets/success_animation_widget.dart';
import '../widgets/premium_slide_to_submit.dart';

class OrderSummaryPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderSummaryPage({super.key, required this.orderData});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _isProcessing = false;
  String _processingStatus = ''; // حالة الإرسال للعرض
  int _currentAttempt = 0; // المحاولة الحالية

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
      'ميسان': '19',
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
  int _deliveryFee = 5000; // ✅ رسوم التوصيل التي اختارها المستخدم (السلايدر)
  List<int> _deliveryOptions = [5000, 4000, 3000, 2000, 1000, 0];

  // 🧮 بيانات الحساب من السيرفر
  OrderCalculation? _serverCalculation;
  bool _isCalculating = false;
  String? _calculationError;
  Timer? _calculateDebounce; // لتأخير استدعاء API عند تغيير السلايدر

  @override
  void initState() {
    super.initState();
    // تحديد سعر التوصيل وخيارات السلايدر بناءً على المحافظة المختارة
    final provinceName = widget.orderData['province'] as String?;
    _deliveryFee = _getDeliveryFeeByProvince(provinceName);
    _deliveryOptions = _getDeliveryOptionsByProvince(provinceName);
    debugPrint('🚚 تم تحديد سعر التوصيل للمحافظة "$provinceName": $_deliveryFee د.ع');
    debugPrint('🎛️ خيارات السلايدر: $_deliveryOptions');

    // 🧮 استدعاء API لحساب القيم من السيرفر
    _calculateFromServer();
  }

  @override
  void dispose() {
    _calculateDebounce?.cancel();
    super.dispose();
  }

  /// 🧮 استدعاء API لحساب القيم من السيرفر
  Future<void> _calculateFromServer() async {
    if (_isCalculating) return;

    setState(() {
      _isCalculating = true;
      _calculationError = null;
    });

    try {
      // تحضير بيانات المنتجات
      final itemsData = widget.orderData['items'] as List?;
      final items = <Map<String, dynamic>>[];

      if (itemsData != null) {
        for (final item in itemsData) {
          if (item is Map) {
            items.add({
              'product_id': item['productId']?.toString() ?? '',
              'quantity': item['quantity'] ?? 1,
              'customer_price': item['customerPrice'] ?? 0,
            });
          }
        }
      }

      debugPrint('🧮 استدعاء /calculate مع ${items.length} منتج');

      final result = await OrderCalculatorService.calculate(
        items: items,
        province: widget.orderData['province'],
        provinceId: widget.orderData['provinceId']?.toString(),
        city: widget.orderData['city'],
        cityId: widget.orderData['cityId']?.toString(),
        sliderDeliveryFee: _deliveryFee,
      );

      if (mounted) {
        setState(() {
          _serverCalculation = result;
          _isCalculating = false;
          if (!result.success) {
            _calculationError = result.error;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحساب: $e');
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _calculationError = e.toString();
        });
      }
    }
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة ملخص الطلب...');

    // إعادة حساب من السيرفر
    await _calculateFromServer();

    setState(() {
      if (!_orderConfirmed) {
        _isProcessing = false;
      }
    });

    debugPrint('✅ تم تحديث بيانات صفحة ملخص الطلب');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: PullToRefreshWrapper(
          onRefresh: _refreshData,
          refreshMessage: 'تم تحديث ملخص الطلب',
          child: Column(
            children: [
              // المحتوى القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero, // تصفير الهوامش للتحكم الداخلي
                  child: Column(
                    children: [
                      const SizedBox(height: 25), // مساحة علوية
                      _buildHeader(isDark), // ✅ الشريط العلوي أصبح هنا (يتحرك مع الصفحة)
                      const SizedBox(height: 20),

                      // باقي المحتوى مع هوامش جانبية
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildDeliveryFeeSlider(isDark),
                            const SizedBox(height: 20),
                            _buildOrderSummary(isDark),
                            const SizedBox(height: 100), // مساحة للزر الثابت
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 الشريط العلوي
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع - يرجع لصفحة بيانات العميل
          GestureDetector(
            onTap: () {
              // الرجوع لصفحة بيانات العميل لتعديل البيانات
              // استخدام pop للرجوع للصفحة السابقة (صفحة بيانات العميل)
              context.pop();
            },
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
            'ملخص الطلب',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // ✅ حذف أيقونة السيارة
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDeliveryFeeSlider(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✨ تصميم نظيف واحترافي
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white, // خلفية بيضاء نظيفة
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFFe6b31e).withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.15), // حد رمادي فاتح
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان السلايدر
          Text(
            'دفع كلفة التوصيل من الربح',
            style: GoogleFonts.cairo(
              color: isDark ? const Color(0xFFffd700) : const Color(0xFF8B6914), // ذهبي داكن في النهار
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          // السلايدر
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFffd700),
              inactiveTrackColor: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.2),
              thumbColor: const Color(0xFFffd700),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: const Color(0xFFffd700).withValues(alpha: 0.2),
              trackHeight: 6,
              valueIndicatorColor: const Color(0xFFffd700),
              valueIndicatorTextStyle: GoogleFonts.cairo(color: const Color(0xFF1a1a2e), fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: _deliveryOptions.indexOf(_deliveryFee).toDouble(),
              min: 0,
              max: (_deliveryOptions.length - 1).toDouble(),
              divisions: _deliveryOptions.length - 1,
              onChanged: (value) {
                final newFee = _deliveryOptions[value.round()];

                // 🧮 استخدام الربح من السيرفر أو fallback
                int profitInitial = 0;
                int baseDeliveryFee = _getDeliveryFeeByProvince(widget.orderData['province'] as String?);

                if (_serverCalculation != null && _serverCalculation!.success) {
                  profitInitial = _serverCalculation!.profitInitial;
                  baseDeliveryFee = _serverCalculation!.baseDeliveryFee;
                } else {
                  // Fallback
                  final totalsData = widget.orderData['totals'];
                  if (totalsData != null) {
                    if (totalsData is Map<String, int>) {
                      profitInitial = totalsData['profit'] ?? 0;
                    } else if (totalsData is Map<String, dynamic>) {
                      profitInitial = (totalsData['profit'] as num?)?.toInt() ?? 0;
                    }
                  }
                }

                final deliveryPaidByUser = baseDeliveryFee - newFee;
                final newProfit = profitInitial - deliveryPaidByUser;

                // ✅ منع التقليل إذا وصل الربح لـ 0 أو أقل
                if (newProfit >= 0) {
                  setState(() {
                    _deliveryFee = newFee;
                  });

                  // 🧮 استدعاء API لإعادة الحساب (مع debounce)
                  _calculateDebounce?.cancel();
                  _calculateDebounce = Timer(const Duration(milliseconds: 300), () {
                    _calculateFromServer();
                  });
                } else {
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

              // 🧮 استخدام الربح من السيرفر أو fallback
              int profitInitial = 0;
              int baseDeliveryFee = _getDeliveryFeeByProvince(widget.orderData['province'] as String?);

              if (_serverCalculation != null && _serverCalculation!.success) {
                profitInitial = _serverCalculation!.profitInitial;
                baseDeliveryFee = _serverCalculation!.baseDeliveryFee;
              } else {
                final totalsData = widget.orderData['totals'];
                if (totalsData != null) {
                  if (totalsData is Map<String, int>) {
                    profitInitial = totalsData['profit'] ?? 0;
                  } else if (totalsData is Map<String, dynamic>) {
                    profitInitial = (totalsData['profit'] as num?)?.toInt() ?? 0;
                  }
                }
              }

              final deliveryPaidByUser = baseDeliveryFee - fee;
              final newProfit = profitInitial - deliveryPaidByUser;
              final isDisabled = newProfit < 0;

              return GestureDetector(
                onTap: () {
                  if (isDisabled) {
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
                    return;
                  }

                  setState(() => _deliveryFee = fee);

                  // 🧮 استدعاء API لإعادة الحساب
                  _calculateDebounce?.cancel();
                  _calculateDebounce = Timer(const Duration(milliseconds: 300), () {
                    _calculateFromServer();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          : (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    fee == 0 ? 'مجاني' : _formatPrice(fee),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDisabled
                          ? Colors.red.withValues(alpha: 0.7)
                          : isSelected
                          ? const Color(0xFFffd700)
                          : (isDark ? Colors.white70 : Colors.black87),
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

  // ✅ دالة مشتركة للحصول على القيم النهائية (من السيرفر أو fallback)
  Map<String, int> _calculateFinalValues() {
    // 🧮 إذا لدينا حساب من السيرفر، نستخدمه
    if (_serverCalculation != null && _serverCalculation!.success) {
      final calc = _serverCalculation!;
      return {
        'subtotal': calc.customerTotal, // مجموع سعر العميل
        'profit': calc.profitInitial,
        'deliveryFee': calc.deliveryFee,
        'baseDeliveryFee': calc.baseDeliveryFee,
        'deliveryPaidByUser': calc.deliveryPaidFromProfit,
        'fullTotal': calc.totalWaseet, // المبلغ الكامل للوسيط
        'customerTotal': calc.totalCustomer, // المبلغ المدفوع من العميل
        'finalProfit': calc.profitFinal,
      };
    }

    // ⚠️ Fallback: استخدام البيانات المحلية (في حالة فشل السيرفر)
    final totalsData = widget.orderData['totals'];
    Map<String, int> totals = <String, int>{};

    if (totalsData != null) {
      if (totalsData is Map<String, int>) {
        totals = totalsData;
      } else if (totalsData is Map<String, dynamic>) {
        totals = totalsData.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    }

    final subtotal = totals['subtotal'] ?? 0;
    final profit = totals['profit'] ?? 0;
    final provinceName = widget.orderData['province'] as String?;
    final baseDeliveryFee = _getDeliveryFeeByProvince(provinceName);
    final deliveryPaidByUser = baseDeliveryFee - _deliveryFee;
    final fullTotal = subtotal + baseDeliveryFee;
    final customerTotal = subtotal + _deliveryFee;
    final finalProfit = math.max(0, profit - deliveryPaidByUser);

    return {
      'subtotal': subtotal,
      'profit': profit,
      'deliveryFee': _deliveryFee,
      'baseDeliveryFee': baseDeliveryFee,
      'deliveryPaidByUser': deliveryPaidByUser,
      'fullTotal': fullTotal,
      'customerTotal': customerTotal,
      'finalProfit': finalProfit,
    };
  }

  Widget _buildOrderSummary(bool isDark) {
    final values = _calculateFinalValues();

    final subtotal = values['subtotal']!;
    final customerTotal = values['customerTotal']!; // 💰 المبلغ المدفوع من العميل
    final finalProfit = values['finalProfit']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFFe6b31e).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // العنوان مع مؤشر التحميل
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ملخص الطلب',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFffd700) : const Color(0xFF1A1A1A),
                ),
              ),
              // 🧮 مؤشر تحميل عند الحساب من السيرفر
              if (_isCalculating) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? const Color(0xFFffd700) : Colors.blue,
                  ),
                ),
              ],
              // ✅ علامة من السيرفر
              if (_serverCalculation != null && _serverCalculation!.success && !_isCalculating) ...[
                const SizedBox(width: 10),
                Icon(Icons.verified, size: 18, color: Colors.green[400]),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // الصفوف
          _buildSummaryRow('المجموع الفرعي', subtotal),
          const SizedBox(height: 12),
          _buildSummaryRow('رسوم التوصيل', _deliveryFee),
          const SizedBox(height: 12),

          // الفاصل الرمادي الفاتح
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 12),

          _buildSummaryRow('المجموع النهائي', customerTotal, isTotal: true),
          const SizedBox(height: 16),

          // صندوق الربح - تصميم نظيف
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.green.withValues(alpha: 0.4) : Colors.green.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.coins, color: isDark ? Colors.green[300] : Colors.green[700], size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'ربحك:',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.green[300] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_formatPrice(finalProfit)} د.ع',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.green[300] : Colors.green[700],
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
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal
                  ? (isDark ? const Color(0xFFffd700) : const Color(0xFF1A1A1A))
                  : (isDark ? Colors.white70 : Colors.grey.withValues(alpha: 0.7)),
            ),
          ),
          Text(
            '${_formatPrice(amount)} د.ع',
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              color: isTotal
                  ? (isDark ? const Color(0xFFffd700) : const Color(0xFF1A1A1A))
                  : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    // ✅ إزالة الـ Container الخارجي بالكامل - فقط شريط السحب
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16), // هامش بسيط من الأسفل فقط
        child: Center(
          child: SizedBox(
            width: 250,
            child: _orderConfirmed
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        'تم تأكيد طلبك بنجاح ❤️',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ),
                  )
                : SlideToSubmitWidget(
                    text: "اسحب لتأكيد الطلب",
                    isEnabled: !_isProcessing,
                    isSubmitting: _isProcessing,
                    onSubmit: _confirmOrder,
                  ),
          ),
        ),
      ),
    );
  }

  // 🎯 الانتقال المباشر إلى صفحة المنتجات
  void _navigateToProducts() {
    debugPrint('🎬 الانتقال المباشر إلى صفحة المنتجات');
    if (mounted) {
      try {
        context.go('/products');
        debugPrint('✅ تم الانتقال بنجاح إلى صفحة المنتجات');
      } catch (e) {
        debugPrint('❌ خطأ في الانتقال المباشر: $e');
      }
    }
  }

  // ✨ إظهار أنيميشن النجاح
  void _showSuccessAnimation() {
    debugPrint('🎬 بدء عرض أنيميشن النجاح');

    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      _navigateToProducts();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const SuccessAnimationWidget(),
    );

    Timer(const Duration(milliseconds: 2000), () {
      debugPrint('🎬 انتهاء أنيميشن النجاح - إغلاق الحوار');

      if (!mounted) {
        debugPrint('⚠️ الصفحة لم تعد موجودة');
        return;
      }

      try {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint('✅ تم إغلاق حوار النجاح');
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            debugPrint('🎬 الانتقال إلى صفحة المنتجات');
            try {
              context.go('/products');
              debugPrint('✅ تم الانتقال بنجاح إلى صفحة المنتجات');
            } catch (e) {
              debugPrint('❌ خطأ في الانتقال: $e');
            }
          } else {
            debugPrint('⚠️ الصفحة لم تعد موجودة عند محاولة الانتقال');
          }
        });
      } catch (e) {
        debugPrint('❌ خطأ في إغلاق الحوار أو الانتقال: $e');
        if (mounted) {
          _navigateToProducts();
        }
      }
    });
  }

  // ❌ إظهار أنيميشن الخطأ
  void _showErrorAnimation() {
    debugPrint('🎬 بدء عرض أنيميشن الخطأ');

    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      _navigateToProducts();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const ErrorAnimationWidget(),
    );

    Timer(const Duration(milliseconds: 2000), () {
      debugPrint('🎬 انتهاء أنيميشن الخطأ - إغلاق الحوار');

      if (!mounted) {
        debugPrint('⚠️ الصفحة لم تعد موجودة');
        return;
      }

      try {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint('✅ تم إغلاق حوار الخطأ');
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            debugPrint('🎬 الانتقال إلى صفحة المنتجات');
            try {
              context.go('/products');
              debugPrint('✅ تم الانتقال بنجاح إلى صفحة المنتجات');
            } catch (e) {
              debugPrint('❌ خطأ في الانتقال: $e');
            }
          } else {
            debugPrint('⚠️ الصفحة لم تعد موجودة عند محاولة الانتقال');
          }
        });
      } catch (e) {
        debugPrint('❌ خطأ في إغلاق الحوار أو الانتقال: $e');
        if (mounted) {
          _navigateToProducts();
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
          _navigateToProducts();
        } catch (e) {
          debugPrint('❌ خطأ في الانتقال الاحتياطي: $e');
        }
      }
    });
  }

  // ❌ إظهار أنيميشن الخطأ مع رسالة مفصلة
  void _showErrorAnimationWithMessage(String errorMessage) {
    debugPrint('🎬 بدء عرض أنيميشن الخطأ مع رسالة: $errorMessage');

    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      return;
    }

    // تحديد رسالة مناسبة للمستخدم
    String userMessage = 'حدث خطأ أثناء إنشاء الطلب';
    if (errorMessage.contains('timeout') || errorMessage.contains('مهلة')) {
      userMessage = 'الإنترنت بطيء جداً - يرجى المحاولة مرة أخرى';
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('fetch') ||
        errorMessage.contains('connection')) {
      userMessage = 'لا يوجد اتصال بالإنترنت - يرجى التحقق من الاتصال';
    } else if (errorMessage.contains('server') || errorMessage.contains('500')) {
      userMessage = 'خطأ في الخادم - يرجى المحاولة لاحقاً';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // ✅ شفاف بالكامل
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // ✅ ضبابية 5 درجات
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.85), // ✅ أسود شفاف
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)), // إطار خفيف
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.circleExclamation, color: Color(0xFFdc3545), size: 55),
                  const SizedBox(height: 16),
                  Text(
                    'فشل إنشاء الطلب',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userMessage,
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _confirmOrder(); // إعادة المحاولة
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFffd700),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
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
                const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'بيانات الطلب غير صحيحة',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFdc3545),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'جاري تحضير الطلب...';
      _currentAttempt = 0;
    });

    // 🚀 النظام الذكي - لا timeout خارجي، النظام يدير نفسه
    try {
      await _createOrderInternal();

      // ✅ إذا وصلنا هنا، فالطلب تم إنشاؤه بنجاح
      debugPrint('✅ تم إنشاء الطلب بنجاح - لا أخطاء');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      debugPrint('🔍 نوع الخطأ: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _orderConfirmed = false;
          _processingStatus = '';
        });

        // ✨ إظهار أنيميشن الخطأ مع رسالة مفصلة
        _showErrorAnimationWithMessage(e.toString());
      }
    }
  }

  /// 📝 الدالة الداخلية لإنشاء الطلب
  Future<void> _createOrderInternal() async {
    try {
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
      final fullTotal = values['fullTotal']!; // 🎯 المبلغ الكامل للوسيط
      final customerTotal = values['customerTotal']!; // 💰 المبلغ المدفوع من العميل
      final finalProfit = values['finalProfit']!;

      // إنشاء الطلب فعلياً في قاعدة البيانات
      debugPrint('📋 إنشاء الطلب الجديد في قاعدة البيانات...');
      debugPrint('💰 المجموع الفرعي: $subtotal د.ع');
      debugPrint('🚚 رسوم التوصيل: $_deliveryFee د.ع');
      debugPrint('💰 المجموع الكامل (للوسيط): $fullTotal د.ع');
      debugPrint('💰 المجموع المدفوع (من العميل): $customerTotal د.ع');
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
        'total': customerTotal, // 💰 المبلغ المدفوع من العميل
        'waseetTotal': fullTotal, // 🎯 المبلغ الكامل للوسيط
        'profit': finalProfit,
        'deliveryPaidByUser': deliveryPaidByUser,
        'deliveryPaidFromProfit': deliveryPaidByUser, // ✅ إضافة المبلغ المدفوع من الربح
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
      debugPrint('   - fullTotal (للوسيط): $fullTotal د.ع');
      debugPrint('   - customerTotal (من العميل): $customerTotal د.ع');
      debugPrint('   - finalProfit: $finalProfit د.ع');

      // 🔍 تشخيص مفصل للربح
      debugPrint('🔍 === تشخيص مفصل للربح ===');
      debugPrint('   - profit (الأولي): $profit');
      debugPrint('   - deliveryPaidByUser: $deliveryPaidByUser');
      debugPrint('   - finalProfit (المحسوب): $finalProfit');
      debugPrint('   - finalOrderData[profit]: ${finalOrderData['profit']}');
      debugPrint('   - نوع finalOrderData[profit]: ${finalOrderData['profit'].runtimeType}');
      debugPrint('   - القيمة بعد toInt(): ${finalOrderData['profit'].toInt()}');

      debugPrint('   - رسوم التوصيل: ${finalOrderData['deliveryFee']} د.ع');
      debugPrint('   - المجموع النهائي: ${finalOrderData['total']} د.ع');
      debugPrint('   - الربح الأولي: $profit د.ع');
      debugPrint('   - المبلغ المدفوع من الربح: ${finalOrderData['deliveryPaidByUser']} د.ع');
      debugPrint('   - الربح النهائي (بعد خصم التوصيل): ${finalOrderData['profit']} د.ع');
      debugPrint('   - معادلة الحساب: $profit - ${finalOrderData['deliveryPaidByUser']} = ${finalOrderData['profit']}');

      // تحديد نوع الطلب حسب وجود تاريخ الجدولة
      final scheduledDate = widget.orderData['scheduledDate'] as DateTime?;
      final scheduleNotes = widget.orderData['scheduleNotes'] as String?;

      Map<String, dynamic> result;

      if (scheduledDate != null) {
        // 📅 طلب مجدول - حفظ في جدول scheduled_orders
        debugPrint('📅 إنشاء طلب مجدول لتاريخ: $scheduledDate');

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

        debugPrint('🚀 بدء إنشاء الطلب المجدول...');

        // ✅ إضافة timeout محسّن (30 ثانية) - استخدام البيانات النهائية من ملخص الطلب
        result = await scheduledOrdersService
            .addScheduledOrder(
              customerName: finalOrderData['customerName'] ?? '',
              customerPhone: finalOrderData['primaryPhone'] ?? '',
              customerAddress: '${finalOrderData['province'] ?? 'غير محدد'} - ${finalOrderData['city'] ?? 'غير محدد'}',
              totalAmount: finalOrderData['total'].toDouble(), // ✅ المجموع النهائي
              scheduledDate: scheduledDate,
              items: scheduledItems,
              notes: scheduleNotes ?? finalOrderData['notes'] ?? '', // ✅ notes صحيح هنا
              profitAmount: finalOrderData['profit'].toDouble(), // ✅ الربح النهائي
              userPhone: currentUserPhone, // ✅ إضافة رقم هاتف المستخدم
              customerProvince: finalOrderData['province'], // ✅ اسم المحافظة للتوافق
              customerCity: finalOrderData['city'], // ✅ اسم المدينة للتوافق
              provinceId: finalOrderData['provinceId'], // ✅ معرف المحافظة
              cityId: finalOrderData['cityId'], // ✅ معرف المدينة
            )
            .timeout(
              const Duration(seconds: 30), // ✅ timeout محسّن بعد 30 ثانية
              onTimeout: () {
                debugPrint('⏰ انتهت مهلة إنشاء الطلب المجدول (30 ثانية)');
                throw TimeoutException('انتهت مهلة إنشاء الطلب المجدول', const Duration(seconds: 30));
              },
            );

        debugPrint('✅ تم إنشاء الطلب المجدول بنجاح');

        // 🔔 تقليل المخزون للطلبات المجدولة (مثل الطلبات العادية)
        debugPrint('📉 بدء تقليل المخزون للطلب المجدول...');
        for (final item in items) {
          if (item.productId.isNotEmpty && item.quantity > 0) {
            try {
              debugPrint('📉 تقليل مخزون المنتج ${item.productId} بكمية ${item.quantity}');

              // استخدام نفس دالة تقليل المخزون المستخدمة في الطلبات العادية
              await InventoryService.reserveProduct(productId: item.productId, reservedQuantity: item.quantity);

              debugPrint('✅ تم تقليل مخزون المنتج ${item.name} بمقدار ${item.quantity} قطعة');
            } catch (e) {
              debugPrint('⚠️ خطأ في تقليل مخزون المنتج ${item.productId}: $e');
            }
          } else {
            debugPrint('⚠️ لا يمكن تقليل المخزون للعنصر ${item.name} - بيانات غير صحيحة');
          }
        }
        debugPrint('✅ تم الانتهاء من تقليل المخزون للطلب المجدول');
      } else {
        // ⚡ طلب عادي - حفظ في جدول orders
        debugPrint('⚡ إنشاء طلب عادي مع timeout...');

        // ✅ الحصول على رقم هاتف المستخدم الحالي
        final prefs = await SharedPreferences.getInstance();
        final currentUserPhone = prefs.getString('current_user_phone');
        debugPrint('📱 رقم هاتف المستخدم الحالي للطلب العادي: $currentUserPhone');

        final ordersService = OfficialOrdersService();

        // 🚀 النظام الذكي - لا timeout خارجي، النظام يدير نفسه
        result = await ordersService.createOrder(
          customerName: finalOrderData['customerName'] ?? '',
          primaryPhone: finalOrderData['primaryPhone'] ?? '',
          secondaryPhone: finalOrderData['secondaryPhone'],
          province: finalOrderData['province'] ?? 'غير محدد',
          city: finalOrderData['city'] ?? 'غير محدد',
          // ✅ استخدام المعرفات الفعلية من بيانات الطلب (من شركة الوسيط)
          provinceId: finalOrderData['provinceId']?.toString() ?? _getProvinceId(finalOrderData['province']),
          cityId:
              finalOrderData['cityId']?.toString() ?? _getCityId(finalOrderData['province'], finalOrderData['city']),
          regionId: widget.orderData['regionId']?.toString() ?? '1', // استخدام regionId من البيانات الأصلية
          notes: finalOrderData['notes'],
          items: finalOrderData['items'], // استخدام items من البيانات النهائية
          totals: {
            'subtotal': finalOrderData['subtotal'].toInt(),
            'delivery_fee': finalOrderData['deliveryFee'].toInt(),
            'total': finalOrderData['total'].toInt(),
            'profit': finalOrderData['profit'].toInt(),
            'deliveryPaidFromProfit': (finalOrderData['deliveryPaidFromProfit'] ?? 0)
                .toInt(), // ✅ المبلغ المخصوم من الربح
          },
          userPhone: currentUserPhone, // ✅ إضافة رقم هاتف المستخدم الحالي
          // 🚀 callback لتحديث حالة الإرسال في الواجهة
          onStatusChange: (status, attempt) {
            if (mounted) {
              setState(() {
                _processingStatus = status;
                _currentAttempt = attempt;
              });
            }
          },
        );

        debugPrint('✅ تم إنشاء الطلب العادي بنجاح');
      }

      // ✅ استخراج معرف الطلب من جميع الأماكن الممكنة
      String? orderId = result['orderId'] ?? result['data']?['orderId'] ?? result['data']?['id'];

      debugPrint('🔍 === استخراج معرف الطلب ===');
      debugPrint('   - نوع result: ${result.runtimeType}');
      debugPrint('   - result.keys: ${result.keys}');
      debugPrint('   - result[orderId]: ${result['orderId']}');
      debugPrint('   - result[data]: ${result['data']}');
      debugPrint('   - result[data][orderId]: ${result['data']?['orderId']}');
      debugPrint('   - result[data][id]: ${result['data']?['id']}');
      debugPrint('   - معرف الطلب النهائي: $orderId');

      if (orderId == null || orderId.isEmpty) {
        debugPrint('❌ فشل في استخراج معرف الطلب من الاستجابة');
        debugPrint('📋 الاستجابة الكاملة: $result');
        throw Exception('فشل في استخراج معرف الطلب من الاستجابة');
      }

      debugPrint('✅ تم إنشاء الطلب بنجاح - معرف الطلب: $orderId');
      debugPrint('✅ تم إنشاء الطلب بنجاح - لا أخطاء');

      // ✅ تحديث حالة الطلب
      debugPrint('🔄 تحديث حالة الطلب إلى confirmed...');
      setState(() {
        _orderConfirmed = true;
      });

      // ✅ مسح السلة فوراً
      final cartService = CartService();
      cartService.clearCart();

      if (mounted) {
        // 🎉 الطلب نجح بالفعل! عرض رسالة النجاح فوراً
        debugPrint('🎉 عرض أنيميشن النجاح فوراً - الطلب تم إنشاؤه بنجاح');
        _showSuccessAnimation();

        // ✅ إعادة تحميل الطلبات في الخلفية (بدون انتظار - لا تأثر على المستخدم)
        final ordersService = SimpleOrdersService();
        ordersService.clearCache();
        ordersService
            .loadOrders(forceRefresh: true)
            .then((_) {
              debugPrint('✅ تم إعادة تحميل الطلبات في الخلفية');
            })
            .catchError((e) {
              debugPrint('⚠️ خطأ في إعادة تحميل الطلبات (غير مهم): $e');
            });

        // ✅ إعادة تعيين حالة المعالجة
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      debugPrint('❌ خطأ داخلي في إنشاء الطلب: $e');
      // إعادة رمي الخطأ ليتم التعامل معه في الـ wrapper الخارجي
      rethrow;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
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
