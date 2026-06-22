import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/stock_provider.dart';
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
    final stockProvider = context.read<StockProvider>();
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

      // 2. Susun data item belanjaan
      final List<Map<String, dynamic>> itemsToInsert = cart.items.map((item) {
        final int productIdParsed = int.tryParse(item.product.id.toString()) ?? 0;

        return {
          'transaction_id': transactionId,
          'product_id': productIdParsed,
          'product_name': item.product.name,
          'price': item.product.price.round(),
          'quantity': item.quantity,
          'subtotal': item.subtotal.round(),
        };
      }).toList();

      // 3. Simpan rincian item ke database cloud Supabase
      await _supabase.from('transaction_items').insert(itemsToInsert);

      // 🔥 3b. SUNTIK KE TABEL DAPUR
      try {
        final List<Map<String, dynamic>> kitchenItemsToInsert = cart.items.map((item) {
          return {
            'transaction_id': transactionId,
            'item_name': item.product.name,
            'quantity': item.quantity,
            'status': 'Memasak',
            'notes': '', 
          };
        }).toList();

        await _supabase.from('dapur').insert(kitchenItemsToInsert);
        print('🎉 DATA BERHASIL MASUK DAPUR JIRR!');
      } catch (kitchenError) {
        print('🚨 EROR TABLE DAPUR RILL: $kitchenError');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.orange, 
                duration: const Duration(seconds: 8),
                content: Text('Dapur Macet Jirr: $kitchenError'),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          });
        }
      }

      // 🔥 3c. SINKRONISASI TOTAL: POTONG STOK & AUTO-REFRESH KEMBALI KE APLIKASI
      try {
        await cart.checkout(stockProvider);
        print('⚡ STOK SUPABASE BERHASIL DIPOTONG SECARA REAL-TIME!');
        
        await stockProvider.fetchProducts();
        print('🔄 STATE STOK PROVIDER LOKAL SELESAI DI-REFRESH DARI SUPABASE CLOUD!');
      } catch (stockError) {
        print('🚨 GAGAL POTONG/REFRESH STOK SUPABASE: $stockError');
      }

      // 4. STRATEGI BYPASS TOTAL LOCAL MODEL
      final List<local_model.TransactionItem> localItemsBebasError = [];

      final local_model.Transaction tx = local_model.Transaction(
        id: transactionId.toString(),
        dateTime: DateTime.parse(insertedTx['created_at']).toLocal(),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  // Helper untuk generate tombol pintasan uang tunai yang adaptif
  List<int> _generateQuickAmounts(double total) {
    int currentTotal = total.round();
    Set<int> quickSet = {currentTotal}; // Tambahkan opsi uang pas
    
    List<int> bases = [10000, 20000, 50000, 100000];
    for (var base in bases) {
      if (base > currentTotal) {
        quickSet.add(base);
      }
    }
    
    // Tambah alternatif kelipatan round up terdekat jika belum penuh
    int roundedUp = ((currentTotal + 9999) ~/ 10000) * 10000;
    quickSet.add(roundedUp);
    quickSet.add(roundedUp + 10000);
    quickSet.add(roundedUp + 50000);

    List<int> sortedList = quickSet.where((element) => element >= currentTotal).toList();
    sortedList.sort();
    return sortedList.take(5).toList(); // Ambil 5 opsi teratas aja biar gak penuh
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
        title: const Text('Konfirmasi Pembayaran'),
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
                // INFO BAR: Status Pelanggan Premium & Rapi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryFixed.withOpacity(0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama Pelanggan / Meja', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                          Text(widget.customerName.isEmpty ? 'Pelanggan Umum (Dine In)' : widget.customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text('Pilih Metode Pembayaran', style: AppTextStyles.headlineSm),
                const SizedBox(height: 16),
                
                // GRID METODE PEMBAYARAN SLIM VERSION
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 12, 
                    mainAxisSpacing: 12, 
                    childAspectRatio: 3.5 // Diperpendek biar gak makan tempat rill!
                  ),
                  itemCount: methods.length,
                  itemBuilder: (_, i) {
                    final m = methods[i];
                    final sel = _method == m['label'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _method = m['label'] as String;
                        _amountError = null;
                        _amountCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primaryFixed.withOpacity(0.25) : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.outlineVariant, width: sel ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(m['icon'] as IconData, color: sel ? AppColors.primary : AppColors.onSurfaceVariant, size: 20),
                            const SizedBox(width: 10),
                            Text(m['label'] as String, style: AppTextStyles.bodyMd.copyWith(color: sel ? AppColors.primary : AppColors.onSurface, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // AREA DINAMIS: BIAR GAK GARING & KOSONG LAGI JIRR
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KONDISI 1: JIKA PILIH TUNAI
                      if (_method == 'Tunai') ...[
                        Text('Jumlah Uang Tunai Diterima', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Rekomendasi Uang Pas / Pecahan:', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _generateQuickAmounts(cart.grandTotal).map((amount) {
                            final isPas = amount == cart.grandTotal.round();
                            return GestureDetector(
                              onTap: () {
                                _amountCtrl.text = amount.toString();
                                setState(() => _amountError = null);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isPas ? AppColors.primaryFixed.withOpacity(0.3) : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isPas ? AppColors.primary : AppColors.outlineVariant),
                                ),
                                child: Text(
                                  isPas ? 'Uang Pas (${fmt.format(amount)})' : fmt.format(amount), 
                                  style: AppTextStyles.labelSm.copyWith(fontWeight: isPas ? FontWeight.bold : FontWeight.normal, color: isPas ? AppColors.primary : AppColors.onSurface)
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // KONDISI 2: JIKA PILIH QRIS
                      if (_method == 'QRIS')
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, size: 140, color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 14),
                              Text('Scan QRIS Dinamis Toko', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Total yang harus discan: ${fmt.format(cart.grandTotal)}', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      // KONDISI 3: JIKA PILIH KARTU / DEBIT
                      if (_method == 'Kartu')
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.credit_card_rounded, size: 64, color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text('Silakan Gesek / Masukkan Kartu pada Mesin EDC', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Pastikan status EDC berhasil sebelum konfirmasi bayar jirr.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
                            ],
                          ),
                        ),

                      // KONDISI 4: JIKA PILIH BANK TRANSFER
                      if (_method == 'Transfer')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rekening Tujuan Transfer Toko:', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('BCA - Tanjosu Cianjur', style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.bold)),
                                      Text('No. Rek: 182-3948-231', style: AppTextStyles.bodySm),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );

          Widget rightPanel = Container(
            width: isWide ? 340 : double.infinity,
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
                Text('Ringkasan Belanja', style: AppTextStyles.headlineSm),
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
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text('${item.product.imageEmoji} ', style: const TextStyle(fontSize: 18)),
                            Expanded(child: Text(item.product.name, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}  ', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                            Text(fmt.format(item.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 24),
                Row(children: [Text('Subtotal', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 6),
                Row(children: [Text('PPN 11%', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.taxAmount), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(children: [
                  Text('TOTAL', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface.withOpacity(0.8), fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(fmt.format(cart.grandTotal), style: AppTextStyles.priceDisplay.copyWith(color: AppColors.primary, fontSize: 24)),
                ]),
                const SizedBox(height: 24),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: PrimaryButton(
                          label: 'Konfirmasi Bayar',
                          icon: Icons.check_circle_rounded,
                          onPressed: _processPayment,
                        ),
                      ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
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