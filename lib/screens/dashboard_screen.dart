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
  String _selectedDay = 'Minggu';

  @override
  Widget build(BuildContext context) {
    ReportSummary summary;
    List<SalesDatum> salesData;
    List<TopProduct> topProducts;
    String periodLabel;

    if (_selectedPeriod == ReportPeriod.harian) {
      salesData = harianData;
      if (_selectedDay == 'Senin') {
        summary = seninSummary;
        topProducts = topProductsSenin;
        periodLabel = 'Senin';
      } else if (_selectedDay == 'Selasa') {
        summary = selasaSummary;
        topProducts = topProductsSelasa;
        periodLabel = 'Selasa';
      } else if (_selectedDay == 'Rabu') {
        summary = rabuSummary;
        topProducts = topProductsRabu;
        periodLabel = 'Rabu';
      } else if (_selectedDay == 'Kamis') {
        summary = kamisSummary;
        topProducts = topProductsKamis;
        periodLabel = 'Kamis';
      } else if (_selectedDay == 'Jumat') {
        summary = jumatSummary;
        topProducts = topProductsJumat;
        periodLabel = 'Jumat';
      } else if (_selectedDay == 'Sabtu') {
        summary = sabtuSummary;
        topProducts = topProductsSabtu;
        periodLabel = 'Sabtu';
      } else {
        summary = mingguSummary;
        topProducts = topProductsMinggu;
        periodLabel = 'Minggu';
      }
    } else {
      summary = getSummary(_selectedPeriod);
      salesData = getSalesData(_selectedPeriod);
      topProducts = getTopProducts(_selectedPeriod);
      periodLabel = getPeriodLabel(_selectedPeriod);
    }
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
                    selectedDay: _selectedPeriod == ReportPeriod.harian ? _selectedDay : null,
                    onDayChanged: (day) {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
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

class _ChartCard extends StatefulWidget {
  final String title;
  final List<SalesDatum> data;
  final String? selectedDay;
  final ValueChanged<String>? onDayChanged;

  const _ChartCard({
    required this.title,
    required this.data,
    this.selectedDay,
    this.onDayChanged,
  });

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int? _selectedBarIndex;

  @override
  void didUpdateWidget(covariant _ChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _selectedBarIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox();
    final maxVal = widget.data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final fmt = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final fullFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.headlineSm),
                    const SizedBox(height: 2),
                    Text(
                      widget.selectedDay != null
                          ? 'Klik batang hari untuk melihat detail analitik hari tersebut'
                          : 'Distribusi penjualan per periode',
                      style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.data.length, (i) {
                final d = widget.data[i];
                final h = maxVal == 0 ? 0.0 : (d.amount / maxVal) * 110;
                
                final isSelected = widget.selectedDay != null
                    ? widget.selectedDay == d.label
                    : _selectedBarIndex == i;

                final isToday = widget.selectedDay != null
                    ? d.label == 'Minggu'
                    : i == widget.data.length - 1;
                
                final barColor = isSelected
                    ? AppColors.primary
                    : (widget.selectedDay != null || _selectedBarIndex != null)
                        ? AppColors.primaryFixed.withOpacity(0.3)
                        : isToday
                            ? AppColors.primary
                            : AppColors.primaryFixed.withOpacity(0.6);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.selectedDay != null && widget.onDayChanged != null) {
                          widget.onDayChanged!(d.label);
                        } else {
                          setState(() {
                            if (_selectedBarIndex == i) {
                              _selectedBarIndex = null;
                            } else {
                              _selectedBarIndex = i;
                            }
                          });
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected || (isToday && widget.selectedDay == null && _selectedBarIndex == null))
                              Text(
                                fmt.format(d.amount),
                                style: AppTextStyles.labelXs.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: h,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected
                                    ? Border.all(color: AppColors.primaryFixed, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.label,
                              style: AppTextStyles.labelXs.copyWith(
                                color: isSelected || (isToday && widget.selectedDay == null && _selectedBarIndex == null)
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                fontWeight: isSelected || (isToday && widget.selectedDay == null && _selectedBarIndex == null)
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: (widget.selectedDay != null || _selectedBarIndex != null)
                ? () {
                    final activeIdx = widget.selectedDay != null
                        ? widget.data.indexWhere((d) => d.label == widget.selectedDay)
                        : _selectedBarIndex;
                    if (activeIdx == null || activeIdx == -1) return const SizedBox();
                    final activeData = widget.data[activeIdx];
                    
                    return Container(
                      key: ValueKey<String>(activeData.label),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.selectedDay != null
                                      ? 'Detail Penjualan Hari ${activeData.label}'
                                      : 'Detail Penjualan: ${activeData.label}',
                                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Omzet: ',
                                      style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                    Text(
                                      fullFmt.format(activeData.amount),
                                      style: AppTextStyles.labelXs.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Transaksi: ',
                                      style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                    Text(
                                      '${activeData.transactions} Transaksi',
                                      style: AppTextStyles.labelXs.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }()
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Klik batang grafik hari apa saja untuk melihat rincian omzet & detail data penjualan.',
                          style: AppTextStyles.labelXs.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
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
