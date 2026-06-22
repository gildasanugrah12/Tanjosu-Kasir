import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class StockProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // 🟢 AMAN: Kita default-kan isi list-nya ke buildDummyProducts() dulu, 
  // jadi pas aplikasi pertama loading, UI gak bakal kosong melompong!
  List<Product> _products = buildDummyProducts();
  bool _isLoading = false;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.stock <= p.minStock).toList();

  List<Product> getCategories(String category) {
    if (category == 'ALL' || category.toUpperCase() == 'SEMUA') return products;
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // 🟢 AMBIL DATA REAL-TIME DARI TABEL 'products' SUPABASE
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> response = await _supabase
          .from('products') // ⚡ Sesuai nama tabel asli di database lu (pake s)
          .select()
          .order('id', ascending: true);

      // Jika response dari Supabase ada isinya, mari kita timpa data dummynya
      if (response != null && response.isNotEmpty) {
        _products = response.map<Product>((data) {
          return Product(
            // Mengamankan ID: di-convert dengan aman ke String
            id: data['id']?.toString() ?? '', 
            
            // Antisipasi nama kolom nama produk di DB lu
            name: data['name'] ?? data['product_name'] ?? 'Menu Tanpa Nama',
            
            category: data['category'] ?? 'Campur',
            
            price: (data['price'] as num? ?? 0).toDouble(),
            
            // Antisipasi nama kolom emoji di DB lu
            imageEmoji: data['image_emoji'] ?? data['emoji'] ?? data['image_url'] ?? '🍵', 
            
            description: data['description'] ?? '',
            
            isAvailable: data['is_available'] as bool? ?? true,
            
            stock: (data['stock'] as num? ?? 0).toInt(),
            
            minStock: (data['min_stock'] as num? ?? data['minStock'] as num? ?? 10).toInt(),
          );
        }).toList();
        
        debugPrint("⚡ BERHASIL MEMUAT ${_products.length} PRODUK DARI SUPABASE REAL-TIME!");
      }
    } catch (e) {
      // 🟡 KUNCI PENYELAMAT: Kalau Supabase error/kolom beda, aplikasi gak bakal ngeblank putih,
      // tapi tetep nampilin data dummy bawaan file product.dart lu!
      debugPrint("🚨 Error fetchProducts dari Supabase: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🟢 POTONG STATE LOKAL SETELAH CHECKOUT BIAR KASIR INSTAN BERUBAH
  void adjustStock(String id, int delta) {
    final index = _products.indexWhere((p) => p.id.toString() == id.toString());
    if (index >= 0) {
      final currentStock = _products[index].stock;
      final newStock = currentStock + delta;
      if (newStock >= 0) {
        _products[index].stock = newStock;
        notifyListeners();
      }
    }
  }

  // 🟢 UPDATE STOK MANUAL DARI TOMBOL + / - DI HALAMAN MANAJEMEN STOK
  Future<void> setStock(String id, int newQty) async {
    final index = _products.indexWhere((p) => p.id.toString() == id.toString());
    if (index >= 0 && newQty >= 0) {
      try {
        final int productIdParsed = int.tryParse(id.toString()) ?? 0;
        await _supabase
            .from('products')
            .update({'stock': newQty})
            .eq('id', productIdParsed);
            
        _products[index].stock = newQty;
        notifyListeners();
      } catch (e) {
        debugPrint("🚨 Gagal update stok manual ke Supabase: $e");
      }
    }
  }

  bool checkAvailability(String id, int requiredQty) {
    final index = _products.indexWhere((p) => p.id.toString() == id.toString());
    if (index >= 0) {
      return _products[index].stock >= requiredQty;
    }
    return false;
  }
}