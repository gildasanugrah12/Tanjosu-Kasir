import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL LAPORAN
// ─────────────────────────────────────────────────────────────────────────────

enum ReportPeriod { hariIni, mingguIni, bulanIni, kustom }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.hariIni: return 'Hari Ini';
      case ReportPeriod.mingguIni: return 'Minggu Ini';
      case ReportPeriod.bulanIni: return 'Bulan Ini';
      case ReportPeriod.kustom: return 'Kustom';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _supabase = Supabase.instance.client;
  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  ReportPeriod _period = ReportPeriod.hariIni;
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _loadingTx = false;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _transactionItems = [];

  // ── Computed Stats ──────────────────────────────────────────────────────────
  double get _totalRevenue =>
      _transactions.fold(0.0, (sum, tx) => sum + ((tx['total_price'] as num?) ?? 0).toDouble());

  int get _totalOrders => _transactions.length;

  int get _totalItemsSold =>
      _transactionItems.fold(0, (sum, item) => sum + ((item['quantity'] as num?) ?? 0).toInt());

  double get _avgOrder => _totalOrders == 0 ? 0 : _totalRevenue / _totalOrders;

  String get _periodLabel {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.hariIni:
        return 'Hari Ini · ${_dateFmt.format(now)}';
      case ReportPeriod.mingguIni:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return 'Minggu Ini · ${_dateFmt.format(startOfWeek)} – ${_dateFmt.format(endOfWeek)}';
      case ReportPeriod.bulanIni:
        final monthFmt = DateFormat('MMMM yyyy', 'id_ID');
        return 'Bulan Ini · ${monthFmt.format(now)}';
      case ReportPeriod.kustom:
        if (_customStart != null && _customEnd != null) {
          return '${_dateFmt.format(_customStart!)} – ${_dateFmt.format(_customEnd!)}';
        }
        return 'Kustom';
    }
  }

  // ── Date Range ──────────────────────────────────────────────────────────────
  (DateTime, DateTime) get _dateRange {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.hariIni:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return (start, end);
      case ReportPeriod.mingguIni:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 7));
        return (start, end);
      case ReportPeriod.bulanIni:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
      case ReportPeriod.kustom:
        final start = _customStart ?? DateTime(now.year, now.month, now.day);
        final end = (_customEnd ?? now).add(const Duration(days: 1));
        return (start, end);
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingTx = true);
    try {
      final (start, end) = _dateRange;
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();

      // Ambil transaksi dalam rentang
      final txResponse = await _supabase
          .from('transactions')
          .select()
          .gte('created_at', startStr)
          .lt('created_at', endStr)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> txList =
          (txResponse as List).cast<Map<String, dynamic>>();

      if (txList.isEmpty) {
        setState(() {
          _transactions = [];
          _transactionItems = [];
          _loadingTx = false;
        });
        return;
      }

      final txIds = txList.map((tx) => (tx['id'] as num).toInt()).toList();

      // Ambil items
      final itemsResponse = await _supabase
          .from('transaction_items')
          .select()
          .filter('transaction_id', 'in', txIds);

      setState(() {
        _transactions = txList;
        _transactionItems = (itemsResponse as List).cast<Map<String, dynamic>>();
        _loadingTx = false;
      });
    } catch (e) {
      debugPrint('❌ Error load report: $e');
      setState(() => _loadingTx = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Custom Date Picker ───────────────────────────────────────────────────────
  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _period = ReportPeriod.kustom;
      });
      _loadData();
    }
  }

  // ── Export Actions ───────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    try {
      await ExportService.exportToPdf(
        context: context,
        totalRevenue: _totalRevenue,
        totalOrders: _totalOrders,
        totalItemsSold: _totalItemsSold,
        transactions: _transactions,
        transactionItems: _transactionItems,
        periodLabel: _periodLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      final bytes = await ExportService.buildExcelBytes(
        totalRevenue: _totalRevenue,
        totalOrders: _totalOrders,
        totalItemsSold: _totalItemsSold,
        transactions: _transactions,
        transactionItems: _transactionItems,
        periodLabel: _periodLabel,
      );

      final dir = await getTemporaryDirectory();
      final safePeriod = _periodLabel.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/Laporan_Tanjosu_$safePeriod.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Laporan Transaksi Tanjosu – $_periodLabel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor Excel: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────────
          _buildHeader(),
          const Divider(height: 1),

          // ── CONTENT ─────────────────────────────────────────────────────────
          Expanded(
            child: _loadingTx
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Stats cards
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      // Transactions table
                      _buildTransactionsTable(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: AppColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan Transaksi', style: AppTextStyles.headlineMd),
                    const SizedBox(height: 2),
                    Text(_periodLabel, style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              // Refresh
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Muat Ulang',
                onPressed: _loadData,
              ),
              const SizedBox(width: 8),
              // Export buttons
              _ExportButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFE53935),
                onTap: _exportPdf,
              ),
              const SizedBox(width: 8),
              _ExportButton(
                label: 'Excel',
                icon: Icons.table_chart_rounded,
                color: const Color(0xFF2E7D32),
                onTap: _exportExcel,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Period filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...ReportPeriod.values.where((p) => p != ReportPeriod.kustom).map((p) {
                  final active = _period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (_period != p) {
                          setState(() => _period = p);
                          _loadData();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: active ? AppColors.primary : AppColors.outlineVariant,
                          ),
                        ),
                        child: Text(
                          p.label,
                          style: AppTextStyles.labelSm.copyWith(
                            color: active ? Colors.white : AppColors.onSurfaceVariant,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Kustom
                GestureDetector(
                  onTap: _pickCustomRange,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _period == ReportPeriod.kustom ? AppColors.primary : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _period == ReportPeriod.kustom ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 14,
                          color: _period == ReportPeriod.kustom ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _period == ReportPeriod.kustom ? _periodLabel : 'Kustom',
                          style: AppTextStyles.labelSm.copyWith(
                            color: _period == ReportPeriod.kustom ? Colors.white : AppColors.onSurfaceVariant,
                            fontWeight: _period == ReportPeriod.kustom ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          title: 'Total Pendapatan',
          value: _fmt.format(_totalRevenue),
          icon: Icons.payments_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Total Transaksi',
          value: '$_totalOrders Order',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Item Terjual',
          value: '$_totalItemsSold Pcs',
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFFE65100),
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Rata-rata Order',
          value: _fmt.format(_avgOrder),
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF7B1FA2),
        ),
      ],
    );
  }

  // ── TRANSACTIONS TABLE ─────────────────────────────────────────────────────
  Widget _buildTransactionsTable() {
    // Build item lookup map
    final Map<int, List<Map<String, dynamic>>> itemsByTxId = {};
    for (final item in _transactionItems) {
      final txId = (item['transaction_id'] as num?)?.toInt() ?? 0;
      itemsByTxId.putIfAbsent(txId, () => []).add(item);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detail Transaksi',
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${_transactions.length} transaksi',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (_transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada transaksi pada periode ini',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Column headers
            Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: const [
                  _TH('ID', flex: 2),
                  _TH('Waktu', flex: 1),
                  _TH('Pelanggan', flex: 2),
                  _TH('Item', flex: 3),
                  _TH('Metode', flex: 2),
                  _TH('Total', flex: 2),
                  _TH('Status', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1),

            // Data rows
            ...List.generate(_transactions.length, (i) {
              final tx = _transactions[i];
              final txId = (tx['id'] as num?)?.toInt() ?? 0;
              final items = itemsByTxId[txId] ?? [];
              final itemStr = items.map((it) => '${it['product_name']} (x${it['quantity']})').join(', ');

              String time = '--:--';
              if (tx['created_at'] != null) {
                try {
                  time = DateFormat('HH:mm').format(DateTime.parse(tx['created_at'].toString()).toLocal());
                } catch (_) {}
              }

              final status = tx['status']?.toString() ?? '-';
              final isOdd = i.isOdd;

              return Column(
                children: [
                  Container(
                    color: isOdd ? AppColors.surfaceContainerLow.withValues(alpha: 0.4) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '#TJN-$txId',
                            style: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(time, style: AppTextStyles.bodySm),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            tx['customer_name']?.toString().trim().isEmpty ?? true
                                ? 'Umum'
                                : tx['customer_name'],
                            style: AppTextStyles.bodySm,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            itemStr.isEmpty ? '-' : itemStr,
                            style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(_methodIcon(tx['payment_method'] ?? ''), size: 14, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 5),
                              Text(tx['payment_method'] ?? 'Tunai', style: AppTextStyles.bodySm),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt.format(tx['total_price'] ?? 0),
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _StatusBadge(status: status),
                        ),
                      ],
                    ),
                  ),
                  if (i < _transactions.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS LOKAL
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await widget.onTap();
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(widget.icon, size: 16, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  _loading ? 'Loading...' : 'Ekspor ${widget.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelXs, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelXs.copyWith(letterSpacing: 0.7, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Selesai':
        color = AppColors.primary;
        break;
      case 'Batal':
        color = AppColors.error;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}