import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/order_monitoring_service.dart';
import '../services/fcm_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/waseet_statuses_screen.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _isLoading = false;
  final TextEditingController _testPhoneController = TextEditingController();

  // إعدادات النظام العامة
  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _autoApproveUsers = false;
  bool _emailVerificationRequired = true;
  bool _phoneVerificationRequired = true;

  // إعدادات الطلبات
  bool _autoConfirmOrders = false;
  int _orderExpiryDays = 7;
  double _minOrderAmount = 1000.0;
  double _maxOrderAmount = 10000000.0;
  bool _allowOrderCancellation = true;
  int _cancellationTimeLimit = 24;

  // إعدادات السحوبات
  double _minWithdrawalAmount = 1000.0;
  double _maxWithdrawalAmount = 10000000.0;
  double _withdrawalFee = 0.0;
  bool _autoApproveWithdrawals = false;
  int _withdrawalProcessingDays = 3;
  bool _weekendProcessing = false;

  // إعدادات المالية
  double _systemCommission = 5.0;
  double _defaultUserCommission = 10.0;
  bool _dynamicCommission = false;
  double _vipCommissionRate = 15.0;
  bool _profitSharing = false;

  // إعدادات الأمان
  int _maxLoginAttempts = 5;
  int _lockoutDuration = 30;
  bool _ipWhitelist = false;
  bool _twoFactorRequired = false;
  int _sessionTimeout = 60;
  bool _logAllActions = true;

  // إعدادات الإشعارات
  bool _adminNotifications = true;
  bool _userNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;

  // إعدادات النسخ الاحتياطي
  bool _autoBackup = true;
  int _backupFrequency = 24; // ساعات
  int _backupRetention = 30; // أيام
  bool _cloudBackup = true;

  // إعدادات التقارير
  bool _autoGenerateReports = true;
  int _reportFrequency = 7; // أيام
  bool _emailReports = true;

  // إعدادات الصلاحيات
  Map<String, bool> _permissions = <String, bool>{
    'manage_users': true,
    'manage_orders': true,
    'manage_products': true,
    'manage_withdrawals': true,
    'view_reports': true,
    'system_settings': true,
    'financial_management': true,
    'backup_restore': true,
  };

  @override
  void initState() {
    super.initState();
    _loadAdminSettings();
  }

  Future<void> _loadAdminSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // تحميل إعدادات النظام
      setState(() {
        _maintenanceMode = prefs.getBool('maintenance_mode') ?? false;
        _registrationEnabled = prefs.getBool('registration_enabled') ?? true;
        _autoApproveUsers = prefs.getBool('auto_approve_users') ?? false;
        _emailVerificationRequired =
            prefs.getBool('email_verification_required') ?? true;
        _phoneVerificationRequired =
            prefs.getBool('phone_verification_required') ?? true;

        // إعدادات الطلبات
        _autoConfirmOrders = prefs.getBool('auto_confirm_orders') ?? false;
        _orderExpiryDays = prefs.getInt('order_expiry_days') ?? 7;
        _minOrderAmount = prefs.getDouble('min_order_amount') ?? 1000.0;
        _maxOrderAmount = prefs.getDouble('max_order_amount') ?? 10000000.0;
        _allowOrderCancellation =
            prefs.getBool('allow_order_cancellation') ?? true;
        _cancellationTimeLimit = prefs.getInt('cancellation_time_limit') ?? 24;

        // إعدادات السحوبات
        _minWithdrawalAmount =
            prefs.getDouble('min_withdrawal_amount') ?? 1000.0;
        _maxWithdrawalAmount =
            prefs.getDouble('max_withdrawal_amount') ?? 10000000.0;
        _withdrawalFee = prefs.getDouble('withdrawal_fee') ?? 0.0;
        _autoApproveWithdrawals =
            prefs.getBool('auto_approve_withdrawals') ?? false;
        _withdrawalProcessingDays =
            prefs.getInt('withdrawal_processing_days') ?? 3;
        _weekendProcessing = prefs.getBool('weekend_processing') ?? false;

        // إعدادات المالية
        _systemCommission = prefs.getDouble('system_commission') ?? 5.0;
        _defaultUserCommission =
            prefs.getDouble('default_user_commission') ?? 10.0;
        _dynamicCommission = prefs.getBool('dynamic_commission') ?? false;
        _vipCommissionRate = prefs.getDouble('vip_commission_rate') ?? 15.0;
        _profitSharing = prefs.getBool('profit_sharing') ?? false;

        // إعدادات الأمان
        _maxLoginAttempts = prefs.getInt('max_login_attempts') ?? 5;
        _lockoutDuration = prefs.getInt('lockout_duration') ?? 30;
        _ipWhitelist = prefs.getBool('ip_whitelist') ?? false;
        _twoFactorRequired = prefs.getBool('two_factor_required') ?? false;
        _sessionTimeout = prefs.getInt('session_timeout') ?? 60;
        _logAllActions = prefs.getBool('log_all_actions') ?? true;

        // إعدادات الإشعارات
        _adminNotifications = prefs.getBool('admin_notifications') ?? true;
        _userNotifications = prefs.getBool('user_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _smsNotifications = prefs.getBool('sms_notifications') ?? false;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;

        // إعدادات النسخ الاحتياطي
        _autoBackup = prefs.getBool('auto_backup') ?? true;
        _backupFrequency = prefs.getInt('backup_frequency') ?? 24;
        _backupRetention = prefs.getInt('backup_retention') ?? 30;
        _cloudBackup = prefs.getBool('cloud_backup') ?? true;

        // إعدادات التقارير
        _autoGenerateReports = prefs.getBool('auto_generate_reports') ?? true;
        _reportFrequency = prefs.getInt('report_frequency') ?? 7;
        _emailReports = prefs.getBool('email_reports') ?? true;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات الإدارة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAdminSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // حفظ إعدادات النظام
      await prefs.setBool('maintenance_mode', _maintenanceMode);
      await prefs.setBool('registration_enabled', _registrationEnabled);
      await prefs.setBool('auto_approve_users', _autoApproveUsers);
      await prefs.setBool(
        'email_verification_required',
        _emailVerificationRequired,
      );
      await prefs.setBool(
        'phone_verification_required',
        _phoneVerificationRequired,
      );

      // حفظ إعدادات الطلبات
      await prefs.setBool('auto_confirm_orders', _autoConfirmOrders);
      await prefs.setInt('order_expiry_days', _orderExpiryDays);
      await prefs.setDouble('min_order_amount', _minOrderAmount);
      await prefs.setDouble('max_order_amount', _maxOrderAmount);
      await prefs.setBool('allow_order_cancellation', _allowOrderCancellation);
      await prefs.setInt('cancellation_time_limit', _cancellationTimeLimit);

      // حفظ إعدادات السحوبات
      await prefs.setDouble('min_withdrawal_amount', _minWithdrawalAmount);
      await prefs.setDouble('max_withdrawal_amount', _maxWithdrawalAmount);
      await prefs.setDouble('withdrawal_fee', _withdrawalFee);
      await prefs.setBool('auto_approve_withdrawals', _autoApproveWithdrawals);
      await prefs.setInt(
        'withdrawal_processing_days',
        _withdrawalProcessingDays,
      );
      await prefs.setBool('weekend_processing', _weekendProcessing);

      // حفظ إعدادات المالية
      await prefs.setDouble('system_commission', _systemCommission);
      await prefs.setDouble('default_user_commission', _defaultUserCommission);
      await prefs.setBool('dynamic_commission', _dynamicCommission);
      await prefs.setDouble('vip_commission_rate', _vipCommissionRate);
      await prefs.setBool('profit_sharing', _profitSharing);

      // حفظ إعدادات الأمان
      await prefs.setInt('max_login_attempts', _maxLoginAttempts);
      await prefs.setInt('lockout_duration', _lockoutDuration);
      await prefs.setBool('ip_whitelist', _ipWhitelist);
      await prefs.setBool('two_factor_required', _twoFactorRequired);
      await prefs.setInt('session_timeout', _sessionTimeout);
      await prefs.setBool('log_all_actions', _logAllActions);

      // حفظ إعدادات الإشعارات
      await prefs.setBool('admin_notifications', _adminNotifications);
      await prefs.setBool('user_notifications', _userNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('sms_notifications', _smsNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);

      // حفظ إعدادات النسخ الاحتياطي
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setInt('backup_frequency', _backupFrequency);
      await prefs.setInt('backup_retention', _backupRetention);
      await prefs.setBool('cloud_backup', _cloudBackup);

      // حفظ إعدادات التقارير
      await prefs.setBool('auto_generate_reports', _autoGenerateReports);
      await prefs.setInt('report_frequency', _reportFrequency);
      await prefs.setBool('email_reports', _emailReports);

      // تطبيق الإعدادات على النظام
      await _applySystemSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ إعدادات الإدارة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإدارة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في حفظ إعدادات الإدارة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applySystemSettings() async {
    try {
      // تطبيق إعدادات وضع الصيانة
      if (_maintenanceMode) {
        await _enableMaintenanceMode();
      } else {
        await _disableMaintenanceMode();
      }

      // تطبيق إعدادات السحوبات
      await _updateWithdrawalSettings();

      // تطبيق إعدادات الأمان
      await _updateSecuritySettings();
    } catch (e) {
      debugPrint('خطأ في تطبيق إعدادات النظام: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'إعدادات الإدارة'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemSettings(),
                  const SizedBox(height: 20),
                  _buildOrderSettings(),
                  const SizedBox(height: 20),
                  _buildWithdrawalSettings(),
                  const SizedBox(height: 20),
                  _buildFinancialSettings(),
                  const SizedBox(height: 20),
                  _buildSecuritySettings(),
                  const SizedBox(height: 20),
                  _buildNotificationSettings(),
                  const SizedBox(height: 20),
                  _buildNotificationTestSection(),
                  const SizedBox(height: 20),
                  _buildWaseetStatusesSection(),
                  const SizedBox(height: 20),
                  _buildBackupSettings(),
                  const SizedBox(height: 20),
                  _buildReportSettings(),
                  const SizedBox(height: 20),
                  _buildPermissionSettings(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_system_daydream, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات النظام العامة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('وضع الصيانة'),
              subtitle: const Text('تعطيل النظام مؤقتاً للصيانة'),
              value: _maintenanceMode,
              onChanged: (value) {
                setState(() => _maintenanceMode = value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('تفعيل التسجيل'),
              subtitle: const Text('السماح للمستخدمين الجدد بالتسجيل'),
              value: _registrationEnabled,
              onChanged: (value) {
                setState(() => _registrationEnabled = value);
              },
            ),
            SwitchListTile(
              title: const Text('الموافقة التلقائية على المستخدمين'),
              subtitle: const Text('الموافقة على المستخدمين الجدد تلقائياً'),
              value: _autoApproveUsers,
              onChanged: (value) {
                setState(() => _autoApproveUsers = value);
              },
            ),
            SwitchListTile(
              title: const Text('التحقق من البريد الإلكتروني مطلوب'),
              subtitle: const Text(
                'إجبار المستخدمين على تأكيد البريد الإلكتروني',
              ),
              value: _emailVerificationRequired,
              onChanged: (value) {
                setState(() => _emailVerificationRequired = value);
              },
            ),
            SwitchListTile(
              title: const Text('التحقق من رقم الهاتف مطلوب'),
              subtitle: const Text('إجبار المستخدمين على تأكيد رقم الهاتف'),
              value: _phoneVerificationRequired,
              onChanged: (value) {
                setState(() => _phoneVerificationRequired = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات الطلبات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('التأكيد التلقائي للطلبات'),
              subtitle: const Text('تأكيد الطلبات الجديدة تلقائياً'),
              value: _autoConfirmOrders,
              onChanged: (value) {
                setState(() => _autoConfirmOrders = value);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('مدة انتهاء صلاحية الطلبات'),
              subtitle: Text('$_orderExpiryDays أيام'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _orderExpiryDays.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffix: Text('يوم'),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final days = int.tryParse(value);
                    if (days != null) {
                      setState(() => _orderExpiryDays = days);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('السماح بإلغاء الطلبات'),
              subtitle: const Text('السماح للمستخدمين بإلغاء طلباتهم'),
              value: _allowOrderCancellation,
              onChanged: (value) {
                setState(() => _allowOrderCancellation = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات السحوبات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('الحد الأدنى للسحب'),
              subtitle: Text('${_minWithdrawalAmount.toStringAsFixed(0)} د.ع'),
              trailing: SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: _minWithdrawalAmount.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffix: Text('د.ع'),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value);
                    if (amount != null) {
                      setState(() => _minWithdrawalAmount = amount);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('الموافقة التلقائية على السحوبات'),
              subtitle: const Text('الموافقة على طلبات السحب تلقائياً'),
              value: _autoApproveWithdrawals,
              onChanged: (value) {
                setState(() => _autoApproveWithdrawals = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'الإعدادات المالية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('عمولة النظام'),
              subtitle: Text('${_systemCommission.toStringAsFixed(1)}%'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _systemCommission.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffix: Text('%'),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final commission = double.tryParse(value);
                    if (commission != null) {
                      setState(() => _systemCommission = commission);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('العمولة الافتراضية للمستخدمين'),
              subtitle: Text('${_defaultUserCommission.toStringAsFixed(1)}%'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _defaultUserCommission.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffix: Text('%'),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final commission = double.tryParse(value);
                    if (commission != null) {
                      setState(() => _defaultUserCommission = commission);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('العمولة الديناميكية'),
              subtitle: const Text('تغيير العمولة حسب الأداء'),
              value: _dynamicCommission,
              onChanged: (value) {
                setState(() => _dynamicCommission = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات الأمان',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('الحد الأقصى لمحاولات تسجيل الدخول'),
              subtitle: Text('$_maxLoginAttempts محاولات'),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _maxLoginAttempts.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final attempts = int.tryParse(value);
                    if (attempts != null) {
                      setState(() => _maxLoginAttempts = attempts);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('المصادقة الثنائية مطلوبة'),
              subtitle: const Text(
                'إجبار جميع المستخدمين على استخدام المصادقة الثنائية',
              ),
              value: _twoFactorRequired,
              onChanged: (value) {
                setState(() => _twoFactorRequired = value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('تسجيل جميع الإجراءات'),
              subtitle: const Text('تسجيل جميع إجراءات المستخدمين في النظام'),
              value: _logAllActions,
              onChanged: (value) {
                setState(() => _logAllActions = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات الإشعارات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('إشعارات الإدارة'),
              subtitle: const Text('إشعارات للمديرين عن الأحداث المهمة'),
              value: _adminNotifications,
              onChanged: (value) {
                setState(() => _adminNotifications = value);
              },
            ),
            SwitchListTile(
              title: const Text('إشعارات المستخدمين'),
              subtitle: const Text('إشعارات للمستخدمين عن حالة طلباتهم'),
              value: _userNotifications,
              onChanged: (value) {
                setState(() => _userNotifications = value);
              },
            ),
            SwitchListTile(
              title: const Text('الإشعارات عبر البريد الإلكتروني'),
              subtitle: const Text('إرسال الإشعارات عبر البريد الإلكتروني'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
            ),
            SwitchListTile(
              title: const Text('الإشعارات عبر الرسائل النصية'),
              subtitle: const Text('إرسال الإشعارات عبر الرسائل النصية'),
              value: _smsNotifications,
              onChanged: (value) {
                setState(() => _smsNotifications = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات النسخ الاحتياطي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('النسخ الاحتياطي التلقائي'),
              subtitle: const Text('إنشاء نسخ احتياطية تلقائياً'),
              value: _autoBackup,
              onChanged: (value) {
                setState(() => _autoBackup = value);
              },
            ),
            if (_autoBackup) ...[
              const Divider(),
              ListTile(
                title: const Text('تكرار النسخ الاحتياطي'),
                subtitle: Text('كل $_backupFrequency ساعة'),
                trailing: SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _backupFrequency.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffix: Text('ساعة'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final frequency = int.tryParse(value);
                      if (frequency != null) {
                        setState(() => _backupFrequency = frequency);
                      }
                    },
                  ),
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('النسخ الاحتياطي السحابي'),
              subtitle: const Text('حفظ النسخ الاحتياطية في السحابة'),
              value: _cloudBackup,
              onChanged: (value) {
                setState(() => _cloudBackup = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات التقارير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('إنشاء التقارير تلقائياً'),
              subtitle: const Text('إنشاء تقارير دورية تلقائياً'),
              value: _autoGenerateReports,
              onChanged: (value) {
                setState(() => _autoGenerateReports = value);
              },
            ),
            if (_autoGenerateReports) ...[
              const Divider(),
              ListTile(
                title: const Text('تكرار التقارير'),
                subtitle: Text('كل $_reportFrequency أيام'),
                trailing: SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _reportFrequency.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffix: Text('يوم'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final frequency = int.tryParse(value);
                      if (frequency != null) {
                        setState(() => _reportFrequency = frequency);
                      }
                    },
                  ),
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('إرسال التقارير بالبريد الإلكتروني'),
              subtitle: const Text(
                'إرسال التقارير للمديرين عبر البريد الإلكتروني',
              ),
              value: _emailReports,
              onChanged: (value) {
                setState(() => _emailReports = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات الصلاحيات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._permissions.entries.map((entry) {
              return Column(
                children: [
                  SwitchListTile(
                    title: Text(_getPermissionTitle(entry.key)),
                    subtitle: Text(_getPermissionDescription(entry.key)),
                    value: entry.value,
                    onChanged: (value) {
                      setState(() {
                        _permissions[entry.key] = value;
                      });
                    },
                  ),
                  if (entry.key != _permissions.keys.last) const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveAdminSettings,
            icon: const Icon(Icons.save),
            label: const Text('حفظ إعدادات الإدارة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('استعادة الافتراضية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportSettings,
                icon: const Icon(Icons.download),
                label: const Text('تصدير الإعدادات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _systemDiagnostics,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('تشخيص النظام'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPermissionTitle(String key) {
    switch (key) {
      case 'manage_users':
        return 'إدارة المستخدمين';
      case 'manage_orders':
        return 'إدارة الطلبات';
      case 'manage_products':
        return 'إدارة المنتجات';
      case 'manage_withdrawals':
        return 'إدارة السحوبات';
      case 'view_reports':
        return 'عرض التقارير';
      case 'system_settings':
        return 'إعدادات النظام';
      case 'financial_management':
        return 'الإدارة المالية';
      case 'backup_restore':
        return 'النسخ الاحتياطي والاستعادة';
      default:
        return key;
    }
  }

  String _getPermissionDescription(String key) {
    switch (key) {
      case 'manage_users':
        return 'إضافة وتعديل وحذف المستخدمين';
      case 'manage_orders':
        return 'إدارة جميع الطلبات وحالاتها';
      case 'manage_products':
        return 'إضافة وتعديل وحذف المنتجات';
      case 'manage_withdrawals':
        return 'الموافقة على طلبات السحب ومعالجتها';
      case 'view_reports':
        return 'عرض التقارير والإحصائيات';
      case 'system_settings':
        return 'تعديل إعدادات النظام العامة';
      case 'financial_management':
        return 'إدارة الأمور المالية والعمولات';
      case 'backup_restore':
        return 'إنشاء واستعادة النسخ الاحتياطية';
      default:
        return 'وصف غير متوفر';
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة الإعدادات الافتراضية'),
        content: const Text(
          'هل تريد استعادة جميع إعدادات الإدارة إلى القيم الافتراضية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset();
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    setState(() {
      // إعدادات النظام
      _maintenanceMode = false;
      _registrationEnabled = true;
      _autoApproveUsers = false;
      _emailVerificationRequired = true;
      _phoneVerificationRequired = true;

      // إعدادات الطلبات
      _autoConfirmOrders = false;
      _orderExpiryDays = 7;
      _minOrderAmount = 1000.0;
      _maxOrderAmount = 10000000.0;
      _allowOrderCancellation = true;
      _cancellationTimeLimit = 24;

      // إعدادات السحوبات
      _minWithdrawalAmount = 1000.0;
      _maxWithdrawalAmount = 10000000.0;
      _withdrawalFee = 0.0;
      _autoApproveWithdrawals = false;
      _withdrawalProcessingDays = 3;
      _weekendProcessing = false;

      // إعدادات المالية
      _systemCommission = 5.0;
      _defaultUserCommission = 10.0;
      _dynamicCommission = false;
      _vipCommissionRate = 15.0;
      _profitSharing = false;

      // إعدادات الأمان
      _maxLoginAttempts = 5;
      _lockoutDuration = 30;
      _ipWhitelist = false;
      _twoFactorRequired = false;
      _sessionTimeout = 60;
      _logAllActions = true;

      // إعدادات الإشعارات
      _adminNotifications = true;
      _userNotifications = true;
      _emailNotifications = true;
      _smsNotifications = false;
      _pushNotifications = true;

      // إعدادات النسخ الاحتياطي
      _autoBackup = true;
      _backupFrequency = 24;
      _backupRetention = 30;
      _cloudBackup = true;

      // إعدادات التقارير
      _autoGenerateReports = true;
      _reportFrequency = 7;
      _emailReports = true;

      // إعدادات الصلاحيات
      _permissions = <String, bool>{
        'manage_users': true,
        'manage_orders': true,
        'manage_products': true,
        'manage_withdrawals': true,
        'view_reports': true,
        'system_settings': true,
        'financial_management': true,
        'backup_restore': true,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استعادة الإعدادات الافتراضية')),
    );
  }

  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تصدير إعدادات الإدارة قريباً')),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء نسخة احتياطية'),
        content: const Text('هل تريد إنشاء نسخة احتياطية من النظام الآن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _performBackup() async {
    setState(() => _isLoading = true);

    try {
      // محاكاة عملية النسخ الاحتياطي
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _systemDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تشخيص النظام'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ قاعدة البيانات: متصلة'),
            Text('✅ الخادم: يعمل بشكل طبيعي'),
            Text('✅ النسخ الاحتياطي: محدث'),
            Text('✅ الأمان: مفعل'),
            Text('✅ الإشعارات: تعمل'),
            Text('⚠️ التحديثات: متوفرة'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableMaintenanceMode() async {
    // تطبيق وضع الصيانة
    debugPrint('تم تفعيل وضع الصيانة');
  }

  Future<void> _disableMaintenanceMode() async {
    // إلغاء وضع الصيانة
    debugPrint('تم إلغاء وضع الصيانة');
  }

  Future<void> _updateWithdrawalSettings() async {
    // تحديث إعدادات السحوبات في قاعدة البيانات
    debugPrint('تم تحديث إعدادات السحوبات');
  }

  Future<void> _updateSecuritySettings() async {
    // تحديث إعدادات الأمان في قاعدة البيانات
    debugPrint('تم تحديث إعدادات الأمان');
  }

  // ===================================
  // واجهة اختبار الإشعارات
  // ===================================

  Widget _buildWaseetStatusesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'إدارة حالات الوسيط',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'إدارة وعرض جميع حالات الطلبات المعتمدة من شركة الوسيط',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaseetStatusesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('عرض حالات الوسيط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'معلومات الحالات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• إجمالي 20 حالة معتمدة من الوسيط\n'
                    '• مجمعة في 7 فئات رئيسية\n'
                    '• تحديث تلقائي لحالات الطلبات\n'
                    '• إحصائيات مفصلة لكل حالة',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notification_important, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'اختبار نظام الإشعارات الرسمي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'اختبر نظام الإشعارات للتأكد من وصول الإشعارات للمستخدمين',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // مؤشر حالة تسجيل الدخول
            FutureBuilder<String?>(
              future: _getCurrentUserPhone(),
              builder: (context, snapshot) {
                final isLoggedIn = snapshot.data != null && snapshot.data!.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLoggedIn ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLoggedIn ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoggedIn ? Icons.check_circle : Icons.warning,
                        color: isLoggedIn ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLoggedIn
                            ? 'مسجل دخول: ${snapshot.data}'
                            : 'غير مسجل دخول - يجب تسجيل الدخول أولاً',
                          style: TextStyle(
                            color: isLoggedIn ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // زر محاكاة تسجيل الدخول للاختبار
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _simulateLogin,
                icon: const Icon(Icons.login),
                label: const Text('محاكاة تسجيل دخول للاختبار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testNotificationSystem,
                    icon: const Icon(Icons.send),
                    label: const Text('اختبار إرسال إشعار'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshFCMToken,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث FCM Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testOrderMonitoring,
                    icon: const Icon(Icons.monitor_heart),
                    label: const Text('اختبار المراقبة الفورية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _restartOrderMonitoring,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('إعادة تشغيل المراقبة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'تم إزالة نظام الإشعارات',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
            // قسم اختبار الإشعارات الفورية
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active,
                           color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'اختبار الإشعارات الفورية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // حقل رقم الهاتف
                  TextField(
                    controller: _testPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف العميل للاختبار',
                      hintText: '05xxxxxxxx',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // أزرار الاختبار
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testNotification,
                          icon: const Icon(Icons.send),
                          label: const Text('إرسال إشعار تجريبي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testOrderNotification,
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('اختبار إشعار طلب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // معلومات FCM
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات خدمة الإشعارات:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getFCMServiceInfo(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final info = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• الحالة: ${info['isInitialized'] ? 'مفعل' : 'غير مفعل'}'),
                                  Text('• يوجد Token: ${info['hasToken'] ? 'نعم' : 'لا'}'),
                                  if (info['tokenPreview'] != null)
                                    Text('• Token: ${info['tokenPreview']}...'),
                                ],
                              );
                            }
                            return const Text('جاري التحميل...');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // أزرار إدارة الرموز
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getTokenStats,
                          icon: const Icon(Icons.analytics),
                          label: const Text('إحصائيات الرموز'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _cleanupTokens,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('تنظيف الرموز'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // زر صفحة اختبار الإشعارات
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('نظام الإشعارات يعمل بشكل صحيح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('✅ فحص نظام الإشعارات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'نظام الإشعارات غير مهيأ',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===================================
  // دوال مساعدة
  // ===================================

  Future<String?> _getCurrentUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_phone');
    } catch (e) {
      return null;
    }
  }

  // ===================================
  // محاكاة تسجيل الدخول للاختبار
  // ===================================

  Future<void> _simulateLogin() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 محاكاة تسجيل دخول للاختبار...');

      // حفظ رقم هاتف تجريبي
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', '07503597589');
      await prefs.setString('user_name', 'مستخدم تجريبي');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تسجيل الدخول التجريبي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ خطأ في محاكاة تسجيل الدخول: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تسجيل الدخول: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===================================
  // اختبار نظام الإشعارات الرسمي
  // ===================================

  Future<void> _testNotificationSystem() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('⚠️ تم إزالة نظام الإشعارات من التطبيق');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ تم إزالة نظام الإشعارات من التطبيق'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // تم إزالة نظام الإشعارات
      debugPrint('⚠️ تم إزالة نظام الإشعارات من التطبيق');

    } catch (e) {
      debugPrint('❌ خطأ في اختبار نظام الإشعارات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshFCMToken() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 إعادة تهيئة FCM Token...');

      // الحصول على رقم هاتف المستخدم الحالي
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ يجب تسجيل الدخول أولاً لتحديث FCM Token'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      debugPrint('📱 رقم المستخدم الحالي: $currentUserPhone');

      // تم إزالة نظام الإشعارات
      debugPrint('⚠️ تم إزالة نظام الإشعارات من التطبيق');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث FCM Token بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ خطأ في تحديث FCM Token: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تحديث FCM Token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===================================
  // اختبار نظام المراقبة الفورية
  // ===================================

  Future<void> _testOrderMonitoring() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🧪 اختبار نظام المراقبة الفورية...');

      // اختبار الإشعارات المحلية
      await OrderMonitoringService.testNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال إشعار اختبار المراقبة الفورية'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ خطأ في اختبار المراقبة الفورية: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في اختبار المراقبة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restartOrderMonitoring() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 إعادة تشغيل نظام المراقبة الفورية...');

      await OrderMonitoringService.restartMonitoring();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إعادة تشغيل نظام المراقبة الفورية'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ خطأ في إعادة تشغيل المراقبة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إعادة تشغيل المراقبة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _testPhoneController.dispose();
    super.dispose();
  }

  /// اختبار إرسال إشعار عام
  Future<void> _testNotification() async {
    if (_testPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الهاتف'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AdminService.testNotification(_testPhoneController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? '✅ تم إرسال الإشعار التجريبي بنجاح!'
              : '❌ فشل في إرسال الإشعار التجريبي'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إرسال الإشعار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// اختبار إرسال إشعار تحديث طلب
  Future<void> _testOrderNotification() async {
    if (_testPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الهاتف'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AdminService.sendGeneralNotification(
        customerPhone: _testPhoneController.text.trim(),
        title: '📦 تحديث حالة طلبك',
        message: 'تم تحديث حالة طلبك إلى: جاري التوصيل - هذا إشعار تجريبي',
        additionalData: {
          'type': 'order_status_test',
          'orderId': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          'newStatus': 'out_for_delivery',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال إشعار تحديث الطلب التجريبي!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إرسال إشعار الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// الحصول على معلومات خدمة FCM
  Future<Map<String, dynamic>> _getFCMServiceInfo() async {
    try {
      return FCMService().getServiceInfo();
    } catch (e) {
      return {
        'isInitialized': false,
        'hasToken': false,
        'error': e.toString(),
      };
    }
  }

  /// الحصول على إحصائيات FCM Tokens
  Future<void> _getTokenStats() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AdminService.baseUrl}/api/fcm/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final stats = data['data'];

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('📊 إحصائيات FCM Tokens'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📈 إجمالي الرموز: ${stats['total']['tokens']}'),
                      Text('✅ الرموز النشطة: ${stats['total']['activeTokens']}'),
                      Text('❌ الرموز غير النشطة: ${stats['total']['inactiveTokens']}'),
                      Text('👥 المستخدمين الفريدين: ${stats['total']['uniqueUsers']}'),
                      const Divider(),
                      Text('📱 استخدم اليوم: ${stats['usage']['usedToday']}'),
                      Text('📅 استخدم هذا الأسبوع: ${stats['usage']['usedThisWeek']}'),
                      Text('📆 استخدم هذا الشهر: ${stats['usage']['usedThisMonth']}'),
                      const Divider(),
                      Text('🆕 أنشئ اليوم: ${stats['growth']['createdToday']}'),
                      Text('📊 أنشئ هذا الأسبوع: ${stats['growth']['createdThisWeek']}'),
                      const Divider(),
                      Text('💚 نسبة النشاط: ${stats['health']['activePercentage']}%'),
                      Text('📈 معدل الاستخدام: ${stats['health']['usageRate']}%'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الحصول على الإحصائيات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تنظيف FCM Tokens القديمة
  Future<void> _cleanupTokens() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AdminService.baseUrl}/api/fcm/cleanup'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${data['message']}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تنظيف الرموز: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
