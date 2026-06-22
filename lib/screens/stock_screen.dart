import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/stock_provider.dart';
import '../models/product.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'Semua';
  String _searchQuery = ''; // 🟢 Taruh query pencarian di sini rill
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 📥 Pop-up Dialog untuk Edit Angka Stok Langsung
  void _showEditStockDialog(BuildContext context, Product product, StockProvider provider) {
    final TextEditingController qtyController = 
        TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Stok ${product.name}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Jumlah Stok Baru',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                int newQty = int.tryParse(qtyController.text) ?? 0;
                provider.setStock(product.id, newQty); // Panggil fungsi bawaan providermu rill
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final products = stockProvider.products;
    final lowStock = stockProvider.lowStockProducts.length;

    // 🟢 Logika filter Kategori + Search digabung langsung di sini jirr!
    List<Product> displayedProducts = products;
    
    // 1. Filter Kategori dulu
    if (_filter == 'Stok Rendah') {
      displayedProducts = products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
    } else if (_filter == 'Habis') {
      displayedProducts = products.where((p) => p.stock <= 0).toList();
    }

    // 2. Kemudian filter berdasarkan ketikan Search Bar
    if (_searchQuery.isNotEmpty) {
      displayedProducts = displayedProducts
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: AppColors.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Manajemen Stok', style: AppTextStyles.headlineMd),
                    const SizedBox(width: 16),
                    if (lowStock > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$lowStock item menipis',
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: ['Semua', 'Stok Rendah', 'Habis'].map((f) {
                    final active = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.labelSm.copyWith(
                              color: active ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // 🟢 SEARCH BAR AMAN BEBAS EROR JIRR
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = ''; // Reset pencarian rill
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    fillColor: AppColors.surfaceContainerLow,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value; // Trigger build ulang otomatis jirr
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minTableWidth = 700.0;
                final tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Table header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('PRODUK', style: AppTextStyles.labelXs)),
                              Expanded(flex: 1, child: Text('KATEGORI', style: AppTextStyles.labelXs)),
                              Expanded(flex: 1, child: Text('STOK', style: AppTextStyles.labelXs, textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('STATUS', style: AppTextStyles.labelXs, textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('AKSI', style: AppTextStyles.labelXs, textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: displayedProducts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = displayedProducts[index];
                              final isLow = p.stock <= p.minStock;
                              final isOut = p.stock <= 0;

                              Color statusColor = AppColors.primary;
                              String statusText = 'Aman';
                              if (isOut) {
                                statusColor = AppColors.error;
                                statusText = 'Habis';
                              } else if (isLow) {
                                statusColor = Colors.orange;
                                statusText = 'Rendah';
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    // Product name
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerLow,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(child: Text(p.imageEmoji, style: const TextStyle(fontSize: 20))),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(p.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    // Category
                                    Expanded(
                                      flex: 1,
                                      child: Text(p.category, style: AppTextStyles.bodySm),
                                    ),
                                    // Angka Stok Bisa Diklik Langsung jirr!
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        onTap: () => _showEditStockDialog(context, p, stockProvider),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${p.stock}',
                                                style: AppTextStyles.headlineSm.copyWith(
                                                  color: isOut ? AppColors.error : AppColors.onSurface,
                                                  decoration: TextDecoration.underline,
                                                  decorationStyle: TextDecorationStyle.dashed,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.edit, size: 14, color: isOut ? AppColors.error.withOpacity(0.6) : AppColors.onSurfaceVariant.withOpacity(0.6)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Status
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(statusText, style: AppTextStyles.labelXs.copyWith(color: statusColor)),
                                        ),
                                      ),
                                    ),
                                    // Actions (+ / -)
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            color: AppColors.onSurfaceVariant,
                                            onPressed: p.stock > 0
                                                ? () => stockProvider.adjustStock(p.id, -1)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            color: AppColors.primary,
                                            onPressed: () => stockProvider.adjustStock(p.id, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}