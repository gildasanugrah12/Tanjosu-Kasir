import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/checkout_blade.dart';
import '../widgets/side_nav_bar.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'payment_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavItem _activeNav = NavItem.register;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left: Sidebar
          SideNavBar(
            activeItem: _activeNav,
            onItemSelected: (item) => setState(() => _activeNav = item),
          ),
          // Center: Main Content
          Expanded(
            child: _buildContent(),
          ),
          // Right: Checkout Blade (only on register screen)
          if (_activeNav == NavItem.register)
            CheckoutBlade(
              onCheckout: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeNav) {
      case NavItem.register:
        return const PosMainCanvas();
      case NavItem.history:
        return const HistoryScreen();
      case NavItem.dashboard:
        return const DashboardScreen();
      case NavItem.settings:
        return const _SettingsPlaceholder();
    }
  }
}

class PosMainCanvas extends StatefulWidget {
  const PosMainCanvas({super.key});

  @override
  State<PosMainCanvas> createState() => _PosMainCanvasState();
}

class _PosMainCanvasState extends State<PosMainCanvas> {
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Product> get _filteredProducts {
    return dummyProducts.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

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
          // Top Bar
          _buildTopBar(),
          // Category Tabs
          _buildCategoryTabs(),
          // Product Grid
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tanjosu POS', style: AppTextStyles.headlineSm),
              Text(
                _getGreeting(),
                style: AppTextStyles.labelSm,
              ),
            ],
          ),
          const Spacer(),
          // Search
          SizedBox(
            width: 280,
            height: 44,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('K', style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 56,
      color: AppColors.surfaceContainerLowest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: productCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = productCategories[index];
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
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Tidak ada produk ditemukan', style: AppTextStyles.bodyMd),
          ],
        ),
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
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi, Kasir ☀️';
    if (hour < 17) return 'Selamat Siang, Kasir 🌤️';
    return 'Selamat Malam, Kasir 🌙';
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
