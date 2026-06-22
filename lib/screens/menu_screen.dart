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
  String _searchQuery = ''; // 🔍 STATE PENCARIAN
  final _searchController = TextEditingController(); // CONTROLLER SEARCH BAR
  final _supabase = Supabase.instance.client;

  final List<String> _uiCategories = [
    'ALL', 'KHS', 'Coklat', 'Green Tea', 'Milo', 'Taro', 
    'Alpukat', 'Strawberry', 'Durian', 'Mangga', 
    'Tiramisu', 'Vanila X Red Velvet', 'Traditional Series', 'Drinks',
    'Mojito Series', 'Sticky Rice', 'Tea Series', 'Campur'
  ];

  // FUNGSI WARNA PASTEL MEWAH
  Color _getPastelColor(String category) {
    switch (category.toLowerCase()) {
      case 'coklat': return const Color(0xFFF5E6D3);
      case 'khs': return const Color(0xFFE8F5E9);
      case 'green tea': return const Color(0xFFE0F2F1);
      case 'milo': return const Color(0xFFECEFF1);
      case 'taro': return const Color(0xFFF3E5F5);
      case 'alpukat': return const Color(0xFFF1F8E9);
      case 'strawberry': return const Color(0xFFFFEBEE);
      case 'durian': return const Color(0xFFFFFDE7);
      case 'mangga': return const Color(0xFFFFF3E0);
      case 'mojito series': 
      case 'drinks':
      case 'tea series': return const Color(0xFFE1F5FE);
      case 'sticky rice': return const Color(0xFFFAFAFA);
      default: return AppColors.surfaceContainerHigh;
    }
  }

  // FUNGSI EMOJI DINAMIS
  String _getEmoji(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('coklat')) return '🍫';
    if (cat.contains('strawberry')) return '🍓';
    if (cat.contains('mangga')) return '🥭';
    if (cat.contains('alpukat')) return '🥑';
    if (cat.contains('mojito')) return '🍹';
    if (cat.contains('tea')) return '🍵';
    if (cat.contains('pudding')) return '🍮';
    return '✨';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                    const SizedBox(height: 12),
                    TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [..._uiCategories.where((c) => c != 'ALL')].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setStateModal(() => category = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final data = {'name': nameCtrl.text, 'price': int.tryParse(priceCtrl.text) ?? 0, 'category': category, 'stock': isEditing ? productRaw['stock'] : 50};
                    if (isEditing) await _supabase.from('product').update(data).eq('id', productRaw['id']);
                    else await _supabase.from('product').insert(data);
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

  void _confirmDelete(Map<String, dynamic> productRaw) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Yakin ingin menghapus ${productRaw['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () async {
            await _supabase.from('product').delete().eq('id', productRaw['id']);
            if (mounted) Navigator.pop(ctx);
          }, child: const Text('Hapus', style: TextStyle(color: Colors.red))),
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
            
            // ==================== HEADER + SEARCH BAR ROW ====================
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar Menu Produk', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 4),
                      Text('Kelola menu penjualan kasir secara real-time', style: AppTextStyles.bodySm),
                    ],
                  ),
                  
                  // SEARCH BAR & BUTTON ROW
                  Row(
                    children: [
                      SizedBox(
                        width: 280,
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama produk...',
                            hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            fillColor: AppColors.surfaceContainerLowest, // ✅ FIXED: Menggunakan fillColor
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // TOMBOL TAMBAH PRODUK
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => _showProductDialog(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // ==================== FILTER KATEGORI (CHIPS) ====================
            SizedBox(
              height: 50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _uiCategories.length,
                itemBuilder: (context, index) {
                  final cat = _uiCategories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : AppColors.outlineVariant.withOpacity(0.4)
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ==================== STREAM & GRID VIEW DATA ====================
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('product').stream(primaryKey: ['id']).order('name'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  // FILTER LOGIC
                  final filteredProducts = snapshot.data!.where((p) {
                    final nameMatches = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                    
                    if (_selectedCategory == 'ALL') {
                      return nameMatches;
                    }
                    final categoryMatches = p['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
                    return nameMatches && categoryMatches;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            'Menu tidak ditemukan...',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // CONTAINER EMOJI MEWAH
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                color: _getPastelColor(p['category'] ?? ''),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Center(child: Text(_getEmoji(p['category'] ?? ''), style: const TextStyle(fontSize: 32))),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                p['name'] ?? '', 
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center, // ✅ FIXED: Menggunakan TextAlign.center
                              ),
                            ),
                            Text('Rp ${p['price']}', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showProductDialog(p)),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDelete(p)),
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