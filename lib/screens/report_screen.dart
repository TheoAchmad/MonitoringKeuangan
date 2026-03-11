import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Laporan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.white38,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [Tab(text: 'Bulanan'), Tab(text: 'Tahunan')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_MonthlyTab(), _YearlyTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== MONTHLY =====================

class _MonthlyTab extends StatelessWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final expCat = provider.expenseByCategory;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM y', 'id_ID').format(DateTime(provider.selectedYear, provider.selectedMonth)),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Ringkasan
              Row(
                children: [
                  _SummaryCard(label: 'Pemasukan', amount: fmt.format(provider.totalIncome), color: const Color(0xFF00E676)),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Pengeluaran', amount: fmt.format(provider.totalExpense), color: const Color(0xFFFF5252)),
                ],
              ),

              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Saldo Bersih',
                amount: fmt.format(provider.monthlyBalance),
                color: provider.monthlyBalance >= 0 ? const Color(0xFF6C63FF) : const Color(0xFFFF5252),
                fullWidth: true,
              ),

              if (expCat.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Pengeluaran per Kategori', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Pie chart
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _buildSections(expCat),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Legend
                ...expCat.entries.map((e) {
                  final idx = expCat.keys.toList().indexOf(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: _chartColors[idx % _chartColors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                        Text(fmt.format(e.value), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Text('📊', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada data pengeluaran', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    return data.entries.map((e) {
      final idx = data.keys.toList().indexOf(e.key);
      final pct = total > 0 ? (e.value / total * 100) : 0;
      return PieChartSectionData(
        color: _chartColors[idx % _chartColors.length],
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      );
    }).toList();
  }
}

// ===================== YEARLY =====================

class _YearlyTab extends StatefulWidget {
  const _YearlyTab();

  @override
  State<_YearlyTab> createState() => _YearlyTabState();
}

class _YearlyTabState extends State<_YearlyTab> {
  int _year = DateTime.now().year;
  Map<int, Map<String, double>>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await context.read<TransactionProvider>().getYearlyData(_year);
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final shortFmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

    if (_data == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    }

    final totalIncome = _data!.values.fold(0.0, (s, m) => s + (m['income'] ?? 0));
    final totalExpense = _data!.values.fold(0.0, (s, m) => s + (m['expense'] ?? 0));

    // Cari bulan terboros & terhemat
    int borosMonth = 1;
    int hematMonth = 1;
    double maxExp = 0;
    double minExp = double.infinity;
    for (int m = 1; m <= 12; m++) {
      final exp = _data![m]!['expense']!;
      if (exp > maxExp) { maxExp = exp; borosMonth = m; }
      if (exp < minExp && exp > 0) { minExp = exp; hematMonth = m; }
    }

    final maxVal = _data!.values.fold(0.0, (s, m) => [s, m['income']!, m['expense']!].reduce((a, b) => a > b ? a : b));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pilih tahun
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Laporan Tahunan', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white54),
                    onPressed: () { setState(() { _year--; _data = null; }); _load(); },
                  ),
                  Text('$_year', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white54),
                    onPressed: () { setState(() { _year++; _data = null; }); _load(); },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total
          Row(
            children: [
              _SummaryCard(label: 'Total Pemasukan', amount: fmt.format(totalIncome), color: const Color(0xFF00E676)),
              const SizedBox(width: 12),
              _SummaryCard(label: 'Total Pengeluaran', amount: fmt.format(totalExpense), color: const Color(0xFFFF5252)),
            ],
          ),

          const SizedBox(height: 28),
          const Text('Grafik 12 Bulan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Legenda
          Row(
            children: [
              _LegendDot(color: const Color(0xFF00E676), label: 'Pemasukan'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFFF5252), label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.2 : 1000000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY;
                      return BarTooltipItem(
                        shortFmt.format(val),
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx > 11) return const SizedBox();
                        return Text(months[idx], style: const TextStyle(color: Colors.white38, fontSize: 10));
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  final m = i + 1;
                  final inc = _data![m]!['income']!;
                  final exp = _data![m]!['expense']!;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: inc, color: const Color(0xFF00E676), width: 8, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: exp, color: const Color(0xFFFF5252), width: 8, borderRadius: BorderRadius.circular(4)),
                    ],
                    barsSpace: 3,
                  );
                }),
              ),
            ),
          ),

          if (maxExp > 0) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: '🔥',
                    label: 'Bulan Terboros',
                    value: months[borosMonth - 1],
                    sub: fmt.format(maxExp),
                    color: const Color(0xFFFF5252),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: '💚',
                    label: 'Bulan Terhemat',
                    value: months[hematMonth - 1],
                    sub: fmt.format(minExp == double.infinity ? 0 : minExp),
                    color: const Color(0xFF00E676),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===================== WIDGETS =====================

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool fullWidth;

  const _SummaryCard({required this.label, required this.amount, required this.color, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: child) : Expanded(child: child);
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _InfoCard({required this.icon, required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $label', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

const _chartColors = [
  Color(0xFF6C63FF), Color(0xFFFF5252), Color(0xFF00E676),
  Color(0xFFFFD740), Color(0xFF40C4FF), Color(0xFFFF6D00),
  Color(0xFFE040FB), Color(0xFF69F0AE),
];