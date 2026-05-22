import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import 'stock_provider.dart';
enum OrderType { dineIn, takeaway, delivery }

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  OrderType _orderType = OrderType.dineIn;
  String _tableNumber = 'T-01';
  double _discountPercent = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  OrderType get orderType => _orderType;
  String get tableNumber => _tableNumber;
  double get discountPercent => _discountPercent;

  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);

  double get discountAmount => subtotal * (_discountPercent / 100);

  double get taxAmount => (subtotal - discountAmount) * 0.11; // PPN 11%

  double get grandTotal => subtotal - discountAmount + taxAmount;

  bool hasItem(String productId) =>
      _items.any((i) => i.product.id == productId);

  int getQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  void addItem(Product product) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void deleteItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discountPercent = 0;
    _tableNumber = 'T-01';
    _orderType = OrderType.dineIn;
    notifyListeners();
  }

  void checkout(StockProvider stockProvider) {
    for (var item in _items) {
      stockProvider.adjustStock(item.product.id, -item.quantity);
    }
    clearCart();
  }

  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  void setTableNumber(String table) {
    _tableNumber = table;
    notifyListeners();
  }

  void setDiscount(double percent) {
    _discountPercent = percent;
    notifyListeners();
  }
}
