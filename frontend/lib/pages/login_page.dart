import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../router.dart';
import '../services/real_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double screenHeight = constraints.maxHeight;

              // تحديد الأحجام بناءً على حجم الشاشة
              double horizontalPadding = screenWidth > 600
                  ? screenWidth * 0.2
                  : 20;
              double logoSize = screenWidth > 600 ? 120 : 100;
              double cardPadding = screenWidth > 600 ? 35 : 25;
              double fontSize = screenWidth > 600 ? 28 : 24;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.05),
                      _buildLogo(logoSize),
                      SizedBox(height: screenHeight * 0.06),
                      _buildLoginCard(cardPadding, fontSize),
                      SizedBox(height: screenHeight * 0.04),
                      _buildSignUpLink(),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: size * 0.8,
              height: size * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // في حالة عدم وجود الصورة، اعرض الشعار القديم
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.gem,
                      color: Color(0xFFffd700),
                      size: size * 0.15,
                    ),
                    SizedBox(height: size * 0.05),
                    Text(
                      'منتجاتي',
                      style: GoogleFonts.cairo(
                        fontSize: size * 0.18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFffd700),
                        letterSpacing: 1.2,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: size * 0.02),
                      width: size * 0.4,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFffd700).withValues(alpha: 0.3),
                            Color(0xFFffd700),
                            Color(0xFFffd700).withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(double padding, double fontSize) {
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
            Text(
              'تسجيل الدخول',
              style: GoogleFonts.cairo(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Color(0xFFffd700),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مرحباً بك تاجرنا',
                  style: GoogleFonts.cairo(
                    fontSize: fontSize * 0.6,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFffd700).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.solidHeart,
                    color: Color(0xFFffd700),
                    size: fontSize * 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildPhoneField(),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _passwordController,
              hint: 'كلمة المرور',
              icon: FontAwesomeIcons.lock,
              isPassword: true,
              focusNode: _passwordFocusNode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    bool isValidPhone =
        _phoneController.text.length == 11 &&
        RegExp(r'^[0-9]+$').hasMatch(_phoneController.text);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isValidPhone
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.06),
        border: isValidPhone
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Color(0xFFffd700), width: 1),
      ),
      child: TextFormField(
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 11,
        autofocus: false,
        enableInteractiveSelection: true,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        onChanged: (value) {
          setState(() {}); // لتحديث اللون عند التغيير
        },
        onTap: () {
          // التأكد من ظهور الكيبورد عند النقر
          if (!_phoneFocusNode.hasFocus) {
            _phoneFocusNode.requestFocus();
          }
        },
        onFieldSubmitted: (value) {
          // الانتقال لحقل كلمة المرور عند الانتهاء
          _passwordFocusNode.requestFocus();
        },
        decoration: InputDecoration(
          hintText: 'رقم الهاتف (11 رقم)',
          hintStyle: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            FontAwesomeIcons.phone,
            color: isValidPhone ? Colors.green : Color(0xFFffd700),
            size: 18,
          ),
          suffixIcon: isValidPhone
              ? Icon(FontAwesomeIcons.check, color: Colors.green, size: 16)
              : null,
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
            return 'يجب كتابة رقم الهاتف 11 رقم';
          }

          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
          }

          if (value.length != 11) {
            return 'يجب كتابة رقم الهاتف 11 رقم';
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
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
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
        focusNode: focusNode,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: isPassword ? TextInputType.text : TextInputType.number,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
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
                    _isPasswordVisible
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                    color: Color(0xFFffd700),
                    size: 14,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
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

  Widget _buildLoginButton() {
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
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _login,
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
                    'تسجيل الدخول',
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

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟ ',
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: _goToSignUp,
          child: Text(
            'إنشاء حساب',
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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // استخدام خدمة المصادقة الآمنة
        final result = await AuthService.login(
          usernameOrPhone: _phoneController.text.trim(),
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

          // الانتقال لصفحة المنتجات
          NavigationHelper.goToProducts(context);
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

  void _goToSignUp() {
    NavigationHelper.goToRegister(context);
  }
}
