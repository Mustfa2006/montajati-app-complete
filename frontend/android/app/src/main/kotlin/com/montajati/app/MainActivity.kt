package com.montajati.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.view.WindowManager
import android.view.View
import android.os.Build
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private lateinit var methodChannel: MethodChannel
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // تحسين أداء التطبيق عند البداية
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )

        // إزالة أي تأخير في عرض المحتوى
        window.setFlags(
            WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS,
            WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        )

        // 🔥 إعداد النمط الغامر الشامل
        setupImmersiveMode()
        setupSystemUiVisibilityListener()
        setupMethodChannel()

        // مراقبة مستمرة لضمان إخفاء Navigation Bar
        startNavigationBarMonitoring()
    }

    private fun setupImmersiveMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ - Status Bar ثابت + Navigation Bar مخفي
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                // إخفاء Navigation Bar فقط
                controller.hide(android.view.WindowInsets.Type.navigationBars())
                // إظهار Status Bar دائماً
                controller.show(android.view.WindowInsets.Type.statusBars())
                controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Android 10 وأقل - Status Bar ثابت + Navigation Bar مخفي
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                // لا نضيف SYSTEM_UI_FLAG_FULLSCREEN لإبقاء Status Bar
            )
        }

        // ألوان الشرائط
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            // Status Bar ثابت مع لون مناسب
            window.statusBarColor = android.graphics.Color.parseColor("#1A1A2E")
        }
    }

    private fun setupSystemUiVisibilityListener() {
        // للإصدارات الأقدم من Android 11 - مراقبة Navigation Bar فقط
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            window.decorView.setOnSystemUiVisibilityChangeListener { visibility ->
                // إذا ظهر Navigation Bar، أخفه (Status Bar يبقى ثابت)
                if (visibility and View.SYSTEM_UI_FLAG_HIDE_NAVIGATION == 0) {
                    // Navigation Bar ظاهر، أخفه مع إبقاء Status Bar
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        hideNavigationBarOnly()
                    }, 100)
                }
            }
        }
    }

    private fun hideNavigationBarOnly() {
        // إخفاء Navigation Bar فقط مع إبقاء Status Bar ثابت
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.hide(android.view.WindowInsets.Type.navigationBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    private fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "immersive_mode")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hideNavigationBar" -> {
                    forceHideNavigationBar()
                    result.success(null)
                }
                "showNavigationBar" -> {
                    forceShowNavigationBar()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun forceHideNavigationBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ - إخفاء قوي للـ Navigation Bar
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(android.view.WindowInsets.Type.navigationBars())
                controller.show(android.view.WindowInsets.Type.statusBars()) // Status Bar ثابت
                controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Android 10 وأقل - إخفاء قوي
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    private fun forceShowNavigationBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(android.view.WindowInsets.Type.navigationBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        }
    }

    private fun startNavigationBarMonitoring() {
        // مراقبة كل 500ms لضمان إخفاء Navigation Bar
        handler.postDelayed(object : Runnable {
            override fun run() {
                forceHideNavigationBar()
                handler.postDelayed(this, 500)
            }
        }, 500)
    }
}
