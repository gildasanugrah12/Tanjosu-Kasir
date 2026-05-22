import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Semua';
  final _methods = ['Semua', 'QRIS', 'Tunai', 'Kartu', 'Transfer'];

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_filter == 'Semua') return transactions;
    return transactions.where((t) => t.paymentMethod == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final filteredTx = _getFilteredTransactions(transactions);

    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalToday = filteredTx.fold(0.0, (s, t) => s + t.grandTotal);
    final txList = filteredTx;

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: AppColors.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Transaksi', style: AppTextStyles.headlineMd),
                const SizedBox(height: 4),
                Text('Hari ini · ${txList.length} transaksi', style: AppTextStyles.labelSm),
                const SizedBox(height: 16),
                // Stats
                Row(
                  children: [
                    _StatChip(
                      label: 'Total Pendapatan',
                      value: fmt.format(totalToday),
                      icon: Icons.trending_up_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Transaksi',
                      value: '${txList.length}',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Rata-rata',
                      value: txList.isEmpty ? 'Rp 0' : fmt.format(totalToday / txList.length),
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter chips
                Row(
                  children: _methods.map((m) {
                    final active = m == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(m, style: AppTextStyles.labelSm.copyWith(color: active ? Colors.white : AppColors.onSurfaceVariant)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                _TableHeader('ID Transaksi', flex: 2),
                _TableHeader('Waktu', flex: 1),
                _TableHeader('Item', flex: 1),
                _TableHeader('Metode', flex: 2),
                _TableHeader('Total', flex: 2),
                _TableHeader('Status', flex: 2),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table rows
          Expanded(
            child: txList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Tidak ada transaksi ditemukan', style: AppTextStyles.bodyMd),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: txList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = txList[index];
                      final timeStr = DateFormat('HH:mm').format(tx.dateTime);
                      final totalItems = tx.items.fold<int>(0, (sum, item) => sum + item.quantity);

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(tx.id, style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700))),
                            Expanded(flex: 1, child: Text(timeStr, style: AppTextStyles.bodySm)),
                            Expanded(flex: 1, child: Text('$totalItems item', style: AppTextStyles.bodySm)),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Icon(_methodIcon(tx.paymentMethod), size: 16, color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(tx.paymentMethod, style: AppTextStyles.bodySm),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(fmt.format(tx.grandTotal), style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tx.status == 'Selesai'
                                        ? AppColors.primaryFixed.withOpacity(0.4)
                                        : AppColors.statusPending.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    tx.status,
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: tx.status == 'Selesai'
                                          ? AppColors.primary
                                          : AppColors.statusPending,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'QRIS': return Icons.qr_code_2_rounded;
      case 'Tunai': return Icons.payments_outlined;
      case 'Kartu': return Icons.credit_card_rounded;
      default: return Icons.account_balance_rounded;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelXs),
                Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _TableHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label.toUpperCase(), style: AppTextStyles.labelXs.copyWith(letterSpacing: 0.8)),
    );
  }
}
