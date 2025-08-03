import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/common_header.dart';

class EditOrderPage extends StatefulWidget {
  final String orderId;
  final bool isScheduled;

  const EditOrderPage({
    super.key,
    required this.orderId,
    this.isScheduled = false,
  });

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  // تم إزالة _order غير المستخدم
  bool _isLoading = true;
  bool _isSaving = false;
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
    _loadProvinces();
    _loadOrderDetails();
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

      final response = await Supabase.instance.client
          .from('provinces')
          .select('id, name, name_en')
          .order('name');

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
        (p) =>
            p['name'] == _selectedProvince || p['name_en'] == _selectedProvince,
        orElse: () => <String, dynamic>{},
      );

      if (province.isNotEmpty) {
        _selectedProvinceId = province['id'];
        debugPrint(
          '✅ تم العثور على المحافظة: $_selectedProvince (ID: $_selectedProvinceId)',
        );

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
          .select(
            widget.isScheduled
                ? '*, scheduled_order_items(*)'
                : '*, order_items(*)',
          )
          .eq('id', widget.orderId)
          .single();

      debugPrint('✅ تم جلب تفاصيل الطلب: ${orderResponse['id']}');

      // تحويل عناصر الطلب
      final itemsKey = widget.isScheduled
          ? 'scheduled_order_items'
          : 'order_items';
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
        province:
            orderResponse['province'] ??
            orderResponse['customer_province'] ??
            '',
        city: orderResponse['city'] ?? orderResponse['customer_city'] ?? '',
        notes: widget.isScheduled
            ? (orderResponse['customer_notes'])
            : (orderResponse['notes']),
        items: orderItems,
        totalCost:
            (orderResponse['total_amount'] ?? orderResponse['total'] ?? 0).toInt(),
        totalProfit:
            (orderResponse['profit_amount'] ?? orderResponse['profit'] ?? 0).toInt(),
        subtotal:
            (orderResponse['total_amount'] ?? orderResponse['subtotal'] ?? 0).toInt(),
        total: (orderResponse['total_amount'] ?? orderResponse['total'] ?? 0).toInt(),
        status: widget.isScheduled
            ? OrderStatus.pending
            : _parseOrderStatus(orderResponse['status']),
        createdAt: DateTime.parse(orderResponse['created_at']),
        scheduledDate: widget.isScheduled
            ? DateTime.parse(orderResponse['scheduled_date'])
            : null,
      );

      // ملء الحقول بالبيانات الحالية
      _customerNameController.text = order.customerName;
      _primaryPhoneController.text = order.primaryPhone;
      _secondaryPhoneController.text = order.secondaryPhone ?? '';
      _notesController.text = order.notes ?? '';

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
      backgroundColor: const Color(0xFF1a1a2e),
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'تعديل الطلب',
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
                    Icons.arrow_back,
                    color: Color(0xFFffd700),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildEditForm(),
          ),
        ],
      ),
    );
  }



  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFffd700)),
          SizedBox(height: 20),
          Text(
            'جاري تحميل تفاصيل الطلب...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          Text(
            'خطأ في تحميل الطلب',
            style: GoogleFonts.cairo(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 100, // مساحة للشريط السفلي
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFffd700), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFFffd700), size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.isScheduled
                      ? 'تعديل الطلب المجدول'
                      : 'تعديل معلومات العميل',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFffd700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // حقول التعديل
          _buildTextField(
            controller: _customerNameController,
            label: 'اسم العميل',
            icon: Icons.person,
            isRequired: true,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _primaryPhoneController,
            label: 'رقم الهاتف الأساسي',
            icon: Icons.phone,
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _secondaryPhoneController,
            label: 'رقم الهاتف الثانوي (اختياري)',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // ✅ حقل المحافظة الجديد
          _buildProvinceField(),
          const SizedBox(height: 16),

          // ✅ حقل المدينة الجديد
          _buildCityField(),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _notesController,
            label: 'ملاحظات إضافية (اختياري)',
            icon: Icons.note,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // حقل تاريخ الجدولة (للطلبات المجدولة فقط)
          if (widget.isScheduled) ...[
            _buildScheduledDateField(),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 30),

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFffd700),
                foregroundColor: const Color(0xFF1a1a2e),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF1a1a2e),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('جاري الحفظ...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'حفظ التغييرات',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    // ✅ تحديد حالة التحقق من صحة الحقل
    bool isValid = false;
    if (controller == _customerNameController) {
      isValid = controller.text.trim().isNotEmpty;
    } else if (controller == _primaryPhoneController) {
      isValid = controller.text.trim().length == 11;
    } else if (controller == _secondaryPhoneController) {
      isValid =
          controller.text.trim().isEmpty || controller.text.trim().length == 11;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFffd700), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            // ✅ علامة الصح للحقول الصحيحة
            if (isValid && controller.text.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF28a745),
                size: 18,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          onChanged: (value) {
            // ✅ تحويل الأرقام العربية إلى إنجليزية للهاتف
            if (keyboardType == TextInputType.phone) {
              final englishNumbers = _convertArabicToEnglish(value);
              if (englishNumbers != value) {
                controller.value = controller.value.copyWith(
                  text: englishNumbers,
                  selection: TextSelection.collapsed(
                    offset: englishNumbers.length,
                  ),
                );
              }
            }
            setState(() {}); // ✅ إعادة بناء الواجهة لتحديث الإطار
          },
          inputFormatters: keyboardType == TextInputType.phone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11), // ✅ حد أقصى 11 رقم
                ]
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF16213e),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid && controller.text.trim().isNotEmpty
                    ? const Color(0xFF28a745) // ✅ إطار أخضر للحقول الصحيحة
                    : const Color(0xFF2a3f5f),
                width: isValid && controller.text.trim().isNotEmpty ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid && controller.text.trim().isNotEmpty
                    ? const Color(0xFF28a745) // ✅ إطار أخضر للحقول الصحيحة
                    : const Color(0xFF2a3f5f),
                width: isValid && controller.text.trim().isNotEmpty ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid && controller.text.trim().isNotEmpty
                    ? const Color(0xFF28a745) // ✅ إطار أخضر للحقول الصحيحة
                    : const Color(0xFFffd700),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'أدخل $label',
            hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ✅ تحويل الأرقام العربية إلى إنجليزية
  String _convertArabicToEnglish(String input) {
    const arabicNumbers = '٠١٢٣٤٥٦٧٨٩';
    const englishNumbers = '0123456789';

    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
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
      setState(() {
        _isSaving = true;
      });

      debugPrint('💾 بدء حفظ تعديلات الطلب: ${widget.orderId}');

      // تحديث البيانات في قاعدة البيانات
      if (widget.isScheduled) {
        // تحديث الطلب المجدول
        await Supabase.instance.client
            .from('scheduled_orders')
            .update({
              'customer_name': _customerNameController.text.trim(),
              'customer_phone': _primaryPhoneController.text.trim(),
              'customer_alternate_phone':
                  _secondaryPhoneController.text.trim().isEmpty
                  ? null
                  : _secondaryPhoneController.text.trim(),
              'province': _selectedProvince!,
              'city': _selectedCity!,
              'customer_province': _selectedProvince!,
              'customer_city': _selectedCity!,
              'customer_notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              'scheduled_date': _selectedScheduledDate?.toIso8601String().split(
                'T',
              )[0],
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
              'notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            })
            .eq('id', widget.orderId);
      }

      debugPrint('✅ تم حفظ تعديلات الطلب بنجاح');

      setState(() {
        _isSaving = false;
      });

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // العودة للصفحة الصحيحة حسب نوع الطلب
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            if (widget.isScheduled) {
              // للطلبات المجدولة - العودة لصفحة الطلبات المجدولة
              context.go('/scheduled-orders');
            } else {
              // للطلبات العادية - العودة لصفحة الطلبات العادية
              context.go('/orders');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تعديلات الطلب: $e');

      setState(() {
        _isSaving = false;
      });

      _showErrorMessage('خطأ في حفظ التغييرات: $e');
    }
  }

  // ✅ بناء حقل المحافظة
  Widget _buildProvinceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFffd700),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'المحافظة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showProvinceSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedProvince != null
                    ? const Color(0xFF28a745)
                    : const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedProvince ?? 'اختر المحافظة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedProvince != null
                          ? const Color(0xFFf0f0f0)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFFffd700),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ بناء حقل المدينة
  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFffd700),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'المدينة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectedProvince != null ? _showCitySelector : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCity != null
                    ? const Color(0xFF28a745)
                    : _selectedProvince != null
                    ? const Color(0xFFffd700).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCity ??
                        (_selectedProvince != null
                            ? 'اختر المدينة'
                            : 'اختر المحافظة أولاً'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCity != null
                          ? const Color(0xFFf0f0f0)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: _selectedProvince != null
                      ? const Color(0xFFffd700)
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFffd700),
                    ),
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
                    final provinceName =
                        province['name'] ?? province['name_en'] ?? '';

                    return ListTile(
                      title: Text(
                        provinceName,
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedProvince = provinceName;
                          _selectedProvinceId = province['id'];
                          _selectedCity = null;
                        });
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFffd700),
                    ),
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
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    final city = _filteredCities[index];
                    final cityName = city['name'] ?? city['name_en'] ?? '';

                    return ListTile(
                      title: Text(
                        cityName,
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCity = cityName;
                        });
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
          final provinceName = (province['name'] ?? province['name_en'] ?? '')
              .toLowerCase();
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
          final cityName = (city['name'] ?? city['name_en'] ?? '')
              .toLowerCase();
          return cityName.startsWith(query.toLowerCase());
        }).toList();
      }
    });
  }

  // بناء حقل تاريخ الجدولة
  Widget _buildScheduledDateField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffd700), width: 1),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFFffd700)),
        title: Text(
          'تاريخ الجدولة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _selectedScheduledDate != null
              ? _formatDate(_selectedScheduledDate!)
              : 'اختر تاريخ الجدولة',
          style: GoogleFonts.cairo(
            color: _selectedScheduledDate != null
                ? const Color(0xFFffd700)
                : Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFffd700),
          size: 16,
        ),
        onTap: _selectScheduledDate,
      ),
    );
  }

  // اختيار تاريخ الجدولة
  Future<void> _selectScheduledDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedScheduledDate ?? DateTime.now().add(const Duration(days: 1)),
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

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
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
