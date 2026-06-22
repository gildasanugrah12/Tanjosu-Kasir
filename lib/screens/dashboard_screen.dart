import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

// ==================== MODEL DATA ASLI ====================
class SalesDatum {
  final String label;
  final double amount;
  final int transactions;

  SalesDatum({
    required this.label,
    required this.amount,
    required this.transactions,
  });
}

class TopProduct {
  final String name;
  final int qty;
  final double pct;
  final String emoji;

  TopProduct({
    required this.name,
    required this.qty,
    required this.pct,
    required this.emoji,
  });
}

enum ReportPeriod { harian, mingguan, bulanan, tahunan }

// ==================== MAIN SCREEN ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  ReportPeriod _selectedPeriod = ReportPeriod.harian;
  String _selectedDay = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _getHariIndo(DateTime.now().weekday);
  }

  String _getHariIndo(int weekday) {
    switch (weekday) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      default: return 'Minggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final lebarLayar = MediaQuery.of(context).size.width;
    final isWeb = lebarLayar > 950; // Ditinggikan sedikit thresholdnya agar lebih aman di web

    return Container(
      color: AppColors.background,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('transactions').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, txSnapshot) {
          if (txSnapshot.hasError) {
            return Center(child: Text('🚨 Eror database: ${txSnapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (txSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = txSnapshot.data ?? [];

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('transaction_items').stream(primaryKey: ['id']),
            builder: (context, itemsSnapshot) {
              final allTransactionItems = itemsSnapshot.data ?? [];

              // ==================== LOGIKA PENCOCOKAN REAL-TIME ====================
              Map<String, int> omzetPerHari = {'Senin': 0, 'Selasa': 0, 'Rabu': 0, 'Kamis': 0, 'Jumat': 0, 'Sabtu': 0, 'Minggu': 0};
              Map<String, int> txPerHari = {'Senin': 0, 'Selasa': 0, 'Rabu': 0, 'Kamis': 0, 'Jumat': 0, 'Sabtu': 0, 'Minggu': 0};
              Map<String, int> pcsPerHari = {'Senin': 0, 'Selasa': 0, 'Rabu': 0, 'Kamis': 0, 'Jumat': 0, 'Sabtu': 0, 'Minggu': 0};
              
              int totalOmzetSemua = 0;
              int totalItemsSemua = 0;
              Map<int, String> txIdToHariMap = {};
              
              for (var tx in allTransactions) {
                final txId = (tx['id'] as num? ?? -1).toInt();
                final price = (tx['total_price'] as num? ?? 0).toInt();
                totalOmzetSemua += price;

                try {
                  final date = DateTime.parse(tx['created_at'] ?? '').toLocal();
                  final namaHari = _getHariIndo(date.weekday);
                  
                  if (txId != -1) {
                    txIdToHariMap[txId] = namaHari;
                  }

                  omzetPerHari[namaHari] = (omzetPerHari[namaHari] ?? 0) + price;
                  txPerHari[namaHari] = (txPerHari[namaHari] ?? 0) + 1;
                } catch (_) {}
              }

              for (var item in allTransactionItems) {
                final qty = (item['quantity'] as num? ?? 0).toInt();
                totalItemsSemua += qty;

                final itemTxId = (item['transaction_id'] as num? ?? -1).toInt();
                if (itemTxId != -1 && txIdToHariMap.containsKey(itemTxId)) {
                  String hariTx = txIdToHariMap[itemTxId]!;
                  pcsPerHari[hariTx] = (pcsPerHari[hariTx] ?? 0) + qty;
                }
              }

              List<SalesDatum> salesData = omzetPerHari.entries.map((e) {
                return SalesDatum(label: e.key, amount: e.value.toDouble(), transactions: txPerHari[e.key] ?? 0);
              }).toList();

              int currentRevenue = 0;
              int currentTxCount = 0;
              int currentItemsCount = 0;

              if (_selectedPeriod == ReportPeriod.harian) {
                currentRevenue = omzetPerHari[_selectedDay] ?? 0;
                currentTxCount = txPerHari[_selectedDay] ?? 0;
                currentItemsCount = pcsPerHari[_selectedDay] ?? 0;
              } else {
                currentRevenue = totalOmzetSemua;
                currentTxCount = allTransactions.length;
                currentItemsCount = totalItemsSemua;
              }

              double avgOrder = currentTxCount > 0 ? currentRevenue / currentTxCount : 0;
              String periodLabel = _selectedPeriod == ReportPeriod.harian ? _selectedDay : _selectedPeriod.name.toUpperCase();

              Map<String, int> produkQtyMap = {};
              for (var item in allTransactionItems) {
                final pName = item['product_name'] ?? item['item_name'] ?? 'Menu';
                final itemTxId = (item['transaction_id'] as num? ?? -1).toInt();
                
                if (_selectedPeriod == ReportPeriod.harian) {
                  if (itemTxId != -1 && txIdToHariMap[itemTxId] == _selectedDay) {
                    produkQtyMap[pName] = (produkQtyMap[pName] ?? 0) + (item['quantity'] as num? ?? 0).toInt();
                  }
                } else {
                  produkQtyMap[pName] = (produkQtyMap[pName] ?? 0) + (item['quantity'] as num? ?? 0).toInt();
                }
              }

              var sortedProduk = produkQtyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              int maxQty = sortedProduk.isNotEmpty ? sortedProduk.first.value : 1;

              List<TopProduct> topProducts = sortedProduk.take(5).map((e) {
                String emoji = '🍔';
                if (e.key.toLowerCase().contains('tea') || e.key.toLowerCase().contains('drink')) emoji = '🍹';
                if (e.key.toLowerCase().contains('pudding')) emoji = '🍮';
                return TopProduct(name: e.key, qty: e.value, pct: e.value / maxQty, emoji: emoji);
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Laporan & Analitik', style: AppTextStyles.headlineMd),
                            const SizedBox(height: 4),
                            Text('📢 Pembaruan real-time aktif dari Supabase', style: AppTextStyles.labelSm.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: ReportPeriod.values.map((period) {
                              final isSelected = _selectedPeriod == period;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPeriod = period),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    period.name.toUpperCase(),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FIX 1: KPI CARDS BERBARIS SEMPURNA (4 KOLOM DI WEB)
                    isWeb 
                      ? Row(
                          children: [
                            Expanded(child: _KpiCard(icon: '💰', label: 'Pendapatan $periodLabel', value: fmt.format(currentRevenue), change: 'Live')),
                            const SizedBox(width: 16),
                            Expanded(child: _KpiCard(icon: '🧾', label: 'Transaksi', value: '$currentTxCount Order', change: 'Sync')),
                            const SizedBox(width: 16),
                            Expanded(child: _KpiCard(icon: '☕', label: 'Item Terjual', value: '$currentItemsCount Pcs', change: 'Realtime')),
                            const SizedBox(width: 16),
                            Expanded(child: _KpiCard(icon: '⭐', label: 'Rata-rata Order', value: fmt.format(avgOrder), change: 'Nilai')),
                          ],
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildMobileKpiWrapper(
                              context: context,
                              child: _KpiCard(icon: '💰', label: 'Pendapatan $periodLabel', value: fmt.format(currentRevenue), change: 'Live'),
                            ),
                            _buildMobileKpiWrapper(
                              context: context,
                              child: _KpiCard(icon: '🧾', label: 'Transaksi', value: '$currentTxCount Order', change: 'Sync'),
                            ),
                            _buildMobileKpiWrapper(
                              context: context,
                              child: _KpiCard(icon: '☕', label: 'Item Terjual', value: '$currentItemsCount Pcs', change: 'Realtime'),
                            ),
                            _buildMobileKpiWrapper(
                              context: context,
                              child: _KpiCard(icon: '⭐', label: 'Rata-rata Order', value: fmt.format(avgOrder), change: 'Nilai'),
                            ),
                          ],
                        ),
                    const SizedBox(height: 24),

                    // FIX 2: MIDDLE SECTION (GRAFIK & TOP PRODUK REKREASI TINGGI SAMA BESAR)
                    isWeb 
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _ChartCard(
                                  title: 'Grafik Penjualan Mingguan',
                                  data: salesData,
                                  selectedDay: _selectedPeriod == ReportPeriod.harian ? _selectedDay : null,
                                  onDayChanged: (day) => setState(() => _selectedDay = day),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _TopProductsCard(products: topProducts, periodLabel: 'Berdasarkan Data Cloud'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _ChartCard(
                              title: 'Grafik Penjualan Mingguan',
                              data: salesData,
                              selectedDay: _selectedPeriod == ReportPeriod.harian ? _selectedDay : null,
                              onDayChanged: (day) => setState(() => _selectedDay = day),
                            ),
                            const SizedBox(height: 16),
                            _TopProductsCard(products: topProducts, periodLabel: 'Berdasarkan Data Cloud'),
                          ],
                        ),
                    const SizedBox(height: 24),

                    // FIX 3: BOTTOM SECTION (METODE BAYAR & RINGKASAN TINGGI SAMA BESAR)
                    isWeb
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(child: _PaymentBreakdown()),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _RecentSummary(
                                  totalTx: allTransactions.length,
                                  totalItems: totalItemsSemua,
                                  totalRevenue: totalOmzetSemua,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            const _PaymentBreakdown(),
                            const SizedBox(height: 16),
                            _RecentSummary(
                              totalTx: allTransactions.length,
                              totalItems: totalItemsSemua,
                              totalRevenue: totalOmzetSemua,
                            ),
                          ],
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper Khusus Mobile agar Card terbagi 2 rata kanan-kiri
  Widget _buildMobileKpiWrapper({required BuildContext context, required Widget child}) {
    return SizedBox(width: (MediaQuery.of(context).size.width - 48 - 16) / 2, child: child);
  }
}

// ==================== SUB-WIDGET COMPONENTS (CLEANED) ====================

class _KpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String change;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Sejajarkan tengah secara vertikal jika ada perbedaan tinggi teks
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<SalesDatum> data;
  final String? selectedDay;
  final Function(String) onDayChanged;

  const _ChartCard({
    required this.title,
    required this.data,
    this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    double maxAmount = 1;
    for (var d in data) {
      if (d.amount > maxAmount) maxAmount = d.amount;
    }

    return Container(
      padding: const EdgeInsets.all(20), // Ditingkatkan sedikit paddingnya agar lebih luas
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(), // Dorong chart ke bagian bawah container jika container membesar akibat IntrinsicHeight
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final barHeightPct = d.amount / maxAmount;
                final isSelected = selectedDay == d.label;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayChanged(d.label),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: (120 * barHeightPct).clamp(4, 120).toDouble(),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6), // Diperhalus corner barnya
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.label.substring(0, 3),
                          style: AppTextStyles.labelSm.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<TopProduct> products;
  final String periodLabel;

  const _TopProductsCard({required this.products, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produk Terlaris', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold)),
          Text(periodLabel, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          products.isEmpty
              ? const Expanded(child: Center(child: Text('Belum ada data penjualan')))
              : Column(
                  children: products.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: p.pct,
                                    minHeight: 6, // Tebal indikator disamakan agar solid
                                    backgroundColor: AppColors.surfaceContainerLow,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('${p.qty} pcs', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Metode Pembayaran', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _rowPay('💵 Tunai (Cash)', '80% Pengguna'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _rowPay('📱 QRIS / Transfer', '20% Pengguna'),
        ],
      ),
      // Ditutup rapi tanpa spasi gantung
    );
  }

  Widget _rowPay(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
        Text(subtitle, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RecentSummary extends StatelessWidget {
  final int totalTx;
  final int totalItems;
  final int totalRevenue;

  const _RecentSummary({
    required this.totalTx,
    required this.totalItems,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Agar sejajar rapi dengan metode pembayaran di sebelahnya
        children: [
          Text('Ringkasan Akumulasi Cloud', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Nota Masuk:', style: AppTextStyles.bodyMd),
              Text('$totalTx Transaksi', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Kuantitas:', style: AppTextStyles.bodyMd),
              Text('$totalItems Produk', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Omzet Kotor:', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
              Text(fmt.format(totalRevenue), style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}