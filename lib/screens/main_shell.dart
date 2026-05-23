import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/checkout_blade.dart';
import '../widgets/side_nav_bar.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'payment_screen.dart';
import 'stock_screen.dart';
import 'menu_screen.dart';
import 'kitchen_screen.dart';

class MainShell extends StatefulWidget {
  final String role; // Menerima data role ('owner' / 'kasir') dari login_screen

  const MainShell({super.key, required this.role});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavItem _activeNav = NavItem.register;
  final _customerNameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final showBlade = _activeNav == NavItem.register;
        
        Widget checkoutBladeWidget = CheckoutBlade(
          customerNameController: _customerNameCtrl,
          onCheckout: () {
            final name = _customerNameCtrl.text.trim();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PaymentScreen(customerName: name)),
            ).then((_) {
              _customerNameCtrl.clear();
              if (!isWide && Navigator.canPop(context)) {
                Navigator.pop(context); // Tutup drawer jika di HP
              }
            });
          },
        );

        return Scaffold(
          body: Row(
            children: [
              // KIRI: Sidebar Navigasi dengan filter hak akses role
              SideNavBar(
                activeItem: _activeNav,
                onItemSelected: (item) {
                  if (widget.role == 'kasir' && 
                      (item == NavItem.dashboard || item == NavItem.stock || item == NavItem.menu)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Akses Ditolak: Menu ini hanya untuk Owner! 🔒')),
                    );
                    return;
                  }
                  setState(() => _activeNav = item);
                },
              ),
              // TENGAH: Workspace Utama
              Expanded(
                child: _buildContent(),
              ),
              // KANAN: Checkout Blade Belanjaan
              if (isWide && showBlade) 
                SizedBox(width: 320, child: checkoutBladeWidget),
            ],
          ),
          endDrawer: (!isWide && showBlade) ? Drawer(
            width: 320,
            child: checkoutBladeWidget,
          ) : null,
          floatingActionButton: (!isWide && showBlade) ? Builder(
            builder: (context) {
              final cartItems = context.watch<CartProvider>().totalItems;
              return FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                label: Text(
                  '$cartItems Item', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              );
            }
          ) : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    if (widget.role == 'kasir' && 
        (_activeNav == NavItem.dashboard || _activeNav == NavItem.stock || _activeNav == NavItem.menu)) {
      return const Scaffold(
        body: Center(
          child: Text('Maaf, halaman ini dikunci untuk akun Kasir.'),
        ),
      );
    }

    switch (_activeNav) {
      case NavItem.register:
        return PosMainCanvas(role: widget.role); 
      case NavItem.history:
        return const HistoryScreen();
      case NavItem.dashboard:
        return const DashboardScreen();
      case NavItem.stock:
        return const StockScreen();
      case NavItem.menu:
        return const MenuScreen();
      case NavItem.dapur:
        return const KitchenScreen();
      case NavItem.settings:
        return const _SettingsPlaceholder();
    }
  }
}

class PosMainCanvas extends StatefulWidget {
  final String role; 

  const PosMainCanvas({super.key, required this.role});

  @override
  State<PosMainCanvas> createState() => _PosMainCanvasState();
}

class _PosMainCanvasState extends State<PosMainCanvas> {
  String _selectedCategory = 'ALL';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _supabase = Supabase.instance.client;

  // Daftar kategori statis penyesuai tab navigasi UI kasir
  final List<String> _uiCategories = [
    'ALL', 'KHS', 'Coklat', 'Green Tea', 'Milo', 'Taro', 
    'Alpukat', 'Strawberry', 'Durian', 'Mangga', 
    'Tiramisu', 'Vanila X Red Velvet', 'Traditional Series', 'Drinks',
    'Mojito Series', 'Sticky Rice', 'Tea Series', 'Campur'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          _buildCategoryTabs(),
          // Menggunakan StreamBuilder Real-time Supabase agar data langsung sinkron
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
                  return const Center(child: Text('Belum ada produk di database.'));
                }

