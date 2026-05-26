import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';
import '../providers/inventory_provider.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  final String? preselectedItemId;

  const AddPurchaseScreen({super.key, this.preselectedItemId});

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _supplierCtr   = TextEditingController();
  final _quantityCtr   = TextEditingController();
  final _costCtr       = TextEditingController();
  final _notesCtr      = TextEditingController();
  InventoryItem? _selectedItem;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _supplierCtr.dispose(); _quantityCtr.dispose();
    _costCtr.dispose(); _notesCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.caramel)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (_selectedItem == null && widget.preselectedItemId != null) {
            try {
              _selectedItem = items.firstWhere(
                (i) => i.id == widget.preselectedItemId);
            } catch (_) {}
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de insumo
                  Text('Insumo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<InventoryItem>(
                    value: _selectedItem,
                    items: items.map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedItem = v),
                    validator: (v) => v == null ? 'Selecciona un insumo' : null,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona el insumo...',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Proveedor
                  TextFormField(
                    controller: _supplierCtr,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtr,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cantidad (${_selectedItem?.unit ?? 'unidad'})',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costCtr,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Costo total \$',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Fecha
                  InkWell(
                    onTap: () => _pickDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de compra',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        '${_date.day.toString().padLeft(2,'0')}/'
                        '${_date.month.toString().padLeft(2,'0')}/'
                        '${_date.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesCtr,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Preview de costo unitario
                  if (_quantityCtr.text.isNotEmpty && _costCtr.text.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.creamDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Costo unitario estimado:'),
                          Text(
                            '\$${_computeUnitCost().toStringAsFixed(2)} / ${_selectedItem?.unit ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.coffeeBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Guardando...' : 'Registrar compra'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _computeUnitCost() {
    final qty  = double.tryParse(_quantityCtr.text) ?? 0;
    final cost = double.tryParse(_costCtr.text) ?? 0;
    return qty > 0 ? cost / qty : 0;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;
    setState(() => _saving = true);

    final purchase = Purchase(
      id:                '',
      inventoryItemId:   _selectedItem!.id,
      inventoryItemName: _selectedItem!.name,
      supplier:          _supplierCtr.text.trim(),
      quantity:          double.parse(_quantityCtr.text),
      cost:              double.parse(_costCtr.text),
      purchaseDate:      _date,
      notes:             _notesCtr.text.trim(),
    );

    try {
      await ref.read(registerPurchaseProvider(purchase).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compra de ${_selectedItem!.name} registrada ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
