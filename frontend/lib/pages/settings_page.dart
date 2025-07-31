import 'package:flutter/material.dart';



import '../widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  // إعدادات الحساب
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // إعدادات الإشعارات
  bool _notificationsEnabled = true;
  bool _orderNotifications = true;
  bool _withdrawalNotifications = true;
  bool _systemNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

  // إعدادات التطبيق
  String _selectedTheme = 'system';
  String _selectedLanguage = 'ar';
  bool _biometricEnabled = false;
  bool _autoBackup = true;
  bool _offlineMode = false;

  // إعدادات الأمان
  bool _twoFactorEnabled = false;
  bool _loginAlerts = true;
  int _sessionTimeout = 30;

  // إعدادات الأعمال
  double _defaultCommission = 10.0;
  int _minWithdrawalAmount = 1000;
  int _maxWithdrawalAmount = 10000000;
  bool _autoOrderConfirmation = false;
  int _orderExpiryDays = 7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _orderNotifications = prefs.getBool('order_notifications') ?? true;
        _withdrawalNotifications =
            prefs.getBool('withdrawal_notifications') ?? true;
        _systemNotifications = prefs.getBool('system_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? false;
        _smsNotifications = prefs.getBool('sms_notifications') ?? false;

        _selectedTheme = prefs.getString('selected_theme') ?? 'system';
        _selectedLanguage = prefs.getString('selected_language') ?? 'ar';
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _autoBackup = prefs.getBool('auto_backup') ?? true;
        _offlineMode = prefs.getBool('offline_mode') ?? false;

        _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
        _loginAlerts = prefs.getBool('login_alerts') ?? true;
        _sessionTimeout = prefs.getInt('session_timeout') ?? 30;

        _defaultCommission = prefs.getDouble('default_commission') ?? 10.0;
        _minWithdrawalAmount = prefs.getInt('min_withdrawal_amount') ?? 1000;
        _maxWithdrawalAmount =
            prefs.getInt('max_withdrawal_amount') ?? 10000000;
        _autoOrderConfirmation =
            prefs.getBool('auto_order_confirmation') ?? false;
        _orderExpiryDays = prefs.getInt('order_expiry_days') ?? 7;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // تم إزالة userId غير المستخدم

      // هنا يجب تحميل بيانات المستخدم من قاعدة البيانات
      setState(() {
        _nameController.text = 'مصطفى عبد الله'; // مؤقت
        _phoneController.text = '07503597589'; // مؤقت
        _emailController.text = 'user@example.com'; // مؤقت
        _addressController.text = 'بغداد، العراق'; // مؤقت
      });
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // حفظ إعدادات الإشعارات
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('order_notifications', _orderNotifications);
      await prefs.setBool('withdrawal_notifications', _withdrawalNotifications);
      await prefs.setBool('system_notifications', _systemNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('sms_notifications', _smsNotifications);

      // حفظ إعدادات التطبيق
      await prefs.setString('selected_theme', _selectedTheme);
      await prefs.setString('selected_language', _selectedLanguage);
      await prefs.setBool('biometric_enabled', _biometricEnabled);
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setBool('offline_mode', _offlineMode);

      // حفظ إعدادات الأمان
      await prefs.setBool('two_factor_enabled', _twoFactorEnabled);
      await prefs.setBool('login_alerts', _loginAlerts);
      await prefs.setInt('session_timeout', _sessionTimeout);

      // حفظ إعدادات الأعمال
      await prefs.setDouble('default_commission', _defaultCommission);
      await prefs.setInt('min_withdrawal_amount', _minWithdrawalAmount);
      await prefs.setInt('max_withdrawal_amount', _maxWithdrawalAmount);
      await prefs.setBool('auto_order_confirmation', _autoOrderConfirmation);
      await prefs.setInt('order_expiry_days', _orderExpiryDays);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('خطأ في حفظ الإعدادات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في حفظ الإعدادات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الإعدادات'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountSettings(),
                  const SizedBox(height: 20),
                  _buildNotificationSettings(),
                  const SizedBox(height: 20),
                  _buildAppSettings(),
                  const SizedBox(height: 20),
                  _buildSecuritySettings(),
                  const SizedBox(height: 20),
                  _buildBusinessSettings(),
                  const SizedBox(height: 20),
                  _buildSystemSettings(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
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
            const Text(
              'إعدادات الإشعارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تفعيل الإشعارات'),
              subtitle: const Text('تفعيل أو إلغاء جميع الإشعارات'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات الطلبات'),
              subtitle: const Text('إشعارات الطلبات الجديدة وتحديثات الحالة'),
              value: _orderNotifications,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _orderNotifications = value);
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('إشعارات السحوبات'),
              subtitle: const Text('إشعارات طلبات السحب وتحديثات الحالة'),
              value: _withdrawalNotifications,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _withdrawalNotifications = value);
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('إشعارات النظام'),
              subtitle: const Text('إشعارات التحديثات والصيانة'),
              value: _systemNotifications,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _systemNotifications = value);
                    }
                  : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات البريد الإلكتروني'),
              subtitle: const Text('استقبال الإشعارات عبر البريد الإلكتروني'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
            ),
            SwitchListTile(
              title: const Text('إشعارات الرسائل النصية'),
              subtitle: const Text('استقبال الإشعارات عبر الرسائل النصية'),
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

  Widget _buildAppSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('المظهر'),
              subtitle: Text(_getThemeText()),
              trailing: DropdownButton<String>(
                value: _selectedTheme,
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('فاتح')),
                  DropdownMenuItem(value: 'dark', child: Text('داكن')),
                  DropdownMenuItem(value: 'system', child: Text('تلقائي')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTheme = value!);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('اللغة'),
              subtitle: Text(_getLanguageText()),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ku', child: Text('کوردی')),
                ],
                onChanged: (value) {
                  setState(() => _selectedLanguage = value!);
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('المصادقة البيومترية'),
              subtitle: const Text('استخدام بصمة الإصبع أو الوجه للدخول'),
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() => _biometricEnabled = value);
              },
            ),
            SwitchListTile(
              title: const Text('النسخ الاحتياطي التلقائي'),
              subtitle: const Text('نسخ احتياطي تلقائي للبيانات'),
              value: _autoBackup,
              onChanged: (value) {
                setState(() => _autoBackup = value);
              },
            ),
            SwitchListTile(
              title: const Text('الوضع غير المتصل'),
              subtitle: const Text('العمل بدون اتصال بالإنترنت'),
              value: _offlineMode,
              onChanged: (value) {
                setState(() => _offlineMode = value);
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
            const Text(
              'إعدادات الأمان',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('المصادقة الثنائية'),
              subtitle: const Text('طبقة حماية إضافية للحساب'),
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() => _twoFactorEnabled = value);
              },
            ),
            SwitchListTile(
              title: const Text('تنبيهات تسجيل الدخول'),
              subtitle: const Text('إشعار عند تسجيل الدخول من جهاز جديد'),
              value: _loginAlerts,
              onChanged: (value) {
                setState(() => _loginAlerts = value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('انتهاء الجلسة'),
              subtitle: Text('انتهاء الجلسة بعد $_sessionTimeout دقيقة'),
              trailing: DropdownButton<int>(
                value: _sessionTimeout,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                  DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                  DropdownMenuItem(value: 60, child: Text('ساعة')),
                  DropdownMenuItem(value: 120, child: Text('ساعتان')),
                  DropdownMenuItem(value: -1, child: Text('بدون انتهاء')),
                ],
                onChanged: (value) {
                  setState(() => _sessionTimeout = value!);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('تغيير كلمة المرور'),
              subtitle: const Text('تحديث كلمة مرور الحساب'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج من جميع الأجهزة'),
              subtitle: const Text('إنهاء جميع الجلسات النشطة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _logoutAllDevices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الأعمال',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('العمولة الافتراضية'),
              subtitle: Text('${_defaultCommission.toStringAsFixed(1)}%'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _defaultCommission.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffix: Text('%'),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final commission = double.tryParse(value);
                    if (commission != null) {
                      setState(() => _defaultCommission = commission);
                    }
                  },
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('الحد الأدنى للسحب'),
              subtitle: Text('$_minWithdrawalAmount د.ع'),
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
                    final amount = int.tryParse(value);
                    if (amount != null) {
                      setState(() => _minWithdrawalAmount = amount);
                    }
                  },
                ),
              ),
            ),
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
            const Text(
              'إعدادات النظام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('معلومات التطبيق'),
              subtitle: const Text('الإصدار 1.0.0'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showAppInfo,
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('البحث عن تحديثات'),
              subtitle: const Text('التحقق من وجود إصدار جديد'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _checkForUpdates,
            ),
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
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('حفظ الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.restore),
            label: const Text('استعادة الإعدادات الافتراضية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeText() {
    switch (_selectedTheme) {
      case 'light':
        return 'فاتح';
      case 'dark':
        return 'داكن';
      case 'system':
        return 'تلقائي';
      default:
        return 'تلقائي';
    }
  }

  String _getLanguageText() {
    switch (_selectedLanguage) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'ku':
        return 'کوردی';
      default:
        return 'العربية';
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: const Text('هذه الميزة قيد التطوير'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _logoutAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من جميع الأجهزة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم التطبيق: منتجاتي'),
            Text('الإصدار: 1.0.0'),
            Text('تاريخ الإصدار: 2025-06-26'),
            Text('المطور: فريق منتجاتي'),
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

  void _checkForUpdates() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('لا توجد تحديثات متاحة')));
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة الإعدادات'),
        content: const Text(
          'هل تريد استعادة جميع الإعدادات إلى القيم الافتراضية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _notificationsEnabled = true;
      _orderNotifications = true;
      _withdrawalNotifications = true;
      _systemNotifications = true;
      _emailNotifications = false;
      _smsNotifications = false;

      _selectedTheme = 'system';
      _selectedLanguage = 'ar';
      _biometricEnabled = false;
      _autoBackup = true;
      _offlineMode = false;

      _twoFactorEnabled = false;
      _loginAlerts = true;
      _sessionTimeout = 30;

      _defaultCommission = 10.0;
      _minWithdrawalAmount = 1000;
      _maxWithdrawalAmount = 10000000;
      _autoOrderConfirmation = false;
      _orderExpiryDays = 7;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استعادة الإعدادات الافتراضية')),
    );
  }
}
