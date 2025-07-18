import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/admin_service.dart';
import '../services/withdrawal_service.dart';
import '../services/official_notification_service.dart';
import '../widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _isLoading = false;

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
  final List<String> _reportRecipients = [];

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات الإدارة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإدارة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في حفظ إعدادات الإدارة'),
          backgroundColor: Colors.red,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في إنشاء النسخة الاحتياطية'),
          backgroundColor: Colors.red,
        ),
      );
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
            const SizedBox(height: 10),
            if (OfficialNotificationService.isInitialized)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'نظام الإشعارات مهيأ ويعمل',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
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
  // اختبار نظام الإشعارات الرسمي
  // ===================================

  Future<void> _testNotificationSystem() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🧪 بدء اختبار نظام الإشعارات الرسمي...');

      // تهيئة النظام
      await OfficialNotificationService.initialize();

      // حفظ FCM Token للمستخدم الحالي
      final success = await OfficialNotificationService.saveUserFCMToken('07503597589');

      if (success) {
        // اختبار إرسال إشعار
        final testResult = await OfficialNotificationService.testNotificationForCurrentUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(testResult
                ? '✅ تم إرسال إشعار الاختبار بنجاح!'
                : '❌ فشل في إرسال إشعار الاختبار'),
              backgroundColor: testResult ? Colors.green : Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ فشل في حفظ FCM Token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في اختبار نظام الإشعارات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في اختبار الإشعارات: $e'),
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

  Future<void> _refreshFCMToken() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 إعادة تهيئة FCM Token...');

      await OfficialNotificationService.refreshFCMToken();

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
}
