// إحصائيات حالات الطلبات - نسخة مبسطة
// Order Status Statistics - Simplified Version

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_status_provider.dart';
import '../utils/order_status_helper.dart';

class OrderStatusStats extends StatelessWidget {
  final bool showTitle;
  final Function(String)? onStatusTap;

  const OrderStatusStats({super.key, this.showTitle = true, this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderStatusProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                const Text(
                  'إحصائيات الطلبات',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // إحصائيات مع التحديث الفوري
              StreamBuilder<Map<String, int>>(
                stream: provider.statusCountsStream,
                builder: (context, snapshot) {
                  if (provider.isLoading && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFffd700),
                      ),
                    );
                  }

                  final counts = snapshot.data ?? {};
                  final totalOrders = counts.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );

                  if (totalOrders == 0) {
                    return const Center(
                      child: Text(
                        'لا توجد طلبات',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // إجمالي الطلبات
                      _buildTotalCard(totalOrders),
                      const SizedBox(height: 12),

                      // إحصائيات كل حالة
                      ...OrderStatusHelper.getAvailableStatuses().map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildStatusCard(
                            status,
                            counts[status] ?? 0,
                            totalOrders,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalCard(int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFffd700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFffd700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFFffd700), size: 20),
          const SizedBox(width: 8),
          const Text(
            'إجمالي الطلبات:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$total',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, int count, int total) {
    final databaseStatus = OrderStatusHelper.arabicToDatabase(status);
    final color = OrderStatusHelper.getStatusColor(databaseStatus);
    final icon = OrderStatusHelper.getStatusIcon(databaseStatus);
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return GestureDetector(
      onTap: onStatusTap != null ? () => onStatusTap!(status) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// نسخة مبسطة للاستخدام في الأماكن الضيقة
class CompactOrderStatusStats extends StatelessWidget {
  const CompactOrderStatusStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderStatusProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<Map<String, int>>(
          stream: provider.statusCountsStream,
          builder: (context, snapshot) {
            final counts = snapshot.data ?? {};

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: OrderStatusHelper.getAvailableStatuses().map((status) {
                final databaseStatus = OrderStatusHelper.arabicToDatabase(
                  status,
                );
                final color = OrderStatusHelper.getStatusColor(databaseStatus);
                final count = counts[status] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
