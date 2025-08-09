// 🔒 Console Blocker - قفل كامل للـ Console
// يمنع ظهور أي رسائل في F12 Console نهائياً

(function() {
    'use strict';
    
    // حفظ المراجع الأصلية (في حالة الحاجة لاحقاً)
    const originalConsole = {
        log: console.log,
        warn: console.warn,
        error: console.error,
        info: console.info,
        debug: console.debug,
        trace: console.trace,
        table: console.table,
        group: console.group,
        groupEnd: console.groupEnd,
        groupCollapsed: console.groupCollapsed,
        time: console.time,
        timeEnd: console.timeEnd,
        count: console.count,
        assert: console.assert,
        clear: console.clear,
        dir: console.dir,
        dirxml: console.dirxml
    };
    
    // دالة فارغة لا تفعل شيء
    const noop = function() {};
    
    // قفل جميع دوال Console
    console.log = noop;
    console.warn = noop;
    console.error = noop;
    console.info = noop;
    console.debug = noop;
    console.trace = noop;
    console.table = noop;
    console.group = noop;
    console.groupEnd = noop;
    console.groupCollapsed = noop;
    console.time = noop;
    console.timeEnd = noop;
    console.count = noop;
    console.assert = noop;
    console.clear = noop;
    console.dir = noop;
    console.dirxml = noop;
    
    // منع إعادة تعريف Console
    Object.defineProperty(window, 'console', {
        value: console,
        writable: false,
        configurable: false
    });
    
    // قفل debugPrint إذا كان موجود
    if (window.debugPrint) {
        window.debugPrint = noop;
    }

    // قفل جميع أشكال الطباعة المحتملة
    if (window.flutter_print) {
        window.flutter_print = noop;
    }

    // قفل أي دوال طباعة أخرى قد تضاف
    const printFunctions = ['debugPrint', 'flutter_print', 'dartPrint'];
    printFunctions.forEach(funcName => {
        if (window[funcName]) {
            window[funcName] = noop;
        }
        // منع إضافة دوال جديدة
        Object.defineProperty(window, funcName, {
            value: noop,
            writable: false,
            configurable: false
        });
    });
    
    // منع فتح Developer Tools (اختياري - يمكن تعطيله)
    /*
    document.addEventListener('keydown', function(e) {
        // F12
        if (e.keyCode === 123) {
            e.preventDefault();
            return false;
        }
        // Ctrl+Shift+I
        if (e.ctrlKey && e.shiftKey && e.keyCode === 73) {
            e.preventDefault();
            return false;
        }
        // Ctrl+Shift+C
        if (e.ctrlKey && e.shiftKey && e.keyCode === 67) {
            e.preventDefault();
            return false;
        }
        // Ctrl+U
        if (e.ctrlKey && e.keyCode === 85) {
            e.preventDefault();
            return false;
        }
    });
    */
    
    // قفل فوري بدون أي رسائل
    // لا نريد أي رسائل نهائياً
    
})();
