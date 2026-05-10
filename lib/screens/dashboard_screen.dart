import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Laporan & Analitik', style: AppTextStyles.headlineMd),
            const SizedBox(height: 4),
            Text('Kamis, 8 Mei 2026 · Pembaruan real-time', style: AppTextStyles.labelSm),
            const SizedBox(height: 24),

            // KPI Cards
            Row(
              children: [
                _KpiCard(
                  icon: '💰',
                  label: 'Pendapatan Hari Ini',
                  value: fmt.format(834000),
                  change: '+12.4%',
                  positive: true,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '🧾',
                  label: 'Transaksi Hari Ini',
                  value: '47',
                  change: '+8 dari kemarin',
                  positive: true,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '☕',
                  label: 'Item Terjual',
                  value: '128',
                  change: '+5.2%',
                  positive: true,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: '⭐',
                  label: 'Rata-rata Order',
                  value: fmt.format(17745),
                  change: '-1.3%',
                  positive: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales chart (placeholder)
                Expanded(
                  flex: 3,
                  child: _ChartCard(title: 'Penjualan Mingguan'),
                ),
                const SizedBox(width: 16),
                // Top products
                Expanded(
                  flex: 2,
                  child: _TopProductsCard(),
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
                  child: _RecentSummary(),
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
  const _ChartCard({required this.title});

  static const _data = [320000.0, 480000.0, 290000.0, 610000.0, 720000.0, 540000.0, 834000.0];
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final maxVal = _data.reduce((a, b) => a > b ? a : b);
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
          const SizedBox(height: 4),
          Text('7 hari terakhir', style: AppTextStyles.labelSm),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_data.length, (i) {
                final h = (_data[i] / maxVal) * 110;
                final isToday = i == _data.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isToday)
                          Text(fmt.format(_data[i]), style: AppTextStyles.labelXs.copyWith(color: AppColors.primary, fontSize: 9), overflow: TextOverflow.ellipsis),
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
                          _days[i],
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
  _TopProductsCard();

  final _products = const [
    {'name': 'Matcha Latte', 'emoji': '🍵', 'qty': 34, 'pct': 0.85},
    {'name': 'Flat White', 'emoji': '☕', 'qty': 28, 'pct': 0.70},
    {'name': 'Iced Matcha', 'emoji': '🧊', 'qty': 22, 'pct': 0.55},
    {'name': 'Matcha Croissant', 'emoji': '🥐', 'qty': 18, 'pct': 0.45},
    {'name': 'Cold Brew', 'emoji': '🧋', 'qty': 14, 'pct': 0.35},
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
          Text('Produk Terlaris', style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          Text('Hari ini', style: AppTextStyles.labelSm),
          const SizedBox(height: 20),
          ...(_products.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(p['emoji'] as String, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p['name'] as String, style: AppTextStyles.bodyMd.copyWith(fontSize: 13)),
                          const Spacer(),
                          Text('${p['qty']} terjual', style: AppTextStyles.labelXs),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: p['pct'] as double,
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
          Text('Distribusi hari ini', style: AppTextStyles.labelSm),
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
  const _RecentSummary();

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
          Text('Ringkasan Shift', style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          Text('Shift pagi · 08:00 – sekarang', style: AppTextStyles.labelSm),
          const SizedBox(height: 20),
          _SummaryItem(icon: Icons.receipt_long_rounded, label: 'Total Transaksi', value: '47'),
          _SummaryItem(icon: Icons.shopping_bag_outlined, label: 'Item Terjual', value: '128'),
          _SummaryItem(icon: Icons.people_outline_rounded, label: 'Pelanggan', value: '41'),
          _SummaryItem(icon: Icons.discount_outlined, label: 'Diskon Diberikan', value: fmt.format(24500)),
          _SummaryItem(icon: Icons.attach_money_rounded, label: 'Pendapatan Bersih', value: fmt.format(809500), highlight: true),
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
