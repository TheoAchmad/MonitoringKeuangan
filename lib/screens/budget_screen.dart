import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final expCategories = provider.categories.where((c) => c.type == 'expense').toList();
        final budgetMap = {for (var b in provider.budgets) b['category'] as String: b};

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Anggaran', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM y', 'id_ID').format(DateTime(provider.selectedYear, provider.selectedMonth)),
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Ringkasan anggaran
                      if (provider.budgets.isNotEmpty) ...[
                        _BudgetSummaryCard(provider: provider, fmt: fmt),
                        const SizedBox(height: 20),
                      ],

                      const Text('Atur Anggaran per Kategori',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final cat = expCategories[i];
                    final budget = budgetMap[cat.name];
                    final spent = provider.getSpentForCategory(cat.name);
                    final limit = budget != null ? (budget['limit_amount'] as num).toDouble() : 0.0;
                    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                    final isOver = spent > limit && limit > 0;
                    final isWarn = pct >= 0.8 && !isOver;

                    Color barColor = const Color(0xFF6C63FF);
                    if (isOver) barColor = const Color(0xFFFF5252);
                    else if (isWarn) barColor = const Color(0xFFFFD740);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOver
                                ? const Color(0xFFFF5252).withValues(alpha: 0.5)
                                : isWarn
                                    ? const Color(0xFFFFD740).withValues(alpha: 0.5)
                                    : Colors.white10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(cat.icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(cat.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                                if (isOver)
                                  const Text('⚠️ Melebihi!', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w700))
                                else if (isWarn)
                                  const Text('⚠️ Hampir habis', style: TextStyle(color: Color(0xFFFFD740), fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showSetBudget(context, provider, cat.name, limit),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      budget != null ? 'Edit' : '+ Atur',
                                      style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                if (budget != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => provider.deleteBudget(budget['id'] as int),
                                    child: const Icon(Icons.close, color: Colors.white24, size: 16),
                                  ),
                                ],
                              ],
                            ),
                            if (budget != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(fmt.format(spent),
                                      style: TextStyle(
                                          color: isOver ? const Color(0xFFFF5252) : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text('dari ${fmt.format(limit)}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                  minHeight: 6,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              Text('Belum ada anggaran · Pengeluaran: ${fmt.format(spent)}',
                                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: expCategories.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  void _showSetBudget(BuildContext context, TransactionProvider provider, String category, double currentLimit) {
    final ctrl = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur Anggaran · $category',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(ctrl.text) ?? 0;
                  if (amount > 0) {
                    await provider.setBudget(category, amount);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Simpan Anggaran',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final TransactionProvider provider;
  final NumberFormat fmt;

  const _BudgetSummaryCard({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    double totalBudget = 0;
    double totalSpent = 0;
    for (final b in provider.budgets) {
      totalBudget += (b['limit_amount'] as num).toDouble();
      totalSpent += provider.getSpentForCategory(b['category'] as String);
    }
    final sisa = totalBudget - totalSpent;
    final pct = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sisa < 0
              ? [const Color(0xFFFF5252), const Color(0xFFB71C1C)]
              : [const Color(0xFF6C63FF), const Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Anggaran Bulan Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(fmt.format(totalBudget),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Terpakai', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(fmt.format(totalSpent),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sisa < 0 ? 'Melebihi' : 'Sisa', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(fmt.format(sisa.abs()),
                        style: TextStyle(
                            color: sisa < 0 ? const Color(0xFFFF8A80) : const Color(0xFF69F0AE),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}