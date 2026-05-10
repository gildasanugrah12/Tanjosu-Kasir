import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../widgets/buttons.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'QRIS';
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (_isPaid) {
      return Scaffold(
        body: Container(
          color: AppColors.background,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: const Center(child: Text('✅', style: TextStyle(fontSize: 56))),
                ),
                const SizedBox(height: 24),
                Text('Pembayaran Berhasil!', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Terima kasih telah berbelanja', style: AppTextStyles.bodyMd),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  child: PrimaryButton(
                    label: 'Pesanan Baru',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      context.read<CartProvider>().clearCart();
                      Navigator.of(context).pop();
                    },
                  ),
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
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onTap: () => setState(() => _method = m['label'] as String),
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
          ),
          Container(
            width: 300,
            decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border(left: BorderSide(color: AppColors.outlineVariant))),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan', style: AppTextStyles.headlineSm),
                const SizedBox(height: 16),
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
                )),
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
                const Spacer(),
                PrimaryButton(label: 'Konfirmasi Bayar', icon: Icons.check_circle_rounded, onPressed: () => setState(() => _isPaid = true)),
                const SizedBox(height: 12),
                SecondaryButton(label: 'Kembali', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
