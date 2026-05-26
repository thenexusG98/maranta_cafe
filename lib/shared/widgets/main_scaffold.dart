import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';

/// Scaffold principal con BottomNavigationBar y badge de stock bajo
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(path: AppRouter.pos,       icon: Icons.coffee,           label: AppStrings.navPos),
    _NavItem(path: AppRouter.inventory, icon: Icons.inventory_2,      label: AppStrings.navInventory),
    _NavItem(path: AppRouter.dashboard, icon: Icons.bar_chart_rounded, label: AppStrings.navDashboard),
    _NavItem(path: AppRouter.sync,      icon: Icons.cloud_sync_outlined, label: AppStrings.navSettings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIdx = _currentIndex(location);
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIdx,
          onTap: (i) => context.go(_items[i].path),
          items: _items.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;

            // Badge en inventario si hay stock bajo
            final showBadge = i == 1 && lowStockAsync.maybeWhen(
              data: (items) => items.isNotEmpty,
              orElse: () => false,
            );

            return BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon),
                  if (showBadge)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith(AppRouter.dashboard)) return 2;
    if (location.startsWith(AppRouter.inventory)) return 1;
    if (location.startsWith(AppRouter.sync))      return 3;
    return 0; // POS es default
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;

  const _NavItem({required this.path, required this.icon, required this.label});
}