                // Transformasi data raw Map dari Supabase menjadi Object Model Product Flutter kamu
                final dummyList = buildDummyProducts();
                final allProducts = snapshot.data!.map((map) {
                  final String name = map['name'] ?? '';
                  final String category = map['category'] ?? 'Minuman';
                  
                  // Cari emoji yang cocok dari dummy data berdasarkan nama
                  String matchedEmoji = '🍵';
                  try {
                    final matchedDummy = dummyList.firstWhere(
                      (d) => d.name.toLowerCase() == name.toLowerCase(),
                    );
                    matchedEmoji = matchedDummy.imageEmoji;
                  } catch (_) {
                    // Fallback berdasarkan kategori jika nama tidak cocok secara presisi
                    final catLower = category.toLowerCase();
                    if (catLower.contains('coklat')) {
                      matchedEmoji = '🍫';
                    } else if (catLower.contains('keju')) {
                      matchedEmoji = '🧀';
                    } else if (catLower.contains('kelapa')) {
                      matchedEmoji = '🍵';
                    } else if (catLower.contains('milo')) {
                      matchedEmoji = '🥤';
                    } else if (catLower.contains('taro')) {
                      matchedEmoji = '🍠';
                    } else if (catLower.contains('alpukat')) {
                      matchedEmoji = '🥑';
                    } else if (catLower.contains('strawberry')) {
                      matchedEmoji = '🍓';
                    } else if (catLower.contains('durian')) {
                      matchedEmoji = '🍈';
                    } else if (catLower.contains('mangga')) {
                      matchedEmoji = '🥭';
                    } else if (catLower.contains('tiramisu')) {
                      matchedEmoji = '🍰';
                    } else if (catLower.contains('vanila')) {
                      matchedEmoji = '🍦';
                    } else if (catLower.contains('oncom')) {
                      matchedEmoji = '🍘';
                    } else if (catLower.contains('abon')) {
                      matchedEmoji = '🍗';
                    } else if (catLower.contains('klepon')) {
                      matchedEmoji = '🟢';
                    } else if (catLower.contains('mojito')) {
                      matchedEmoji = '🥤';
                    } else if (catLower.contains('campur')) {
                      matchedEmoji = '🍧';
                    }
                  }

                  return Product(
                    id: map['id'].toString(),
                    name: name,
                    category: category,
                    price: (map['price'] as num).toDouble(),
                    imageEmoji: matchedEmoji,
                    stock: map['stock'] ?? 0,
                    minStock: 10,
                  );
                }).toList();

                // Proses Filter Berdasarkan Pencarian & Tab Kategori
                final filteredProducts = allProducts.where((p) {
                  bool matchCat = false;
                  final cat = p.category.toLowerCase();
                  if (_selectedCategory == 'ALL') {
                    matchCat = true;
                  } else if (_selectedCategory == 'KHS') {
                    matchCat = cat.startsWith('khs');
                  } else if (_selectedCategory == 'Drinks') {
                    matchCat = cat.startsWith('drinks');
                  } else if (_selectedCategory == 'Vanila X Red Velvet') {
                    matchCat = cat.contains('vanila') || cat.contains('velvet');
                  } else if (_selectedCategory == 'Traditional Series') {
                    matchCat = cat.contains('tradisional') || cat.contains('traditional');
                  } else if (_selectedCategory == 'Mojito Series') {
                    matchCat = cat.contains('mojito');
                  } else if (_selectedCategory == 'Sticky Rice') {
                    matchCat = cat.contains('sticky') || cat.contains('rice');
                  } else if (_selectedCategory == 'Tea Series') {
                    matchCat = cat.contains('tea');
                  } else {
                    matchCat = cat.contains(_selectedCategory.toLowerCase());
                  }

                  final matchSearch = _searchQuery.isEmpty ||
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchCat && matchSearch;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada produk menu yang cocok.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) => ProductCard(product: filteredProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    String avatarLetter = widget.role == 'owner' ? 'O' : 'K';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanjosu Cianjur', style: AppTextStyles.headlineSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  _getGreeting(widget.role), 
                  style: AppTextStyles.labelSm,
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari menu...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                avatarLetter, 
                style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary, fontSize: 18)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _uiCategories.map((cat) {
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
    );
  }

  String _getGreeting(String role) {
    final hour = DateTime.now().hour;
    String timeGreeting = 'Pagi';
    if (hour >= 12 && hour < 17) timeGreeting = 'Siang';
    if (hour >= 17) timeGreeting = 'Malam';

    String displayRole = role == 'owner' ? 'Owner 👑' : 'Kasir ☀️';
    return 'Selamat $timeGreeting, $displayRole';
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚙️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Setelan', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text('Segera hadir', style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}