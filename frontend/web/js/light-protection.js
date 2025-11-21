/**
 * 🔒 حماية خفيفة للتطبيق - تطبيق منتجاتي
 * حماية بسيطة بدون إغلاق الموقع
 */

(function() {
    'use strict';

    // 🚫 منع النقر بالزر الأيمن فقط
    document.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        showLightWarning('⚠️ النقر بالزر الأيمن غير مسموح');
        return false;
    });

    // 🚫 منع بعض اختصارات لوحة المفاتيح
    document.addEventListener('keydown', function(e) {
        // F12 فقط
        if (e.keyCode === 123) {
            e.preventDefault();
            showLightWarning('🔒 F12 محظور');
            return false;
        }
        
        // Ctrl+U (View Source)
        if (e.ctrlKey && e.keyCode === 85) {
            e.preventDefault();
            showLightWarning('🔒 عرض المصدر محظور');
            return false;
        }
    });

    // 📱 إظهار تحذير خفيف
    function showLightWarning(message) {
        // تحقق من وجود تحذير سابق
        const existingWarning = document.getElementById('light-warning');
        if (existingWarning) {
            existingWarning.remove();
        }

        // إنشاء عنصر التحذير
        const warning = document.createElement('div');
        warning.id = 'light-warning';
        warning.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff6b6b;
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            font-family: 'Cairo', Arial, sans-serif;
            font-size: 14px;
            font-weight: 600;
            z-index: 999999;
            box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
            transform: translateX(100%);
            transition: transform 0.3s ease;
        `;
        warning.textContent = message;
        
        document.body.appendChild(warning);
        
        // أنيميشن الدخول
        setTimeout(() => {
            warning.style.transform = 'translateX(0)';
        }, 10);
        
        // إزالة التحذير بعد 3 ثوان
        setTimeout(() => {
            warning.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (warning.parentNode) {
                    warning.parentNode.removeChild(warning);
                }
            }, 300);
        }, 3000);
    }

    // 🔐 حماية console خفيفة (بدون إغلاق الموقع)
    function lightConsoleProtection() {
        // رسالة تحذير في console
        console.log('%c🔒 تطبيق منتجاتي محمي', 'color: #ff6b6b; font-size: 16px; font-weight: bold;');
        console.log('%c⚠️ يرجى عدم التلاعب بالكود', 'color: #ffa500; font-size: 12px;');
        
        // تعطيل بعض دوال console فقط
        const originalLog = console.log;
        const originalWarn = console.warn;
        const originalError = console.error;
        
        // السماح ببعض الرسائل المهمة
        console.log = function(...args) {
            const message = args.join(' ');
            if (message.includes('Flutter') || message.includes('Error') || message.includes('Warning')) {
                originalLog.apply(console, args);
            }
        };
        
        console.warn = function(...args) {
            originalWarn.apply(console, args);
        };
        
        console.error = function(...args) {
            originalError.apply(console, args);
        };
    }

    // 🚀 تشغيل الحماية الخفيفة
    function initLightProtection() {
        lightConsoleProtection();
        
        // رسالة ترحيب
        console.log('%c🌐 مرحباً بك في تطبيق منتجاتي', 'color: #2ecc71; font-size: 18px; font-weight: bold;');
        console.log('%cللدعم الفني: support@montajati.com', 'color: #3498db; font-size: 12px;');
    }

    // 🎯 تشغيل الحماية عند تحميل الصفحة
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initLightProtection);
    } else {
        initLightProtection();
    }

})();
