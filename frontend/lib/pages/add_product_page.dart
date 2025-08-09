import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';
import '../services/image_upload_service.dart';
// خدمات الاختبار تم حذفها لتحسين الأداء

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '100');
  final _minOrderController = TextEditingController(text: '10');
  final _maxOrderController = TextEditingController(text: '50');

  // State variables
  String _selectedCategory = '';
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Categories
  final List<Map<String, String>> _categories = [
    {'value': 'home_appliances', 'label': '🏠 الأجهزة المنزلية'},
    {'value': 'home_devices', 'label': '🔌 أجهزة المنزل'},
    {'value': 'electronics', 'label': '📱 الإلكترونيات والإكسسوارات'},
    {'value': 'car_accessories', 'label': '🚗 كماليات السيارات'},
    {'value': 'personal_care', 'label': '💄 منتجات العناية الشخصية'},
    {'value': 'clothing', 'label': '👕 الملابس والأزياء'},
    {'value': 'sports', 'label': '⚽ الرياضة واللياقة'},
    {'value': 'books', 'label': '📚 الكتب والقرطاسية'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _wholesalePriceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _stockQuantityController.dispose();
    _minOrderController.dispose();
    _maxOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a1a2e)),
        ),
        title: Text(
          'إضافة منتج جديد',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1a1a2e),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildMainForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس النموذج
          Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.boxOpen,
                  color: Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'بيانات المنتج الجديد',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFffd700),
                  ),
                ),
              ],
            ),
          ),

          // جسم النموذج
          Padding(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 30),
                  _buildPricingSection(),
                  const SizedBox(height: 30),
                  _buildInventorySection(),
                  const SizedBox(height: 30),
                  _buildImagesSection(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildFinalInfoBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // القسم الأول: المعلومات الأساسية
  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'المعلومات الأساسية',
      icon: FontAwesomeIcons.info,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج',
                hint: 'أدخل اسم المنتج',
                isRequired: true,
                helpText: 'اختر اسماً واضحاً ومميزاً للمنتج',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم المنتج مطلوب';
                  }
                  if (value.trim().length < 3) {
                    return 'اسم المنتج يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildDropdownField(
                value: _selectedCategory,
                label: 'فئة المنتج',
                hint: 'اختر فئة المنتج',
                isRequired: true,
                items: _categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'وصف المنتج',
          hint: 'اكتب وصفاً مفصلاً للمنتج، مميزاته، واستخداماته...',
          expandable: true,
          minLines: 3,
          isRequired: true,
          helpText: 'وصف جيد يساعد التجار على فهم المنتج بشكل أفضل • المربع سيتوسع تلقائياً مع النص • اكتب بحرية!',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'وصف المنتج مطلوب';
            }
            return null;
          },
        ),
      ],
    );
  }

  // القسم الثاني: الأسعار والتكلفة
  Widget _buildPricingSection() {
    return _buildSection(
      title: 'الأسعار والتكلفة',
      icon: FontAwesomeIcons.dollarSign,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _wholesalePriceController,
                label: 'سعر الجملة',
                hint: '0.00',
                isRequired: true,
                keyboardType: TextInputType.number,
                suffix: 'د.ع',
                helpText: 'السعر الذي تشتري به المنتج',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'سعر الجملة مطلوب';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'يجب أن يكون السعر أكبر من صفر';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _minPriceController,
                label: 'الحد الأدنى لسعر البيع',
                hint: 'اختياري',
                keyboardType: TextInputType.number,
                suffix: 'د.ع',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _maxPriceController,
                label: 'الحد الأعلى لسعر البيع',
                hint: 'اختياري',
                keyboardType: TextInputType.number,
                suffix: 'د.ع',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoBox(
          'إذا لم تحدد الحد الأدنى، سيتم استخدام سعر الجملة كحد أدنى تلقائياً',
          FontAwesomeIcons.lightbulb,
        ),
      ],
    );
  }

  // القسم الثالث: المخزون والكميات
  Widget _buildInventorySection() {
    return _buildSection(
      title: 'المخزون والكميات',
      icon: FontAwesomeIcons.boxesStacked,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _stockQuantityController,
                label: 'كمية المخزون الفعلية',
                hint: '100',
                isRequired: true,
                keyboardType: TextInputType.number,
                suffix: 'قطعة',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'كمية المخزون مطلوبة';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 0) {
                    return 'يجب أن تكون الكمية صفر أو أكثر';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _minOrderController,
                label: 'الحد الأدنى للطلب',
                hint: '10',
                keyboardType: TextInputType.number,
                suffix: 'قطعة',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final minOrder = int.tryParse(value);
                    if (minOrder == null || minOrder < 1) {
                      return 'يجب أن يكون الحد الأدنى 1 أو أكثر';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _maxOrderController,
                label: 'الحد الأعلى للطلب',
                hint: 'اختياري - مثال: 50',
                keyboardType: TextInputType.number,
                suffix: 'قطعة',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final maxOrder = int.tryParse(value);
                    final stockQuantity = int.tryParse(
                      _stockQuantityController.text,
                    );
                    if (maxOrder != null &&
                        stockQuantity != null &&
                        maxOrder > stockQuantity) {
                      return 'لا يمكن أن يكون أكبر من كمية المخزون';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildAlertBox(
          'سيتم إرسال إشعارات نفاد المخزون تلقائياً عند انخفاض الكمية',
          FontAwesomeIcons.bell,
        ),
      ],
    );
  }

  // القسم الخامس: صور المنتج
  Widget _buildImagesSection() {
    return _buildSection(
      title: 'صور المنتج',
      icon: FontAwesomeIcons.images,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFffd700),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFFffd700).withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.cloudArrowUp,
                          size: 40,
                          color: Color(0xFFffd700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'اختيار صور المنتج',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFffd700),
                          ),
                        ),
                        Text(
                          'JPG, PNG, GIF',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                GestureDetector(
                  onTap: _addTestImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.blue.withValues(alpha: 0.05),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.flask,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'صور تجريبية',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // عرض الصور المختارة أو رسالة عدم وجود صور
        if (_selectedImages.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                FontAwesomeIcons.images,
                color: const Color(0xFFffd700),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'الصور المختارة (${_selectedImages.length})',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.lightbulb,
                  color: const Color(0xFFffd700),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اضغط على أي صورة لتحديدها كصورة رئيسية • استخدم الأسهم لإعادة الترتيب • اضغط على ⭐ لتحديد الصورة الرئيسية • اضغط على ✕ لحذف الصورة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF1a1a2e),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildImagePreview(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    FontAwesomeIcons.images,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لم يتم اختيار صور بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'اضغط على "اختيار صور المنتج" أعلاه لإضافة صور',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildImageTips(),
      ],
    );
  }

  // أزرار الإجراءات
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              elevation: 0,
            ),
            icon: const Icon(FontAwesomeIcons.arrowRotateLeft, size: 18),
            label: Text(
              'إعادة التعيين',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(FontAwesomeIcons.floppyDisk, size: 18),
            label: Text(
              _isLoading ? 'جاري الحفظ...' : 'حفظ المنتج',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // دالة بناء القسم
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1a1a2e), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // دالة بناء حقل النص
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    int? minLines,
    bool expandable = false,
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
    String? helpText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1a1a2e),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: TextFormField(
            controller: controller,
            maxLines: expandable ? null : maxLines,
            minLines: expandable ? (minLines ?? 3) : null,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black),
            textAlignVertical: expandable ? TextAlignVertical.top : TextAlignVertical.center,
            decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14),
            suffixText: suffix,
            suffixStyle: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(0xFFffd700),
                width: expandable ? 3 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: expandable ? 15 : 12,
            ),
            filled: true,
            fillColor: Colors.white,
            // إضافة أيقونة للحقول القابلة للتوسع
            prefixIcon: expandable ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8, top: 12),
              child: Icon(
                FontAwesomeIcons.alignLeft,
                color: const Color(0xFFffd700),
                size: 16,
              ),
            ) : null,
          ),
        ),
      ),
        if (helpText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  helpText,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              // عداد الأحرف للحقول القابلة للتوسع
              if (expandable)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final charCount = value.text.length;
                    final color = charCount > 500
                        ? Colors.orange
                        : charCount > 200
                            ? const Color(0xFFffd700)
                            : Colors.grey[600];

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color?.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color!, width: 1),
                      ),
                      child: Text(
                        '$charCount حرف',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  // دالة بناء القائمة المنسدلة
  Widget _buildDropdownField({
    required String value,
    required String label,
    required String hint,
    bool isRequired = false,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1a1a2e),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          onChanged: onChanged,
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(
                item['label']!,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            );
          }).toList(),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label مطلوب';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  // دالة بناء صندوق المعلومات
  Widget _buildInfoBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFffd700), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء صندوق التنبيه
  Widget _buildAlertBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة معاينة الصور
  Widget _buildImagePreview() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedImages.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        final isMainImage = index == 0;

        return GestureDetector(
          onTap: () => _setAsMainImage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMainImage ? const Color(0xFFffd700) : Colors.grey[300]!,
                      width: isMainImage ? 3 : 1,
                    ),
                    boxShadow: isMainImage ? [
                      BoxShadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImagePreviewWidget(image),
                  ),
                ),

              // شارة الصورة الرئيسية
              if (isMainImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          FontAwesomeIcons.star,
                          size: 10,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'رئيسية',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // زر تحديد كصورة رئيسية
              if (!isMainImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _setAsMainImage(index),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFffd700),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.star,
                        color: Color(0xFFffd700),
                        size: 12,
                      ),
                    ),
                  ),
                ),

              // زر الحذف
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.xmark,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),

              // رقم الصورة وأزرار التحكم
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // رقم الصورة
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // أزرار إعادة الترتيب
                    if (_selectedImages.length > 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            GestureDetector(
                              onTap: () => _moveImageLeft(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.arrowLeft,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                          if (index > 0 && index < _selectedImages.length - 1)
                            const SizedBox(width: 4),
                          if (index < _selectedImages.length - 1)
                            GestureDetector(
                              onTap: () => _moveImageRight(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.arrowRight,
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
            ],
          ),
        ),
      );
      }).toList(),
    );
  }

  // دالة نصائح الصور
  Widget _buildImageTips() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.lightbulb,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح للصور:',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...const [
            '• استخدم صور عالية الجودة وواضحة',
            '• أضف صور من زوايا مختلفة للمنتج',
            '• تأكد من إضاءة جيدة وخلفية مناسبة',
            '• اضغط على أي صورة لتحديدها كصورة رئيسية',
            '• الصورة الرئيسية ستظهر في صفحة المنتجات',
            '• يمكنك إعادة ترتيب الصور بسهولة',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                tip,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دوال الوظائف

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // دالة تحديد الصورة الرئيسية
  void _setAsMainImage(int index) {
    if (index == 0) return; // الصورة الأولى هي الرئيسية بالفعل

    setState(() {
      // نقل الصورة المختارة إلى المقدمة
      final selectedImage = _selectedImages.removeAt(index);
      _selectedImages.insert(0, selectedImage);
    });

    // طباعة معلومات تشخيصية
    debugPrint('🔄 تم تحديد الصورة رقم ${index + 1} كصورة رئيسية');
    debugPrint('📋 ترتيب الصور الحالي:');
    for (int i = 0; i < _selectedImages.length; i++) {
      debugPrint('  ${i + 1}. ${_selectedImages[i].name} ${i == 0 ? '(رئيسية)' : ''}');
    }

    // إظهار رسالة تأكيد
    _showSuccessSnackBar('✅ تم تحديد الصورة كصورة رئيسية');
  }

  // دالة نقل الصورة لليسار
  void _moveImageLeft(int index) {
    if (index <= 0) return;

    setState(() {
      final image = _selectedImages.removeAt(index);
      _selectedImages.insert(index - 1, image);
    });

    _showSuccessSnackBar('تم نقل الصورة لليسار ✅');
  }

  // دالة نقل الصورة لليمين
  void _moveImageRight(int index) {
    if (index >= _selectedImages.length - 1) return;

    setState(() {
      final image = _selectedImages.removeAt(index);
      _selectedImages.insert(index + 1, image);
    });

    _showSuccessSnackBar('تم نقل الصورة لليمين ✅');
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();

      // اختيار صور متعددة
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(images);
        });
        _showSuccessSnackBar('تم اختيار ${images.length} صورة بنجاح!');
      } else {
        _showErrorSnackBar('لم يتم اختيار أي صورة');
      }
    } catch (e) {
      debugPrint('خطأ في اختيار الصور: $e');
      _showErrorSnackBar('خطأ في اختيار الصور. يرجى المحاولة مرة أخرى.');
    }
  }

  // إضافة صور تجريبية للاختبار
  void _addTestImages() {
    final List<XFile> testImages = [
      XFile(
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
      ),
      XFile(
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
      ),
      XFile(
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop',
      ),
    ];

    setState(() {
      _selectedImages.clear();
      _selectedImages.addAll(testImages);
    });

    _showSuccessSnackBar('تم إضافة ${testImages.length} صورة تجريبية للاختبار');
  }

  // اختبار Storage
  // تم حذف دالة اختبار Storage لتحسين الأداء

  // بناء معاينة الصورة
  Widget _buildImagePreviewWidget(XFile image) {
    // التحقق من نوع الصورة (رابط أم ملف محلي)
    if (image.path.startsWith('http')) {
      // صورة من رابط
      return Image.network(
        image.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
          );
        },
      );
    } else {
      // صورة محلية - استخدام FutureBuilder لقراءة البيانات
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
            );
          } else {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تحميل...',
                      style: GoogleFonts.cairo(
                        fontSize: 8,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      );
    }
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إعادة تعيين النموذج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من إعادة تعيين جميع البيانات؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'إعادة تعيين',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _wholesalePriceController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _stockQuantityController.text = '100';
      _minOrderController.text = '10';
      _maxOrderController.clear(); // إزالة القيمة الافتراضية
      _selectedCategory = '';
      _selectedImages.clear();
    });
  }

  Future<void> _saveProduct() async {
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('يرجى التحقق من جميع الحقول المطلوبة');
      return;
    }

    // التحقق من اختيار الفئة
    if (_selectedCategory.isEmpty) {
      _showErrorSnackBar('يرجى اختيار فئة المنتج');
      return;
    }

    // التحقق من وجود صور
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('يرجى إضافة صورة واحدة على الأقل');
      return;
    }

    // التحقق من الحقول الرقمية
    if (_wholesalePriceController.text.isEmpty ||
        _stockQuantityController.text.isEmpty) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _showSuccessSnackBar('جاري رفع الصور...');

      // رفع الصورة الأولى (الرئيسية)
      String? imageUrl;

      // التحقق من نوع الصورة
      if (_selectedImages.first.path.startsWith('http')) {
        // صورة من رابط - استخدمها مباشرة
        imageUrl = _selectedImages.first.path;
      } else {
        // صورة محلية - ارفعها
        _showSuccessSnackBar('جاري رفع الصورة الرئيسية...');

        final uploadResult = await ImageUploadService.uploadSingleImage(
          _selectedImages.first,
        );

        if (uploadResult == null) {
          _showErrorSnackBar(
            'فشل في رفع الصورة الرئيسية!\n\n'
            'تحقق من:\n'
            '• حجم الصورة (أقل من 50MB)\n'
            '• نوع الصورة (JPG, PNG, GIF, WEBP)\n'
            '• اتصالك بالإنترنت',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        imageUrl = uploadResult;
        _showSuccessSnackBar('تم رفع الصورة الرئيسية بنجاح! ✅');
      }

      final wholesalePrice =
          double.tryParse(_wholesalePriceController.text) ?? 0.0;
      final minPrice = _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text) ?? wholesalePrice
          : wholesalePrice;
      final maxPrice = _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text) ?? (wholesalePrice * 1.5)
          : (wholesalePrice * 1.5);
      final stockQuantity = int.tryParse(_stockQuantityController.text) ?? 100;

      // التحقق من صحة البيانات الرقمية
      if (wholesalePrice <= 0) {
        _showErrorSnackBar('يرجى إدخال سعر جملة صحيح');
        return;
      }

      // إعداد الصور الإضافية
      List<String> additionalImages = [];
      if (_selectedImages.length > 1) {
        // رفع باقي الصور (إذا كان هناك أكثر من صورة)
        for (int i = 1; i < _selectedImages.length; i++) {
          String? additionalUrl;

          if (_selectedImages[i].path.startsWith('http')) {
            // صورة تجريبية من رابط
            additionalUrl = _selectedImages[i].path;
          } else {
            // صورة محلية - ارفعها
            additionalUrl = await ImageUploadService.uploadImageWithValidation(
              _selectedImages[i],
            );
          }

          if (additionalUrl != null) {
            additionalImages.add(additionalUrl);
          }
        }
      }

      // طباعة البيانات للتشخيص
      debugPrint('🔍 بيانات المنتج قبل الحفظ:');
      debugPrint('الاسم: ${_nameController.text.trim()}');
      debugPrint('الوصف: ${_descriptionController.text.trim()}');
      debugPrint('سعر الجملة: $wholesalePrice');
      debugPrint('الحد الأدنى: $minPrice');
      debugPrint('الحد الأعلى: $maxPrice');
      debugPrint('الصورة الرئيسية: $imageUrl');
      debugPrint(
        'الفئة: ${_selectedCategory.isEmpty ? 'عام' : _selectedCategory}',
      );
      debugPrint('الكمية: $stockQuantity');
      debugPrint('الصور الإضافية: $additionalImages');

      // حفظ المنتج مع جميع الصور
      await AdminService.addProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        wholesalePrice: wholesalePrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        imageUrl: imageUrl.isNotEmpty
            ? imageUrl
            : 'https://via.placeholder.com/400x300/1a1a2e/ffd700?text=منتج+جديد',
        category: _selectedCategory.isEmpty ? 'عام' : _selectedCategory,
        availableQuantity: stockQuantity,
        additionalImages: additionalImages,
      );

      _showSuccessSnackBar('تم إضافة المنتج بنجاح! ✅');

      // العودة إلى لوحة التحكم
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/admin');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في إضافة المنتج: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      String errorMessage = 'خطأ في إضافة المنتج';

      if (e.toString().contains('available_quantity')) {
        errorMessage = 'خطأ في قاعدة البيانات - يرجى المحاولة مرة أخرى';
      } else if (e.toString().contains('duplicate')) {
        errorMessage = 'اسم المنتج موجود بالفعل';
      } else if (e.toString().contains('relation "products" does not exist')) {
        errorMessage = 'جدول المنتجات غير موجود في قاعدة البيانات';
      } else if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
        errorMessage = 'هيكل قاعدة البيانات غير صحيح';
      } else if (e.toString().contains('images')) {
        errorMessage = 'خطأ في رفع الصور';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية لإضافة المنتجات';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'فشل في رفع الصور إلى التخزين السحابي';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى';
      }

      _showErrorSnackBar('$errorMessage\n\nتفاصيل الخطأ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(FontAwesomeIcons.heart, color: Color(0xFFffd700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // صندوق المعلومات النهائي
  Widget _buildFinalInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              FontAwesomeIcons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بعد الحفظ:',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'سيتم إضافة المنتج إلى قائمة المنتجات وسيكون متاحاً للتجار فوراً',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
