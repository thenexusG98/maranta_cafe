import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../providers/pos_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_drawer.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('☕ Punto de Venta'),
        actions: [
          // Botón carrito con badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _openCart(context),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.caramel,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Filtro de categorías ────────────────────────────────────
          _CategoryChips(categories: categories, selected: selectedCategory),

          // ── Grid de productos ────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.caramel),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Error al cargar productos', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (_) => filteredProducts.isEmpty
                ? const _EmptyProducts()
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) => ProductCard(
                      product: filteredProducts[index],
                    ),
                  ),
            ),
          ),
        ],
      ),

      // ── FAB: Ver carrito / Finalizar ─────────────────────────────────
      floatingActionButton: cart.items.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => _openCart(context),
            backgroundColor: AppColors.coffeeBrown,
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: Text(
              '\$${cart.total.toStringAsFixed(2)} · Ver orden',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
    );
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartDrawer(),
    );
  }
}

// ── Chips de categorías ──────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  final List<String> categories;
  final String selected;

  const _CategoryChips({required this.categories, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = cat == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) =>
                  ref.read(selectedCategoryProvider.notifier).state = cat,
                backgroundColor: Colors.white,
                selectedColor: AppColors.coffeeBrown,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.coffeeBrown : const Color(0xFFDDD0C0),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('☕', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Sin productos en esta categoría',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
