import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  String _statusFilter = 'Memasak';
  late Timer _timer;
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _kitchenStream;

  // Variabel lokal untuk menyimpan ID transaksi yang baru saja diklik
  // Ini kunci biar kartu langsung hilang seketika tanpa nunggu internet!
  final Set<int> _optimisticCompletedTxIds = {};

  @override
  void initState() {
    super.initState();
    // Mengunci stream di initState biar koneksi real-time stabil rill
    _kitchenStream = _supabase.from('dapur').stream(
      primaryKey: ['id'],
    ).order('created_at', ascending: true);

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _optimisticCompletedTxIds.clear();
    super.dispose();
  }

  String _timeElapsed(String timestamptzStr) {
    try {
      final dateTime = DateTime.parse(timestamptzStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
      return '${diff.inHours} jam lalu';
    } catch (_) {
      return 'Baru saja';
    }
  }

  Map<int, List<Map<String, dynamic>>> _groupItemsByTransaction(List<dynamic> rawData) {
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (var item in rawData) {
      final txId = item['transaction_id'] as int;
      if (!grouped.containsKey(txId)) {
        grouped[txId] = [];
      }
      grouped[txId]!.add(item as Map<String, dynamic>);
    }
    return grouped;
  }

  Future<void> _updateKitchenStatus(int txId, String newStatus) async {
    // 1. OPTIMISTIC UPDATE: Langsung masukkan ke daftar selesai biar UI langsung merespon rill
    if (mounted) {
      setState(() {
        _optimisticCompletedTxIds.add(txId);
      });
    }

    try {
      // 2. Kirim data ke Supabase di background paralel biar ngebut
      await Future.wait([
        _supabase.from('dapur').update({'status': newStatus}).eq('transaction_id', txId),
        _supabase.from('transactions').update({'status': newStatus}).eq('id', txId),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan #$txId berhasil disajikan! 🔥'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Jika internet putus/gagal, kembalikan kartu ke layar (rollback)
      if (mounted) {
        setState(() {
          _optimisticCompletedTxIds.remove(txId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status jirr: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _kitchenStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('🚨 Eror Stream Supabase: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data ?? [];

          // Menghitung angka statistik dengan mempertimbangkan data lokal (Optimistic)
          final activeCount = rawData
              .where((item) {
                final txId = item['transaction_id'] as int;
                return item['status'] == 'Memasak' && !_optimisticCompletedTxIds.contains(txId);
              })
              .map((item) => item['transaction_id'])
              .toSet()
              .length;

          final completedCount = rawData
              .where((item) {
                final txId = item['transaction_id'] as int;
                return item['status'] == 'Selesai' || _optimisticCompletedTxIds.contains(txId);
              })
              .map((item) => item['transaction_id'])
              .toSet()
              .length;

          final allGroupedOrders = _groupItemsByTransaction(rawData);
          final Map<int, List<Map<String, dynamic>>> filteredGroupedOrders = {};

          allGroupedOrders.forEach((txId, items) {
            // Cek status berdasarkan database rill
            final hasCookingItem = items.any((item) => item['status'] == 'Memasak');
            
            // Gabungkan kondisi DB dengan kondisi klik lokal (Optimistic)
            String currentStatus = hasCookingItem ? 'Memasak' : 'Selesai';
            if (_optimisticCompletedTxIds.contains(txId)) {
              currentStatus = 'Selesai';
            }
            
            if (_statusFilter == 'Semua' || currentStatus == _statusFilter) {
              filteredGroupedOrders[txId] = items;
            }
          });

          final transactionIds = filteredGroupedOrders.keys.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(activeCount, completedCount),
              _buildFilters(),
              const Divider(height: 1),
              Expanded(
                child: _buildGrid(transactionIds, filteredGroupedOrders),
              ),
            ],
          );
        },
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
                Text(
                    'Kelola status penyajian masakan secara real-time dari cloud Supabase',
                    style: AppTextStyles.labelSm),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
                label: 'Selesai',
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
    final filters = [
      {'key': 'Memasak', 'label': 'Lagi Dibuat'},
      {'key': 'Selesai', 'label': 'Selesai'},
      {'key': 'Semua', 'label': 'Semua'},
    ];
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = f['key'] == _statusFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  f['label']!,
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

  Widget _buildGrid(List<int> txIds, Map<int, List<Map<String, dynamic>>> groupedOrders) {
    if (txIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👨‍🍳', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 16),
            Text(
              _statusFilter == 'Memasak'
                  ? 'Tidak ada pesanan antrean saat ini'
                  : 'Tidak ada pesanan ditemukan',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _statusFilter == 'Memasak'
                  ? 'Dapur sedang santai rill.'
                  : 'Silakan periksa filter lain.',
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
      itemCount: txIds.length,
      itemBuilder: (context, index) {
        final txId = txIds[index];
        final items = groupedOrders[txId]!;

        final firstItem = items.first;
        final timeString = _timeElapsed(firstItem['created_at']);
        
        final hasCookingItem = items.any((item) => item['status'] == 'Memasak');
        String currentStatus = hasCookingItem ? 'Memasak' : 'Selesai';
        if (_optimisticCompletedTxIds.contains(txId)) {
          currentStatus = 'Selesai';
        }

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: currentStatus == 'Memasak'
                  ? AppColors.statusPending.withOpacity(0.4)
                  : AppColors.outlineVariant,
              width: currentStatus == 'Memasak' ? 1.5 : 1,
            ),
          ),
          color: AppColors.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'ORDER #$txId',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Dine In',
                        style: TextStyle(
                          color: Color(0xFF0288D1),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pelanggan Tanjosu',
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
                          color: currentStatus == 'Memasak'
                              ? AppColors.statusPending
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeString,
                          style: AppTextStyles.labelXs.copyWith(
                            color: currentStatus == 'Memasak'
                                ? AppColors.statusPending
                                : AppColors.onSurfaceVariant,
                            fontWeight: currentStatus == 'Memasak'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Text('🍽️ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              item['item_name'] ?? 'Menu',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item['quantity'] ?? 1) > 1
                                  ? AppColors.primaryFixed.withOpacity(0.6)
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x${item['quantity']}',
                              style: AppTextStyles.labelXs.copyWith(
                                fontWeight: FontWeight.bold,
                                color: (item['quantity'] ?? 1) > 1
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: currentStatus == 'Memasak'
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
                        onPressed: () => _updateKitchenStatus(txId, 'Selesai'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                            Icon(Icons.done_all_rounded,
                                size: 18, color: AppColors.primary),
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