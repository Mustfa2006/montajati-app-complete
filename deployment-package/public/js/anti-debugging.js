/**
 * 🛡️ حماية ضد التصحيح والهندسة العكسية - تطبيق منتجاتي
 * نظام حماية متقدم ضد جميع أنواع التلاعب والتحليل
 */

(function() {
    'use strict';

    // 🔐 إعدادات الحماية
    const ANTI_DEBUG_CONFIG = {
        enableDebuggerTrap: true,
        enableTimingCheck: true,
        enableStackTrace: true,
        enableMemoryCheck: true,
        enableNetworkMonitor: true,
        redirectUrl: 'about:blank',
        warningDuration: 3000
    };

    // 🚨 كاشف التصحيح المتقدم
    class AntiDebugger {
        constructor() {
            this.isDebugging = false;
            this.checkInterval = 50;
            this.timingThreshold = 100;
            this.init();
        }

        init() {
            this.startDebuggerTrap();
            this.startTimingAnalysis();
            this.startStackTraceMonitor();
            this.startMemoryMonitor();
            this.startNetworkMonitor();
            this.obfuscateCode();
        }

        // 🪤 فخ الـ Debugger
        startDebuggerTrap() {
            if (!ANTI_DEBUG_CONFIG.enableDebuggerTrap) return;

            const trapFunction = () => {
                const start = performance.now();
                debugger;
                const end = performance.now();
                
                if (end - start > this.timingThreshold) {
                    this.handleDebugDetection('debugger_trap');
                }
            };

            // تشغيل الفخ بشكل عشوائي
            setInterval(() => {
                if (Math.random() > 0.7) {
                    trapFunction();
                }
            }, this.checkInterval + Math.random() * 100);
        }

        // ⏱️ تحليل التوقيت
        startTimingAnalysis() {
            if (!ANTI_DEBUG_CONFIG.enableTimingCheck) return;

            let lastTime = performance.now();
            
            const checkTiming = () => {
                const currentTime = performance.now();
                const timeDiff = currentTime - lastTime;
                
                // إذا كان الفرق كبير جداً، قد يكون هناك breakpoint
                if (timeDiff > 1000) {
                    this.handleDebugDetection('timing_anomaly');
                }
                
                lastTime = currentTime;
            };

            setInterval(checkTiming, 100);
        }

        // 📚 مراقب Stack Trace
        startStackTraceMonitor() {
            if (!ANTI_DEBUG_CONFIG.enableStackTrace) return;

            const originalError = Error;
            
            Error = function(...args) {
                const error = new originalError(...args);
                
                // فحص stack trace للبحث عن أدوات التصحيح
                if (error.stack) {
                    const suspiciousPatterns = [
                        'chrome-extension://',
                        'moz-extension://',
                        'webkit-masked-url://',
                        'devtools://',
                        'chrome-devtools://'
                    ];
                    
                    if (suspiciousPatterns.some(pattern => error.stack.includes(pattern))) {
                        this.handleDebugDetection('stack_trace_analysis');
                    }
                }
                
                return error;
            };
        }

        // 💾 مراقب الذاكرة
        startMemoryMonitor() {
            if (!ANTI_DEBUG_CONFIG.enableMemoryCheck) return;

            if ('memory' in performance) {
                let baselineMemory = performance.memory.usedJSHeapSize;
                
                setInterval(() => {
                    const currentMemory = performance.memory.usedJSHeapSize;
                    const memoryIncrease = currentMemory - baselineMemory;
                    
                    // زيادة مفاجئة في الذاكرة قد تشير لأدوات التصحيح
                    if (memoryIncrease > 50 * 1024 * 1024) { // 50MB
                        this.handleDebugDetection('memory_anomaly');
                    }
                    
                    baselineMemory = currentMemory;
                }, 5000);
            }
        }

        // 🌐 مراقب الشبكة
        startNetworkMonitor() {
            if (!ANTI_DEBUG_CONFIG.enableNetworkMonitor) return;

            // مراقبة XMLHttpRequest
            const originalXHR = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (url.includes('devtools') || url.includes('chrome-extension')) {
                    this.handleDebugDetection('network_devtools');
                }
                return originalXHR.apply(this, arguments);
            };

            // مراقبة fetch
            const originalFetch = window.fetch;
            window.fetch = function(url) {
                if (typeof url === 'string' && 
                    (url.includes('devtools') || url.includes('chrome-extension'))) {
                    this.handleDebugDetection('fetch_devtools');
                }
                return originalFetch.apply(this, arguments);
            };
        }

        // 🔀 تشويش الكود
        obfuscateCode() {
            // إنشاء دوال وهمية لتضليل المحللين
            const dummyFunctions = [];
            
            for (let i = 0; i < 50; i++) {
                const funcName = this.generateRandomString(8);
                window[funcName] = function() {
                    return Math.random() * 1000;
                };
                dummyFunctions.push(funcName);
            }

            // تشغيل الدوال الوهمية بشكل عشوائي
            setInterval(() => {
                const randomFunc = dummyFunctions[Math.floor(Math.random() * dummyFunctions.length)];
                if (window[randomFunc]) {
                    window[randomFunc]();
                }
            }, 1000);
        }

        // 🎲 توليد نص عشوائي
        generateRandomString(length) {
            const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
            let result = '';
            for (let i = 0; i < length; i++) {
                result += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            return result;
        }

        // 🚨 التعامل مع اكتشاف التصحيح
        handleDebugDetection(method) {
            if (this.isDebugging) return;
            
            this.isDebugging = true;
            
            console.log(`🚨 Debug attempt detected: ${method}`);
            
            // إخفاء المحتوى فوراً
            this.hideContent();
            
            // إظهار رسالة تحذير
            this.showAntiDebugWarning(method);
            
            // إعادة توجيه بعد فترة
            setTimeout(() => {
                window.location.href = ANTI_DEBUG_CONFIG.redirectUrl;
            }, ANTI_DEBUG_CONFIG.warningDuration);
        }

        // 🙈 إخفاء المحتوى
        hideContent() {
            document.body.style.visibility = 'hidden';
            document.documentElement.style.visibility = 'hidden';
        }

        // ⚠️ إظهار تحذير مكافحة التصحيح
        showAntiDebugWarning(method) {
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: linear-gradient(45deg, #ff6b6b, #ee5a24);
                color: white;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                font-family: 'Cairo', Arial, sans-serif;
                z-index: 999999;
                text-align: center;
                animation: pulse 1s infinite;
            `;
            
            overlay.innerHTML = `
                <div style="font-size: 100px; margin-bottom: 30px; animation: shake 0.5s infinite;">⚠️</div>
                <h1 style="font-size: 42px; margin-bottom: 20px; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.5);">
                    تحذير أمني
                </h1>
                <p style="font-size: 24px; margin-bottom: 20px; opacity: 0.9;">
                    تم اكتشاف محاولة تصحيح غير مصرح بها
                </p>
                <p style="font-size: 18px; margin-bottom: 30px; opacity: 0.8;">
                    طريقة الاكتشاف: ${this.getMethodDescription(method)}
                </p>
                <div style="
                    padding: 20px 40px;
                    background: rgba(0,0,0,0.3);
                    border-radius: 15px;
                    font-size: 16px;
                    margin-bottom: 30px;
                ">
                    🔒 هذا التطبيق محمي بنظام أمان متقدم
                </div>
                <div style="font-size: 14px; opacity: 0.7;">
                    سيتم إعادة التوجيه خلال ${ANTI_DEBUG_CONFIG.warningDuration / 1000} ثوان
                </div>
            `;
            
            // إضافة الأنيميشن
            const style = document.createElement('style');
            style.textContent = `
                @keyframes pulse {
                    0% { opacity: 1; }
                    50% { opacity: 0.8; }
                    100% { opacity: 1; }
                }
                @keyframes shake {
                    0%, 100% { transform: translateX(0); }
                    25% { transform: translateX(-5px); }
                    75% { transform: translateX(5px); }
                }
            `;
            document.head.appendChild(style);
            
            document.body.appendChild(overlay);
        }

        // 📝 وصف طريقة الاكتشاف
        getMethodDescription(method) {
            const descriptions = {
                'debugger_trap': 'فخ الـ Debugger',
                'timing_anomaly': 'تحليل التوقيت',
                'stack_trace_analysis': 'تحليل Stack Trace',
                'memory_anomaly': 'مراقبة الذاكرة',
                'network_devtools': 'مراقبة الشبكة',
                'fetch_devtools': 'مراقبة Fetch API'
            };
            
            return descriptions[method] || 'طريقة غير معروفة';
        }
    }

    // 🔐 حماية إضافية ضد التلاعب
    class CodeIntegrityProtector {
        constructor() {
            this.originalCode = this.getCodeHash();
            this.init();
        }

        init() {
            this.startIntegrityCheck();
            this.protectCriticalFunctions();
        }

        // 🔍 فحص سلامة الكود
        startIntegrityCheck() {
            setInterval(() => {
                const currentHash = this.getCodeHash();
                if (currentHash !== this.originalCode) {
                    this.handleTampering();
                }
            }, 2000);
        }

        // 🔢 حساب hash للكود
        getCodeHash() {
            const scripts = Array.from(document.scripts);
            const codeContent = scripts.map(script => script.innerHTML).join('');
            return this.simpleHash(codeContent);
        }

        // 🔢 hash بسيط
        simpleHash(str) {
            let hash = 0;
            for (let i = 0; i < str.length; i++) {
                const char = str.charCodeAt(i);
                hash = ((hash << 5) - hash) + char;
                hash = hash & hash; // Convert to 32bit integer
            }
            return hash;
        }

        // 🛡️ حماية الدوال المهمة
        protectCriticalFunctions() {
            const criticalFunctions = [
                'fetch', 'XMLHttpRequest', 'eval', 'Function',
                'setTimeout', 'setInterval', 'addEventListener'
            ];

            criticalFunctions.forEach(funcName => {
                if (window[funcName]) {
                    const original = window[funcName];
                    Object.defineProperty(window, funcName, {
                        get: () => original,
                        set: () => {
                            this.handleTampering();
                        },
                        configurable: false
                    });
                }
            });
        }

        // 🚨 التعامل مع التلاعب
        handleTampering() {
            console.log('🚨 Code tampering detected!');
            window.location.href = 'about:blank';
        }
    }

    // 🚀 تشغيل نظام مكافحة التصحيح
    function initAntiDebugging() {
        // رسالة تحذير أخيرة
        console.log('%c🛡️ نظام مكافحة التصحيح مُفعل', 'color: #e74c3c; font-size: 18px; font-weight: bold;');
        console.log('%c⚠️ أي محاولة تصحيح ستؤدي للحظر الفوري', 'color: #f39c12; font-size: 14px;');

        // تشغيل أنظمة الحماية
        new AntiDebugger();
        new CodeIntegrityProtector();
    }

    // 🎯 تشغيل النظام
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAntiDebugging);
    } else {
        initAntiDebugging();
    }

})();
