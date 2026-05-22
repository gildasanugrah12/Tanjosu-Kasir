import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/report_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.harian;

  @override
  Widget build(BuildContext context) {
    final summary = getSummary(_selectedPeriod);
    final salesData = getSalesData(_selectedPeriod);
    final topProducts = getTopProducts(_selectedPeriod);
    final periodLabel = getPeriodLabel(_selectedPeriod);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header & Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan & Analitik', style: AppTextStyles.headlineMd),
                    const SizedBox(height: 4),
                    Text('Pembaruan real-time', style: AppTextStyles.labelSm),
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

            // KPI Cards
            Row(
              children: [
                _KpiCard(
                  icon: '💰',
                  label: 'Pendapatan $periodLabel',
                  value: fmt.format(summary.totalRevenue),
                  change: '${summary.revenueChange > 0 ? '+' : ''}${summary.revenueChange}%',
                  positive: summary.revenueChange >= 0,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '🧾',
                  label: 'Transaksi',
                  value: '${summary.totalTransactions}',
                  change: '${summary.transactionChange > 0 ? '+' : ''}${summary.transactionChange}%',
                  positive: summary.transactionChange >= 0,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '☕',
                  label: 'Item Terjual',
                  value: '${summary.totalItems}',
                  change: '+5.2%',
                  positive: true,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '⭐',
                  label: 'Rata-rata Order',
                  value: fmt.format(summary.avgOrder),
                  change: '-1.3%',
                  positive: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales chart
                Expanded(
                  flex: 3,
                  child: _ChartCard(
                    title: 'Grafik Penjualan $periodLabel',
                    data: salesData,
                  ),
                ),
                const SizedBox(width: 16),
                // Top products
                Expanded(
                  flex: 2,
                  child: _TopProductsCard(products: topProducts, periodLabel: periodLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PaymentBreakdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RecentSummary(summary: summary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String change;
  final bool positive;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: positive ? AppColors.primaryFixed.withOpacity(0.4) : AppColors.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    change,
                    style: AppTextStyles.labelXs.copyWith(
                      color: positive ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: AppTextStyles.headlineMd),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSm),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<SalesDatum> data;
  const _ChartCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxVal = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final fmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSm),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final d = data[i];
                final h = maxVal == 0 ? 0.0 : (d.amount / maxVal) * 110;
                final isToday = i == data.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isToday)
                          Text(fmt.format(d.amount), style: AppTextStyles.labelXs.copyWith(color: AppColors.primary, fontSize: 9), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primary : AppColors.primaryFixed.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.label,
                          style: AppTextStyles.labelXs.copyWith(
                            color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
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
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produk Terlaris', style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          Text(periodLabel, style: AppTextStyles.labelSm),
          const SizedBox(height: 20),
          ...(products.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.name, style: AppTextStyles.bodyMd.copyWith(fontSize: 13)),
                          const Spacer(),
                          Text('${p.qty} terjual', style: AppTextStyles.labelXs),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: p.pct,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ))).toList(),
        ],
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown();

  final _methods = const [
    {'label': 'QRIS', 'pct': 0.52, 'color': 0xFF446900},
    {'label': 'Tunai', 'pct': 0.26, 'color': 0xFF74A12E},
    {'label': 'Kartu', 'pct': 0.14, 'color': 0xFFA5D65D},
    {'label': 'Transfer', 'pct': 0.08, 'color': 0xFFC0F275},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metode Pembayaran', style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          Text('Distribusi rata-rata', style: AppTextStyles.labelSm),
          const SizedBox(height: 20),
          ..._methods.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: Color(m['color'] as int), borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Text(m['label'] as String, style: AppTextStyles.bodySm),
                const Spacer(),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: m['pct'] as double,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(Color(m['color'] as int)),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${((m['pct'] as double) * 100).toInt()}%',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _RecentSummary extends StatelessWidget {
  final ReportSummary summary;
  const _RecentSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Total', style: AppTextStyles.headlineSm),
          const SizedBox(height: 24),
          _SummaryItem(icon: Icons.receipt_long_rounded, label: 'Total Transaksi', value: '${summary.totalTransactions}'),
          _SummaryItem(icon: Icons.shopping_bag_outlined, label: 'Item Terjual', value: '${summary.totalItems}'),
          _SummaryItem(icon: Icons.people_outline_rounded, label: 'Estimasi Pelanggan', value: '${(summary.totalTransactions * 0.9).toInt()}'),
          _SummaryItem(icon: Icons.attach_money_rounded, label: 'Pendapatan Bersih', value: fmt.format(summary.totalRevenue), highlight: true),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _SummaryItem({required this.icon, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: highlight ? AppColors.primary : AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySm),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
