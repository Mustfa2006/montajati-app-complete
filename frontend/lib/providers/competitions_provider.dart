import 'package:flutter/foundation.dart';

import '../models/competition.dart';
import '../services/competitions_api_service.dart';

class CompetitionsProvider with ChangeNotifier {
  final List<Competition> _items = [];
  bool _loaded = false;

  List<Competition> get competitions => List.unmodifiable(_items);
  bool get isLoaded => _loaded;

  // تحميل عام (للمستخدمين): المسابقات النشطة فقط من الباك اند
  Future<void> load() async {
    try {
      final data = await CompetitionsApiService.fetchPublic();
      _items
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading public competitions: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // تحميل إداري: كل المسابقات
  Future<void> loadAdmin() async {
    try {
      final data = await CompetitionsApiService.fetchAllAdmin();
      _items
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading admin competitions: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> refresh({bool admin = false}) async {
    _loaded = false;
    notifyListeners();
    if (admin) {
      await loadAdmin();
    } else {
      await load();
    }
  }

  // CRUD عبر الباك اند (يتطلب صلاحيات للمشرف)
  Future<void> addCompetition(Competition c) async {
    try {
      final created = await CompetitionsApiService.createAdmin(c);
      if (created != null) {
        _items.add(created);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ addCompetition error: $e');
    }
  }

  Future<void> updateCompetition(Competition c) async {
    try {
      final updated = await CompetitionsApiService.updateAdmin(c);
      if (updated != null) {
        final idx = _items.indexWhere((x) => x.id == updated.id);
        if (idx != -1) {
          _items[idx] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateCompetition error: $e');
    }
  }

  Future<void> deleteCompetition(String id) async {
    try {
      final ok = await CompetitionsApiService.deleteAdmin(id);
      if (ok) {
        _items.removeWhere((x) => x.id == id);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteCompetition error: $e');
    }
  }

  // Helpers
  Competition? getById(String id) {
    try {
      return _items.firstWhere((x) => x.id == id);
    } catch (_) {
      return null;
    }
  }
}
