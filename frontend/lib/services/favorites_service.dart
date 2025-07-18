// خدمة إدارة المفضلة - Favorites Service
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'user_favorites';
  static FavoritesService? _instance;

  // Singleton pattern
  static FavoritesService get instance {
    _instance ??= FavoritesService._();
    return _instance!;
  }

  FavoritesService._();

  // قائمة المفضلة الحالية
  List<Product> _favorites = [];

  // الحصول على قائمة المفضلة
  List<Product> get favorites => List.unmodifiable(_favorites);

  // تحميل المفضلة من التخزين المحلي
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favorites = favoritesList
            .map((item) => Product.fromJson(item))
            .toList();
        print('✅ تم تحميل ${_favorites.length} منتج من المفضلة');
      }
    } catch (e) {
      print('❌ خطأ في تحميل المفضلة: $e');
      _favorites = [];
    }
  }

  // حفظ المفضلة في التخزين المحلي
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(
        _favorites.map((product) => product.toJson()).toList(),
      );
      await prefs.setString(_favoritesKey, favoritesJson);
      print('💾 تم حفظ ${_favorites.length} منتج في المفضلة');
    } catch (e) {
      print('❌ خطأ في حفظ المفضلة: $e');
    }
  }

  // إضافة منتج للمفضلة
  Future<bool> addToFavorites(Product product) async {
    try {
      if (!isFavorite(product.id)) {
        _favorites.add(product);
        await _saveFavorites();
        notifyListeners();
        print('❤️ تم إضافة ${product.name} للمفضلة');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في إضافة المنتج للمفضلة: $e');
      return false;
    }
  }

  // إزالة منتج من المفضلة
  Future<bool> removeFromFavorites(String productId) async {
    try {
      final initialLength = _favorites.length;
      _favorites.removeWhere((product) => product.id == productId);

      if (_favorites.length < initialLength) {
        await _saveFavorites();
        notifyListeners();
        print('💔 تم إزالة المنتج من المفضلة');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في إزالة المنتج من المفضلة: $e');
      return false;
    }
  }

  // التبديل بين إضافة وإزالة المنتج من المفضلة
  Future<bool> toggleFavorite(Product product) async {
    if (isFavorite(product.id)) {
      return await removeFromFavorites(product.id);
    } else {
      return await addToFavorites(product);
    }
  }

  // التحقق من وجود المنتج في المفضلة
  bool isFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }

  // الحصول على عدد المنتجات في المفضلة
  int get favoritesCount => _favorites.length;

  // مسح جميع المفضلة
  Future<void> clearFavorites() async {
    try {
      _favorites.clear();
      await _saveFavorites();
      notifyListeners();
      print('🗑️ تم مسح جميع المفضلة');
    } catch (e) {
      print('❌ خطأ في مسح المفضلة: $e');
    }
  }

  // البحث في المفضلة
  List<Product> searchFavorites(String query) {
    if (query.isEmpty) return _favorites;

    return _favorites.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // ترتيب المفضلة حسب السعر
  List<Product> getFavoritesSortedByPrice({bool ascending = true}) {
    final sortedList = List<Product>.from(_favorites);
    sortedList.sort((a, b) {
      if (ascending) {
        return a.wholesalePrice.compareTo(b.wholesalePrice);
      } else {
        return b.wholesalePrice.compareTo(a.wholesalePrice);
      }
    });
    return sortedList;
  }

  // ترتيب المفضلة حسب الاسم
  List<Product> getFavoritesSortedByName({bool ascending = true}) {
    final sortedList = List<Product>.from(_favorites);
    sortedList.sort((a, b) {
      if (ascending) {
        return a.name.compareTo(b.name);
      } else {
        return b.name.compareTo(a.name);
      }
    });
    return sortedList;
  }

  // الحصول على إحصائيات المفضلة
  Map<String, dynamic> getFavoritesStats() {
    if (_favorites.isEmpty) {
      return {
        'totalProducts': 0,
        'averagePrice': 0.0,
        'minPrice': 0.0,
        'maxPrice': 0.0,
        'totalValue': 0.0,
      };
    }

    final prices = _favorites.map((p) => p.wholesalePrice).toList();
    final totalValue = prices.reduce((a, b) => a + b);

    return {
      'totalProducts': _favorites.length,
      'averagePrice': totalValue / _favorites.length,
      'minPrice': prices.reduce((a, b) => a < b ? a : b),
      'maxPrice': prices.reduce((a, b) => a > b ? a : b),
      'totalValue': totalValue,
    };
  }
}
