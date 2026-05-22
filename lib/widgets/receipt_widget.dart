import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/transaction.dart';

class ReceiptWidget extends StatelessWidget {
  final Transaction transaction;
  const ReceiptWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    final timeFmt = DateFormat('HH:mm:ss');

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                const Text('🍵', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                  'TANJOSU CIANJUR',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jl. Raya Cianjur No. 88',
                  style: AppTextStyles.labelXs.copyWith(color: Colors.white70),
                ),
                Text(
                  'Telp: (0263) 123-456',
                  style: AppTextStyles.labelXs.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // ── Metadata ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              children: [
                _MetaRow(label: 'No. Struk', value: transaction.id),
                const SizedBox(height: 4),
                _MetaRow(label: 'Tanggal', value: dateFmt.format(transaction.dateTime)),
                const SizedBox(height: 4),
                _MetaRow(label: 'Waktu', value: timeFmt.format(transaction.dateTime)),
                const SizedBox(height: 4),
                _MetaRow(label: 'Kasir', value: 'Admin'),
                const SizedBox(height: 4),
                _MetaRow(label: 'Pembeli', value: transaction.customerName),
                const SizedBox(height: 4),
                _MetaRow(label: 'Tipe', value: transaction.orderType),
                const SizedBox(height: 4),
                _MetaRow(label: 'Bayar via', value: transaction.paymentMethod),
              ],
            ),
          ),

          // ── Divider Dashed ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DashedDivider(),
          ),

          // ── Items ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Column(
              children: transaction.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.emoji} ${item.name}',
                        style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '  ${item.quantity} x ${fmt.format(item.unitPrice)}',
                            style: AppTextStyles.labelXs.copyWith(color: Colors.black54),
                          ),
                          const Spacer(),
                          Text(
                            fmt.format(item.subtotal),
                            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Divider Dashed ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DashedDivider(),
          ),

          // ── Totals ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Column(
              children: [
                _TotalRow(label: 'Subtotal', value: fmt.format(transaction.subtotal)),
                if (transaction.discountAmount > 0) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label: 'Diskon ${transaction.discountPercent.toInt()}%',
                    value: '-${fmt.format(transaction.discountAmount)}',
                    valueColor: AppColors.primary,
                  ),
                ],
                const SizedBox(height: 4),
                _TotalRow(label: 'PPN 11%', value: fmt.format(transaction.taxAmount)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DashedDivider(),
          ),

          // ── Grand Total ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                Text('TOTAL', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w800, color: Colors.black87)),
                const Spacer(),
                Text(
                  fmt.format(transaction.grandTotal),
                  style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // ── Payment info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Column(
              children: [
                _TotalRow(label: 'Jumlah Bayar', value: fmt.format(transaction.amountPaid)),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'Kembalian',
                  value: fmt.format(transaction.change),
                  valueColor: transaction.change > 0 ? AppColors.primary : Colors.black87,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DashedDivider(),
          ),

          // ── Footer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              children: [
                Text(
                  'Terima Kasih Atas Kunjungan Anda!',
                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Semoga hari Anda menyenangkan ☕',
                  style: AppTextStyles.labelXs.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Barcode placeholder
                Container(
                  width: 180,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '||||| ${transaction.id} |||||',
                      style: AppTextStyles.labelXs.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                        color: Colors.black38,
                      ),
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
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.labelXs.copyWith(color: Colors.black54)),
        ),
        Text(': ', style: AppTextStyles.labelXs.copyWith(color: Colors.black54)),
        Expanded(
          child: Text(value, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _TotalRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.black54)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 5.0;
        final dashSpace = 3.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
              ),
            );
          }),
        );
      },
    );
  }
}
