// قائمة الطلبات الذكية مع التحديث الفوري
// Smart Orders List with Real-time Updates

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_status_provider.dart';
import '../utils/order_status_helper.dart';
import '../services/admin_service.dart';
import '../pages/simple_order_details_page.dart';

class SmartOrdersList extends StatefulWidget {
  final String? statusFilter;
  final bool showStatusFilter;
  final Function(AdminOrder)? onOrderTap;

  const SmartOrdersList({
    super.key,
    this.statusFilter,
    this.showStatusFilter = true,
    this.onOrderTap,
  });

  @override
  State<SmartOrdersList> createState() => _SmartOrdersListState();
}

class _SmartOrdersListState extends State<SmartOrdersList> {
  @override
  void initState() {
    super.initState();
    // تهيئة المزود عند بدء التشغيل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderStatusProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderStatusProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // فلتر الحالات (اختياري)
            if (widget.showStatusFilter) _buildStatusFilter(provider),

            // قائمة الطلبات مع StreamBuilder
            Expanded(
              child: StreamBuilder<List<AdminOrder>>(
                stream: provider.filteredOrdersStream,
                builder: (context, snapshot) {
                  if (provider.isLoading && !snapshot.hasData) {
                    return _buildLoadingState();
                  }

                  if (provider.error != null && !snapshot.hasData) {
                    return _buildErrorState(provider.error!, provider);
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildOrdersList(orders);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusFilter(OrderStatusProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<Map<String, int>>(
        stream: provider.statusCountsStream,
        builder: (context, snapshot) {
          final counts = snapshot.data ?? {};

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'الكل',
                  null,
                  provider.selectedFilter == null,
                  counts.values.fold(0, (sum, count) => sum + count),
                  provider,
                ),
                const SizedBox(width: 8),
                ...OrderStatusHelper.getAvailableStatuses().map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      status,
                      status,
                      provider.selectedFilter == status,
                      counts[status] ?? 0,
                      provider,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? status,
    bool isSelected,
    int count,
    OrderStatusProvider provider,
  ) {
    final color = status != null
        ? OrderStatusHelper.getStatusColor(
            OrderStatusHelper.arabicToDatabase(status),
          )
        : const Color(0xFFffd700);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? color : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        provider.setStatusFilter(selected ? status : null);
      },
      backgroundColor: const Color(0xFF16213e),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFffd700)),
          SizedBox(height: 16),
          Text(
            'جاري تحميل الطلبات...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, OrderStatusProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'خطأ في تحميل الطلبات',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadOrders(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لم يتم العثور على أي طلبات تطابق الفلتر المحدد',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<AdminOrder> orders) {
    return RefreshIndicator(
      onRefresh: () => context.read<OrderStatusProvider>().loadOrders(),
      color: const Color(0xFFffd700),
      backgroundColor: const Color(0xFF16213e),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(AdminOrder order) {
    final statusColor = OrderStatusHelper.getStatusColor(order.status);
    final statusIcon = OrderStatusHelper.getStatusIcon(order.status);
    final statusText = OrderStatusHelper.getArabicStatus(order.status);

    // تشخيص مفصل
    debugPrint('🔍 [SmartOrdersList] عرض بطاقة الطلب: ${order.id}');
    debugPrint(
      '📋 [SmartOrdersList] حالة الطلب من قاعدة البيانات: "${order.status}"',
    );
    debugPrint('📋 [SmartOrdersList] النص المعروض: "$statusText"');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onOrderTap != null) {
            widget.onOrderTap!(order);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SimpleOrderDetailsPage(orderId: order.id),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header مع الحالة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // معلومات العميل
              Text(
                order.customerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.customerPhone,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // المبلغ والتاريخ
              Row(
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
