import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/order_item.dart';

/// Bottom sheet para seleccionar modificadores de un producto
class ModifierSheet extends StatefulWidget {
  final Product product;
  final void Function(List<SelectedModifierOption>) onConfirm;

  const ModifierSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<ModifierSheet> {
  // modifier_id -> Set de optionIds seleccionadas
  final Map<String, Set<String>> _selected = {};

  @override
  void initState() {
    super.initState();
    // Preseleccionar primera opción en modificadores requeridos
    for (final mod in widget.product.modifiers) {
      if (mod.isRequired && mod.options.isNotEmpty) {
        _selected[mod.id] = {mod.options.first.id};
      } else {
        _selected[mod.id] = {};
      }
    }
  }

  bool get _canConfirm {
    for (final mod in widget.product.modifiers) {
      if (mod.isRequired && (_selected[mod.id]?.isEmpty ?? true)) return false;
    }
    return true;
  }

  double get _extraCost {
    double total = 0;
    for (final mod in widget.product.modifiers) {
      final selectedIds = _selected[mod.id] ?? {};
      for (final opt in mod.options) {
        if (selectedIds.contains(opt.id)) total += opt.extraCost;
      }
    }
    return total;
  }

  List<SelectedModifierOption> get _buildSelectedList {
    final result = <SelectedModifierOption>[];
    for (final mod in widget.product.modifiers) {
      final selectedIds = _selected[mod.id] ?? {};
      for (final opt in mod.options) {
        if (selectedIds.contains(opt.id)) {
          result.add(SelectedModifierOption(
            modifierId:   mod.id,
            modifierName: mod.name,
            optionId:     opt.id,
            optionName:   opt.name,
            extraCost:    opt.extraCost,
          ));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.price + _extraCost;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(widget.product.imageEmoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Personaliza tu pedido',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Modificadores
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: widget.product.modifiers.map((modifier) =>
                  _ModifierGroup(
                    modifier: modifier,
                    selected: _selected[modifier.id] ?? {},
                    onSelect: (optionId) {
                      setState(() {
                        _selected[modifier.id] ??= {};
                        // Selección única (radio behavior)
                        if (_selected[modifier.id]!.contains(optionId)) {
                          if (!modifier.isRequired) {
                            _selected[modifier.id]!.remove(optionId);
                          }
                        } else {
                          _selected[modifier.id] = {optionId};
                        }
                      });
                    },
                  )
                ).toList(),
              ),
            ),

            // Footer con precio y botón
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total',
                        style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: AppColors.coffeeBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _canConfirm
                        ? () {
                            widget.onConfirm(_buildSelectedList);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${widget.product.imageEmoji} ${widget.product.name} agregado',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Agregar al carrito'),
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

// ── Grupo de opciones para un modificador ─────────────────────────────────────

class _ModifierGroup extends StatelessWidget {
  final Modifier modifier;
  final Set<String> selected;
  final void Function(String optionId) onSelect;

  const _ModifierGroup({
    required this.modifier,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                modifier.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              if (modifier.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.caramel.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Requerido',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.caramel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...modifier.options.map((option) {
            final isSelected = selected.contains(option.id);
            return GestureDetector(
              onTap: () => onSelect(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.coffeeBrown.withOpacity(0.08) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.coffeeBrown : const Color(0xFFE0D0C0),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.coffeeBrown : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.coffeeDark : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (option.extraCost > 0)
                      Text(
                        '+\$${option.extraCost.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSelected ? AppColors.coffeeBrown : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
