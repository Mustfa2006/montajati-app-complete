import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

class EditOrderPage extends StatefulWidget {
  final String orderId;
  final bool isScheduled;

  const EditOrderPage({super.key, required this.orderId, this.isScheduled = false});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  // تم إزالة _order غير المستخدم
  bool _isLoading = true;
  String? _error;

  // Controllers للحقول
  final _customerNameController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  // متغيرات خاصة بالطلبات المجدولة
  DateTime? _selectedScheduledDate;

  // ✅ متغيرات المحافظات والمدن (مثل صفحة معلومات العميل)
  final List<Map<String, dynamic>> _provinces = [];
  final List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredProvinces = [];
  List<Map<String, dynamic>> _filteredCities = [];

  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedProvinceId; // ✅ إضافة معرف المحافظة

  final _provinceSearchController = TextEditingController();
  final _citySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // إضافة listeners لتحديث الواجهة عند تغيير النص
    _customerNameController.addListener(() => setState(() {}));
    _primaryPhoneController.addListener(() => setState(() {}));
    _secondaryPhoneController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
  }

  // ✅ تهيئة البيانات بالترتيب الصحيح
  Future<void> _initializeData() async {
    // تحميل المحافظات أولاً
    await _loadProvinces();
    // ثم تحميل بيانات الطلب
    await _loadOrderDetails();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _provinceSearchController.dispose();
    _citySearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ✅ تحميل المحافظات من قاعدة البيانات
  Future<void> _loadProvinces() async {
    try {
      debugPrint('🏛️ جلب المحافظات من قاعدة البيانات...');

      final response = await Supabase.instance.client.from('provinces').select('id, name, name_en').order('name');

      if (response.isNotEmpty) {
        setState(() {
          _provinces.clear();
          _provinces.addAll(response);
          _filteredProvinces.clear();
          _filteredProvinces.addAll(_provinces);
        });
        debugPrint('✅ تم جلب ${_provinces.length} محافظة من قاعدة البيانات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحافظات: $e');
    }
  }

  // ✅ تحميل المدن لمحافظة معينة
  Future<void> _loadCities(String provinceId) async {
    try {
      debugPrint('🏙️ جلب مدن المحافظة: $provinceId من قاعدة البيانات...');

      final response = await Supabase.instance.client
          .from('cities')
          .select('id, name, name_en, province_id')
          .eq('province_id', provinceId)
          .order('name');

      if (response.isNotEmpty) {
        setState(() {
          _cities.clear();
          _cities.addAll(response);
          _filteredCities.clear();
          _filteredCities.addAll(_cities);
        });
        debugPrint('✅ تم جلب ${_cities.length} مدينة للمحافظة $provinceId');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e');
    }
  }

  // ✅ البحث عن معرف المحافظة وتحميل المدن
  Future<void> _findProvinceAndLoadCities() async {
    if (_selectedProvince != null && _provinces.isNotEmpty) {
      // البحث عن المحافظة في القائمة
      final province = _provinces.firstWhere(
        (p) => p['name'] == _selectedProvince || p['name_en'] == _selectedProvince,
        orElse: () => <String, dynamic>{},
      );

      if (province.isNotEmpty) {
        _selectedProvinceId = province['id'];
        debugPrint('✅ تم العثور على المحافظة: $_selectedProvince (ID: $_selectedProvinceId)');

        // تحميل المدن للمحافظة
        await _loadCities(_selectedProvinceId!);
      } else {
        debugPrint('❌ لم يتم العثور على المحافظة: $_selectedProvince');
      }
    }
  }

  // تحميل تفاصيل الطلب
  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('📥 جلب تفاصيل الطلب للتعديل: ${widget.orderId}');

      // جلب تفاصيل الطلب من قاعدة البيانات
      final orderResponse = await Supabase.instance.client
          .from(widget.isScheduled ? 'scheduled_orders' : 'orders')
          .select(widget.isScheduled ? '*, scheduled_order_items(*)' : '*, order_items(*)')
          .eq('id', widget.orderId)
          .single();

      debugPrint('✅ تم جلب تفاصيل الطلب: ${orderResponse['id']}');
      debugPrint('📝 الملاحظات المجلبة: ${orderResponse['customer_notes']}');

      // تحويل عناصر الطلب
      final itemsKey = widget.isScheduled ? 'scheduled_order_items' : 'order_items';
      final orderItems =
          (orderResponse[itemsKey] as List?)?.map((item) {
            return OrderItem(
              id: item['id'].toString(),
              productId: item['product_id'] ?? '',
              name: item['product_name'] ?? 'منتج غير محدد',
              image: item['product_image'] ?? '',
              wholesalePrice: double.tryParse(item['wholesale_price']?.toString() ?? '0') ?? 0.0,
              customerPrice: double.tryParse((item['customer_price'] ?? item['price'])?.toString() ?? '0') ?? 0.0,
              quantity: item['quantity'] ?? 1,
            );
          }).toList() ??
          [];

      // إنشاء كائن الطلب
      final order = Order(
        id: orderResponse['id'],
        customerName: orderResponse['customer_name'] ?? '',
        primaryPhone: widget.isScheduled
            ? (orderResponse['customer_phone'] ?? '')
            : (orderResponse['primary_phone'] ?? ''),
        secondaryPhone: widget.isScheduled
            ? (orderResponse['customer_alternate_phone'])
            : (orderResponse['secondary_phone']),
        province: orderResponse['province'] ?? orderResponse['customer_province'] ?? '',
        city: orderResponse['city'] ?? orderResponse['customer_city'] ?? '',
        notes: orderResponse['customer_notes'], // ✅ جلب من customer_notes دائماً
        items: orderItems,
        totalCost: (orderResponse['total_amount'] ?? orderResponse['total'] ?? 0).toInt(),
        totalProfit: (orderResponse['profit_amount'] ?? orderResponse['profit'] ?? 0).toInt(),
        subtotal: (orderResponse['total_amount'] ?? orderResponse['subtotal'] ?? 0).toInt(),
        total: (orderResponse['total_amount'] ?? orderResponse['total'] ?? 0).toInt(),
        status: widget.isScheduled ? OrderStatus.pending : _parseOrderStatus(orderResponse['status']),
        createdAt: DateTime.parse(orderResponse['created_at']),
        scheduledDate: widget.isScheduled ? DateTime.parse(orderResponse['scheduled_date']) : null,
      );

      // ملء الحقول بالبيانات الحالية
      _customerNameController.text = order.customerName;
      _primaryPhoneController.text = order.primaryPhone;
      _secondaryPhoneController.text = order.secondaryPhone ?? '';
      _notesController.text = order.notes ?? '';
      debugPrint('📝 تم تعبئة حقل الملاحظات: ${_notesController.text}');

      // ✅ تعيين المحافظة والمدينة المحفوظة
      _selectedProvince = order.province;
      _selectedCity = order.city;

      // ✅ تعيين تاريخ الجدولة للطلبات المجدولة
      if (widget.isScheduled && order.scheduledDate != null) {
        _selectedScheduledDate = order.scheduledDate;
      }

      // ✅ البحث عن معرف المحافظة وتحميل المدن
      await _findProvinceAndLoadCities();

      setState(() {
        // تم إزالة تعيين _order غير المستخدم
        _isLoading = false;
      });

      debugPrint('✅ تم تحميل تفاصيل الطلب للتعديل بنجاح: ${order.id}');
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل الطلب للتعديل: $e');
      setState(() {
        _error = 'خطأ في جلب تفاصيل الطلب: $e';
        _isLoading = false;
      });
    }
  }

  // تحويل حالة الطلب من النص
  OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_delivery':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? _buildEnhancedLoadingState()
              : _error != null
              ? _buildEnhancedErrorState()
              : _buildEnhancedEditForm(),
        ),
      ),
    );
  }

  // 🎨 الشريط العلوي المحسن
  Widget _buildEnhancedHeader() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.2), width: 1),
              boxShadow: isDark
                  ? []
                  : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // زر الرجوع على اليمين
                GestureDetector(
                  onTap: () => GoRouter.of(context).go('/orders'),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFffd700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFFffd700).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFFffd700), size: 18),
                  ),
                ),

                // العنوان في الوسط
                Expanded(
                  child: Center(
                    child: Text(
                      'تعديل الطلب',
                      style: GoogleFonts.cairo(
                        color: ThemeColors.textColor(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // مساحة فارغة للتوازن
                const SizedBox(width: 45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⏳ حالة التحميل المحسنة
  Widget _buildEnhancedLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // مؤشر التحميل البسيط
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)), strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'جاري التحميل...',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ❌ حالة الخطأ المحسنة
  Widget _buildEnhancedErrorState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الخطأ
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
                ),
                const SizedBox(height: 25),
                Text(
                  'خطأ في تحميل الطلب',
                  style: GoogleFonts.cairo(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  _error ?? 'حدث خطأ غير متوقع',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // زر إعادة المحاولة
                GestureDetector(
                  onTap: _loadOrderDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFFffd700), const Color(0xFFffed4e)]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'إعادة المحاولة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF1a1a2e),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 النموذج المحسن للتعديل
  Widget _buildEnhancedEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // الشريط العلوي المحسن
          _buildEnhancedHeader(),
          const SizedBox(height: 20),

          // بطاقة معلومات العميل
          _buildCustomerInfoCard(),
          const SizedBox(height: 20),

          // بطاقة الموقع
          _buildLocationCard(),
          const SizedBox(height: 20),

          // بطاقة الملاحظات
          _buildNotesCard(),

          // بطاقة تاريخ الجدولة (للطلبات المجدولة فقط)
          if (widget.isScheduled) ...[const SizedBox(height: 20), _buildScheduleCard()],

          const SizedBox(height: 30),

          // زر الحفظ المحسن
          _buildEnhancedSaveButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 👤 بطاقة معلومات العميل
  Widget _buildCustomerInfoCard() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.2 : 0.5),
              width: isDark ? 1 : 2,
            ),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل اسم العميل
              _buildEnhancedTextField(
                controller: _customerNameController,
                label: 'اسم العميل',
                icon: Icons.person_outline,
                isRequired: true,
              ),
              const SizedBox(height: 20),

              // حقل الهاتف الأساسي
              _buildEnhancedTextField(
                controller: _primaryPhoneController,
                label: 'رقم الهاتف الأساسي',
                icon: Icons.phone,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 11,
              ),
              const SizedBox(height: 20),

              // حقل الهاتف الثانوي
              _buildEnhancedTextField(
                controller: _secondaryPhoneController,
                label: 'رقم الهاتف الثانوي (اختياري)',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                maxLength: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ حقل نصي محسن مع تأثيرات بصرية
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool showIcon = true,
    int? maxLength,
  }) {
    // ✅ التحقق من صحة البيانات بدقة
    bool isValid = false;

    if (keyboardType == TextInputType.phone) {
      // للهاتف: يجب أن يكون 11 رقم ويبدأ بـ 07
      if (isRequired) {
        // الهاتف الأساسي: مطلوب
        isValid = controller.text.length == 11 && controller.text.startsWith('07');
      } else {
        // الهاتف الثانوي: اختياري - صحيح إذا كان فارغ أو 11 رقم ويبدأ بـ 07
        isValid = controller.text.isEmpty || (controller.text.length == 11 && controller.text.startsWith('07'));
      }
    } else if (keyboardType == TextInputType.multiline) {
      // للملاحظات: لا نريد إطار أخضر
      isValid = false;
    } else {
      // لاسم العميل: يجب أن يكون مملوء
      if (isRequired) {
        isValid = controller.text.trim().isNotEmpty;
      } else {
        // للحقول الاختيارية: صحيح إذا كان مملوء أو فارغ
        isValid = true;
      }
    }
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Container(
      height: maxLines > 1 ? null : 75,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isValid ? const Color(0xFF28a745) : const Color(0xFFffd700).withValues(alpha: 0.3),
                width: isValid ? 3 : 1,
              ),
              boxShadow: isDark
                  ? []
                  : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                maxLength: maxLength,
                style: GoogleFonts.cairo(
                  color: ThemeColors.textColor(isDark),
                  fontSize: 16,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  setState(() {}); // ✅ تحديث UI عند تغيير النص لإظهار الإطار الأخضر
                },
                decoration: InputDecoration(
                  labelText: null,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: isRequired ? '$label *' : label,
                  hintStyle: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
                  counterText: '', // إخفاء عداد الأحرف
                  prefixIcon: showIcon
                      ? Container(
                          margin: const EdgeInsets.all(12),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFffd700).withValues(alpha: 0.3),
                                const Color(0xFFffed4e).withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: const Color(0xFFffd700), size: 20),
                        )
                      : null,
                  border: InputBorder.none, // ✅ إزالة الحدود الافتراضية
                  enabledBorder: InputBorder.none, // ✅ إزالة حدود الحالة العادية
                  focusedBorder: InputBorder.none, // ✅ إزالة حدود التركيز
                  disabledBorder: InputBorder.none, // ✅ إزالة حدود التعطيل
                  errorBorder: InputBorder.none, // ✅ إزالة حدود الخطأ
                  focusedErrorBorder: InputBorder.none, // ✅ إزالة حدود الخطأ مع التركيز
                  contentPadding: EdgeInsets.symmetric(horizontal: showIcon ? 20 : 20, vertical: 14),
                ),
              ),
            ), // ✅ إغلاق Material widget
          ),
        ),
      ),
    );
  }

  // 📍 بطاقة الموقع
  Widget _buildLocationCard() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00d4ff).withValues(alpha: isDark ? 0.2 : 0.5),
              width: isDark ? 1 : 2,
            ),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل المحافظة
              _buildEnhancedProvinceField(),
              const SizedBox(height: 20),

              // حقل المدينة
              _buildEnhancedCityField(),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 بطاقة الملاحظات
  Widget _buildNotesCard() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFff6b6b).withValues(alpha: isDark ? 0.2 : 0.5),
              width: isDark ? 1 : 2,
            ),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل الملاحظات
              _buildEnhancedTextField(
                controller: _notesController,
                label: 'ملاحظات (اختياري)',
                icon: Icons.note_outlined,
                maxLines: 3,
                showIcon: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💾 زر الحفظ المحسن
  Widget _buildEnhancedSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: const Color(0xFFffd700).withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFffd700), borderRadius: BorderRadius.circular(15)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _isLoading ? null : _saveChanges,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a1a2e)),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 15),
                        ] else ...[
                          const Icon(Icons.save, color: Color(0xFF1a1a2e), size: 24),
                          const SizedBox(width: 15),
                        ],
                        Text(
                          _isLoading ? 'جاري الحفظ...' : 'حفظ التعديلات',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF1a1a2e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🏛️ حقل المحافظة المحسن
  Widget _buildEnhancedProvinceField() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return GestureDetector(
      onTap: _showProvinceSelector,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: isDark
              ? [BoxShadow(color: const Color(0xFF00d4ff).withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)]
              : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF00d4ff).withValues(alpha: 0.3),
                  width: isDark ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00d4ff).withValues(alpha: 0.3),
                          const Color(0xFF00a8cc).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_city, color: Color(0xFF00d4ff), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المحافظة *', style: GoogleFonts.cairo(color: const Color(0xFF00d4ff), fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(
                          _selectedProvince ?? 'اختر المحافظة',
                          style: GoogleFonts.cairo(
                            color: _selectedProvince != null
                                ? ThemeColors.textColor(isDark)
                                : ThemeColors.secondaryTextColor(isDark),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: const Color(0xFF00d4ff), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🏘️ حقل المدينة المحسن
  Widget _buildEnhancedCityField() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return GestureDetector(
      onTap: _selectedProvince != null ? _showCitySelector : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: isDark
              ? [BoxShadow(color: const Color(0xFF00d4ff).withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)]
              : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF00d4ff).withValues(alpha: 0.3),
                  width: isDark ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00d4ff).withValues(alpha: 0.3),
                          const Color(0xFF00a8cc).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFF00d4ff), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المدينة *', style: GoogleFonts.cairo(color: const Color(0xFF00d4ff), fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(
                          _selectedCity ?? (_selectedProvince != null ? 'اختر المدينة' : 'اختر المحافظة أولاً'),
                          style: GoogleFonts.cairo(
                            color: _selectedCity != null
                                ? ThemeColors.textColor(isDark)
                                : ThemeColors.secondaryTextColor(isDark),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: _selectedProvince != null ? const Color(0xFF00d4ff) : Colors.white38,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📅 بطاقة تاريخ الجدولة
  Widget _buildScheduleCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4ecdc4).withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFF4ecdc4), const Color(0xFF44a08d)]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.schedule, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الجدولة',
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'موعد تسليم الطلب',
                          style: GoogleFonts.cairo(color: const Color(0xFF4ecdc4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // حقل التاريخ
              _buildEnhancedDateField(),
            ],
          ),
        ),
      ),
    );
  }

  // 📅 حقل التاريخ المحسن
  Widget _buildEnhancedDateField() {
    return GestureDetector(
      onTap: _selectScheduledDate,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4ecdc4).withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4ecdc4).withValues(alpha: 0.3),
                          const Color(0xFF44a08d).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: Color(0xFF4ecdc4), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاريخ التسليم *', style: GoogleFonts.cairo(color: const Color(0xFF4ecdc4), fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(
                          _selectedScheduledDate != null
                              ? '${_selectedScheduledDate!.day}/${_selectedScheduledDate!.month}/${_selectedScheduledDate!.year}'
                              : 'اختر تاريخ التسليم',
                          style: GoogleFonts.cairo(
                            color: _selectedScheduledDate != null ? Colors.white : Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.date_range, color: const Color(0xFF4ecdc4), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // حفظ التغييرات
  Future<void> _saveChanges() async {
    // التحقق من الحقول المطلوبة
    if (_customerNameController.text.trim().isEmpty) {
      _showErrorMessage('يرجى إدخال اسم العميل');
      return;
    }

    if (_primaryPhoneController.text.trim().isEmpty) {
      _showErrorMessage('يرجى إدخال رقم الهاتف الأساسي');
      return;
    }

    if (_selectedProvince == null) {
      _showErrorMessage('يرجى اختيار المحافظة');
      return;
    }

    if (_selectedCity == null) {
      _showErrorMessage('يرجى اختيار المدينة');
      return;
    }

    // التحقق من تاريخ الجدولة للطلبات المجدولة
    if (widget.isScheduled && _selectedScheduledDate == null) {
      _showErrorMessage('يرجى اختيار تاريخ الجدولة');
      return;
    }

    try {
      debugPrint('💾 بدء حفظ تعديلات الطلب: ${widget.orderId}');
      debugPrint('📍 المحافظة المختارة: $_selectedProvince');
      debugPrint('🏙️ المدينة المختارة: $_selectedCity');

      // تحديث البيانات في قاعدة البيانات
      if (widget.isScheduled) {
        // تحديث الطلب المجدول
        await Supabase.instance.client
            .from('scheduled_orders')
            .update({
              'customer_name': _customerNameController.text.trim(),
              'customer_phone': _primaryPhoneController.text.trim(),
              'customer_alternate_phone': _secondaryPhoneController.text.trim().isEmpty
                  ? null
                  : _secondaryPhoneController.text.trim(),
              'province': _selectedProvince!,
              'city': _selectedCity!,
              'customer_province': _selectedProvince!,
              'customer_city': _selectedCity!,
              'customer_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              'scheduled_date': _selectedScheduledDate?.toIso8601String().split('T')[0],
            })
            .eq('id', widget.orderId);
      } else {
        // تحديث الطلب العادي
        await Supabase.instance.client
            .from('orders')
            .update({
              'customer_name': _customerNameController.text.trim(),
              'primary_phone': _primaryPhoneController.text.trim(),
              'secondary_phone': _secondaryPhoneController.text.trim().isEmpty
                  ? null
                  : _secondaryPhoneController.text.trim(),
              'province': _selectedProvince!,
              'city': _selectedCity!,
              'customer_notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(), // ✅ حفظ في customer_notes دائماً
            })
            .eq('id', widget.orderId);
      }

      debugPrint('✅ تم حفظ تعديلات الطلب بنجاح');

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // العودة للصفحة الصحيحة حسب نوع الطلب والمستخدم
        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            // حفظ BuildContext قبل العملية غير المتزامنة
            final navigator = GoRouter.of(context);

            // العودة دائماً لصفحة طلبات المستخدم
            // بغض النظر عن نوع الطلب أو نوع المستخدم
            navigator.go('/orders');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تعديلات الطلب: $e');

      _showErrorMessage('خطأ في حفظ التغييرات: $e');
    }
  }

  // ✅ عرض قائمة المحافظات
  void _showProvinceSelector() {
    _filteredProvinces = List.from(_provinces);
    _provinceSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16213e),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFffd700)),
                        const SizedBox(width: 10),
                        Text(
                          'اختر المحافظة',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFffd700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _provinceSearchController,
                      onChanged: (value) => _filterProvinces(value, setModalState),
                      style: GoogleFonts.cairo(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن المحافظة...',
                        hintStyle: GoogleFonts.cairo(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFffd700)),
                        filled: true,
                        fillColor: const Color(0xFF16213e),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredProvinces.length,
                      itemBuilder: (context, index) {
                        final province = _filteredProvinces[index];
                        final provinceName = province['name'] ?? province['name_en'] ?? '';

                        return ListTile(
                          title: Text(provinceName, style: GoogleFonts.cairo(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedProvince = provinceName;
                              _selectedProvinceId = province['id'];
                              _selectedCity = null; // إعادة تعيين المدينة عند تغيير المحافظة
                            });
                            debugPrint('✅ تم اختيار المحافظة: $provinceName (ID: ${province['id']})');
                            _loadCities(province['id']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ عرض قائمة المدن
  void _showCitySelector() {
    _filteredCities = List.from(_cities);
    _citySearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF16213e),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: Color(0xFFffd700)),
                    const SizedBox(width: 10),
                    Text(
                      'اختر المدينة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFffd700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _citySearchController,
                  onChanged: (value) => _filterCities(value, setModalState),
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن المدينة...',
                    hintStyle: GoogleFonts.cairo(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFffd700)),
                    filled: true,
                    fillColor: const Color(0xFF16213e),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    final city = _filteredCities[index];
                    final cityName = city['name'] ?? city['name_en'] ?? '';

                    return ListTile(
                      title: Text(cityName, style: GoogleFonts.cairo(color: Colors.white)),
                      onTap: () {
                        setState(() {
                          _selectedCity = cityName;
                        });
                        debugPrint('✅ تم اختيار المدينة: $cityName');
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ فلترة المحافظات
  void _filterProvinces(String query, [Function? setModalState]) {
    final updateState = setModalState ?? setState;
    updateState(() {
      if (query.isEmpty) {
        _filteredProvinces = List.from(_provinces);
      } else {
        _filteredProvinces = _provinces.where((province) {
          final provinceName = (province['name'] ?? province['name_en'] ?? '').toLowerCase();
          return provinceName.startsWith(query.toLowerCase());
        }).toList();
      }
    });
  }

  // ✅ فلترة المدن
  void _filterCities(String query, [Function? setModalState]) {
    final updateState = setModalState ?? setState;
    updateState(() {
      if (query.isEmpty) {
        _filteredCities = List.from(_cities);
      } else {
        _filteredCities = _cities.where((city) {
          final cityName = (city['name'] ?? city['name_en'] ?? '').toLowerCase();
          return cityName.startsWith(query.toLowerCase());
        }).toList();
      }
    });
  }

  // اختيار تاريخ الجدولة
  Future<void> _selectScheduledDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedScheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFffd700),
              onPrimary: Color(0xFF1a1a2e),
              surface: Color(0xFF16213e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedScheduledDate) {
      setState(() {
        _selectedScheduledDate = picked;
      });
    }
  }

  // إظهار رسالة خطأ
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
