import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/stock_provider.dart';
import '../models/product.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'ALL';

  void _showProductDialog([Product? product]) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toInt().toString() ?? '');
    final emojiCtrl = TextEditingController(text: product?.imageEmoji ?? '🍔');
    String category = product?.category ?? productCategories.firstWhere((c) => c != 'ALL', orElse: () => 'KHS');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceContainerLowest,
              title: Text(isEditing ? 'Edit Menu' : 'Tambah Menu Baru', style: AppTextStyles.headlineSm),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Produk'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: productCategories.where((c) => c != 'ALL').map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setStateModal(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emojiCtrl,
                      decoration: const InputDecoration(labelText: 'Emoji Ikon (cth: 🍵)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () {
                    final newProduct = Product(
                      id: isEditing ? product.id : 'new_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      category: category,
                      price: double.tryParse(priceCtrl.text) ?? 0,
                      imageEmoji: emojiCtrl.text,
                      stock: isEditing ? product.stock : 50,
                      minStock: isEditing ? product.minStock : 10,
                    );

                    if (isEditing) {
                      context.read<StockProvider>().updateProduct(newProduct);
                    } else {
                      context.read<StockProvider>().addProduct(newProduct);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Simpan' : 'Tambah', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Hapus Menu'),
        content: Text('Yakin ingin menghapus ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<StockProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final products = stockProvider.getCategories(_selectedCategory);

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.surfaceContainerLowest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kelola Menu', style: AppTextStyles.headlineMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Total ${stockProvider.products.length} item menu', style: AppTextStyles.labelSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => _showProductDialog(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Tambah Menu', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tabs
          Container(
            color: AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: productCategories.map((cat) {
                final isActive = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      cat,
                      style: AppTextStyles.labelSm.copyWith(
                        color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.imageEmoji, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(p.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Rp ${p.price.toInt()}', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showProductDialog(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                            onPressed: () => _confirmDelete(p),
                          ),
                        ],
                      ),
                    ],
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
