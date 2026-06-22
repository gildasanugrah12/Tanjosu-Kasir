import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🟢 AKSES DB SUPABASE
import '../models/product.dart';
import '../models/cart_item.dart';
import 'stock_provider.dart';

enum OrderType { dineIn, takeaway, delivery }

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  OrderType _orderType = OrderType.dineIn;
  String _tableNumber = 'T-01';
  double _discountPercent = 0;
  
  // Instance supabase client
  final _supabase = Supabase.instance.client; // 🟢 CLIENT SUPABASE

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

  // 🔥 FIX TOTAL 100%: MENEMBAK TABEL 'products' DAN PARSING ID INTEGER
  Future<bool> checkout(StockProvider stockProvider) async {
    if (_items.isEmpty) return false;

    try {
      // 1. Looping semua item yang dibeli kasir di dalam keranjang
      for (var item in _items) {
        // Ubah ID produk ke Integer agar sesuai dengan tipe data int8 di Supabase
        final int productIdParsed = int.tryParse(item.product.id.toString()) ?? 0;

        // Ambil stok real-time paling update dari DB dulu untuk produk ini
        final productData = await _supabase
            .from('products') // 🟢 FIXED: Sekarang nembak ke 'products' (pake s) sesuai DB lu!
            .select('stock')
            .eq('id', productIdParsed) 
            .single();

        final currentStock = (productData['stock'] as num? ?? 0).toInt();
        final newStock = currentStock - item.quantity;

        // Update stok terpotongnya langsung ke tabel products Supabase
        await _supabase
            .from('products') // 🟢 FIXED: Pakai 'products' (pake s) juga di sini!
            .update({'stock': newStock})
            .eq('id', productIdParsed); 

        // Update state lokal biar UI kasir yang lagi kebuka ikut berubah instan
        stockProvider.adjustStock(item.product.id, -item.quantity);
      }

      // 2. Kosongkan keranjang setelah semua stok sukses terpotong di cloud
      clearCart();
      return true; // Berhasil slebeww rill
    } catch (e) {
      // Kalau ada error, bakal keliatan jelas di debug console teks aslinya apa
      debugPrint("🚨 ERROR GAGAL COBA POTONG STOK SUPABASE: $e");
      return false; // Gagal transaksi
    }
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