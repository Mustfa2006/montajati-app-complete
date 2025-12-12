import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

/// 🌟 SlideToSubmitWidget - النسخة المعدلة (بدون توهج، حركة سلسة)
class SlideToSubmitWidget extends StatefulWidget {
  final VoidCallback onSubmit;
  final bool isEnabled;
  final bool isSubmitting;
  final String text;

  const SlideToSubmitWidget({
    super.key,
    required this.onSubmit,
    this.isEnabled = true,
    this.isSubmitting = false,
    this.text = "اسحب لتأكيد الطلب",
  });

  @override
  State<SlideToSubmitWidget> createState() => _SlideToSubmitWidgetState();
}

class _SlideToSubmitWidgetState extends State<SlideToSubmitWidget> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _controller.addListener(() {
      setState(() {
        _dragValue = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled || widget.isSubmitting) return;

    setState(() {
      _dragValue += details.delta.dx;

      // ✅ حساب دقيق للحدود:
      // العرض الكلي ناقص حجم الكرة (55) ناقص الهوامش الداخلية (6 من كل جهة = 12)
      final maxDrag = _maxWidth - 55 - 12;
      _dragValue = _dragValue.clamp(0.0, maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.isEnabled || widget.isSubmitting) return;

    final maxDrag = _maxWidth - 55 - 12;
    // ✅ النسبة المطلوبة للتأكيد (مثلاً 70% من المسافة)
    final threshold = maxDrag * 0.70;

    if (_dragValue > threshold) {
      _completeSlide();
    } else {
      _resetSlide(); // ✅ يرجع دائماً للصفر إذا لم يكتمل
    }
  }

  void _handleDragCancel() {
    if (!widget.isEnabled || widget.isSubmitting) return;
    _resetSlide();
  }

  void _completeSlide() {
    final maxDrag = _maxWidth - 55 - 12;

    // أنيميشن للإكمال للنهاية
    _animation = Tween<double>(
      begin: _dragValue,
      end: maxDrag,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0.0).then((_) {
      widget.onSubmit();

      // إعادة تعيين احتياطية
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !widget.isSubmitting) {
          _resetSlide();
        }
      });
    });
  }

  void _resetSlide() {
    // أنيميشن الرجوع للبداية (نقطة الصفر)
    _animation = Tween<double>(
      begin: _dragValue,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)); // رجوع سلس
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        final handleSize = 55.0;
        // الهامش الداخلي للكرة (padding)
        final innerPadding = 6.0;

        return Container(
          height: 65,
          // ✅ إزالة الظلال والتوهج كما طلب المستخدم
          decoration: BoxDecoration(
            color: widget.isEnabled ? const Color(0xFF1A1A1A) : Colors.grey[900],
            borderRadius: BorderRadius.circular(100),
            // حدود بسيطة فقط
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1️⃣ خلفية التقدم (بدون تدرج قوي، لون ثابت بسيط)
              if (_dragValue > 0)
                Container(
                  width: _dragValue + handleSize + innerPadding,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: const Color(0xFFffd700).withValues(alpha: 0.2), // لون ذهبي خفيف جداً
                  ),
                ),

              // 2️⃣ النص
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    // إخفاء النص عند بدء السحب
                    opacity: _dragValue > 5 ? 0.0 : 1.0,
                    child: widget.isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFffd700)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "جاري المعالجة...",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 15,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Shimmer.fromColors(
                            // تم تقليل تباين الـ Shimmer ليكون أقل "توهجاً"
                            baseColor: widget.isEnabled ? const Color(0xFFffd700) : Colors.grey[600]!,
                            highlightColor: widget.isEnabled ? Colors.white.withValues(alpha: 0.5) : Colors.grey[500]!,
                            period: const Duration(seconds: 3),
                            child: Text(
                              widget.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // 3️⃣ المقبض (الكرة)
              Positioned(
                // ✅ يبدأ من 6 بيكسل (innerPadding)
                left: innerPadding + _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: _handleDragUpdate,
                  onHorizontalDragEnd: _handleDragEnd,
                  onHorizontalDragCancel: _handleDragCancel,
                  behavior: HitTestBehavior.translucent, // التقاط أفضل
                  child: Container(
                    height: handleSize,
                    width: handleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ✅ لون ذهبي صريح بدون توهج زائد
                      gradient: widget.isEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFFffd700), Color(0xFFD4AF37)], // ذهبي بسيط
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(colors: [Colors.grey[700]!, Colors.grey[800]!]),
                      // ظل بسيط جداً للعمق فقط (ليس توهجاً)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isSubmitting
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A), // لون داكن (على الخلفية الذهبية)
                              ),
                            )
                          : widget.isEnabled
                          ? const Icon(FontAwesomeIcons.arrowRight, color: Color(0xFF1A1A1A), size: 18)
                          : Icon(FontAwesomeIcons.lock, color: Colors.grey[400], size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
