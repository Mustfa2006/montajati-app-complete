/**
 * 🔒 حماية Console من F12 - تطبيق منتجاتي
 * يمنع المستخدمين من الوصول لـ Developer Tools والتلاعب بالكود
 */

(function() {
    'use strict';

    // 🚫 تعطيل النقر بالزر الأيمن
    document.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        showWarning('⚠️ النقر بالزر الأيمن غير مسموح');
        return false;
    });

    // 🚫 تعطيل اختصارات لوحة المفاتيح للـ Developer Tools
    document.addEventListener('keydown', function(e) {
        // F12
        if (e.keyCode === 123) {
            e.preventDefault();
            showWarning('🔒 أدوات المطور محظورة');
            return false;
        }
        
        // Ctrl+Shift+I (Inspector)
        if (e.ctrlKey && e.shiftKey && e.keyCode === 73) {
            e.preventDefault();
            showWarning('🔒 فحص العناصر محظور');
            return false;
        }
        
        // Ctrl+Shift+J (Console)
        if (e.ctrlKey && e.shiftKey && e.keyCode === 74) {
            e.preventDefault();
            showWarning('🔒 وحدة التحكم محظورة');
            return false;
        }
        
        // Ctrl+U (View Source)
        if (e.ctrlKey && e.keyCode === 85) {
            e.preventDefault();
            showWarning('🔒 عرض المصدر محظور');
            return false;
        }
        
        // Ctrl+Shift+C (Element Selector)
        if (e.ctrlKey && e.shiftKey && e.keyCode === 67) {
            e.preventDefault();
            showWarning('🔒 محدد العناصر محظور');
            return false;
        }
        
        // Ctrl+S (Save Page)
        if (e.ctrlKey && e.keyCode === 83) {
            e.preventDefault();
            showWarning('🔒 حفظ الصفحة محظور');
            return false;
        }
    });

    // 🔍 كشف فتح Developer Tools
    let devtools = {
        open: false,
        orientation: null
    };

    const threshold = 160;

    setInterval(function() {
        if (window.outerHeight - window.innerHeight > threshold || 
            window.outerWidth - window.innerWidth > threshold) {
            if (!devtools.open) {
                devtools.open = true;
                handleDevToolsOpen();
            }
        } else {
            devtools.open = false;
        }
    }, 500);

    // 🚨 التعامل مع فتح Developer Tools
    function handleDevToolsOpen() {
        // إخفاء المحتوى
        document.body.style.display = 'none';
        
        // إظهار رسالة تحذير
        showFullScreenWarning();
        
        // إعادة توجيه بعد 3 ثوان
        setTimeout(function() {
            window.location.href = 'about:blank';
        }, 3000);
    }

    // 🔒 حماية Console من التلاعب
    function protectConsole() {
        // تعطيل console.log
        if (typeof console !== 'undefined') {
            console.log = function() {};
            console.warn = function() {};
            console.error = function() {};
            console.info = function() {};
            console.debug = function() {};
            console.clear = function() {};
            console.dir = function() {};
            console.dirxml = function() {};
            console.table = function() {};
            console.trace = function() {};
            console.group = function() {};
            console.groupCollapsed = function() {};
            console.groupEnd = function() {};
            console.time = function() {};
            console.timeEnd = function() {};
            console.profile = function() {};
            console.profileEnd = function() {};
            console.count = function() {};
        }

        // منع إنشاء console جديد
        Object.defineProperty(window, 'console', {
            get: function() {
                throw new Error('🔒 Console محظور');
            },
            set: function() {
                throw new Error('🔒 لا يمكن تعديل Console');
            }
        });
    }

    // 🛡️ حماية من التلاعب بالـ DOM
    function protectDOM() {
        // منع تعديل innerHTML
        const originalInnerHTML = Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML');
        Object.defineProperty(Element.prototype, 'innerHTML', {
            set: function(value) {
                if (this.tagName === 'SCRIPT') {
                    throw new Error('🔒 تعديل السكريبت محظور');
                }
                return originalInnerHTML.set.call(this, value);
            },
            get: originalInnerHTML.get
        });
    }

    // 📱 إظهار تحذير بسيط
    function showWarning(message) {
        // إنشاء عنصر التحذير
        const warning = document.createElement('div');
        warning.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff4444;
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            font-family: 'Cairo', Arial, sans-serif;
            font-size: 14px;
            font-weight: bold;
            z-index: 999999;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            animation: slideIn 0.3s ease-out;
        `;
        warning.textContent = message;
        
        // إضافة الأنيميشن
        const style = document.createElement('style');
        style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
        `;
        document.head.appendChild(style);
        
        document.body.appendChild(warning);
        
        // إزالة التحذير بعد 3 ثوان
        setTimeout(() => {
            if (warning.parentNode) {
                warning.parentNode.removeChild(warning);
            }
        }, 3000);
    }

    // 🚨 إظهار تحذير ملء الشاشة
    function showFullScreenWarning() {
        const overlay = document.createElement('div');
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            font-family: 'Cairo', Arial, sans-serif;
            z-index: 999999;
            text-align: center;
        `;
        
        overlay.innerHTML = `
            <div style="font-size: 72px; margin-bottom: 20px;">🔒</div>
            <h1 style="font-size: 32px; margin-bottom: 20px;">منطقة محظورة</h1>
            <p style="font-size: 18px; margin-bottom: 30px;">أدوات المطور محظورة لحماية التطبيق</p>
            <p style="font-size: 16px; opacity: 0.8;">سيتم إعادة توجيهك خلال 3 ثوان...</p>
            <div style="margin-top: 30px;">
                <div style="width: 50px; height: 50px; border: 3px solid rgba(255,255,255,0.3); border-top: 3px solid white; border-radius: 50%; animation: spin 1s linear infinite;"></div>
            </div>
        `;
        
        // إضافة أنيميشن الدوران
        const style = document.createElement('style');
        style.textContent = `
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        `;
        document.head.appendChild(style);
        
        document.body.appendChild(overlay);
    }

    // 🔐 منع النسخ والتحديد
    function preventCopyPaste() {
        // منع التحديد
        document.onselectstart = function() {
            return false;
        };
        
        // منع السحب
        document.ondragstart = function() {
            return false;
        };
        
        // منع النسخ
        document.addEventListener('copy', function(e) {
            e.preventDefault();
            showWarning('🚫 النسخ محظور');
            return false;
        });
        
        // منع اللصق
        document.addEventListener('paste', function(e) {
            e.preventDefault();
            showWarning('🚫 اللصق محظور');
            return false;
        });
    }

    // 🚀 تشغيل جميع الحمايات
    function initProtection() {
        protectConsole();
        protectDOM();
        preventCopyPaste();
        
        // رسالة ترحيب في Console (قبل تعطيله)
        console.log('%c🔒 تطبيق منتجاتي محمي', 'color: #ff4444; font-size: 20px; font-weight: bold;');
        console.log('%cأي محاولة للتلاعب ستؤدي لحظر الوصول', 'color: #ff6666; font-size: 14px;');
    }

    // 🎯 تشغيل الحماية عند تحميل الصفحة
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initProtection);
    } else {
        initProtection();
    }

    // 🔄 حماية إضافية من إعادة تعريف الدوال
    Object.freeze(console);
    Object.freeze(document);
    Object.freeze(window);

})();
