import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  String _statusFilter = 'Lagi Dibuat';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update elapsed timers every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _timeElapsed(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
    return '${diff.inHours} jam lalu';
  }

  String _formatOrderType(String type) {
    final t = type.toLowerCase();
    if (t == 'dinein' || t == 'dine-in') return 'Dine-in';
    if (t == 'takeaway') return 'Takeaway';
    if (t == 'delivery') return 'Delivery';
    return type;
  }

  Color _orderTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('dine')) return const Color(0xFF0288D1); // Blue
    if (t.contains('take')) return const Color(0xFF7B1FA2); // Purple
    return const Color(0xFFE65100); // Orange/Amber
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_statusFilter == 'Semua') return transactions;
    return transactions.where((tx) => tx.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final filteredTx = _getFilteredTransactions(transactions);

    final activeCount = transactions.where((tx) => tx.status == 'Lagi Dibuat').length;
    final completedCount = transactions.where((tx) => tx.status == 'Selesai').length;

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          _buildHeader(activeCount, completedCount),
          // Filter Tabs
          _buildFilters(),
          const Divider(height: 1),
          // Grid content
          Expanded(child: _buildGrid(filteredTx, txProvider)),
        ],
      ),
    );
  }

  Widget _buildHeader(int activeCount, int completedCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dapur & Antrean', style: AppTextStyles.headlineMd),
                const SizedBox(height: 4),
                Text('Kelola status penyajian masakan secara real-time', style: AppTextStyles.labelSm),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stats row
          Row(
            children: [
              _buildStatBox(
                icon: '🍳',
                label: 'Lagi Dibuat',
                value: '$activeCount',
                color: AppColors.statusPending,
              ),
              const SizedBox(width: 12),
              _buildStatBox(
                icon: '✅',
                label: 'Selesai hari ini',
                value: '$completedCount',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelXs),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Lagi Dibuat', 'Selesai', 'Semua'];
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = f == _statusFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.labelSm.copyWith(
                    color: active ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(List<Transaction> list, TransactionProvider txProvider) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👨‍🍳', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 16),
            Text(
              _statusFilter == 'Lagi Dibuat'
                  ? 'Tidak ada pesanan antrean saat ini'
                  : 'Tidak ada pesanan ditemukan',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _statusFilter == 'Lagi Dibuat' ? 'Dapur sedang santai.' : 'Silakan periksa filter lain.',
              style: AppTextStyles.labelSm,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        final typeLabel = _formatOrderType(tx.orderType);
        final typeColor = _orderTypeColor(tx.orderType);

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: tx.status == 'Lagi Dibuat'
                  ? AppColors.statusPending.withOpacity(0.4)
                  : AppColors.outlineVariant,
              width: tx.status == 'Lagi Dibuat' ? 1.5 : 1,
            ),
          ),
          color: AppColors.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      tx.id,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: AppTextStyles.labelXs.copyWith(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Customer Info & Time elapsed
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.customerName,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: tx.status == 'Lagi Dibuat'
                              ? AppColors.statusPending
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeElapsed(tx.dateTime),
                          style: AppTextStyles.labelXs.copyWith(
                            color: tx.status == 'Lagi Dibuat'
                                ? AppColors.statusPending
                                : AppColors.onSurfaceVariant,
                            fontWeight: tx.status == 'Lagi Dibuat'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: tx.items.length,
                  itemBuilder: (context, idx) {
                    final item = tx.items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text('${item.emoji} ', style: const TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.quantity > 1
                                  ? AppColors.primaryFixed.withOpacity(0.6)
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: AppTextStyles.labelXs.copyWith(
                                fontWeight: FontWeight.bold,
                                color: item.quantity > 1
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Action Footer
              Padding(
                padding: const EdgeInsets.all(12),
                child: tx.status == 'Lagi Dibuat'
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          txProvider.updateTransactionStatus(tx.id, 'Selesai');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pesanan ${tx.id} berhasil diselesaikan!'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Siap Disajikan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Selesai Disajikan',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
