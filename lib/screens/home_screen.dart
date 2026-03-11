import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'transaction_screen.dart';
import 'report_screen.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const TransactionScreen(),
    const ReportScreen(),
    const SavingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          if (context.mounted) {
            context.read<TransactionProvider>().loadAll();
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1A1A2E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Beranda', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.list_alt_rounded, label: 'Transaksi', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              const SizedBox(width: 48),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Laporan', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.savings_rounded, label: 'Tabungan', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== DASHBOARD =====================

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final now = DateTime.now();
        final months = List.generate(12, (i) => DateTime(now.year, i + 1));

        final Map<String, List<TransactionModel>> grouped = {};
        for (final t in provider.monthlyTransactions) {
          final key = t.date.substring(0, 10);
          grouped.putIfAbsent(key, () => []).add(t);
        }
        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Monitor Keuangan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(now),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Icon(Icons.settings_rounded, color: Colors.white54, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pilih bulan
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: months.length,
                    itemBuilder: (context, i) {
                      final m = months[i];
                      final isSelected = m.month == provider.selectedMonth && m.year == provider.selectedYear;
                      return GestureDetector(
                        onTap: () => provider.setMonth(m.month, m.year),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: Text(DateFormat('MMM', 'id_ID').format(m),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 13,
                            )),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Balance card — KUMULATIF
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: provider.totalBalance < 0
                            ? [const Color(0xFFB71C1C), const Color(0xFF7B1FA2)]
                            : [const Color(0xFF6C63FF), const Color(0xFF9B59B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0x666C63FF), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Saldo Kamu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        (provider.totalBalance < 0 ? '-' : '') + fmt.format(provider.totalBalance.abs()),
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      const Text('Akumulasi semua pemasukan − pengeluaran', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 20),
                      // Ringkasan bulan dipilih
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            DateFormat('MMMM y', 'id_ID').format(DateTime(provider.selectedYear, provider.selectedMonth)),
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _SummaryItem(label: 'Pemasukan', amount: fmt.format(provider.totalIncome), icon: Icons.arrow_downward_rounded, color: const Color(0xFF00E676))),
                            const SizedBox(width: 12),
                            Expanded(child: _SummaryItem(label: 'Pengeluaran', amount: fmt.format(provider.totalExpense), icon: Icons.arrow_upward_rounded, color: const Color(0xFFFF5252))),
                          ]),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Selisih bulan ini', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text(
                              (provider.monthlyBalance < 0 ? '-' : '+') + fmt.format(provider.monthlyBalance.abs()),
                              style: TextStyle(
                                color: provider.monthlyBalance < 0 ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),

              // Transaksi terbaru
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaksi Terbaru', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${provider.monthlyTransactions.length} transaksi', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              if (provider.monthlyTransactions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(children: [
                      Text('😊', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada transaksi bulan ini', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Tap tombol + untuk mulai', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ]),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _DayGroup(date: sortedDates[i], transactions: grouped[sortedDates[i]]!),
                    childCount: sortedDates.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

// ===================== WIDGETS =====================

class _SummaryItem extends StatelessWidget {
  final String label, amount;
  final IconData icon;
  final Color color;
  const _SummaryItem({required this.label, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 12),
      ),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }
}

class _DayGroup extends StatelessWidget {
  final String date;
  final List<TransactionModel> transactions;
  const _DayGroup({required this.date, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final d = DateTime.parse(date);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(DateFormat('EEEE, d MMMM', 'id_ID').format(d),
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: transactions.asMap().entries.map((entry) =>
              _TransactionTile(transaction: entry.value, fmt: fmt, isLast: entry.key == transactions.length - 1)
            ).toList(),
          ),
        ),
      ]),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat fmt;
  final bool isLast;
  const _TransactionTile({required this.transaction, required this.fmt, required this.isLast});

  String _getIcon(String category) {
    const icons = {
      'Makan & Minum': '🍔', 'Transport': '🚗', 'Belanja': '🛍️',
      'Tagihan': '📱', 'Kesehatan': '💊', 'Hiburan': '🎮',
      'Pendidikan': '📚', 'Gaji': '💼', 'Freelance': '💻',
      'Bonus': '🎁', 'Investasi': '📈', 'Cash': '💵',
      'Rokok': '🚬', 'Lainnya': '💰',
    };
    return icons[category] ?? '💰';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isIncome ? const Color(0x1A00E676) : const Color(0x1AFF5252),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(_getIcon(transaction.category), style: const TextStyle(fontSize: 20)),
        ),
        title: Text(transaction.category, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: transaction.note != null && transaction.note!.isNotEmpty
            ? Text(transaction.note!, style: const TextStyle(color: Colors.white38, fontSize: 12))
            : null,
        trailing: Text(
          '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
          style: TextStyle(color: isIncome ? const Color(0xFF00E676) : const Color(0xFFFF5252), fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      if (!isLast) const Divider(height: 1, color: Color(0x0DFFFFFF), indent: 72),
    ]);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.white38, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.white38,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}