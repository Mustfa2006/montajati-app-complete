// صفحة إنشاء الحساب - Register Page
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../router.dart';
import '../services/real_auth_service.dart';

// ===== الصفحة الرئيسية =====

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // ===== متحكمات النموذج =====
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===== بناء الواجهة =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0F0F23)],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          // تحديد الأحجام بناءً على حجم الشاشة
          double horizontalPadding = screenWidth > 600
              ? screenWidth * 0.15
              : 20;
          double logoSize = screenWidth > 600 ? 100 : 80;
          double cardPadding = screenWidth > 600 ? 35 : 25;
          double fontSize = screenWidth > 600 ? 28 : 24;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.03),
                _buildHeader(logoSize, fontSize),
                SizedBox(height: screenHeight * 0.04),
                _buildRegisterCard(cardPadding),
                SizedBox(height: screenHeight * 0.03),
                _buildLoginLink(),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double logoSize, double fontSize) {
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFffd700).withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            FontAwesomeIcons.userPlus,
            color: Color(0xFF1a1a2e),
            size: logoSize * 0.4,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'إنشاء حساب جديد',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Color(0xFFffd700),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'مرحباً بك في عالم التجارة الإلكترونية',
          style: GoogleFonts.cairo(
            fontSize: fontSize * 0.6,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterCard(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              hint: 'الاسم الكامل',
              icon: FontAwesomeIcons.user,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الاسم الكامل';
                }
                if (value.length < 3) {
                  return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildPhoneField(),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _passwordController,
              hint: 'كلمة المرور (8 أحرف على الأقل)',
              icon: FontAwesomeIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                }
                // ✅ قبول الأحرف الإنجليزية والأرقام فقط
                if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                  return 'كلمة المرور يجب أن تحتوي على أحرف إنجليزية وأرقام فقط';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: 'تأكيد كلمة المرور',
              icon: FontAwesomeIcons.lock,
              isPassword: true,
              isConfirmPassword: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى تأكيد كلمة المرور';
                }
                if (value != _passwordController.text) {
                  return 'كلمة المرور غير متطابقة';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Color(0xFFffd700), width: 1),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 11,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        onChanged: (value) {
          setState(() {}); // لتحديث اللون عند التغيير
        },
        decoration: InputDecoration(
          hintText: 'رقم الهاتف (11 رقم)',
          hintStyle: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            FontAwesomeIcons.phone,
            color: Color(0xFFffd700),
            size: 18,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          counterText: "", // إخفاء عداد الأحرف
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال رقم الهاتف';
          }
          if (value.length != 11) {
            return 'رقم الهاتف يجب أن يكون 11 رقم بالضبط';
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    bool isVisible = isPassword
        ? (isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible)
        : false;

    // التحقق من كون النص أرقام و11 رقم
    bool isPhoneNumber =
        controller.text.isNotEmpty &&
        RegExp(r'^[0-9]+$').hasMatch(controller.text);
    bool isValidPhone = controller.text.length == 11 && isPhoneNumber;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Color(0xFFffd700), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        onChanged: (value) {
          setState(() {}); // لتحديث اللون عند التغيير
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: isValidPhone ? Colors.green : Color(0xFFffd700),
            size: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                    color: Color(0xFFffd700),
                    size: 14,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmPassword) {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      } else {
                        _isPasswordVisible = !_isPasswordVisible;
                      }
                    });
                  },
                )
              : null,

          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _isLoading ? null : _register,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1a1a2e),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'إنشاء الحساب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟ ',
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => NavigationHelper.goToLogin(context),
          child: Text(
            'تسجيل الدخول',
            style: GoogleFonts.cairo(
              color: Color(0xFFffd700),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // استخدام خدمة المصادقة الآمنة
        final result = await AuthService.register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        if (result.success) {
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message, style: GoogleFonts.cairo()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // الانتقال لصفحة تسجيل الدخول
          NavigationHelper.goToLogin(context);
        } else {
          // عرض رسالة خطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message, style: GoogleFonts.cairo()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع، يرجى المحاولة مرة أخرى',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
