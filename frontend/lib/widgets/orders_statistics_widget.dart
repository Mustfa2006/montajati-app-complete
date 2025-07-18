import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class OrdersStatisticsWidget extends StatefulWidget {
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> chartData;
  final Function(String) onPeriodChanged;

  const OrdersStatisticsWidget({
    super.key,
    required this.statistics,
    required this.chartData,
    required this.onPeriodChanged,
  });

  @override
  State<OrdersStatisticsWidget> createState() => _OrdersStatisticsWidgetState();
}

class _OrdersStatisticsWidgetState extends State<OrdersStatisticsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _selectedPeriod = 'today';
  String _selectedChart = 'orders'; // orders, revenue, profit

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatisticsCards(),
              const SizedBox(height: 20),
              _buildChartSection(),
              const SizedBox(height: 20),
              _buildDetailedStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics,
            color: Color(0xFFffd700),
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إحصائيات الطلبات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'تحليل شامل لأداء المبيعات والطلبات',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'value': 'today', 'label': 'اليوم'},
      {'value': 'week', 'label': 'الأسبوع'},
      {'value': 'month', 'label': 'الشهر'},
      {'value': 'year', 'label': 'السنة'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period['value']!);
              widget.onPeriodChanged(period['value']!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFffd700)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period['label']!,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1a1a2e)
                      : const Color(0xFFffd700),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final stats = [
      {
        'title': 'إجمالي الطلبات',
        'value': widget.statistics['totalOrders']?.toString() ?? '0',
        'icon': Icons.shopping_cart,
        'color': const Color(0xFF2196F3),
        'change': '+12%',
        'isPositive': true,
      },
      {
        'title': 'إجمالي المبيعات',
        'value':
            '${(widget.statistics['totalAmount'] ?? 0).toStringAsFixed(0)} د.ع',
        'icon': Icons.attach_money,
        'color': const Color(0xFF4CAF50),
        'change': '+8%',
        'isPositive': true,
      },
      {
        'title': 'إجمالي الأرباح',
        'value':
            '${(widget.statistics['totalProfit'] ?? 0).toStringAsFixed(0)} د.ع',
        'icon': Icons.trending_up,
        'color': const Color(0xFFFF9800),
        'change': '+15%',
        'isPositive': true,
      },
      {
        'title': 'متوسط الطلب',
        'value':
            '${(widget.statistics['averageAmount'] ?? 0).toStringAsFixed(0)} د.ع',
        'icon': Icons.analytics,
        'color': const Color(0xFF9C27B0),
        'change': '-3%',
        'isPositive': false,
      },
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: _buildStatCard(stat),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (stat['color'] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stat['isPositive']
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stat['change'],
                  style: TextStyle(
                    color: stat['isPositive'] ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stat['value'],
            style: TextStyle(
              color: stat['color'] as Color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['title'],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تحليل الأداء',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildChartTypeSelector(),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    final chartTypes = [
      {'value': 'orders', 'label': 'الطلبات', 'icon': Icons.shopping_cart},
      {'value': 'revenue', 'label': 'المبيعات', 'icon': Icons.attach_money},
      {'value': 'profit', 'label': 'الأرباح', 'icon': Icons.trending_up},
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: chartTypes.map((type) {
        final isSelected = _selectedChart == type['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedChart = type['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFffd700).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type['icon'] as IconData,
                  color: isSelected ? const Color(0xFFffd700) : Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  type['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFffd700)
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    switch (_selectedChart) {
      case 'revenue':
        return _buildRevenueChart();
      case 'profit':
        return _buildProfitChart();
      default:
        return _buildOrdersChart();
    }
  }

  Widget _buildOrdersChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                );
                Widget text;
                switch (value.toInt()) {
                  case 0:
                    text = const Text('السبت', style: style);
                    break;
                  case 1:
                    text = const Text('الأحد', style: style);
                    break;
                  case 2:
                    text = const Text('الاثنين', style: style);
                    break;
                  case 3:
                    text = const Text('الثلاثاء', style: style);
                    break;
                  case 4:
                    text = const Text('الأربعاء', style: style);
                    break;
                  case 5:
                    text = const Text('الخميس', style: style);
                    break;
                  case 6:
                    text = const Text('الجمعة', style: style);
                    break;
                  default:
                    text = const Text('', style: style);
                    break;
                }
                return text;
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 1),
              FlSpot(2, 4),
              FlSpot(3, 2),
              FlSpot(4, 5),
              FlSpot(5, 3),
              FlSpot(6, 4),
            ],
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2196F3),
                const Color(0xFF2196F3).withValues(alpha: 0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF2196F3),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2196F3).withValues(alpha: 0.3),
                  const Color(0xFF2196F3).withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20000,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF16213e),
            tooltipHorizontalAlignment: FLHorizontalAlignment.center,
            tooltipMargin: -10,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} د.ع',
                const TextStyle(
                  color: Color(0xFFffd700),
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                );
                Widget text;
                switch (value.toInt()) {
                  case 0:
                    text = const Text('السبت', style: style);
                    break;
                  case 1:
                    text = const Text('الأحد', style: style);
                    break;
                  case 2:
                    text = const Text('الاثنين', style: style);
                    break;
                  case 3:
                    text = const Text('الثلاثاء', style: style);
                    break;
                  case 4:
                    text = const Text('الأربعاء', style: style);
                    break;
                  case 5:
                    text = const Text('الخميس', style: style);
                    break;
                  case 6:
                    text = const Text('الجمعة', style: style);
                    break;
                  default:
                    text = const Text('', style: style);
                    break;
                }
                return text;
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 5000,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: 8000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: 10000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(toY: 14000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(toY: 15000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [
              BarChartRodData(toY: 13000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [
              BarChartRodData(toY: 10000, color: const Color(0xFF4CAF50)),
            ],
          ),
          BarChartGroupData(
            x: 6,
            barRods: [
              BarChartRodData(toY: 16000, color: const Color(0xFF4CAF50)),
            ],
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfitChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: const Color(0xFFFF9800),
            value: 40,
            title: '40%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: const Color(0xFF4CAF50),
            value: 30,
            title: '30%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: const Color(0xFF2196F3),
            value: 20,
            title: '20%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: const Color(0xFFF44336),
            value: 10,
            title: '10%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final statusCounts =
        widget.statistics['statusCounts'] as Map<String, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفصيل حالات الطلبات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (statusCounts.isNotEmpty)
            ...statusCounts.entries.map(
              (entry) => _buildStatusRow(entry.key, entry.value),
            )
          else
            const Text(
              'لا توجد بيانات متاحة',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status, int count) {
    final statusColors = {
      'قيد الانتظار': const Color(0xFFFF9800),
      'مؤكد': const Color(0xFF2196F3),
      'قيد التحضير': const Color(0xFF9C27B0),
      'تم الشحن': const Color(0xFF00BCD4),
      'تم التسليم': const Color(0xFF4CAF50),
      'ملغي': const Color(0xFFF44336),
    };

    final color = statusColors[status] ?? const Color(0xFF9E9E9E);
    final total = widget.statistics['totalOrders'] as int? ?? 1;
    final percentage = (count / total * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '$count طلب',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
