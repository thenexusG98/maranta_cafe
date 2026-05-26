import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/order_item.dart';
import '../providers/pos_provider.dart';
import 'modifier_sheet.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Emoji / imagen ────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.creamDark,
                      AppColors.caramelLight.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    product.imageEmoji,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
            ),

            // ── Info ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.hasModifiers) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${product.modifiers.length} opción(es)',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.caramel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: AppColors.coffeeBrown,
                        ),
                      ),
                      _AddButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (product.hasModifiers) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ModifierSheet(
          product: product,
          onConfirm: (modifiers) {
            ref.read(cartProvider.notifier).addItem(product, modifiers);
          },
        ),
      );
    } else {
      ref.read(cartProvider.notifier).addItem(product, []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.imageEmoji} ${product.name} agregado'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _AddButton extends ConsumerWidget {
  final Product product;
  const _AddButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.coffeeBrown,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }
}
