#!/usr/bin/env dart

/// 🔍 سكريبت التحقق من إصلاح جميع المشاكل
/// 
/// هذا السكريبت يتحقق من:
/// 1. عدم وجود activeColor deprecated
/// 2. عدم وجود withOpacity deprecated
/// 3. عدم وجود استيرادات مكررة
/// 4. عدم وجود DropdownMenuItem بدون نوع

import 'dart:io';

void main() async {
  print('🔍 بدء التحقق من إصلاح المشاكل...');
  print('=' * 50);

  final verifier = FixesVerifier();
  await verifier.verifyAllFixes();
}

class FixesVerifier {
  int checkedFiles = 0;
  List<String> remainingIssues = [];

  Future<void> verifyAllFixes() async {
    final frontendDir = Directory('frontend/lib');
    
    if (!frontendDir.existsSync()) {
      print('❌ مجلد frontend/lib غير موجود');
      return;
    }

    print('📁 فحص مجلد: ${frontendDir.path}');
    await _processDirectory(frontendDir);
    
    _printResults();
  }

  Future<void> _processDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _checkFile(entity);
      }
    }
  }

  Future<void> _checkFile(File file) async {
    try {
      final content = await file.readAsString();
      checkedFiles++;

      // فحص activeColor deprecated
      if (content.contains('activeColor:')) {
        remainingIssues.add('${file.path}: لا يزال يحتوي على activeColor deprecated');
      }

      // فحص withOpacity deprecated
      if (content.contains('.withOpacity(')) {
        remainingIssues.add('${file.path}: لا يزال يحتوي على withOpacity deprecated');
      }

      // فحص الاستيرادات المكررة
      final duplicateImports = _findDuplicateImports(content);
      if (duplicateImports.isNotEmpty) {
        remainingIssues.add('${file.path}: لا يزال يحتوي على ${duplicateImports.length} استيراد مكرر');
      }

      // فحص DropdownMenuItem بدون نوع
      final dropdownRegex = RegExp(r'DropdownMenuItem\s*\(');
      if (dropdownRegex.hasMatch(content)) {
        remainingIssues.add('${file.path}: لا يزال يحتوي على DropdownMenuItem بدون تحديد النوع');
      }

    } catch (e) {
      print('❌ خطأ في فحص ${file.path}: $e');
    }
  }

  List<String> _findDuplicateImports(String content) {
    final lines = content.split('\n');
    final imports = <String>[];
    final duplicates = <String>[];

    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        if (imports.contains(line.trim())) {
          duplicates.add(line.trim());
        } else {
          imports.add(line.trim());
        }
      }
    }

    return duplicates;
  }

  void _printResults() {
    print('\n' + '=' * 50);
    print('📊 نتائج التحقق:');
    print('📁 الملفات المفحوصة: $checkedFiles');
    
    if (remainingIssues.isEmpty) {
      print('🎉 ممتاز! تم إصلاح جميع المشاكل بنجاح!');
      print('✅ لا توجد مشاكل متبقية');
      print('🚀 التطبيق جاهز للاستخدام');
    } else {
      print('⚠️ لا تزال هناك ${remainingIssues.length} مشكلة:');
      for (final issue in remainingIssues) {
        print('  • $issue');
      }
    }

    print('\n💡 للتأكد النهائي، قم بتشغيل:');
    print('   flutter analyze');
    print('   flutter doctor');
  }
}
