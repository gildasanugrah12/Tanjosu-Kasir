import 'package:flutter/foundation.dart';
import '../models/product.dart';

class StockProvider extends ChangeNotifier {
  final List<Product> _products = buildDummyProducts();

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get lowStockProducts =>
      _products.where((p) => p.stock <= p.minStock).toList();

  List<Product> getCategories(String category) {
    if (category == 'ALL') return products;
    return _products.where((p) => p.category == category).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void adjustStock(String id, int delta) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final currentStock = _products[index].stock;
      final newStock = currentStock + delta;
      if (newStock >= 0) {
        _products[index].stock = newStock;
        notifyListeners();
      }
    }
  }

  void setStock(String id, int newQty) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0 && newQty >= 0) {
      _products[index].stock = newQty;
      notifyListeners();
    }
  }

  bool checkAvailability(String id, int requiredQty) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      return _products[index].stock >= requiredQty;
    }
    return false;
  }
}
