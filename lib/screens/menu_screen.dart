import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'ALL';
  final _supabase = Supabase.instance.client;

  // Daftar kategori yang disesuaikan dengan tombol Tab di UI Anda
  final List<String> _uiCategories = [
    'ALL', 'KHS', 'Coklat', 'Green Tea', 'Milo', 'Taro', 
    'Alpukat', 'Strawberry', 'Durian', 'Mangga', 
    'Tiramisu', 'Vanila X Red Velvet', 'Traditional Series', 'Drinks',
    'Mojito Series', 'Sticky Rice', 'Tea Series', 'Campur'
  ];

  // Fungsi Tambah & Edit langsung ke Supabase
  void _showProductDialog([Map<String, dynamic>? productRaw]) {
    final isEditing = productRaw != null;
    final nameCtrl = TextEditingController(text: productRaw?['name'] ?? '');
    final priceCtrl = TextEditingController(text: productRaw?['price']?.toString() ?? '');
    String category = productRaw?['category'] ?? 'KHS';

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
                      items: [
                        ..._uiCategories.where((c) => c != 'ALL'),
                        if (!_uiCategories.contains(category)) category,
                      ].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setStateModal(() => category = v!),
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
                  onPressed: () async {
                    final data = {
                      'name': nameCtrl.text,
                      'price': int.tryParse(priceCtrl.text) ?? 0,
                      'category': category,
                      'stock': isEditing ? productRaw['stock'] : 50,
                    };

                    if (isEditing) {
                      await _supabase.from('product').update(data).eq('id', productRaw['id']);
                    } else {
                      await _supabase.from('product').insert(data);
                    }
                    if (mounted) Navigator.pop(ctx);
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

  // Fungsi Hapus langsung ke Supabase
  void _confirmDelete(Map<String, dynamic> productRaw) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Hapus Menu'),
        content: Text('Yakin ingin menghapus ${productRaw['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await _supabase.from('product').delete().eq('id', productRaw['id']);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                        Text('Menampilkan Menu Live dari Supabase', style: AppTextStyles.labelSm),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: Size.zero, // Menimpa lebar default double.infinity dari global theme
                    ),
                    onPressed: () => _showProductDialog(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Tambah Menu', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tabs Kategori
            Container(
              color: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uiCategories.map((cat) {
                  final isActive = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
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
            // Grid View terintegrasi Real-time Stream Supabase
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('product').stream(primaryKey: ['id']).order('name'),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada data produk di database.'));
                  }

                  // Memfilter data berdasarkan kategori tab yang dipilih
                  final allProducts = snapshot.data!;
                  final filteredProducts = allProducts.where((p) {
                    final cat = (p['category'] ?? 'KHS').toString().toLowerCase();
                    if (_selectedCategory == 'ALL') {
                      return true;
                    } else if (_selectedCategory == 'KHS') {
                      return cat.startsWith('khs');
                    } else if (_selectedCategory == 'Drinks') {
                      return cat.startsWith('drinks');
                    } else if (_selectedCategory == 'Vanila X Red Velvet') {
                      return cat.contains('vanila') || cat.contains('velvet');
                    } else if (_selectedCategory == 'Traditional Series') {
                      return cat.contains('tradisional') || cat.contains('traditional');
                    } else if (_selectedCategory == 'Mojito Series') {
                      return cat.contains('mojito');
                    } else if (_selectedCategory == 'Sticky Rice') {
                      return cat.contains('sticky') || cat.contains('rice');
                    } else if (_selectedCategory == 'Tea Series') {
                      return cat.contains('tea');
                    } else {
                      return cat.contains(_selectedCategory.toLowerCase());
                    }
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('Menu pada kategori ini kosong.'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      
                      // Mengatur fallback default icon text/emoji
                      String emojiIcon = '🍵'; 
                      if (p['category'].toString().toLowerCase().contains('coklat')) emojiIcon = '🍫';
                      if (p['category'].toString().toLowerCase().contains('strawberry')) emojiIcon = '🍓';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emojiIcon, style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(p['name'] ?? '', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Rp ${p['price']}', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}