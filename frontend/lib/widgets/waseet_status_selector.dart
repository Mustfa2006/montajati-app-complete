// ===================================
// مكون اختيار حالات الوسيط
// Waseet Status Selector Widget
// ===================================

import 'package:flutter/material.dart';
import '../services/waseet_status_service.dart';

class WaseetStatusSelector extends StatefulWidget {
  final String? currentStatus;
  final Function(WaseetStatus) onStatusSelected;
  final bool showAllStatuses;

  const WaseetStatusSelector({
    super.key,
    this.currentStatus,
    required this.onStatusSelected,
    this.showAllStatuses = true,
  });

  @override
  State<WaseetStatusSelector> createState() => _WaseetStatusSelectorState();
}

class _WaseetStatusSelectorState extends State<WaseetStatusSelector> {
  List<WaseetStatus> statuses = [];
  Map<String, List<WaseetStatus>> categorizedStatuses = {};
  bool isLoading = true;
  String? error;
  WaseetStatus? selectedStatus;

  @override
  void initState() {
    super.initState();
    loadStatuses();
  }

  Future<void> loadStatuses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final loadedStatuses = await WaseetStatusService.getApprovedStatuses();
      final categorized = WaseetStatusService.getCategorizedStatuses();

      setState(() {
        statuses = loadedStatuses;
        categorizedStatuses = categorized;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text('خطأ في تحميل الحالات', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: loadStatuses,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return widget.showAllStatuses ? buildCategorizedView() : buildSimpleView();
  }

  Widget buildCategorizedView() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر حالة الطلب الجديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...categorizedStatuses.entries.map((entry) =>
              buildCategorySection(entry.key, entry.value)
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSimpleView() {
    // عرض الحالات الأساسية فقط للتحديث السريع
    final basicStatuses = statuses.where((status) => 
      [4, 3, 31, 25].contains(status.id) // تم التوصيل، قيد التوصيل، ملغي، لا يرد
    ).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'تحديث حالة الطلب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...basicStatuses.map((status) => buildStatusTile(status)),
      ],
    );
  }

  Widget buildCategorySection(String categoryName, List<WaseetStatus> categoryStatuses) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Text(
          getCategoryDisplayName(categoryName),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${categoryStatuses.length} حالة'),
        leading: Icon(
          getCategoryIcon(categoryName),
          color: getCategoryColor(categoryName),
        ),
        children: categoryStatuses.map((status) => buildStatusTile(status)).toList(),
      ),
    );
  }

  Widget buildStatusTile(WaseetStatus status) {
    final isSelected = selectedStatus?.id == status.id;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: getStatusColor(status.appStatus),
        child: Text(
          status.id.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        status.text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        'حالة التطبيق: ${getAppStatusDisplayName(status.appStatus)}',
        style: TextStyle(
          color: getStatusColor(status.appStatus),
          fontSize: 12,
        ),
      ),
      trailing: isSelected 
        ? const Icon(Icons.check_circle, color: Colors.green)
        : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
        widget.onStatusSelected(status);
      },
    );
  }

  String getCategoryDisplayName(String category) {
    const categoryNames = {
      'delivered': '🚚 تم التوصيل',
      'modified': '🔄 تعديلات',
      'contact_issue': '📞 مشاكل التواصل',
      'in_delivery': '🚛 قيد التوصيل',
      'postponed': '⏰ مؤجل',
      'cancelled': '❌ ملغي',
      'address_issue': '📍 مشاكل العنوان',
    };
    return categoryNames[category] ?? category;
  }

  IconData getCategoryIcon(String category) {
    const categoryIcons = {
      'delivered': Icons.check_circle,
      'modified': Icons.edit,
      'contact_issue': Icons.phone_disabled,
      'in_delivery': Icons.local_shipping,
      'postponed': Icons.schedule,
      'cancelled': Icons.cancel,
      'address_issue': Icons.location_off,
    };
    return categoryIcons[category] ?? Icons.category;
  }

  Color getCategoryColor(String category) {
    const categoryColors = {
      'delivered': Colors.green,
      'modified': Colors.blue,
      'contact_issue': Colors.orange,
      'in_delivery': Colors.purple,
      'postponed': Colors.amber,
      'cancelled': Colors.red,
      'address_issue': Colors.brown,
    };
    return categoryColors[category] ?? Colors.grey;
  }

  Color getStatusColor(String appStatus) {
    const statusColors = {
      'delivered': Colors.green,
      'in_delivery': Colors.blue,
      'cancelled': Colors.red,
      'active': Colors.orange,
    };
    return statusColors[appStatus] ?? Colors.grey;
  }

  String getAppStatusDisplayName(String appStatus) {
    const statusNames = {
      'delivered': 'تم التوصيل',
      'in_delivery': 'قيد التوصيل',
      'cancelled': 'ملغي',
      'active': 'نشط',
    };
    return statusNames[appStatus] ?? appStatus;
  }
}

// دالة مساعدة لعرض حوار اختيار الحالة
Future<WaseetStatus?> showWaseetStatusDialog(
  BuildContext context, {
  String? currentStatus,
  bool showAllStatuses = true,
}) async {
  WaseetStatus? selectedStatus;

  await showDialog<WaseetStatus>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تحديث حالة الطلب'),
      content: WaseetStatusSelector(
        currentStatus: currentStatus,
        showAllStatuses: showAllStatuses,
        onStatusSelected: (status) {
          selectedStatus = status;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: selectedStatus != null
            ? () => Navigator.pop(context, selectedStatus)
            : null,
          child: const Text('تحديث'),
        ),
      ],
    ),
  );

  return selectedStatus;
}
