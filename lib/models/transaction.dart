import 'cart_item.dart';

class Transaction {
  final String id;
  final String customerName;
  final DateTime dateTime;
  final List<TransactionItem> items;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final double amountPaid;
  final double change;
  final String paymentMethod;
  final String orderType;

  const Transaction({
    required this.id,
    required this.customerName,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.orderType,
  });
}

class TransactionItem {
  final String name;
  final String emoji;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const TransactionItem({
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory TransactionItem.fromCartItem(CartItem cartItem) {
    return TransactionItem(
      name: cartItem.product.name,
      emoji: cartItem.product.imageEmoji,
      quantity: cartItem.quantity,
      unitPrice: cartItem.product.price,
      subtotal: cartItem.subtotal,
    );
  }
}
