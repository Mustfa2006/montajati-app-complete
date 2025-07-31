import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/location_cache_service.dart';

/// 📊 صفحة تشخيص الكاش
/// 
/// تعرض معلومات مفصلة عن حالة التخزين المؤقت للمواقع
class CacheDiagnosticsPage extends StatefulWidget {
  const CacheDiagnosticsPage({super.key});

  @override
  State<CacheDiagnosticsPage> createState() => _CacheDiagnosticsPageState();
}

class _CacheDiagnosticsPageState extends State<CacheDiagnosticsPage> {
  Map<String, dynamic>? _cacheInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await LocationCacheService.getCacheInfo();
      setState(() {
        _cacheInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ خطأ في تحميل معلومات الكاش: $e');
    }
  }

  Future<void> _refreshCache() async {
    setState(() => _isLoading = true);
    try {
      await LocationCacheService.refreshCache();
      await _loadCacheInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث الكاش بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تحديث الكاش: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد مسح الكاش'),
        content: const Text('هل أنت متأكد من مسح جميع البيانات المخزنة؟ سيتم إعادة تحميلها من الخادم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await LocationCacheService.clearCache();
        await LocationCacheService.initialize();
        await _loadCacheInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم مسح الكاش وإعادة التهيئة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ خطأ في مسح الكاش: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'تشخيص الكاش',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFffd700)),
            onPressed: _isLoading ? null : _loadCacheInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFffd700)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isInitialized = _cacheInfo?['isInitialized'] ?? false;
    final isExpired = _cacheInfo?['isExpired'] ?? true;
    
    return Card(
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInitialized ? Icons.check_circle : Icons.error,
                  color: isInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'حالة الكاش',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('مُهيأ', isInitialized ? 'نعم' : 'لا', isInitialized),
            _buildStatusRow('منتهي الصلاحية', isExpired ? 'نعم' : 'لا', !isExpired),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل البيانات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('المحافظات في الذاكرة', '${_cacheInfo?['provincesInMemory'] ?? 0}'),
            _buildDetailRow('المدن في الذاكرة', '${_cacheInfo?['citiesInMemory'] ?? 0}'),
            _buildDetailRow('آخر تحديث', _formatDate(_cacheInfo?['lastUpdate'])),
            _buildDetailRow('الإصدار', _cacheInfo?['version'] ?? 'غير محدد'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإجراءات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshCache,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الكاش'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffd700),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearCache,
                    icon: const Icon(Icons.delete),
                    label: const Text('مسح الكاش'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              Icon(
                isGood ? Icons.check : Icons.close,
                size: 16,
                color: isGood ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isGood ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFffd700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }
}
