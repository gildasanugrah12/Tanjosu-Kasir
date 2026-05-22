import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
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
  Transaction? _completedTx;
  final _amountCtrl = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _processPayment() {
    final cart = context.read<CartProvider>();
    final stockProvider = context.read<StockProvider>();
    final txProvider = context.read<TransactionProvider>();

    double amountPaid = cart.grandTotal;

    if (_method == 'Tunai') {
      final parsed = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      if (parsed == null || parsed < cart.grandTotal) {
        setState(() => _amountError = 'Jumlah bayar kurang dari total');
        return;
      }
      amountPaid = parsed;
    }

    final tx = txProvider.checkout(
      customerName: widget.customerName,
      cart: cart,
      stockProvider: stockProvider,
      amountPaid: amountPaid,
      paymentMethod: _method,
    );

    setState(() {
      _completedTx = tx;
      _amountError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // ── Struk Belanja (setelah bayar) ──
    if (_completedTx != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success badge
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 16),
                Text('Pembayaran Berhasil!', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Struk transaksi ${_completedTx!.id}', style: AppTextStyles.labelSm),
                const SizedBox(height: 24),

                // Receipt
                ReceiptWidget(transaction: _completedTx!),

                const SizedBox(height: 32),
                // Actions
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
                            const SnackBar(content: Text('Demo: Fitur cetak akan terhubung ke printer thermal')),
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

    // ── Halaman Pembayaran ──
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

          Widget leftPanel = Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info badge
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
                        Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Pembeli: ', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(widget.customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
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

                  // Cash amount input
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
                    // Quick amount chips
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
                        width: 200, height: 200,
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
                        child: const Center(child: Text('📱\nQR Code', textAlign: TextAlign.center, style: TextStyle(fontSize: 36))),
                      ),
                    ),
                ],
              ),
            ),
          );

          Widget rightPanel = Container(
            width: isWide ? 300 : double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest, 
              border: Border(
                left: isWide ? const BorderSide(color: AppColors.outlineVariant) : BorderSide.none,
                top: !isWide ? const BorderSide(color: AppColors.outlineVariant) : BorderSide.none,
              )
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Text('Ringkasan', style: AppTextStyles.headlineSm),
                const SizedBox(height: 16),
                if (isWide)
                  Expanded(
                    child: ListView.builder(
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
                              Text(fmt.format(item.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('${item.product.imageEmoji} ', style: const TextStyle(fontSize: 16)),
                            Expanded(child: Text(item.product.name, style: AppTextStyles.bodySm, overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}  ', style: AppTextStyles.bodySm),
                            Text(fmt.format(item.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                          ],
                        ),
                      )).toList(),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [Text('Subtotal', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.subtotal), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 4),
                Row(children: [Text('PPN 11%', style: AppTextStyles.bodySm), const Spacer(), Text(fmt.format(cart.taxAmount), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [
                  Text('TOTAL', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(fmt.format(cart.grandTotal), style: AppTextStyles.priceDisplay.copyWith(color: AppColors.primary)),
                ]),
                if (isWide) const Spacer() else const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Konfirmasi Bayar',
                  icon: Icons.check_circle_rounded,
                  onPressed: _processPayment,
                ),
                const SizedBox(height: 12),
                SecondaryButton(label: 'Kembali', onPressed: () => Navigator.pop(context)),
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: leftPanel),
                rightPanel,
              ],
            );
          } else {
            return SingleChildScrollView(
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    leftPanel,
                    rightPanel,
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
