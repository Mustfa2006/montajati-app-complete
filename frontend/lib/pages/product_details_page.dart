import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../services/cart_service.dart';
// تم إزالة استيراد favorites_service غير المستخدم
import '../utils/number_formatter.dart';
import '../services/permissions_service.dart';
import '../widgets/common_header.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  double _customerPrice = 0;
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();
  final CartService _cartService = CartService();
  // تم إزالة _favoritesService غير المستخدم
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final List<double> _pinnedPrices = [];
  bool _isPriceValid = false;
  // تم إزالة _isFavorite غير المستخدم
  bool favoriteState = false;

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _checkIfFavorite();
    _requestPermissions();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // طلب الصلاحيات فقط في المرة الأولى
  Future<void> _requestPermissions() async {
    await PermissionsService.requestPermissionsIfNeeded();
  }

  // التحقق من حالة المفضلة
  void _checkIfFavorite() {
    setState(() {
      // _isFavorite = _favoritesService.isFavorite(widget.productId);
      // للاختبار، نبدأ بـ false
      // _isFavorite = false;
    });
  }

  // تبديل حالة المفضلة مع انيميشن
  void _toggleFavorite() {
    final product = _productData;
    if (product == null) return;

    setState(() {
      // تبديل الحالة
      favoriteState = !favoriteState;
    });

    // if (currentFavorite) {
    //   _favoritesService.addToFavorites(
    //     widget.productId,
    //     product['name'] ?? 'منتج',
    //     _getImagesList(product).first,
    //     (product['wholesale_price'] ?? 0).toDouble(),
    //   );
    // } else {
    //   _favoritesService.removeFromFavorites(widget.productId);
    // }

    // عرض رسالة تأكيد مع انيميشن
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              favoriteState
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heartCrack,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              favoriteState
                  ? 'تم إضافة المنتج للمفضلة ❤️'
                  : 'تم إزالة المنتج من المفضلة 💔',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: favoriteState ? Colors.green : Colors.orange,
        duration: Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Future<void> _loadProductData() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .eq('id', widget.productId)
          .single();

      setState(() {
        _productData = response;
        _isLoading = false;
        _customerPrice = 0; // البدء بسعر فارغ
        _priceController.text = ''; // شريط فارغ
      });
    } catch (e) {
      setState(() {
        _productData = {
          'id': widget.productId,
          'name': 'منتج تجريبي',
          'description':
              'وصف المنتج التجريبي مع تفاصيل كاملة عن المنتج وخصائصه ومميزاته',
          'wholesale_price': 50000,
          'min_price': 60000,
          'max_price': 80000,
          'images': [
            'https://picsum.photos/400/400?random=1',
            'https://picsum.photos/400/400?random=2',
            'https://picsum.photos/400/400?random=3',
            'https://picsum.photos/400/400?random=4',
          ],
          'available_quantity': 100,
          'category': 'عام',
        };
        _isLoading = false;
        _customerPrice = 60000;
        _priceController.text = '60000';
        _validatePrice();
      });
    }
  }

  void _validatePrice() {
    final minPrice = (_productData?['min_price'] ?? 0).toDouble();
    final maxPrice = (_productData?['max_price'] ?? 0).toDouble();
    setState(() {
      _isPriceValid =
          _customerPrice >= minPrice &&
          _customerPrice <= maxPrice &&
          _customerPrice > 0;
    });
  }

  void _pinPrice() {
    if (_isPriceValid && !_pinnedPrices.contains(_customerPrice)) {
      setState(() {
        _pinnedPrices.add(_customerPrice);
      });
    }
  }

  void _copyDescription() {
    final description = _productData?['description'] ?? '';
    Clipboard.setData(ClipboardData(text: description));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الوصف بنجاح!', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ✨ دالة فتح الصورة بحجم كامل مع التقليب
  void _openFullScreenImageViewer(int initialIndex) {
    final images = _getImagesList(_productData!);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _FullScreenImageViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  List<String> _getImagesList(Map<String, dynamic> product) {
    // التحقق من وجود مصفوفة الصور أولاً
    if (product['images'] != null && product['images'] is List) {
      final images = product['images'] as List;
      if (images.isNotEmpty) {
        return images.map((img) => img.toString()).toList();
      }
    }

    // إذا لم توجد مصفوفة صور، استخدم image_url
    if (product['image_url'] != null &&
        product['image_url'].toString().isNotEmpty) {
      return [product['image_url'].toString()];
    }

    // إذا لم توجد أي صور، استخدم صورة افتراضية
    return ['https://picsum.photos/400/400?random=1'];
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تحميل الصور',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFffd700),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(
                FontAwesomeIcons.download,
                color: Color(0xFFffd700),
              ),
              title: Text(
                'تحميل الصورة الحالية',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadCurrentImage();
              },
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.images, color: Color(0xFFffd700)),
              title: Text(
                'تحميل جميع الصور',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadAllImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  // تحميل الصورة الحالية
  Future<void> _downloadCurrentImage() async {
    final images = _getImagesList(_productData!);
    if (images.isNotEmpty) {
      final currentImageUrl = images[_currentImageIndex];
      final productName = _productData!['name'] ?? 'منتج';
      await _downloadImage(
        currentImageUrl,
        '${productName}_صورة_${_currentImageIndex + 1}',
      );
    }
  }

  // تحميل جميع الصور
  Future<void> _downloadAllImages() async {
    final images = _getImagesList(_productData!);
    final productName = _productData!['name'] ?? 'منتج';

    // عرض رسالة بدء التحميل
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'جاري تحميل ${images.length} صور...',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    // تحميل جميع الصور
    int successCount = 0;
    for (int i = 0; i < images.length; i++) {
      final success = await _downloadImage(
        images[i],
        '${productName}_صورة_${i + 1}',
        showMessage: false,
      );
      if (success) successCount++;
    }

    // عرض رسالة النتيجة النهائية
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == images.length
              ? '✅ تم تحميل جميع الصور بنجاح ($successCount/${images.length})'
              : '⚠️ تم تحميل $successCount من ${images.length} صور',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: successCount == images.length
            ? Colors.green
            : Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // تحميل صورة واحدة مباشرة
  Future<bool> _downloadImage(
    String imageUrl,
    String fileName, {
    bool showMessage = true,
  }) async {
    try {
      if (kIsWeb) {
        // للويب: تحميل مباشر
        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode == 200) {
          // إشعار بنجاح التحميل (تم إزالة تحميل الصور لتجنب مشاكل التوافق)
          if (showMessage && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ تم تحميل الصورة',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return true;
        } else {
          throw 'فشل في تحميل الصورة: ${response.statusCode}';
        }
      } else {
        // للهاتف: التحقق من الصلاحيات أولاً
        final hasPermission = await PermissionsService.hasStoragePermission();

        if (!hasPermission) {
          // محاولة طلب الصلاحيات مرة أخرى
          await PermissionsService.requestAllPermissions();

          // التحقق مرة أخرى
          final hasPermissionAfterRequest = await PermissionsService.hasStoragePermission();

          if (!hasPermissionAfterRequest) {
            if (showMessage && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '❌ يرجى السماح بالوصول للتخزين لتحميل الصور',
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return false;
          }
        }

        // تحميل الصورة وحفظها في معرض الصور
        debugPrint('🔄 بدء تحميل الصورة: $imageUrl');
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;

          // إنشاء اسم الملف مع التاريخ
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String fileExtension = imageUrl.split('.').last.split('?').first;
          final String fullFileName = '${fileName}_$timestamp.$fileExtension';

          debugPrint('💾 حفظ الصورة...');

          if (kIsWeb) {
            // في الويب، نعرض رسالة أن الميزة غير متاحة
            debugPrint('⚠️ تحميل الصور غير متاح في إصدار الويب');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تحميل الصور متاح في تطبيق الهاتف فقط'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return false;
          } else {
            // للمنصات الأخرى (Android/iOS/Desktop)
            try {
              // محاولة حفظ في معرض الهاتف أولاً
              final result = await _saveToGallery(bytes, fullFileName);
              if (result) {
                debugPrint('✅ تم حفظ الصورة بنجاح في معرض الهاتف');
              } else {
                throw 'فشل في حفظ الصورة في معرض الهاتف';
              }
            } catch (e) {
              // إذا فشل، حاول حفظ في مجلد Downloads
              await _saveToDownloads(bytes, fullFileName);
              debugPrint('✅ تم حفظ الصورة في مجلد التحميلات');
            }
          }

          // إشعار بنجاح التحميل والحفظ
          if (showMessage && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ تم حفظ الصورة  بنجاح',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return true;
        } else {
          throw 'فشل في تحميل الصورة: ${response.statusCode}';
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الصورة: $e');
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ خطأ في تحميل الصورة: $fileName\nالسبب: ${e.toString()}',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  // دالة إضافة المنتج للسلة
  Future<void> _addToCart() async {
    if (!mounted) return;

    final product = _productData;
    if (product == null) return;

    // إضافة المنتج مباشرة بدون رسائل

    final result = await _cartService.addItem(
      productId: widget.productId,
      name: product['name'] ?? 'منتج',
      image: _getImagesList(product).first,
      wholesalePrice: (product['wholesale_price'] ?? 0).round(),
      minPrice: (product['min_price'] ?? 0).round(),
      maxPrice: (product['max_price'] ?? 0).round(),
      customerPrice: _customerPrice.round(),
      quantity: 1,
    );

    // التحقق من mounted قبل استخدام context
    if (!mounted) return;

    if (result['success']) {
      // الانتقال فوراً إلى صفحة السلة بدون رسائل
      if (mounted) {
        context.go('/cart'); // الانتقال إلى صفحة السلة
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة حفظ في معرض الهاتف (للمنصات المدعومة فقط)
  Future<bool> _saveToGallery(List<int> bytes, String fileName) async {
    if (kIsWeb) return false;

    try {
      // هذه الدالة تعمل فقط على Android/iOS
      // في الويب، نعرض رسالة أن الميزة غير متاحة
      return false;
    } catch (e) {
      return false;
    }
  }

  // دالة حفظ في مجلد التحميلات (للمنصات المدعومة فقط)
  Future<void> _saveToDownloads(List<int> bytes, String fileName) async {
    if (kIsWeb) return;

    try {
      // هذه الدالة تعمل فقط على Desktop
      // في الويب، نعرض رسالة أن الميزة غير متاحة
      debugPrint('تحميل الملفات غير متاح في إصدار الويب');
    } catch (e) {
      debugPrint('خطأ في حفظ الملف: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFffd700)),
        ),
      );
    }

    final product = _productData!;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'منتجاتي',
            leftActions: [
              // زر المفضلة مع انيميشن
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: GestureDetector(
                  onTap: _toggleFavorite,
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
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        favoriteState
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heartCrack,
                        key: ValueKey(favoriteState),
                        color: Color(0xFFff2d55),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showDownloadOptions,
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
                    FontAwesomeIcons.download,
                    color: Color(0xFFffd700),
                    size: 16,
                  ),
                ),
              ),
            ],
            rightActions: [
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
          ),
          // المحتوى
          Expanded(
            child: Stack(
        children: [
          // المحتوى القابل للتمرير
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معرض الصور
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Color(0xFF16213e),
                    border: Border.all(
                      color: Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFffd700).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: _getImagesList(product).length,
                          itemBuilder: (context, index) {
                            final images = _getImagesList(product);
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Color(0xFF16213e),
                              child: GestureDetector(
                                onTap: () => _openFullScreenImageViewer(index),
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFF16213e),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.image,
                                              size: 50,
                                              color: Colors.white54,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'لا يمكن تحميل الصورة',
                                              style: GoogleFonts.cairo(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // مؤشر الصور بدون خلفية
                      if (_getImagesList(product).length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _getImagesList(product).length,
                              (index) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 12 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _currentImageIndex == index
                                      ? Color(0xFFffd700)
                                      : Colors.white.withValues(alpha: 0.7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // عداد الصور
                      if (_getImagesList(product).length > 1)
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Color(0xFFffd700).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${_getImagesList(product).length}',
                              style: GoogleFonts.cairo(
                                color: Color(0xFFffd700),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // اسم المنتج
                Text(
                  product['name'] ?? 'منتج بدون اسم',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20),

                // معلومات الأسعار
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الأسعار',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFffd700),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'سعر الجملة:',
                            style: GoogleFonts.cairo(color: Colors.white70),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(
                              product['wholesale_price'],
                            ),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الحد الأدنى:',
                            style: GoogleFonts.cairo(color: Colors.green),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(
                              product['min_price'],
                            ),
                            style: GoogleFonts.cairo(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الحد الأقصى:',
                            style: GoogleFonts.cairo(color: Colors.red),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(
                              product['max_price'],
                            ),
                            style: GoogleFonts.cairo(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // تحديد السعر
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحديد سعر البيع',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFffd700),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              focusNode: _priceFocusNode,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              enabled: true,
                              readOnly: false,
                              style: GoogleFonts.cairo(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'السعر للعميل',
                                labelStyle: GoogleFonts.cairo(
                                  color: Colors.white70,
                                ),
                                border: InputBorder.none,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _isPriceValid
                                        ? Colors.green
                                        : Color(0xFFffd700),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _isPriceValid
                                        ? Colors.green
                                        : Color(0xFFffd700),
                                    width: 2,
                                  ),
                                ),
                                suffixText: 'د.ع',
                                suffixStyle: GoogleFonts.cairo(
                                  color: Color(0xFFffd700),
                                ),
                              ),
                              onTap: () {
                                // التأكد من أن الـ TextField يحصل على التركيز
                                _priceFocusNode.requestFocus();
                              },
                              onChanged: (value) {
                                final price = double.tryParse(value) ?? 0;
                                setState(() {
                                  _customerPrice = price;
                                  _validatePrice();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          // زر تثبيت السعر
                          SizedBox(
                            width: 35,
                            height: 35,
                            child: ElevatedButton(
                              onPressed: _isPriceValid ? _pinPrice : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPriceValid
                                    ? Color(0xFFffd700)
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Icon(
                                FontAwesomeIcons.thumbtack,
                                color: Color(0xFF1a1a2e),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // عرض الربح فقط عند كتابة السعر
                      if (_customerPrice > 0)
                        Text(
                          'الربح المتوقع: ${NumberFormatter.formatCurrency(_customerPrice - (product['wholesale_price'] ?? 0))}',
                          style: GoogleFonts.cairo(
                            color:
                                _customerPrice >
                                    (product['wholesale_price'] ?? 0)
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      // الأسعار المثبتة
                      if (_pinnedPrices.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _pinnedPrices
                                .map(
                                  (price) => GestureDetector(
                                    onLongPress: () {
                                      // ✨ حذف السعر المثبت بالنقر المطول
                                      setState(() {
                                        _pinnedPrices.remove(price);
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '🗑️ تم حذف السعر المثبت',
                                            style: GoogleFonts.cairo(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _customerPrice = price;
                                          _priceController.text =
                                              NumberFormatter.formatNumber(
                                                price,
                                              );
                                          _validatePrice();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFffd700),
                                        foregroundColor: Color(0xFF1a1a2e),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text(
                                        NumberFormatter.formatCurrency(price),
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // مربع الوصف
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'وصف المنتج',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFffd700),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyDescription,
                            icon: Icon(
                              FontAwesomeIcons.copy,
                              color: Color(0xFFffd700),
                              size: 18,
                            ),
                            tooltip: 'نسخ الوصف',
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        product['description'] ?? 'لا يوجد وصف',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100), // مساحة إضافية للزر الثابت
              ],
            ),
          ),

          // ✨ زر إضافة للسلة الفخم والأنيق
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _isPriceValid
                    ? LinearGradient(
                        colors: [
                          Color(0xFFffd700),
                          Color(0xFFffed4e),
                          Color(0xFFffd700),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Color(0xFF3a3a3a), Color(0xFF2a2a2a)],
                      ),
                boxShadow: _isPriceValid
                    ? [
                        BoxShadow(
                          color: Color(0xFFffd700).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Color(0xFFffd700).withValues(alpha: 0.2),
                          blurRadius: 25,
                          offset: Offset(0, 15),
                          spreadRadius: 5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isPriceValid ? _addToCart : null,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: _isPriceValid
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.transparent,
                  highlightColor: _isPriceValid
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isPriceValid
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPriceValid) ...[
                            Icon(
                              FontAwesomeIcons.cartPlus,
                              color: Color(0xFF1a1a2e),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                          ],
                          Text(
                            _isPriceValid ? 'إضافة للسلة' : 'أدخل سعر صحيح',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isPriceValid
                                  ? Color(0xFF1a1a2e)
                                  : Colors.white54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_isPriceValid) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF1a1a2e).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                NumberFormatter.formatCurrency(_customerPrice),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a1a2e),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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

// ✨ عارض الصور بحجم كامل مع التقليب
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // عارض الصور
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFffd700),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.image,
                              size: 80,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'لا يمكن تحميل الصورة',
                              style: GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // مؤشر الصور في الأسفل
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 16 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: _currentIndex == index
                          ? Color(0xFFffd700)
                          : Colors.white.withValues(alpha: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
