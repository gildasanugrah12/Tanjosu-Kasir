import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../widgets/buttons.dart';

class CheckoutBlade extends StatefulWidget {
  final VoidCallback onCheckout;
  final TextEditingController customerNameController;

  const CheckoutBlade({
    super.key,
    required this.onCheckout,
    required this.customerNameController,
  });

  @override
  State<CheckoutBlade> createState() => _CheckoutBladeState();
}

class _CheckoutBladeState extends State<CheckoutBlade> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Text('Pesanan', style: AppTextStyles.headlineSm),
                const Spacer(),
                if (cart.totalItems > 0)
                  GestureDetector(
                    onTap: () => _confirmClear(context, cart),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Bersihkan',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Customer Name Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: widget.customerNameController,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nama Pembeli *',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.customerNameController.text.trim().isEmpty
                        ? AppColors.outlineVariant
                        : AppColors.primary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Order type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _OrderTypeSelector(cart: cart),
          ),
          const SizedBox(height: 16),
          const Divider(indent: 20, endIndent: 20),

          // Cart items
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🧾', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pesanan',
                          style: AppTextStyles.bodySm,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih menu untuk mulai',
                          style: AppTextStyles.labelSm,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemRow(item: item);
                    },
                  ),
          ),

          // Summary & checkout
          if (cart.totalItems > 0) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: currency.format(cart.subtotal)),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'PPN 11%', value: currency.format(cart.taxAmount)),
                  if (cart.discountPercent > 0) ...[
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label: 'Diskon ${cart.discountPercent.toInt()}%',
                      value: '-${currency.format(cart.discountAmount)}',
                      valueColor: AppColors.primary,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('TOTAL', style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      const Spacer(),
                      Text(
                        currency.format(cart.grandTotal),
                        style: AppTextStyles.priceDisplay.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: 'Bayar Sekarang',
                icon: Icons.payment_rounded,
                onPressed: widget.customerNameController.text.trim().isEmpty
                    ? null
                    : widget.onCheckout,
              ),
            ),
          ] else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bersihkan Pesanan?'),
        content: const Text('Semua item dalam keranjang akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cart.clearCart();
      widget.customerNameController.clear();
      setState(() {});
    }
  }
}

class _CartItemRow extends StatelessWidget {
  final dynamic item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(item.product.imageEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currency.format(item.product.price),
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Quantity control
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap: () => cart.removeItem(item.product.id),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap: () => cart.addItem(item.product),
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : AppColors.onSurface,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodySm),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _OrderTypeSelector extends StatelessWidget {
  final CartProvider cart;
  const _OrderTypeSelector({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          _TypeChip(label: 'Dine-in', type: OrderType.dineIn, cart: cart),
          _TypeChip(label: 'Takeaway', type: OrderType.takeaway, cart: cart),
          _TypeChip(label: 'Delivery', type: OrderType.delivery, cart: cart),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final OrderType type;
  final CartProvider cart;

  const _TypeChip({required this.label, required this.type, required this.cart});

  @override
  Widget build(BuildContext context) {
    final isActive = cart.orderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => cart.setOrderType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
