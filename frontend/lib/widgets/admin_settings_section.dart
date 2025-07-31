import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminSettingsSection extends StatefulWidget {
  const AdminSettingsSection({super.key});

  @override
  State<AdminSettingsSection> createState() => _AdminSettingsSectionState();
}

class _AdminSettingsSectionState extends State<AdminSettingsSection> {
  // إعدادات الأرباح
  final TextEditingController _minWithdrawalController = TextEditingController(text: '50000');
  final TextEditingController _systemCommissionController = TextEditingController(text: '0');
  final TextEditingController _deliveryFeesController = TextEditingController(text: '5000');

  // إعدادات الطلبات
  final TextEditingController _maxItemsController = TextEditingController(text: '10');
  final TextEditingController _confirmationTimeController = TextEditingController(text: '24');
  bool _notificationsEnabled = true;

  // إعدادات المستخدمين
  bool _allowNewRegistration = true;
  bool _emailVerificationEnabled = false;
  final TextEditingController _maxDailyOrdersController = TextEditingController(text: '5');

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6c757d),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.gears,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'إعدادات النظام',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // إعدادات الأرباح
          _buildProfitSettings(),
          const SizedBox(height: 25),

          // إعدادات الطلبات
          _buildOrderSettings(),
          const SizedBox(height: 25),

          // إعدادات المستخدمين
          _buildUserSettings(),
          const SizedBox(height: 30),

          // زر الحفظ
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildProfitSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.moneyBillWave,
                color: Color(0xFF28a745),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'إعدادات الأرباح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الحد الأدنى للسحب
          _buildSettingField(
            label: 'الحد الأدنى للسحب (د.ع)',
            controller: _minWithdrawalController,
            icon: FontAwesomeIcons.wallet,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // نسبة عمولة النظام
          _buildSettingField(
            label: 'نسبة عمولة النظام (%)',
            controller: _systemCommissionController,
            icon: FontAwesomeIcons.percent,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // رسوم التوصيل
          _buildSettingField(
            label: 'رسوم التوصيل (د.ع)',
            controller: _deliveryFeesController,
            icon: FontAwesomeIcons.truck,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.cartShopping,
                color: Color(0xFF007bff),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'إعدادات الطلبات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الحد الأقصى للعناصر
          _buildSettingField(
            label: 'الحد الأقصى للعناصر في الطلب',
            controller: _maxItemsController,
            icon: FontAwesomeIcons.listOl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // مدة انتظار التأكيد
          _buildSettingField(
            label: 'مدة انتظار تأكيد الطلب (ساعة)',
            controller: _confirmationTimeController,
            icon: FontAwesomeIcons.clock,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // تفعيل الإشعارات
          _buildSwitchSetting(
            label: 'تفعيل الإشعارات',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            icon: FontAwesomeIcons.bell,
          ),
        ],
      ),
    );
  }

  Widget _buildUserSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.users,
                color: Color(0xFFffc107),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'إعدادات المستخدمين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // السماح بالتسجيل الجديد
          _buildSwitchSetting(
            label: 'السماح بالتسجيل الجديد',
            value: _allowNewRegistration,
            onChanged: (value) {
              setState(() {
                _allowNewRegistration = value;
              });
            },
            icon: FontAwesomeIcons.userPlus,
          ),
          const SizedBox(height: 15),

          // تفعيل التحقق من البريد الإلكتروني
          _buildSwitchSetting(
            label: 'تفعيل التحقق من البريد الإلكتروني',
            value: _emailVerificationEnabled,
            onChanged: (value) {
              setState(() {
                _emailVerificationEnabled = value;
              });
            },
            icon: FontAwesomeIcons.envelope,
          ),
          const SizedBox(height: 15),

          // الحد الأقصى للطلبات اليومية
          _buildSettingField(
            label: 'الحد الأقصى للطلبات اليومية',
            controller: _maxDailyOrdersController,
            icon: FontAwesomeIcons.calendarDay,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1a1a2e),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFf8f9fa),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFe9ecef)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: FaIcon(
                icon,
                color: const Color(0xFF6c757d),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              hintStyle: const TextStyle(color: Color(0xFF6c757d)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: const Color(0xFF6c757d),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a2e),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF28a745),
            activeTrackColor: const Color(0xFF28a745).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28a745),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'حفظ الإعدادات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // محاكاة حفظ الإعدادات
      await Future.delayed(const Duration(seconds: 2));

      // ignore: todo
      // TODO: حفظ الإعدادات في قاعدة البيانات
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Color(0xFF28a745),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعدادات: $e'),
            backgroundColor: const Color(0xFFdc3545),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _minWithdrawalController.dispose();
    _systemCommissionController.dispose();
    _deliveryFeesController.dispose();
    _maxItemsController.dispose();
    _confirmationTimeController.dispose();
    _maxDailyOrdersController.dispose();
    super.dispose();
  }
}
