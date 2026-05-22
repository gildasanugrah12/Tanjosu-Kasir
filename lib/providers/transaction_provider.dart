import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/cart_item.dart';
import 'cart_provider.dart';
import 'stock_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  int _counter = 8; // mulai dari 9 karena dummy history sudah 1-8

  TransactionProvider() {
    // Populate dummy transactions to match history and test KDS
    _transactions.addAll([
      Transaction(
        id: '#TJN-008',
        customerName: 'Budi',
        dateTime: DateTime.now().subtract(const Duration(minutes: 5)),
        items: const [
          TransactionItem(name: 'KHS Keju', emoji: '🧀', quantity: 2, unitPrice: 10000, subtotal: 20000),
          TransactionItem(name: 'KHS Coklat Keju', emoji: '🧀', quantity: 1, unitPrice: 14000, subtotal: 14000),
        ],
        subtotal: 34000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 3740,
        grandTotal: 37740,
        amountPaid: 50000,
        change: 12260,
        paymentMethod: 'Kartu',
        orderType: 'Dine-in',
        status: 'Lagi Dibuat',
      ),
      Transaction(
        id: '#TJN-007',
        customerName: 'Siti',
        dateTime: DateTime.now().subtract(const Duration(minutes: 18)),
        items: const [
          TransactionItem(name: 'KHS kelapa', emoji: '🍵', quantity: 3, unitPrice: 8000, subtotal: 24000),
        ],
        subtotal: 24000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 2640,
        grandTotal: 26640,
        amountPaid: 30000,
        change: 3360,
        paymentMethod: 'QRIS',
        orderType: 'Takeaway',
        status: 'Lagi Dibuat',
      ),
      Transaction(
        id: '#TJN-006',
        customerName: 'Amir',
        dateTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
        items: const [
          TransactionItem(name: 'KHS Coklat Crunchy', emoji: '🧇', quantity: 1, unitPrice: 14000, subtotal: 14000),
          TransactionItem(name: 'KHS Tiramisu', emoji: '🍰', quantity: 1, unitPrice: 12000, subtotal: 12000),
        ],
        subtotal: 26000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 2860,
        grandTotal: 28860,
        amountPaid: 30000,
        change: 1140,
        paymentMethod: 'Tunai',
        orderType: 'Dine-in',
        status: 'Selesai',
      ),
      Transaction(
        id: '#TJN-005',
        customerName: 'Dewi',
        dateTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
        items: const [
          TransactionItem(name: 'KHS Alpukat', emoji: '🥑', quantity: 2, unitPrice: 21000, subtotal: 42000),
        ],
        subtotal: 42000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 4620,
        grandTotal: 46620,
        amountPaid: 50000,
        change: 3380,
        paymentMethod: 'Transfer',
        orderType: 'Delivery',
        status: 'Selesai',
      ),
      Transaction(
        id: '#TJN-004',
        customerName: 'Rian',
        dateTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 22)),
        items: const [
          TransactionItem(name: 'KHS Milo Keju', emoji: '🧀', quantity: 4, unitPrice: 14000, subtotal: 56000),
        ],
        subtotal: 56000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 6160,
        grandTotal: 62160,
        amountPaid: 100000,
        change: 37840,
        paymentMethod: 'QRIS',
        orderType: 'Dine-in',
        status: 'Selesai',
      ),
      Transaction(
        id: '#TJN-003',
        customerName: 'Lina',
        dateTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
        items: const [
          TransactionItem(name: 'KHS Durian Keju', emoji: '🧀', quantity: 2, unitPrice: 18000, subtotal: 36000),
        ],
        subtotal: 36000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 3960,
        grandTotal: 39960,
        amountPaid: 50000,
        change: 10040,
        paymentMethod: 'Kartu',
        orderType: 'Takeaway',
        status: 'Selesai',
      ),
      Transaction(
        id: '#TJN-002',
        customerName: 'Eko',
        dateTime: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
        items: const [
          TransactionItem(name: 'KHS Mangga', emoji: '🥭', quantity: 1, unitPrice: 14000, subtotal: 14000),
        ],
        subtotal: 14000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 1540,
        grandTotal: 15540,
        amountPaid: 20000,
        change: 4460,
        paymentMethod: 'Tunai',
        orderType: 'Dine-in',
        status: 'Selesai',
      ),
      Transaction(
        id: '#TJN-001',
        customerName: 'Yanto',
        dateTime: DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
        items: const [
          TransactionItem(name: 'KHS Taro Keju', emoji: '🧀', quantity: 3, unitPrice: 14000, subtotal: 42000),
        ],
        subtotal: 42000,
        discountPercent: 0,
        discountAmount: 0,
        taxAmount: 4620,
        grandTotal: 46620,
        amountPaid: 50000,
        change: 3380,
        paymentMethod: 'QRIS',
        orderType: 'Dine-in',
        status: 'Selesai',
      ),
    ]);
  }

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  int get activeOrdersCount =>
      _transactions.where((tx) => tx.status == 'Lagi Dibuat').length;

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
      status: 'Lagi Dibuat',
    );

    _transactions.insert(0, tx);
    notifyListeners();
    return tx;
  }

  void updateTransactionStatus(String id, String newStatus) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index >= 0) {
      _transactions[index] = _transactions[index].copyWith(status: newStatus);
      notifyListeners();
    }
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
