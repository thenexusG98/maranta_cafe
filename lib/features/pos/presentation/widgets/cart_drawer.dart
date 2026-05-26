import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/order.dart';
import '../providers/pos_provider.dart';

/// Bottom sheet con el carrito y opción de finalizar
class CartDrawer extends ConsumerStatefulWidget {
  const CartDrawer({super.key});

  @override
  ConsumerState<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends ConsumerState<CartDrawer> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.coffeeBrown),
                  const SizedBox(width: 8),
                  Text('Tu orden', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (cart.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Vaciar'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            if (cart.items.isEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text('El carrito está vacío',
                      style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                ),
              ),

            // ── Método de pago ────────────────────────────────────────
            if (cart.items.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Método de pago',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: PaymentMethod.values.map((method) =>
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _PaymentChip(method: method),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // ── Footer ─────────────────────────────────────────────────
            if (cart.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                          style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(color: AppColors.coffeeBrown),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _submit(context),
                        icon: _isSubmitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                        label: Text(_isSubmitting ? 'Procesando...' : 'Finalizar pedido'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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

  Future<void> _submit(BuildContext context) async {
    setState(() => _isSubmitting = true);

    final cart = ref.read(cartProvider);
    try {
      final order = await ref.read(submitOrderProvider(cart).future);
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.of(context).pop(); // close drawer
        context.go('/pos/summary', extra: {
          'orderNumber': order.orderNumber,
          'total':       order.total,
          'method':      order.paymentMethod.label,
          'items':       order.items.length,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pedido: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Tile de ítem en el carrito ────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(item.product.imageEmoji,
            style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                  style: Theme.of(context).textTheme.titleMedium),
                if (item.modifiersDescription.isNotEmpty)
                  Text(item.modifiersDescription,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.caramel,
                    )),
                Text('\$${item.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.coffeeBrown,
                  )),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () => notifier.decrementItem(item.cartId),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () => notifier.incrementItem(item.cartId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.creamDark,
          borderRadius: BorderRadius.circular(8),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFDDD0C0)),
          ),
        ),
        child: Icon(icon, size: 16, color: AppColors.coffeeBrown),
      ),
    );
  }
}

// ── Chip de método de pago ────────────────────────────────────────────────────

class _PaymentChip extends ConsumerWidget {
  final PaymentMethod method;
  const _PaymentChip({required this.method});

  Color get _color {
    switch (method) {
      case PaymentMethod.cash:     return AppColors.cash;
      case PaymentMethod.card:     return AppColors.card;
      case PaymentMethod.transfer: return AppColors.transfer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isSelected = cart.paymentMethod == method;

    return GestureDetector(
      onTap: () => ref.read(cartProvider.notifier).setPaymentMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? _color : const Color(0xFFDDD0C0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(method.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              method.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? _color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
