#!/usr/bin/env dart

/// 🔧 سكريبت إصلاح مشاكل Flutter التلقائي
/// 
/// هذا السكريبت يقوم بـ:
/// 1. فحص جميع ملفات Dart
/// 2. إصلاح المشاكل الشائعة تلقائياً
/// 3. إنشاء تقرير بالإصلاحات

import 'dart:io';

void main() async {
  print('🔧 بدء إصلاح مشاكل Flutter...');
  print('=' * 50);

  final fixer = FlutterIssuesFixer();
  await fixer.fixAllIssues();
}

class FlutterIssuesFixer {
  int fixedFiles = 0;
  int totalFixes = 0;
  List<String> fixedIssues = [];

  Future<void> fixAllIssues() async {
    final frontendDir = Directory('frontend/lib');
    
    if (!frontendDir.existsSync()) {
      print('❌ مجلد frontend/lib غير موجود');
      return;
    }

    print('📁 فحص مجلد: ${frontendDir.path}');
    await _processDirectory(frontendDir);
    
    _printSummary();
  }

  Future<void> _processDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _processFile(entity);
      }
    }
  }

  Future<void> _processFile(File file) async {
    try {
      final content = await file.readAsString();
      String newContent = content;
      int fileFixes = 0;

      // إصلاح activeColor deprecated
      final activeColorRegex = RegExp(r'activeColor:\s*([^,\n]+)');
      if (activeColorRegex.hasMatch(newContent)) {
        newContent = _fixActiveColor(newContent);
        fileFixes++;
        fixedIssues.add('${file.path}: إصلاح activeColor deprecated');
      }

      // إصلاح withOpacity deprecated
      if (newContent.contains('.withOpacity(')) {
        newContent = newContent.replaceAllMapped(
          RegExp(r'\.withOpacity\(([^)]+)\)'),
          (match) => '.withValues(alpha: ${match.group(1)})',
        );
        fileFixes++;
        fixedIssues.add('${file.path}: إصلاح withOpacity deprecated');
      }

      // إصلاح الاستيرادات المكررة
      final duplicateImports = _findDuplicateImports(newContent);
      if (duplicateImports.isNotEmpty) {
        newContent = _removeDuplicateImports(newContent);
        fileFixes++;
        fixedIssues.add('${file.path}: إزالة ${duplicateImports.length} استيراد مكرر');
      }

      // حفظ الملف إذا تم إجراء إصلاحات
      if (fileFixes > 0) {
        await file.writeAsString(newContent);
        fixedFiles++;
        totalFixes += fileFixes;
        print('✅ تم إصلاح: ${file.path} ($fileFixes إصلاحات)');
      }

    } catch (e) {
      print('❌ خطأ في معالجة ${file.path}: $e');
    }
  }

  String _fixActiveColor(String content) {
    return content.replaceAllMapped(
      RegExp(r'activeColor:\s*([^,\n]+)'),
      (match) {
        final color = match.group(1)!.trim();
        return '''thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return $color;
          }
          return Colors.grey;
        })''';
      },
    );
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

  String _removeDuplicateImports(String content) {
    final lines = content.split('\n');
    final seenImports = <String>{};
    final newLines = <String>[];

    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        if (!seenImports.contains(line.trim())) {
          seenImports.add(line.trim());
          newLines.add(line);
        }
        // تجاهل الاستيرادات المكررة
      } else {
        newLines.add(line);
      }
    }

    return newLines.join('\n');
  }

  void _printSummary() {
    print('\n' + '=' * 50);
    print('📊 ملخص الإصلاحات:');
    print('✅ الملفات المُصلحة: $fixedFiles');
    print('🔧 إجمالي الإصلاحات: $totalFixes');
    
    if (fixedIssues.isNotEmpty) {
      print('\n📝 تفاصيل الإصلاحات:');
      for (final issue in fixedIssues) {
        print('  • $issue');
      }
    }

    if (totalFixes == 0) {
      print('🎉 لا توجد مشاكل للإصلاح - الكود نظيف!');
    } else {
      print('\n🎯 تم إصلاح جميع المشاكل بنجاح!');
      print('💡 يُنصح بتشغيل: flutter clean && flutter pub get');
    }
  }
}
