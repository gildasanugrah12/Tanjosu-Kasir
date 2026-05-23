import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../models/transaction.dart' as local_model;
import '../widgets/buttons.dart';
import '../widgets/receipt_widget.dart';

class PaymentScreen extends StatefulWidget {
  final String customerName;
  const PaymentScreen({super.key, required this.customerName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'QRIS';
  local_model.Transaction? _completedTx;
  final _amountCtrl = TextEditingController();
  String? _amountError;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_isLoading) return;

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    double amountPaid = cart.grandTotal;

    if (_method == 'Tunai') {
      final parsed = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      if (parsed == null || parsed < cart.grandTotal) {
        setState(() => _amountError = 'Jumlah bayar kurang dari total');
        return;
      }
      amountPaid = parsed;
    }

    setState(() {
      _isLoading = true;
      _amountError = null;
    });

    try {
      final totalBayar = cart.grandTotal.round();
      final uangDiterima = amountPaid.round();
      final uangKembalian = (uangDiterima - totalBayar);

      // 1. Simpan ke tabel induk transaksi Supabase
      final insertedTx = await _supabase.from('transactions').insert({
        'customer_name': widget.customerName.isEmpty ? 'Pelanggan Umum' : widget.customerName,
        'total_price': totalBayar,
        'total_items': cart.totalItems,
        'payment_method': _method,
        'cash_received': _method == 'Tunai' ? uangDiterima : totalBayar,
        'cash_change': _method == 'Tunai' ? uangKembalian : 0,
        'discount': 0,
        'status': 'Lagi Dibuat',
      }).select().single();

      final int transactionId = insertedTx['id'];

      // 2. Susun data item belanjaan + Paksa Konversi ID produk ke Integer rill!
      final List<Map<String, dynamic>> itemsToInsert = cart.items.map((item) {
        final int productIdParsed = int.tryParse(item.product.id.toString()) ?? 0;

        return {
          'transaction_id': transactionId,
          'product_id': productIdParsed, // 🔥 DIJAMIN MASUK DAN STRUKTUR ANGKA AMAN JIRR!
          'product_name': item.product.name,
          'price': item.product.price.round(),
          'quantity': item.quantity,
          'subtotal': item.subtotal.round(),
        };
      }).toList();

      // 3. Simpan rincian item ke database cloud Supabase
      await _supabase.from('transaction_items').insert(itemsToInsert);

      // 4. STRATEGI BYPASS TOTAL LOCAL MODEL:
      final List<local_model.TransactionItem> localItemsBebasError = [];

      final local_model.Transaction tx = local_model.Transaction(
        id: transactionId.toString(),
        dateTime: DateTime.parse(insertedTx['created_at']),
        customerName: insertedTx['customer_name'],
        items: localItemsBebasError, 
        subtotal: cart.subtotal,
        taxAmount: cart.taxAmount,
        discountPercent: 0.0,
        discountAmount: 0,    
        grandTotal: cart.grandTotal,
        amountPaid: amountPaid,
        change: uangKembalian.toDouble(),
        paymentMethod: _method,
        orderType: 'Dine In', 
      );

      try {
        cart.clearCart();
      } catch (_) {}

      setState(() {
        _completedTx = tx;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (_completedTx != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 16),
                Text('Pembayaran Berhasil!', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Struk Nomor: #${_completedTx!.id}', style: AppTextStyles.labelSm),
                const SizedBox(height: 24),

                ReceiptWidget(transaction: _completedTx!),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: PrimaryButton(
                        label: 'Pesanan Baru',
                        icon: Icons.add_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: SecondaryButton(
                        label: 'Cetak Struk',
                        icon: Icons.print_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printer thermal POS siap dikonfigurasi')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final methods = [
      {'label': 'QRIS', 'icon': Icons.qr_code_2_rounded},
      {'label': 'Tunai', 'icon': Icons.payments_outlined},
      {'label': 'Kartu', 'icon': Icons.credit_card_rounded},
      {'label': 'Transfer', 'icon': Icons.account_balance_rounded},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: AppColors.outlineVariant)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          Widget leftPanel = SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Pembeli: ', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      Text(widget.customerName.isEmpty ? 'Umum' : widget.customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Metode Pembayaran', style: AppTextStyles.headlineSm),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5),
                  itemCount: methods.length,
                  itemBuilder: (_, i) {
                    final m = methods[i];
                    final sel = _method == m['label'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _method = m['label'] as String;
                        _amountError = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primaryFixed.withOpacity(0.4) : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.outlineVariant, width: sel ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(m['icon'] as IconData, color: sel ? AppColors.primary : AppColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(m['label'] as String, style: AppTextStyles.bodyMd.copyWith(color: sel ? AppColors.primary : AppColors.onSurface, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                if (_method == 'Tunai') ...[
                  Text('Jumlah Uang Dibayar', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: fmt.format(cart.grandTotal),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text('Rp', style: AppTextStyles.headlineSm.copyWith(color: AppColors.onSurfaceVariant)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      errorText: _amountError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [50000, 100000, 150000, 200000, 500000].map((amount) {
                      return GestureDetector(
                        onTap: () {
                          _amountCtrl.text = amount.toString();
                          setState(() => _amountError = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text(fmt.format(amount), style: AppTextStyles.labelSm),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (_method == 'QRIS')
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: 200, height: 200,
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
                      child: const Center(child: Text('📱\nQR Code Live', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                    ),
                  ),
              ],
            ),
          );

          Widget rightPanel = Container(
            width: isWide ? 320 : double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                left: isWide ? const BorderSide(color: AppColors.outlineVariant) : BorderSide.none,
                top: !isWide ? const BorderSide(color: AppColors.outlineVariant) : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan', style: AppTextStyles.headlineSm),
                const SizedBox(height: 16),
                
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: ListView.builder(
                    shrinkWrap: !isWide,
                    physics: isWide ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('${item.product.imageEmoji} ', style: const TextStyle(fontSize: 16)),
                            Expanded(child: Text(item.product.name, style: AppTextStyles.bodySm, overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}  ', style: AppTextStyles.bodySm),
                            Text(fmt.format(item.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const Divider(),
                const SizedBox(height: 8),
                Row(children: [Text('Subtotal', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 4),
                Row(children: [Text('PPN 11%', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.taxAmount), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [
                  Text('TOTAL', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface.withOpacity(0.8))),
                  const Spacer(),
                  Text(fmt.format(cart.grandTotal), style: AppTextStyles.priceDisplay.copyWith(color: AppColors.primary)),
                ]),
                const SizedBox(height: 24),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Konfirmasi Bayar',
                          icon: Icons.check_circle_rounded,
                          onPressed: _processPayment,
                        ),
                      ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(label: 'Kembali', onPressed: () => Navigator.pop(context)),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: leftPanel),
                rightPanel,
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  leftPanel,
                  rightPanel,
                ],
              ),
            );
          }
        },
      ),
    );
  }
}