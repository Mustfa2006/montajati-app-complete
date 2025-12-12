import '../models/province.dart';
import '../models/city.dart';
import '../services/location_api_service.dart';

abstract class LocationRepository {
  Future<List<Province>> getProvinces();
  Future<List<City>> getCities(String provinceId);
}

class LocationRepositoryImpl implements LocationRepository {
  @override
  Future<List<Province>> getProvinces() async {
    try {
      return await LocationApiService.getProvinces();
    } catch (e) {
      // Return empty list or throw failure depending on strategy.
      // Failure allows UI to show specific localized error.
      // For now, let's allow throwing so Provider handles it.
      rethrow;
    }
  }

  @override
  Future<List<City>> getCities(String provinceId) async {
    try {
      return await LocationApiService.getCities(provinceId);
    } catch (e) {
      rethrow;
    }
  }
}
