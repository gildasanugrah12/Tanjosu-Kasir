import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum NavItem { register, history, dashboard, settings }

class SideNavBar extends StatelessWidget {
  final NavItem activeItem;
  final ValueChanged<NavItem> onItemSelected;

  const SideNavBar({
    super.key,
    required this.activeItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('T', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 32),
          _NavItemWidget(
            icon: Icons.point_of_sale_rounded,
            label: 'Kasir',
            item: NavItem.register,
            activeItem: activeItem,
            onTap: onItemSelected,
          ),
          const SizedBox(height: 8),
          _NavItemWidget(
            icon: Icons.receipt_long_rounded,
            label: 'Riwayat',
            item: NavItem.history,
            activeItem: activeItem,
            onTap: onItemSelected,
          ),
          const SizedBox(height: 8),
          _NavItemWidget(
            icon: Icons.bar_chart_rounded,
            label: 'Laporan',
            item: NavItem.dashboard,
            activeItem: activeItem,
            onTap: onItemSelected,
          ),
          const Spacer(),
          _NavItemWidget(
            icon: Icons.settings_rounded,
            label: 'Setelan',
            item: NavItem.settings,
            activeItem: activeItem,
            onTap: onItemSelected,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final NavItem item;
  final NavItem activeItem;
  final ValueChanged<NavItem> onTap;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.item,
    required this.activeItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item == activeItem;
    return GestureDetector(
      onTap: () => onTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryFixed.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Active indicator bar
            if (isActive)
              Positioned(
                left: 0,
                top: 16,
                bottom: 16,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTextStyles.navLabel.copyWith(
                      color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
