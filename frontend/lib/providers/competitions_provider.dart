import 'package:flutter/foundation.dart';

import '../models/competition.dart';
import '../services/competitions_api_service.dart';

class CompetitionsProvider with ChangeNotifier {
  final List<Competition> _allItems = [];
  final List<Competition> _mineItems = [];
  bool _loaded = false;
  String _currentFilter = 'all';

  List<Competition> get competitions =>
      _currentFilter == 'all' ? List.unmodifiable(_allItems) : List.unmodifiable(_mineItems);
  List<Competition> get allCompetitions => List.unmodifiable(_allItems);
  List<Competition> get myCompetitions => List.unmodifiable(_mineItems);
  bool get isLoaded => _loaded;
  String get currentFilter => _currentFilter;

  void setFilter(String filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  // تحميل للجميع
  Future<void> loadAll() async {
    try {
      final data = await CompetitionsApiService.fetchPublic(filter: 'all');
      _allItems
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading all competitions: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // تحميل مسابقاتي
  Future<void> loadMine() async {
    try {
      final data = await CompetitionsApiService.fetchPublic(filter: 'mine');
      _mineItems
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading my competitions: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // تحميل كلاهما
  Future<void> load() async {
    await Future.wait([loadAll(), loadMine()]);
  }

  // تحميل إداري: كل المسابقات
  Future<void> loadAdmin() async {
    try {
      final data = await CompetitionsApiService.fetchAllAdmin();
      _allItems
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
        _allItems.add(created);
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
        final idx = _allItems.indexWhere((x) => x.id == updated.id);
        if (idx != -1) {
          _allItems[idx] = updated;
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
        _allItems.removeWhere((x) => x.id == id);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteCompetition error: $e');
    }
  }

  // Helpers
  Competition? getById(String id) {
    try {
      return _allItems.firstWhere((x) => x.id == id);
    } catch (_) {
      return null;
    }
  }
}
