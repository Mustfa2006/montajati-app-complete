import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminReportsSection extends StatefulWidget {
  const AdminReportsSection({super.key});

  @override
  State<AdminReportsSection> createState() => _AdminReportsSectionState();
}

class _AdminReportsSectionState extends State<AdminReportsSection> {
  List<MonthlyProfit> monthlyProfits = [];
  List<TopProduct> topProducts = [];
  List<TopUser> topUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    // محاكاة تحميل البيانات
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      // بيانات الأرباح الشهرية (آخر 12 شهر)
      monthlyProfits = [
        MonthlyProfit('يناير', 1500000),
        MonthlyProfit('فبراير', 1800000),
        MonthlyProfit('مارس', 2200000),
        MonthlyProfit('أبريل', 1900000),
        MonthlyProfit('مايو', 2500000),
        MonthlyProfit('يونيو', 2800000),
        MonthlyProfit('يوليو', 3200000),
        MonthlyProfit('أغسطس', 2900000),
        MonthlyProfit('سبتمبر', 3500000),
        MonthlyProfit('أكتوبر', 3800000),
        MonthlyProfit('نوفمبر', 4200000),
        MonthlyProfit('ديسمبر', 4500000),
      ];

      // أكثر المنتجات مبيعاً
      topProducts = [
        TopProduct('هاتف ذكي Samsung', 'https://via.placeholder.com/50', 145, 2500000),
        TopProduct('ساعة ذكية Apple', 'https://via.placeholder.com/50', 89, 1800000),
        TopProduct('سماعات لاسلكية', 'https://via.placeholder.com/50', 234, 1200000),
        TopProduct('حقيبة يد نسائية', 'https://via.placeholder.com/50', 67, 950000),
        TopProduct('حذاء رياضي', 'https://via.placeholder.com/50', 123, 850000),
      ];

      // أكثر المستخدمين نشاطاً
      topUsers = [
        TopUser('أحمد محمد', 23, 1250000),
        TopUser('فاطمة علي', 18, 980000),
        TopUser('محمد حسن', 15, 750000),
        TopUser('زينب أحمد', 12, 650000),
        TopUser('علي حسين', 10, 520000),
      ];

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF17a2b8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartBar,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'التقارير والإحصائيات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFffd700)),
            )
          else
            Column(
              children: [
                // تقرير الأرباح الشهرية
                _buildMonthlyProfitsChart(),
                const SizedBox(height: 30),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أكثر المنتجات مبيعاً
                    Expanded(child: _buildTopProducts()),
                    const SizedBox(width: 20),
                    // أكثر المستخدمين نشاطاً
                    Expanded(child: _buildTopUsers()),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProfitsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.chartLine,
                color: Color(0xFF28a745),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'الأرباح الشهرية (آخر 12 شهر)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}M',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < monthlyProfits.length) {
                          return Text(
                            monthlyProfits[value.toInt()].month.substring(0, 3),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyProfits.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.profit.toDouble());
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF28a745), Color(0xFF06d6a0)],
                    ),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF28a745).withOpacity(0.3),
                          const Color(0xFF06d6a0).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.trophy,
                color: Color(0xFFffc107),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'أكثر المنتجات مبيعاً',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topProducts.map((product) => _buildProductItem(product)),
        ],
      ),
    );
  }

  Widget _buildProductItem(TopProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.salesCount} مبيعة',
                  style: const TextStyle(
                    color: Color(0xFF6c757d),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${product.totalProfit.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    color: Color(0xFF28a745),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.userTie,
                color: Color(0xFF007bff),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'أكثر المستخدمين نشاطاً',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topUsers.map((user) => _buildUserItem(user)),
        ],
      ),
    );
  }

  Widget _buildUserItem(TopUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF007bff),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.ordersCount} طلب',
                  style: const TextStyle(
                    color: Color(0xFF6c757d),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${user.totalProfit.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    color: Color(0xFF28a745),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// نماذج البيانات
class MonthlyProfit {
  final String month;
  final double profit;

  MonthlyProfit(this.month, this.profit);
}

class TopProduct {
  final String name;
  final String imageUrl;
  final int salesCount;
  final double totalProfit;

  TopProduct(this.name, this.imageUrl, this.salesCount, this.totalProfit);
}

class TopUser {
  final String name;
  final int ordersCount;
  final double totalProfit;

  TopUser(this.name, this.ordersCount, this.totalProfit);
}
