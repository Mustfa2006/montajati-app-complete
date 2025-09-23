import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_app_bar.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // بيانات التقارير
  Map<String, dynamic> _financialData = {};
  Map<String, dynamic> _ordersData = {};
  Map<String, dynamic> _withdrawalsData = {};
  List<Map<String, dynamic>> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);

    try {
      final userId = '07503597589';

      // تحميل البيانات المالية
      await _loadFinancialData(userId);

      // تحميل بيانات الطلبات
      await _loadOrdersData(userId);

      // تحميل بيانات السحوبات
      await _loadWithdrawalsData(userId);

      // تحميل الإحصائيات اليومية
      await _loadDailyStats(userId);
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات التقارير: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFinancialData(String userId) async {
    try {
      // بيانات مؤقتة للعرض
      setState(() {
        _financialData = {
          'total_profits': 150000.0,
          'expected_profits': 75000.0,
          'total_withdrawals': 50000.0,
          'pending_withdrawals': 25000.0,
          'available_balance': 100000.0,
        };
      });
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات المالية: $e');
    }
  }

  Future<void> _loadOrdersData(String userId) async {
    try {
      // هنا يجب إضافة دالة في UnifiedOrdersService للحصول على إحصائيات الطلبات
      setState(() {
        _ordersData = {
          'total_orders': 0,
          'active_orders': 0,
          'completed_orders': 0,
          'cancelled_orders': 0,
          'total_revenue': 0.0,
        };
      });
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الطلبات: $e');
    }
  }

  Future<void> _loadWithdrawalsData(String userId) async {
    try {
      // بيانات مؤقتة للعرض
      setState(() {
        _withdrawalsData = {
          'total_withdrawn': 50000.0,
          'pending_amount': 25000.0,
          'completed_count': 15,
          'pending_count': 3,
          'total_requests': 18,
        };
      });
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات السحوبات: $e');
    }
  }

  Future<void> _loadDailyStats(String userId) async {
    try {
      // إنشاء إحصائيات يومية وهمية للعرض
      List<Map<String, dynamic>> stats = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        stats.add({'date': date, 'profits': (i * 1000 + 500).toDouble(), 'orders': i + 2, 'withdrawals': i * 500.0});
      }
      setState(() => _dailyStats = stats);
    } catch (e) {
      debugPrint('خطأ في تحميل الإحصائيات اليومية: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'التقارير والإحصائيات'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildFinancialSummary(),
                    const SizedBox(height: 20),
                    _buildOrdersStatistics(),
                    const SizedBox(height: 20),
                    _buildWithdrawalsStatistics(),
                    const SizedBox(height: 20),
                    _buildProfitsChart(),
                    const SizedBox(height: 20),
                    _buildDailyStatsTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('فترة التقرير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPeriod,
                    decoration: const InputDecoration(labelText: 'الفترة الزمنية', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem<String>(value: 'week', child: Text('أسبوع')),
                      DropdownMenuItem<String>(value: 'month', child: Text('شهر')),
                      DropdownMenuItem<String>(value: 'quarter', child: Text('ربع سنة')),
                      DropdownMenuItem<String>(value: 'year', child: Text('سنة')),
                      DropdownMenuItem<String>(value: 'custom', child: Text('فترة مخصصة')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _updateDateRange();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadReportsData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                ),
              ],
            ),
            if (_selectedPeriod == 'custom') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'من تاريخ', border: OutlineInputBorder()),
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_startDate)),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'إلى تاريخ', border: OutlineInputBorder()),
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_endDate)),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الملخص المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'الأرباح المحققة',
                  '${_financialData['total_profits']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                _buildStatCard(
                  'الأرباح المتوقعة',
                  '${_financialData['expected_profits']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildStatCard(
                  'إجمالي السحوبات',
                  '${_financialData['total_withdrawals']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.money_off,
                  Colors.orange,
                ),
                _buildStatCard(
                  'الرصيد المتاح',
                  '${_financialData['available_balance']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.account_balance,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إحصائيات الطلبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildStatCard(
                  'إجمالي الطلبات',
                  '${_ordersData['total_orders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard('طلبات نشطة', '${_ordersData['active_orders'] ?? 0}', Icons.pending, Colors.orange),
                _buildStatCard(
                  'طلبات مكتملة',
                  '${_ordersData['completed_orders'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalsStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إحصائيات السحوبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'إجمالي المسحوب',
                  '${_withdrawalsData['total_withdrawn']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.money,
                  Colors.green,
                ),
                _buildStatCard(
                  'قيد المراجعة',
                  '${_withdrawalsData['pending_amount']?.toStringAsFixed(0) ?? '0'} د.ع',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                _buildStatCard(
                  'طلبات مكتملة',
                  '${_withdrawalsData['completed_count'] ?? 0}',
                  Icons.done_all,
                  Colors.blue,
                ),
                _buildStatCard(
                  'طلبات معلقة',
                  '${_withdrawalsData['pending_count'] ?? 0}',
                  Icons.pending_actions,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مخطط الأرباح اليومية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _dailyStats.length) {
                            final date = _dailyStats[value.toInt()]['date'] as DateTime;
                            return Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyStats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['profits'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الإحصائيات اليومية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('الأرباح')),
                  DataColumn(label: Text('الطلبات')),
                  DataColumn(label: Text('السحوبات')),
                ],
                rows: _dailyStats.map((stat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('yyyy-MM-dd').format(stat['date']))),
                      DataCell(Text('${stat['profits'].toStringAsFixed(0)} د.ع')),
                      DataCell(Text('${stat['orders']}')),
                      DataCell(Text('${stat['withdrawals'].toStringAsFixed(0)} د.ع')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month - 1, now.day);
        _endDate = now;
        break;
      case 'quarter':
        _startDate = DateTime(now.year, now.month - 3, now.day);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year - 1, now.month, now.day);
        _endDate = now;
        break;
    }
    if (_selectedPeriod != 'custom') {
      _loadReportsData();
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
      _loadReportsData();
    }
  }
}
