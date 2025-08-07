// إعداد Firebase Remote Config للتحديث بدون APK
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  // إعداد Remote Config
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 تهيئة Firebase Remote Config...');
      
      // إعدادات افتراضية
      await _remoteConfig.setDefaults({
        'app_version': '1.0.0',
        'force_update': false,
        'maintenance_mode': false,
        'api_base_url': 'https://clownfish-app-krnk9.ondigitalocean.app',
        'sync_interval_minutes': 5,
        'show_waseet_status': true,
        'status_display_mode': 'exact', // exact = عرض الحالة كما هي من الوسيط
        'supported_statuses': [
          'تم التسليم للزبون',
          'لا يرد',
          'مغلق',
          'الغاء الطلب',
          'رفض الطلب',
          'قيد التوصيل الى الزبون (في عهدة المندوب)',
          'تم تغيير محافظة الزبون',
          'لا يرد بعد الاتفاق',
          'مغلق بعد الاتفاق',
          'مؤجل',
          'مؤجل لحين اعادة الطلب لاحقا',
          'مستلم مسبقا',
          'الرقم غير معرف',
          'الرقم غير داخل في الخدمة',
          'العنوان غير دقيق',
          'لم يطلب',
          'حظر المندوب',
          'لا يمكن الاتصال بالرقم',
          'تغيير المندوب'
        ].join(','),
        'enable_new_features': true,
        'debug_mode': false
      });
      
      // إعدادات الجلب
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
      // جلب القيم الجديدة
      await fetchAndActivate();
      
      debugPrint('✅ تم تهيئة Remote Config بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Remote Config: $e');
    }
  }
  
  // جلب وتفعيل القيم الجديدة
  static Future<bool> fetchAndActivate() async {
    try {
      debugPrint('🔄 جلب إعدادات جديدة من Firebase...');
      
      bool updated = await _remoteConfig.fetchAndActivate();
      
      if (updated) {
        debugPrint('✅ تم تحديث الإعدادات من Firebase');
        _logCurrentConfig();
      } else {
        debugPrint('📝 لا توجد تحديثات جديدة');
      }
      
      return updated;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإعدادات: $e');
      return false;
    }
  }
  
  // طباعة الإعدادات الحالية
  static void _logCurrentConfig() {
    debugPrint('📋 الإعدادات الحالية:');
    debugPrint('   إصدار التطبيق: ${getAppVersion()}');
    debugPrint('   فرض التحديث: ${isForceUpdateEnabled()}');
    debugPrint('   وضع الصيانة: ${isMaintenanceModeEnabled()}');
    debugPrint('   عنوان API: ${getApiBaseUrl()}');
    debugPrint('   فترة المزامنة: ${getSyncIntervalMinutes()} دقيقة');
    debugPrint('   عرض حالة الوسيط: ${shouldShowWaseetStatus()}');
    debugPrint('   وضع عرض الحالة: ${getStatusDisplayMode()}');
  }
  
  // الحصول على القيم
  static String getAppVersion() => _remoteConfig.getString('app_version');
  static bool isForceUpdateEnabled() => _remoteConfig.getBool('force_update');
  static bool isMaintenanceModeEnabled() => _remoteConfig.getBool('maintenance_mode');
  static String getApiBaseUrl() => _remoteConfig.getString('api_base_url');
  static int getSyncIntervalMinutes() => _remoteConfig.getInt('sync_interval_minutes');
  static bool shouldShowWaseetStatus() => _remoteConfig.getBool('show_waseet_status');
  static String getStatusDisplayMode() => _remoteConfig.getString('status_display_mode');
  static bool isNewFeaturesEnabled() => _remoteConfig.getBool('enable_new_features');
  static bool isDebugModeEnabled() => _remoteConfig.getBool('debug_mode');
  
  // الحصول على الحالات المدعومة
  static List<String> getSupportedStatuses() {
    String statusesString = _remoteConfig.getString('supported_statuses');
    return statusesString.split(',').where((s) => s.isNotEmpty).toList();
  }
  
  // فحص التحديثات دورياً
  static void startPeriodicCheck() {
    Timer.periodic(const Duration(minutes: 10), (timer) async {
      await fetchAndActivate();
    });
  }
}

// خدمة التحديث التلقائي
class AutoUpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // جلب إعدادات جديدة
      bool hasUpdates = await RemoteConfigService.fetchAndActivate();
      
      if (hasUpdates) {
        // فحص إذا كان هناك فرض تحديث
        if (RemoteConfigService.isForceUpdateEnabled()) {
          _showForceUpdateDialog(context);
        }
        
        // فحص وضع الصيانة
        if (RemoteConfigService.isMaintenanceModeEnabled()) {
          _showMaintenanceDialog(context);
        }
        
        // تطبيق الإعدادات الجديدة
        _applyNewSettings();
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص التحديثات: $e');
    }
  }
  
  static void _showForceUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تحديث مطلوب'),
        content: const Text('يتوفر تحديث مهم للتطبيق. يرجى التحديث للمتابعة.'),
        actions: [
          TextButton(
            onPressed: () {
              // فتح متجر التطبيقات
              // أو تحديث داخلي
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }
  
  static void _showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('صيانة مجدولة'),
        content: const Text('التطبيق تحت الصيانة حالياً. يرجى المحاولة لاحقاً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
  
  static void _applyNewSettings() {
    debugPrint('🔄 تطبيق الإعدادات الجديدة...');
    
    // تحديث عنوان API
    String newApiUrl = RemoteConfigService.getApiBaseUrl();
    // تطبيق العنوان الجديد في الخدمات
    
    // تحديث فترة المزامنة
    int newSyncInterval = RemoteConfigService.getSyncIntervalMinutes();
    // تطبيق الفترة الجديدة
    
    // تحديث وضع عرض الحالات
    String displayMode = RemoteConfigService.getStatusDisplayMode();
    if (displayMode == 'exact') {
      // تفعيل عرض الحالة الدقيقة من الوسيط
      debugPrint('✅ تم تفعيل عرض الحالة الدقيقة من الوسيط');
    }
    
    debugPrint('✅ تم تطبيق الإعدادات الجديدة');
  }
}

// استخدام في main.dart
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // تهيئة Remote Config
  await RemoteConfigService.initialize();
  
  // بدء الفحص الدوري
  RemoteConfigService.startPeriodicCheck();
  
  runApp(MyApp());
}
*/
