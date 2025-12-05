import '../../models/banner_model.dart';
import '../api/banners_api.dart';

/// مستودع البانرات الإعلانية
class BannersRepository {
  final BannersApi _api;
  
  // كاش بسيط في الذاكرة
  static List<BannerModel>? _memoryCache;
  
  BannersRepository({BannersApi? api}) : _api = api ?? BannersApi();

  /// جلب البانرات
  Future<List<BannerModel>> getBanners({bool forceRefresh = false}) async {
    // إرجاع الكاش إذا موجود
    if (!forceRefresh && _memoryCache != null && _memoryCache!.isNotEmpty) {
      return _memoryCache!;
    }

    // جلب من السيرفر
    final banners = await _api.fetchBanners();
    _memoryCache = banners;
    
    return banners;
  }

  /// مسح الكاش
  void clearCache() {
    _memoryCache = null;
  }
}

