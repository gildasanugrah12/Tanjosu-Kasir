import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  // ─────────────────────────────────────────────────────────────────────────────
  // PDF EXPORT
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<void> exportToPdf({
    required BuildContext context,
    required double totalRevenue,
    required int totalOrders,
    required int totalItemsSold,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> transactionItems,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    // Build item map for lookup
    final Map<int, List<Map<String, dynamic>>> itemsByTxId = {};
    for (final item in transactionItems) {
      final txId = (item['transaction_id'] as num?)?.toInt() ?? 0;
      itemsByTxId.putIfAbsent(txId, () => []).add(item);
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context ctx) => [
          // ── HEADER ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TANJOSU POS',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#4CAF50'),
                    ),
                  ),
                  pw.Text(
                    'Laporan Transaksi · $periodLabel',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Tanggal Cetak:',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    _dateFmt.format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColor.fromHex('#4CAF50'), thickness: 1.5),
          pw.SizedBox(height: 16),

          // ── RINGKASAN ──
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _pdfSummaryCard('Total Pendapatan', _fmt.format(totalRevenue), PdfColor.fromHex('#4CAF50')),
              pw.SizedBox(width: 12),
              _pdfSummaryCard('Total Transaksi', '$totalOrders Order', PdfColor.fromHex('#2196F3')),
              pw.SizedBox(width: 12),
              _pdfSummaryCard('Item Terjual', '$totalItemsSold Pcs', PdfColor.fromHex('#FF9800')),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── TABEL TRANSAKSI ──
          pw.Text(
            'Detail Transaksi',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          if (transactions.isEmpty)
            pw.Center(
              child: pw.Text(
                'Tidak ada transaksi pada periode ini.',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.center,
              },
              headers: ['ID', 'Waktu', 'Pelanggan', 'Item', 'Metode', 'Total', 'Status'],
              data: transactions.map((tx) {
                final txId = (tx['id'] as num?)?.toInt() ?? 0;
                final items = itemsByTxId[txId] ?? [];
                final itemStr = items.map((i) => '${i['product_name']} (x${i['quantity']})').join(', ');
                String time = '--:--';
                if (tx['created_at'] != null) {
                  try {
                    time = DateFormat('HH:mm').format(DateTime.parse(tx['created_at'].toString()).toLocal());
                  } catch (_) {}
                }
                return [
                  '#TJN-$txId',
                  time,
                  tx['customer_name']?.toString().trim().isEmpty ?? true ? 'Umum' : tx['customer_name'],
                  itemStr.isEmpty ? '-' : itemStr,
                  tx['payment_method'] ?? 'Tunai',
                  _fmt.format(tx['total_price'] ?? 0),
                  tx['status'] ?? '-',
                ];
              }).toList(),
            ),
        ],
        footer: (pw.Context ctx) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tanjosu POS · Laporan dibuat otomatis',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Tanjosu_$periodLabel.pdf',
    );
  }

  static pw.Widget _pdfSummaryCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EXCEL EXPORT
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> buildExcelBytes({
    required double totalRevenue,
    required int totalOrders,
    required int totalItemsSold,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> transactionItems,
    required String periodLabel,
  }) async {
    final excel = Excel.createExcel();

    // ── SHEET 1: RINGKASAN ──
    final Sheet summarySheet = excel['Ringkasan'];
    excel.setDefaultSheet('Ringkasan');

    _excelCell(summarySheet, 0, 0, 'LAPORAN TANJOSU POS', isBold: true, fontSize: 14);
    _excelCell(summarySheet, 1, 0, 'Periode: $periodLabel');
    _excelCell(summarySheet, 2, 0, 'Dicetak: ${_dateFmt.format(DateTime.now())}');
    _excelCell(summarySheet, 3, 0, '');

    _excelCell(summarySheet, 4, 0, 'RINGKASAN', isBold: true);
    _excelCell(summarySheet, 5, 0, 'Total Pendapatan', isBold: true);
    _excelCell(summarySheet, 5, 1, totalRevenue);
    _excelCell(summarySheet, 6, 0, 'Total Transaksi', isBold: true);
    _excelCell(summarySheet, 6, 1, totalOrders);
    _excelCell(summarySheet, 7, 0, 'Total Item Terjual', isBold: true);
    _excelCell(summarySheet, 7, 1, totalItemsSold);

    // Set column widths (approximate)
    summarySheet.setColumnWidth(0, 25);
    summarySheet.setColumnWidth(1, 20);

    // ── SHEET 2: DETAIL TRANSAKSI ──
    final Sheet txSheet = excel['Detail Transaksi'];

    // Build item map
    final Map<int, List<Map<String, dynamic>>> itemsByTxId = {};
    for (final item in transactionItems) {
      final txId = (item['transaction_id'] as num?)?.toInt() ?? 0;
      itemsByTxId.putIfAbsent(txId, () => []).add(item);
    }

    // Header
    final headers = ['ID Transaksi', 'Tanggal', 'Waktu', 'Pelanggan', 'Item Dibeli', 'Metode Pembayaran', 'Total (Rp)', 'Status'];
    for (int i = 0; i < headers.length; i++) {
      _excelCell(txSheet, 0, i, headers[i], isBold: true);
    }

    // Data rows
    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final txId = (tx['id'] as num?)?.toInt() ?? 0;
      final items = itemsByTxId[txId] ?? [];
      final itemStr = items.map((it) => '${it['product_name']} (x${it['quantity']})').join(', ');

      String dateStr = '';
      String timeStr = '';
      if (tx['created_at'] != null) {
        try {
          final dt = DateTime.parse(tx['created_at'].toString()).toLocal();
          dateStr = DateFormat('dd/MM/yyyy').format(dt);
          timeStr = DateFormat('HH:mm').format(dt);
        } catch (_) {}
      }

      final rowIdx = i + 1;
      _excelCell(txSheet, rowIdx, 0, '#TJN-$txId');
      _excelCell(txSheet, rowIdx, 1, dateStr);
      _excelCell(txSheet, rowIdx, 2, timeStr);
      _excelCell(txSheet, rowIdx, 3, tx['customer_name']?.toString().trim().isEmpty ?? true ? 'Umum' : (tx['customer_name'] ?? 'Umum'));
      _excelCell(txSheet, rowIdx, 4, itemStr.isEmpty ? '-' : itemStr);
      _excelCell(txSheet, rowIdx, 5, tx['payment_method'] ?? 'Tunai');
      _excelCell(txSheet, rowIdx, 6, (tx['total_price'] as num?)?.toDouble() ?? 0.0);
      _excelCell(txSheet, rowIdx, 7, tx['status'] ?? '-');
    }

    // Column widths
    txSheet.setColumnWidth(0, 16);
    txSheet.setColumnWidth(1, 14);
    txSheet.setColumnWidth(2, 10);
    txSheet.setColumnWidth(3, 18);
    txSheet.setColumnWidth(4, 40);
    txSheet.setColumnWidth(5, 18);
    txSheet.setColumnWidth(6, 16);
    txSheet.setColumnWidth(7, 14);

    // Remove default Sheet1 if it exists
    excel.delete('Sheet1');

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  static void _excelCell(
    Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool isBold = false,
    double? fontSize,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is double || value is int) {
      cell.value = DoubleCellValue(value is int ? value.toDouble() : value);
    } else {
      cell.value = TextCellValue(value?.toString() ?? '');
    }
    cell.cellStyle = CellStyle(
      bold: isBold,
      fontSize: fontSize?.toInt(),
    );
  }
}
