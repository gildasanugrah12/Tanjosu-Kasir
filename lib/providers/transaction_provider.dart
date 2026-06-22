import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PAKAI IMPORT ABSOLUT BIAR FLUTTER GAK BINGUNG NYARI FILE
import 'package:tanjosu_pos/models/transaction.dart';
import 'package:tanjosu_pos/models/cart_item.dart';
import 'package:tanjosu_pos/providers/cart_provider.dart';
import 'package:tanjosu_pos/providers/stock_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  int _counter = 8;

  final _supabase = Supabase.instance.client;

  TransactionProvider() {
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

  Future<Transaction> checkout({
    required String customerName,
    required CartProvider cart,
    required StockProvider stockProvider,
    required double amountPaid,
    required String paymentMethod,
  }) async {
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

    try {
      if (kDebugMode) print("🌐 [SUPABASE] Memulai upload transaksi ke database...");

      final txInsertResponse = await _supabase.from('transactions').insert({
        'customer_name': tx.customerName,
        'subtotal': tx.subtotal,
        'discount_percent': tx.discountPercent,
        'discount_amount': tx.discountAmount,
        'tax_amount': tx.taxAmount,
        'total_price': tx.grandTotal,
        'amount_paid': tx.amountPaid,
        'payment_method': tx.paymentMethod,
        'order_type': tx.orderType,
        'status': tx.status,
      }).select().single();

      final String dbTransactionId = txInsertResponse['id'].toString();

      for (var item in cart.items) {
        await _supabase.from('transaction_items').insert({
          'transaction_id': int.tryParse(dbTransactionId) ?? dbTransactionId,
          'product_name': item.product.name,
          'price': item.product.price.toInt(),
          'quantity': item.quantity,
          'subtotal': (item.product.price * item.quantity).toInt(),
          'product_id': int.tryParse(item.product.id) ?? 0,
        });
      }

      if (kDebugMode) print("🚀 [SUPABASE] Transaksi & Detail Items sukses disimpan!");

      for (var item in cart.items) {
        await _supabase.from('dapur').insert({
          'item_name': item.product.name,
          'quantity': item.quantity,
          'status': 'Memasak',
          'notes': '', 
        });
      }
      
    } catch (e) {
      if (kDebugMode) print("❌ [CHECKOUT ERROR] Gagal sinkronisasi Supabase: $e");
    }

    for (var item in cart.items) {
      stockProvider.adjustStock(item.product.id, -item.quantity);
    }

    cart.clearCart();
    
    return tx;
  }
}