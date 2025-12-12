import 'package:flutter/material.dart';
import '../models/order_details.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../models/update_order_request.dart';
import '../repositories/order_repository.dart';
import '../repositories/location_repository.dart';
import '../core/error/edit_order_failure.dart';

class EditOrderProvider extends ChangeNotifier {
  // Dependencies
  final OrderRepository _orderRepository;
  final LocationRepository _locationRepository;

  // Domain State
  OrderDetails? _order;
  String? _orderId;
  bool _isScheduled = false;

  List<Province> _provinces = [];
  List<City> _cities = [];

  // UI State
  bool _isLoadingOrder = false;
  bool _isSaving = false;
  bool _isLoadingCities = false;

  EditOrderFailure? _failure;

  // Selection State (Still needed for saving logic, but filtering is gone)
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedProvinceId;
  DateTime? _selectedScheduledDate;

  // Getters
  OrderDetails? get order => _order;
  List<Province> get provinces => _provinces;
  List<City> get cities => _cities;

  bool get isLoadingOrder => _isLoadingOrder;
  bool get isSaving => _isSaving;
  bool get isLoadingCities => _isLoadingCities;
  EditOrderFailure? get failure => _failure;

  String? get selectedProvince => _selectedProvince;
  String? get selectedCity => _selectedCity;
  DateTime? get selectedScheduledDate => _selectedScheduledDate;
  bool get isScheduled => _isScheduled;

  EditOrderProvider({required OrderRepository orderRepository, required LocationRepository locationRepository})
    : _orderRepository = orderRepository,
      _locationRepository = locationRepository;

  // Initialization
  Future<void> init(String orderId, bool isScheduled) async {
    _orderId = orderId;
    _isScheduled = isScheduled;
    await loadData();
  }

  Future<void> loadData() async {
    _isLoadingOrder = true;
    _failure = null;
    notifyListeners();

    try {
      await Future.wait([_loadProvinces(), _loadOrderWrapper()]);

      _isLoadingOrder = false;
      notifyListeners();
    } catch (e) {
      if (e is EditOrderFailure) {
        _failure = e;
      } else {
        _failure = EditOrderFailure.unknown(e.toString());
      }
      _isLoadingOrder = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrderWrapper() async {
    if (_isScheduled) {
      _order = await _orderRepository.getScheduledOrder(_orderId!);
    } else {
      _order = await _orderRepository.getOrder(_orderId!);
    }

    // Initialize selection state
    if (_order != null) {
      _selectedProvince = _order!.location.province;
      _selectedCity = _order!.location.city;
      _selectedScheduledDate = _order!.scheduledDate;

      if (_selectedProvince != null && _provinces.isNotEmpty) {
        try {
          final p = _provinces.firstWhere((element) => element.name == _selectedProvince);
          _selectedProvinceId = p.id;
          await _loadCitiesInternal(p.id);
        } catch (_) {}
      }
    }
  }

  Future<void> _loadProvinces() async {
    try {
      _provinces = await _locationRepository.getProvinces();
    } catch (e) {
      debugPrint("Provinces load error: $e");
    }
  }

  Future<void> _loadCitiesInternal(String provinceId) async {
    _isLoadingCities = true;
    notifyListeners();
    try {
      _cities = await _locationRepository.getCities(provinceId);
    } catch (_) {}
    _isLoadingCities = false;
    notifyListeners();
  }

  // User Actions
  void selectProvince(Province p) {
    _selectedProvince = p.name;
    _selectedProvinceId = p.id;
    _selectedCity = null;
    _cities = []; // Clear cities until loaded
    _loadCitiesInternal(p.id);
    notifyListeners();
  }

  void selectCity(City c) {
    _selectedCity = c.name;
    notifyListeners();
  }

  void selectDate(DateTime d) {
    _selectedScheduledDate = d;
    notifyListeners();
  }

  // Saving
  Future<bool> saveOrder(UpdateOrderRequest request) async {
    _isSaving = true;
    _failure = null;
    notifyListeners();

    try {
      await _orderRepository.updateOrder(request);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      if (e is EditOrderFailure) {
        _failure = e;
      } else {
        _failure = EditOrderFailure.unknown(e.toString());
      }
      notifyListeners();
      return false;
    }
  }
}
