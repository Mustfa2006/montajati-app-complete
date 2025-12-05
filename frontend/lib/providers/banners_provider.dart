import 'dart:async';
import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../services/repository/banners_repository.dart';

/// مزود البانرات الإعلانية - يدير حالة البانرات والتقليب التلقائي
class BannersProvider extends ChangeNotifier {
  final BannersRepository _repository;

  // الحالة
  List<BannerModel> _banners = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;
  PageController? _pageController;

  // إعدادات التقليب التلقائي
  static const Duration _autoSlideDuration = Duration(seconds: 5);
  static const Duration _animationDuration = Duration(milliseconds: 800);

  BannersProvider({BannersRepository? repository}) : _repository = repository ?? BannersRepository();

  // Getters
  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  int get currentIndex => _currentIndex;
  bool get isEmpty => _banners.isEmpty && !_isLoading;
  bool get hasMultipleBanners => _banners.length > 1;

  /// تعيين PageController للتحكم بالتقليب
  void setPageController(PageController controller) {
    _pageController = controller;
  }

  /// تحميل البانرات
  Future<void> loadBanners() async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _banners = await _repository.getBanners();

      // بدء التقليب التلقائي إذا كان هناك أكثر من بانر
      if (_banners.length > 1) {
        _startAutoSlide();
      }
    } catch (e) {
      _hasError = true;
      debugPrint('❌ خطأ في تحميل البانرات: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// بدء التقليب التلقائي
  void _startAutoSlide() {
    _stopAutoSlide();
    _autoSlideTimer = Timer.periodic(_autoSlideDuration, (_) {
      _slideToNext();
    });
  }

  /// إيقاف التقليب التلقائي
  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  /// إيقاف مؤقت ثم استئناف
  void pauseAutoSlide() {
    _stopAutoSlide();
    Timer(const Duration(seconds: 3), () {
      if (_banners.length > 1) _startAutoSlide();
    });
  }

  /// الانتقال للبانر التالي
  void _slideToNext() {
    if (_pageController == null || !_pageController!.hasClients) return;
    if (_pageController!.positions.isEmpty) return;

    final nextIndex = (_currentIndex + 1) % _banners.length;
    _pageController!.animateToPage(nextIndex, duration: _animationDuration, curve: Curves.easeInOutCubic);
  }

  /// تحديث الفهرس الحالي
  void updateCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// التنظيف
  @override
  void dispose() {
    _stopAutoSlide();
    super.dispose();
  }
}
