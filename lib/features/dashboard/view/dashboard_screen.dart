import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:cellaris/core/theme/app_theme.dart';
import '../controller/dashboard_kpi_provider.dart';

/// Unified Dashboard - Minimalist Design (merged with Analytics)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardKPIProvider);
    final today = ref.watch(todayFormattedProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: kpisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (kpis) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, ref, today),
              const SizedBox(height: 24),

              // Primary Stats Row
              Row(children: [
                _StatCard('Revenue', 'Rs. ${f.format(kpis.todaySales)}', 'Today', Colors.green),
                const SizedBox(width: 12),
                _StatCard('Profit', 'Rs. ${f.format(kpis.todayProfit)}', 'Gross', Colors.teal),
                const SizedBox(width: 12),
                _StatCard('Orders', '${kpis.pendingOrders}', 'Pending', Colors.orange),
                const SizedBox(width: 12),
                _StatCard('Repairs', '${kpis.activeRepairs}', 'Active', Colors.blue),
              ]),
              const SizedBox(height: 12),

              // Financial Stats Row
              Row(children: [
                _StatCard('Cash', 'Rs. ${f.format(kpis.inHandBalance)}', 'In-hand', Colors.indigo),
                const SizedBox(width: 12),
                _StatCard('Receivables', 'Rs. ${f.format(kpis.receivables)}', 'Due', Colors.amber),
                const SizedBox(width: 12),
                _StatCard('Payables', 'Rs. ${f.format(kpis.payables)}', 'Owed', Colors.red),
                const SizedBox(width: 12),
                _StatCard('Stock', 'Rs. ${f.format(kpis.stockValue)}', '${kpis.lowStockCount} low', kpis.outOfStockCount > 0 ? Colors.red : Colors.cyan),
              ]),
              const SizedBox(height: 24),

              // Main Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart
                  Expanded(
                    flex: 2,
                    child: _buildChartCard(kpis.chartData, f),
                  ),
                  const SizedBox(width: 16),
                  // Right Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildMonthSummary(kpis.monthSales, kpis.monthProfit, f),
                        const SizedBox(height: 16),
                        _buildRecentSales(kpis.recentSales, f),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String today) {
    final actions = [
      ('Sale', '/pos', LucideIcons.plus, AppTheme.primaryColor),
      ('Purchase', '/purchases', LucideIcons.packagePlus, Colors.blue),
      ('Inventory', '/inventory', LucideIcons.box, Colors.teal),
      ('Customers', '/customers', LucideIcons.users, Colors.purple),
    ];

    return Row(
      children: [
        // Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(today, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        const SizedBox(width: 32),

        // Quick Action Buttons
        ...actions.map((a) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => context.go(a.$2),
            icon: Icon(a.$3, size: 14),
            label: Text(a.$1, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: a.$4,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        )),

        const Spacer(),

        // Refresh
        IconButton(
          icon: Icon(LucideIcons.refreshCw, size: 16, color: Colors.grey[500]),
          onPressed: () => ref.read(dashboardKPIProvider.notifier).refresh(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildChartCard(List chartData, NumberFormat f) {
    // Aggregate last 7 days from chartData
    final now = DateTime.now();
    final Map<int, double> dailyTotals = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      dailyTotals[day.weekday] = 0;
    }
    
    for (final inv in chartData) {
      final dayDiff = now.difference(inv.date).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        final weekday = inv.date.weekday;
        dailyTotals[weekday] = (dailyTotals[weekday] ?? 0) + inv.summary.netValue;
      }
    }

    final spots = <FlSpot>[];
    final days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 1; i <= 7; i++) {
      spots.add(FlSpot(i.toDouble(), (dailyTotals[i] ?? 0) / 1000));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue (7 Days)', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('in thousands', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(days[v.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}k', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryColor, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummary(double sales, double profit, NumberFormat f) {
    final month = DateFormat('MMMM').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(month, style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Sales', 'Rs. ${f.format(sales)}', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('Profit', 'Rs. ${f.format(profit)}', Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('New Sale', '/pos'),
      ('Purchase', '/purchases'),
      ('Inventory', '/inventory'),
      ('Customers', '/customers'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((a) => InkWell(
              onTap: () => context.go(a.$2),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(a.$1, style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(List recentSales, NumberFormat f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Sales', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (recentSales.isEmpty)
            Text('No recent sales', style: TextStyle(color: Colors.grey[600], fontSize: 11))
          else
            ...recentSales.take(5).map((inv) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(inv.partyName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  Text('Rs. ${f.format(inv.summary.netValue)}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard(this.title, this.value, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
