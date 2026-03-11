import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final savings = provider.savings;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tabungan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () => _showAddSaving(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Color(0xFF6C63FF), size: 16),
                              SizedBox(width: 4),
                              Text('Tambah Target', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary
              if (savings.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SavingsSummaryCard(provider: provider, fmt: fmt),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              if (savings.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏦', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text('Belum ada target tabungan',
                            style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Tap "+ Tambah Target" untuk mulai menabung',
                            style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final s = savings[i];
                      final target = (s['target_amount'] as num).toDouble();
                      final current = (s['current_amount'] as num).toDouble();
                      final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
                      final isDone = current >= target;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF00E676).withValues(alpha: 0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                          : const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isDone ? Icons.check_circle_rounded : Icons.savings_rounded,
                                      color: isDone ? const Color(0xFF00E676) : const Color(0xFF6C63FF),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(s['name'] as String,
                                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                            ),
                                            if (isDone)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('✅ Tercapai!',
                                                    style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                        Text('Target: ${fmt.format(target)}',
                                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
                                    color: const Color(0xFF1A1A2E),
                                    onSelected: (val) {
                                      if (val == 'delete') {
                                        provider.deleteSaving(s['id'] as int);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Progress
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(fmt.format(current),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                  Text('${(pct * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          color: isDone ? const Color(0xFF00E676) : const Color(0xFF6C63FF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDone ? const Color(0xFF00E676) : const Color(0xFF6C63FF),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isDone
                                    ? '🎉 Target tabungan tercapai!'
                                    : 'Kurang ${fmt.format(target - current)} lagi',
                                style: TextStyle(
                                  color: isDone ? const Color(0xFF00E676) : Colors.white38,
                                  fontSize: 12,
                                ),
                              ),

                              if (!isDone) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAddAmount(context, provider, s),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.add, color: Color(0xFF6C63FF), size: 18),
                                    label: const Text('Tambah Tabungan',
                                        style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: savings.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  void _showAddSaving(BuildContext context, TransactionProvider provider) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
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
            const Text('Tambah Target Tabungan',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _InputBox(controller: nameCtrl, hint: 'Nama tabungan (cth: Beli HP, Liburan)'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Rp', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Target jumlah',
                        hintStyle: TextStyle(color: Colors.white24),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                  final name = nameCtrl.text.trim();
                  final target = double.tryParse(targetCtrl.text) ?? 0;
                  if (name.isNotEmpty && target > 0) {
                    await provider.addSaving(name, target);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Buat Target', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAmount(BuildContext context, TransactionProvider provider, Map<String, dynamic> saving) {
    final amountCtrl = TextEditingController();
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
            Text('Tambah ke "${saving['name']}"',
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
                  const Text('Rp', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.white24),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                  backgroundColor: const Color(0xFF00E676),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount > 0) {
                    await provider.addToSaving(saving['id'] as int, amount, saving);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsSummaryCard extends StatelessWidget {
  final TransactionProvider provider;
  final NumberFormat fmt;
  const _SavingsSummaryCard({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pct = provider.totalSavingsTarget > 0
        ? (provider.totalSavingsCurrent / provider.totalSavingsTarget).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Tabungan', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(fmt.format(provider.totalSavingsCurrent),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('dari ${fmt.format(provider.totalSavingsTarget)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text('${provider.savings.length} target tabungan',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _InputBox({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}