import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/simple_product_service.dart';
import '../services/basic_product_service.dart';

class SimpleAddProductPage extends StatefulWidget {
  const SimpleAddProductPage({super.key});

  @override
  State<SimpleAddProductPage> createState() => _SimpleAddProductPageState();
}

class _SimpleAddProductPageState extends State<SimpleAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '100');
  final _availableFromController = TextEditingController(text: '90');
  final _availableToController = TextEditingController(text: '80');

  String _selectedCategory = 'عام';
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'عام',
    'إلكترونيات',
    'ملابس',
    'طعام ومشروبات',
    'منزل وحديقة',
    'رياضة',
    'جمال وعناية',
    'كتب',
    'ألعاب',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(
          'إضافة منتج جديد',
          style: GoogleFonts.cairo(
            color: const Color(0xFFffd700),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF16213e),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFffd700)),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // اسم المنتج
              _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج',
                icon: FontAwesomeIcons.tag,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'يرجى إدخال اسم المنتج';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // الوصف
              _buildTextField(
                controller: _descriptionController,
                label: 'وصف المنتج',
                icon: FontAwesomeIcons.alignLeft,
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'يرجى إدخال وصف المنتج';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // الأسعار
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _wholesalePriceController,
                      label: 'سعر الجملة',
                      icon: FontAwesomeIcons.dollarSign,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'مطلوب';
                        if (double.tryParse(value!) == null) {
                          return 'رقم غير صحيح';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _minPriceController,
                      label: 'الحد الأدنى',
                      icon: FontAwesomeIcons.arrowDown,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      label: 'الحد الأعلى',
                      icon: FontAwesomeIcons.arrowUp,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // الفئة
              _buildDropdown(),
              const SizedBox(height: 20),

              // الكمية المخزونة (مخفية عن المستخدم)
              _buildTextField(
                controller: _stockQuantityController,
                label: 'الكمية المخزونة (إجمالي)',
                icon: FontAwesomeIcons.boxesStacked,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'مطلوب';
                  if (int.tryParse(value!) == null) return 'رقم غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // الكمية المتاحة للعرض (من - إلى)
              _buildAvailableQuantitySection(),
              const SizedBox(height: 20),

              // اختيار الصور
              _buildImagePicker(),
              const SizedBox(height: 30),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFffd700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF1a1a2e),
                        )
                      : Text(
                          'حفظ المنتج',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a1a2e),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: const Color(0xFFffd700)),
        prefixIcon: Icon(icon, color: const Color(0xFFffd700)),
        filled: true,
        fillColor: const Color(0xFF16213e),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFffd700)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFffd700)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF16213e),
          style: GoogleFonts.cairo(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFffd700)),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAvailableQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الكمية المتاحة للعرض',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _availableFromController,
                  label: 'من',
                  icon: FontAwesomeIcons.arrowRight,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (int.tryParse(value!) == null) return 'رقم غير صحيح';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 15),
              Text(
                'إلى',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  controller: _availableToController,
                  label: 'إلى',
                  icon: FontAwesomeIcons.arrowLeft,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (int.tryParse(value!) == null) {
                      return 'رقم غير صحيح';
                    }

                    // التحقق من أن "إلى" أقل من "من"
                    final fromValue = int.tryParse(
                      _availableFromController.text,
                    );
                    final toValue = int.tryParse(value);
                    if (fromValue != null && toValue != null) {
                      if (toValue >= fromValue) {
                        return '"إلى" يجب أن يكون أقل من "من"';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '💡 ملاحظة: "من" يجب أن يكون أكبر من "إلى" - سيتم تقليل العدد تلقائياً مع كل حجز',
            style: GoogleFonts.cairo(
              color: Colors.orange,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: Column(
        children: [
          Text(
            'صور المنتج',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(FontAwesomeIcons.camera),
            label: Text('اختيار الصور', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              'تم اختيار ${_selectedImages.length} صورة',
              style: GoogleFonts.cairo(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('يرجى اختيار صورة واحدة على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wholesalePrice = double.parse(_wholesalePriceController.text);
      final minPrice = _minPriceController.text.isNotEmpty
          ? double.parse(_minPriceController.text)
          : wholesalePrice;
      final maxPrice = _maxPriceController.text.isNotEmpty
          ? double.parse(_maxPriceController.text)
          : wholesalePrice * 1.5;
      final stockQuantity = int.parse(_stockQuantityController.text);
      final availableFrom = int.parse(_availableFromController.text);
      final availableTo = int.parse(_availableToController.text);

      // جرب الخدمة الجديدة أولاً، وإذا فشلت استخدم الخدمة الأساسية
      Map<String, dynamic> result;

      try {
        result = await SimpleProductService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          wholesalePrice: wholesalePrice,
          minPrice: minPrice,
          maxPrice: maxPrice,
          images: _selectedImages,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
          availableFrom: availableFrom,
          availableTo: availableTo,
        );
      } catch (e) {
        // إذا فشلت الخدمة الجديدة، استخدم الخدمة الأساسية
        debugPrint('⚠️ فشل في الخدمة الجديدة، التبديل للخدمة الأساسية: $e');
        result = await BasicProductService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          wholesalePrice: wholesalePrice,
          minPrice: minPrice,
          maxPrice: maxPrice,
          images: _selectedImages,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
        );
      }

      if (result['success']) {
        _showSuccessSnackBar('✅ تم إضافة المنتج بنجاح!');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/admin');
        });
      } else {
        _showErrorSnackBar('❌ ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('❌ خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
