/**
 * 🛡️ حماية متقدمة للتطبيق - تطبيق منتجاتي
 * حماية شاملة ضد جميع أنواع التلاعب والهندسة العكسية
 */

(function() {
    'use strict';

    // 🔐 متغيرات الحماية
    const PROTECTION_CONFIG = {
        blockDevTools: true,
        blockRightClick: true,
        blockKeyboardShortcuts: true,
        blockConsole: true,
        blockSourceView: true,
        redirectOnDetection: true,
        showWarnings: true
    };

    // 🚨 كشف أدوات المطور المتقدم
    class DevToolsDetector {
        constructor() {
            this.isOpen = false;
            this.threshold = 160;
            this.checkInterval = 100;
            this.init();
        }

        init() {
            // طريقة 1: فحص حجم النافذة
            this.startSizeCheck();
            
            // طريقة 2: فحص وقت تنفيذ console.log
            this.startConsoleCheck();
            
            // طريقة 3: فحص debugger
            this.startDebuggerCheck();
            
            // طريقة 4: فحص toString
            this.startToStringCheck();
        }

        startSizeCheck() {
            setInterval(() => {
                const heightDiff = window.outerHeight - window.innerHeight;
                const widthDiff = window.outerWidth - window.innerWidth;
                
                if (heightDiff > this.threshold || widthDiff > this.threshold) {
                    this.handleDetection('size_check');
                }
            }, this.checkInterval);
        }

        startConsoleCheck() {
            let start = performance.now();
            console.log('%c', '');
            let end = performance.now();
            
            if (end - start > 100) {
                this.handleDetection('console_timing');
            }
        }

        startDebuggerCheck() {
            setInterval(() => {
                const start = performance.now();
                debugger;
                const end = performance.now();
                
                if (end - start > 100) {
                    this.handleDetection('debugger_timing');
                }
            }, 1000);
        }

        startToStringCheck() {
            const element = document.createElement('div');
            Object.defineProperty(element, 'id', {
                get: () => {
                    this.handleDetection('toString_trap');
                    return 'detected';
                }
            });
            
            setInterval(() => {
                console.log(element);
            }, 1000);
        }

        handleDetection(method) {
            if (!this.isOpen) {
                this.isOpen = true;
                console.log(`🚨 Developer Tools detected via: ${method}`);
                
                if (PROTECTION_CONFIG.redirectOnDetection) {
                    this.blockAccess();
                }
            }
        }

        blockAccess() {
            // إخفاء المحتوى
            document.documentElement.innerHTML = `
                <div style="
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
                    color: white;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    font-family: 'Cairo', Arial, sans-serif;
                    text-align: center;
                    z-index: 999999;
                ">
                    <div style="font-size: 80px; margin-bottom: 30px;">🔒</div>
                    <h1 style="font-size: 36px; margin-bottom: 20px; font-weight: bold;">
                        وصول محظور
                    </h1>
                    <p style="font-size: 20px; margin-bottom: 30px; opacity: 0.9;">
                        تم اكتشاف محاولة للوصول لأدوات المطور
                    </p>
                    <p style="font-size: 16px; opacity: 0.7; margin-bottom: 40px;">
                        هذا التطبيق محمي ضد التلاعب والهندسة العكسية
                    </p>
                    <div style="
                        padding: 15px 30px;
                        background: rgba(255,255,255,0.1);
                        border-radius: 25px;
                        font-size: 14px;
                    ">
                        تطبيق منتجاتي © 2024
                    </div>
                </div>
            `;
            
            // منع التفاعل
            document.addEventListener('keydown', (e) => e.preventDefault());
            document.addEventListener('contextmenu', (e) => e.preventDefault());
            
            // إعادة توجيه بعد 5 ثوان
            setTimeout(() => {
                window.location.href = 'about:blank';
            }, 5000);
        }
    }

    // 🔒 حماية Console المتقدمة
    class ConsoleProtector {
        constructor() {
            this.originalConsole = { ...console };
            this.init();
        }

        init() {
            this.disableConsole();
            this.trapConsoleAccess();
            this.preventConsoleCreation();
        }

        disableConsole() {
            const methods = [
                'log', 'warn', 'error', 'info', 'debug', 'clear',
                'dir', 'dirxml', 'table', 'trace', 'group',
                'groupCollapsed', 'groupEnd', 'time', 'timeEnd',
                'profile', 'profileEnd', 'count', 'assert'
            ];

            methods.forEach(method => {
                console[method] = () => {};
            });
        }

        trapConsoleAccess() {
            Object.defineProperty(window, 'console', {
                get: () => {
                    throw new Error('🔒 Console access denied');
                },
                set: () => {
                    throw new Error('🔒 Console modification denied');
                },
                configurable: false
            });
        }

        preventConsoleCreation() {
            // منع إنشاء console جديد
            const iframe = document.createElement('iframe');
            iframe.style.display = 'none';
            document.body.appendChild(iframe);
            
            const iframeConsole = iframe.contentWindow.console;
            Object.keys(iframeConsole).forEach(key => {
                if (typeof iframeConsole[key] === 'function') {
                    iframeConsole[key] = () => {};
                }
            });
        }
    }

    // ⌨️ حماية لوحة المفاتيح
    class KeyboardProtector {
        constructor() {
            this.blockedKeys = [
                { key: 123 }, // F12
                { key: 116 }, // F5
                { ctrl: true, shift: true, key: 73 }, // Ctrl+Shift+I
                { ctrl: true, shift: true, key: 74 }, // Ctrl+Shift+J
                { ctrl: true, shift: true, key: 67 }, // Ctrl+Shift+C
                { ctrl: true, key: 85 }, // Ctrl+U
                { ctrl: true, key: 83 }, // Ctrl+S
                { ctrl: true, key: 65 }, // Ctrl+A
                { ctrl: true, key: 67 }, // Ctrl+C
                { ctrl: true, key: 86 }, // Ctrl+V
                { ctrl: true, key: 88 }, // Ctrl+X
                { ctrl: true, key: 90 }, // Ctrl+Z
                { ctrl: true, key: 89 }, // Ctrl+Y
            ];
            
            this.init();
        }

        init() {
            document.addEventListener('keydown', (e) => {
                if (this.isBlocked(e)) {
                    e.preventDefault();
                    e.stopPropagation();
                    this.showKeyWarning(e);
                    return false;
                }
            });
        }

        isBlocked(event) {
            return this.blockedKeys.some(blocked => {
                const ctrlMatch = !blocked.ctrl || event.ctrlKey;
                const shiftMatch = !blocked.shift || event.shiftKey;
                const keyMatch = blocked.key === event.keyCode;
                
                return ctrlMatch && shiftMatch && keyMatch;
            });
        }

        showKeyWarning(event) {
            const keyName = this.getKeyName(event);
            this.showToast(`🚫 الاختصار ${keyName} محظور`);
        }

        getKeyName(event) {
            const keys = [];
            if (event.ctrlKey) keys.push('Ctrl');
            if (event.shiftKey) keys.push('Shift');
            if (event.altKey) keys.push('Alt');
            
            const keyNames = {
                123: 'F12',
                116: 'F5',
                73: 'I',
                74: 'J',
                67: 'C',
                85: 'U',
                83: 'S',
                65: 'A',
                86: 'V',
                88: 'X',
                90: 'Z',
                89: 'Y'
            };
            
            keys.push(keyNames[event.keyCode] || event.key);
            return keys.join('+');
        }

        showToast(message) {
            const toast = document.createElement('div');
            toast.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: #ff4757;
                color: white;
                padding: 12px 20px;
                border-radius: 6px;
                font-family: 'Cairo', Arial, sans-serif;
                font-size: 14px;
                font-weight: 600;
                z-index: 999999;
                box-shadow: 0 4px 12px rgba(255, 71, 87, 0.3);
                transform: translateX(100%);
                transition: transform 0.3s ease;
            `;
            toast.textContent = message;
            
            document.body.appendChild(toast);
            
            // أنيميشن الدخول
            setTimeout(() => {
                toast.style.transform = 'translateX(0)';
            }, 10);
            
            // إزالة بعد 3 ثوان
            setTimeout(() => {
                toast.style.transform = 'translateX(100%)';
                setTimeout(() => {
                    if (toast.parentNode) {
                        toast.parentNode.removeChild(toast);
                    }
                }, 300);
            }, 3000);
        }
    }

    // 🖱️ حماية الماوس
    class MouseProtector {
        constructor() {
            this.init();
        }

        init() {
            // منع النقر بالزر الأيمن
            document.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                this.showMouseWarning('النقر بالزر الأيمن محظور');
                return false;
            });

            // منع التحديد
            document.addEventListener('selectstart', (e) => {
                e.preventDefault();
                return false;
            });

            // منع السحب
            document.addEventListener('dragstart', (e) => {
                e.preventDefault();
                return false;
            });
        }

        showMouseWarning(message) {
            // نفس آلية showToast في KeyboardProtector
            const toast = document.createElement('div');
            toast.style.cssText = `
                position: fixed;
                top: 20px;
                left: 20px;
                background: #ff6b6b;
                color: white;
                padding: 12px 20px;
                border-radius: 6px;
                font-family: 'Cairo', Arial, sans-serif;
                font-size: 14px;
                font-weight: 600;
                z-index: 999999;
                box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
            `;
            toast.textContent = `🚫 ${message}`;
            
            document.body.appendChild(toast);
            
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 2000);
        }
    }

    // 🚀 تشغيل جميع أنظمة الحماية
    function initAdvancedProtection() {
        // رسالة ترحيب أخيرة قبل تعطيل Console
        console.log('%c🛡️ تطبيق منتجاتي', 'color: #2ecc71; font-size: 24px; font-weight: bold;');
        console.log('%c🔒 نظام الحماية المتقدم مُفعل', 'color: #e74c3c; font-size: 16px;');
        console.log('%c⚠️ أي محاولة تلاعب ستؤدي للحظر الفوري', 'color: #f39c12; font-size: 14px;');

        // تشغيل أنظمة الحماية
        new DevToolsDetector();
        new ConsoleProtector();
        new KeyboardProtector();
        new MouseProtector();

        // حماية إضافية
        protectGlobalObjects();
        preventInjection();
    }

    // 🔐 حماية الكائنات العامة
    function protectGlobalObjects() {
        // تجميد الكائنات المهمة
        Object.freeze(Object.prototype);
        Object.freeze(Array.prototype);
        Object.freeze(Function.prototype);
        Object.freeze(String.prototype);
        Object.freeze(Number.prototype);
        Object.freeze(Boolean.prototype);
        Object.freeze(Date.prototype);
        Object.freeze(RegExp.prototype);
    }

    // 💉 منع حقن الكود
    function preventInjection() {
        // منع eval
        window.eval = function() {
            throw new Error('🔒 eval() محظور');
        };

        // منع Function constructor
        window.Function = function() {
            throw new Error('🔒 Function constructor محظور');
        };

        // منع setTimeout/setInterval مع strings
        const originalSetTimeout = window.setTimeout;
        const originalSetInterval = window.setInterval;

        window.setTimeout = function(callback, delay) {
            if (typeof callback === 'string') {
                throw new Error('🔒 setTimeout مع string محظور');
            }
            return originalSetTimeout.apply(this, arguments);
        };

        window.setInterval = function(callback, delay) {
            if (typeof callback === 'string') {
                throw new Error('🔒 setInterval مع string محظور');
            }
            return originalSetInterval.apply(this, arguments);
        };
    }

    // 🎯 تشغيل الحماية
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAdvancedProtection);
    } else {
        initAdvancedProtection();
    }

})();
