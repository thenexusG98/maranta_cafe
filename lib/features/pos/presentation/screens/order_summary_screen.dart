import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

/// Pantalla de confirmación al finalizar un pedido
class OrderSummaryScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;

  const OrderSummaryScreen({super.key, this.orderData});

  @override
  Widget build(BuildContext context) {
    final orderNumber = orderData?['orderNumber'] as int? ?? 0;
    final total       = (orderData?['total'] as num?)?.toDouble() ?? 0;
    final method      = orderData?['method'] as String? ?? 'Efectivo';
    final items       = orderData?['items'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animación de éxito
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 80,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '¡Pedido registrado!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Gracias por tu compra',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Detalle del pedido
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coffeeBrown.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow('Orden #', '#${orderNumber.toString().padLeft(4, '0')}'),
                    const Divider(height: 20),
                    _SummaryRow('Productos', '$items ítem(s)'),
                    const Divider(height: 20),
                    _SummaryRow('Pago', method),
                    const Divider(height: 20),
                    _SummaryRow(
                      'Total',
                      '\$${total.toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: AppColors.coffeeBrown,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRouter.pos),
                  icon: const Icon(Icons.coffee),
                  label: const Text('Nuevo pedido'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRouter.dashboard),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Ver estadísticas'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
