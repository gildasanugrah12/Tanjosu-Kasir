import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/cart_item.dart';
import 'cart_provider.dart';
import 'stock_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  int _counter = 8; // mulai dari 9 karena dummy history sudah 1-8

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  String _generateId() {
    _counter++;
    return '#TJN-${_counter.toString().padLeft(3, '0')}';
  }

  Transaction createTransaction({
    required String customerName,
    required List<CartItem> cartItems,
    required double subtotal,
    required double discountPercent,
    required double discountAmount,
    required double taxAmount,
    required double grandTotal,
    required double amountPaid,
    required String paymentMethod,
    required String orderType,
  }) {
    final tx = Transaction(
      id: _generateId(),
      customerName: customerName,
      dateTime: DateTime.now(),
      items: cartItems.map((c) => TransactionItem.fromCartItem(c)).toList(),
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      amountPaid: amountPaid,
      change: amountPaid - grandTotal,
      paymentMethod: paymentMethod,
      orderType: orderType,
    );

    _transactions.insert(0, tx);
    notifyListeners();
    return tx;
  }

  /// Proses lengkap: buat transaksi + kurangi stok + bersihkan keranjang
  Transaction checkout({
    required String customerName,
    required CartProvider cart,
    required StockProvider stockProvider,
    required double amountPaid,
    required String paymentMethod,
  }) {
    final tx = createTransaction(
      customerName: customerName,
      cartItems: cart.items,
      subtotal: cart.subtotal,
      discountPercent: cart.discountPercent,
      discountAmount: cart.discountAmount,
      taxAmount: cart.taxAmount,
      grandTotal: cart.grandTotal,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      orderType: cart.orderType.name,
    );

    // Kurangi stok
    for (var item in cart.items) {
      stockProvider.adjustStock(item.product.id, -item.quantity);
    }

    cart.clearCart();
    return tx;
  }
}
