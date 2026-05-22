import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Semua';
  final _methods = ['Semua', 'QRIS', 'Tunai', 'Kartu', 'Transfer'];
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      color: AppColors.background,
      // 🚀 MENGGUNAKAN STREAM STREAMBUILDER SUPABASE AGAR DATA SINKRON REAL-TIME
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('transactions')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false), // Transaksi terbaru muncul paling atas
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRawTransactions = snapshot.data ?? [];

          // Ambil tanggal hari ini untuk mencocokkan data
          final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          // Filter data khusus transaksi hari ini saja sesuai desain awal kamu
          final todayTransactions = allRawTransactions.where((tx) {
            final createdAt = tx['created_at']?.toString() ?? '';
            return createdAt.startsWith(todayStr);
          }).toList();

          // Terapkan filter metode pembayaran (Semua, QRIS, Tunai, dsb)
          final filteredTransactions = todayTransactions.where((tx) {
            if (_filter == 'Semua') return true;
            return tx['payment_method'] == _filter;
          }).toList();

          // Hitung total statistik dari data real Supabase
          final double totalToday = filteredTransactions.fold(0.0, (sum, tx) => sum + (tx['total_price'] ?? 0));
          final int txCount = filteredTransactions.length;
          final double averageToday = txCount == 0 ? 0.0 : totalToday / txCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER & STATISTIK REAL-TIME ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                color: AppColors.surfaceContainerLowest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat Transaksi', style: AppTextStyles.headlineMd),
                    const SizedBox(height: 4),
                    Text('Hari ini · $txCount transaksi', style: AppTextStyles.labelSm),
                    const SizedBox(height: 16),
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
                          value: '$txCount',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Rata-rata',
                          value: fmt.format(averageToday),
                          icon: Icons.bar_chart_rounded,
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Filter Chips
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
              
              // ── TABEL HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    _TableHeader('ID Transaksi', flex: 2),
                    _TableHeader('Pelanggan', flex: 2), // 👈 Kolom baru disisipkan di sini jirr
                    _TableHeader('Waktu', flex: 1),
                    _TableHeader('Item', flex: 1),
                    _TableHeader('Metode', flex: 2),
                    _TableHeader('Total', flex: 2),
                    _TableHeader('Status', flex: 2),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // ── TABEL DATA LIST REAL-TIME ──
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(child: Text('Belum ada transaksi dengan metode $_filter hari ini.', style: AppTextStyles.bodySm))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = filteredTransactions[index];
                          
                          // Konversi data waktu dari UTC database ke Jam Lokal Toko
                          String formattedTime = '--:--';
                          if (tx['created_at'] != null) {
                            try {
                              final dt = DateTime.parse(tx['created_at'].toString()).toLocal();
                              formattedTime = DateFormat('HH:mm').format(dt);
                            } catch (_) {}
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                // 1. ID Transaksi
                                Expanded(flex: 2, child: Text('#TJN-${tx['id']}', style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700))),
                                
                                // 2. Nama Pelanggan (Mengisi space di sebelah ID Transaksi)
                                Expanded(
                                  flex: 2, 
                                  child: Text(
                                    tx['customer_name'] != null && tx['customer_name'].toString().trim().isNotEmpty
                                        ? tx['customer_name']
                                        : 'Umum', 
                                    style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500)
                                  ),
                                ),

                                // 3. Waktu
                                Expanded(flex: 1, child: Text(formattedTime, style: AppTextStyles.bodySm)),
                                
                                // 4. Jumlah Item
                                Expanded(flex: 1, child: Text('${tx['total_items'] ?? 0} item', style: AppTextStyles.bodySm)),
                                
                                // 5. Metode Pembayaran
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Icon(_methodIcon(tx['payment_method'] ?? 'Tunai'), size: 16, color: AppColors.onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Text(tx['payment_method'] ?? 'Tunai', style: AppTextStyles.bodySm),
                                    ],
                                  ),
                                ),
                                
                                // 6. Total Harga
                                Expanded(
                                  flex: 2,
                                  child: Text(fmt.format(tx['total_price'] ?? 0), style: AppTextStyles.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                                
                                // 7. Status Transaksi
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryFixed.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text('Selesai', style: TextStyle(color: AppColors.primary, fontSize: 12), textAlign: TextAlign.center),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelXs, overflow: TextOverflow.ellipsis),
                  Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                ],
              ),
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