import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_provider.dart';

class InventoryItemTile extends ConsumerWidget {
  final InventoryItem item;

  const InventoryItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = item.minimumStock > 0
      ? (item.currentStock / item.minimumStock).clamp(0.0, 3.0)
      : 1.0;

    final statusColor = item.isOutOfStock
      ? AppColors.error
      : item.isLowStock
        ? AppColors.warning
        : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícono con indicador de estado
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: statusColor,
                        size: 26,
                      ),
                    ),
                    if (item.isLowStock)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        item.supplier.isNotEmpty
                          ? 'Proveedor: ${item.supplier}'
                          : 'Sin proveedor',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Acciones
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'buy') {
                      context.push(AppRouter.addPurchase, extra: item.id);
                    } else if (v == 'edit') {
                      _showEditDialog(context, ref, item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'buy',  child: Text('Registrar compra')),
                    const PopupMenuItem(value: 'edit', child: Text('Editar stock mínimo')),
                  ],
                  child: const Icon(Icons.more_vert, color: AppColors.textHint),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de stock
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Mín: ${item.minimumStock.toStringAsFixed(1)} ${item.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 3.0,
                          backgroundColor: statusColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.isOutOfStock
                      ? 'Agotado'
                      : item.isLowStock
                        ? 'Stock bajo'
                        : 'OK',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, InventoryItem item) {
    final minCtr = TextEditingController(text: item.minimumStock.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${item.name}'),
        content: TextFormField(
          controller: minCtr,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Stock mínimo (${item.unit})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newMin = double.tryParse(minCtr.text) ?? item.minimumStock;
              await ref.read(updateInventoryItemProvider(
                item.copyWith(minimumStock: newMin)
              ).future);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
