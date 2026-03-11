import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _filter = 'all'; // all, income, expense

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        final filtered = provider.monthlyTransactions.where((t) {
          if (_filter == 'income') return t.type == 'income';
          if (_filter == 'expense') return t.type == 'expense';
          return true;
        }).toList();

        final Map<String, List<TransactionModel>> grouped = {};
        for (final t in filtered) {
          final key = t.date.substring(0, 10);
          grouped.putIfAbsent(key, () => []).add(t);
        }
        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Riwayat', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(
                      DateFormat('MMM y', 'id_ID').format(DateTime(provider.selectedYear, provider.selectedMonth)),
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _FilterChip(label: 'Semua', isSelected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip(label: '🟢 Pemasukan', isSelected: _filter == 'income', onTap: () => setState(() => _filter = 'income'), color: const Color(0xFF00E676)),
                    const SizedBox(width: 8),
                    _FilterChip(label: '🔴 Pengeluaran', isSelected: _filter == 'expense', onTap: () => setState(() => _filter = 'expense'), color: const Color(0xFFFF5252)),
                  ],
                ),
              ),

              if (filtered.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Tidak ada transaksi', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, i) {
                      final date = sortedDates[i];
                      final dayTx = grouped[date]!;
                      final d = DateTime.parse(date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              DateFormat('EEEE, d MMMM', 'id_ID').format(d),
                              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: dayTx.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final t = entry.value;
                                final isLast = idx == dayTx.length - 1;
                                return _SwipeableTile(transaction: t, fmt: fmt, isLast: isLast);
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipeableTile extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat fmt;
  final bool isLast;

  const _SwipeableTile({required this.transaction, required this.fmt, required this.isLast});

  String _getIcon(String category) {
    const icons = {
      'Makan & Minum': '🍔', 'Transport': '🚗', 'Belanja': '🛍️',
      'Tagihan': '📱', 'Kesehatan': '💊', 'Hiburan': '🎮',
      'Pendidikan': '📚', 'Gaji': '💼', 'Freelance': '💻',
      'Bonus': '🎁', 'Investasi': '📈',
    };
    return icons[category] ?? '💰';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return Column(
      children: [
        Dismissible(
          key: Key(transaction.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(16))
                  : BorderRadius.zero,
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          confirmDismiss: (_) async {
            return await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                title: const Text('Hapus Transaksi?', style: TextStyle(color: Colors.white)),
                content: const Text('Transaksi ini akan dihapus permanen.', style: TextStyle(color: Colors.white60)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            context.read<TransactionProvider>().deleteTransaction(transaction.id!);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isIncome ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFFFF5252).withOpacity(0.1),
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
              style: TextStyle(
                color: isIncome ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                fontSize: 14, fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: transaction)),
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 72),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.15) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? c : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}