import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/low_stock_banner.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';
import '../../../pos/presentation/providers/pos_provider.dart';
import '../../../pos/domain/entities/product.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          ref.read(inventoryTabProvider.notifier).state = _tabController.index;
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(inventoryTabProvider);

    // Sincronizar el controlador si el estado externo cambia
    if (_tabController.index != tab) {
      _tabController.animateTo(tab);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Inventario'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.coffeeBrown,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.caramelLight,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Insumos'),
                Tab(text: 'Menú'),
                Tab(text: 'Compras'),
              ],
            ),
          ),
        ),
      ),

      body: [
        const _InsumosTab(),
        const _MenuTab(),
        const _ComprasTab(),
      ][tab],

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tab == 0) {
            _showAddItemDialog();
          } else if (tab == 1) {
            _showAddProductDialog();
          } else {
            context.push(AppRouter.addPurchase);
          }
        },
        backgroundColor: AppColors.coffeeBrown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          tab == 0
            ? 'Nuevo insumo'
            : tab == 1
              ? 'Agregar al menú'
              : 'Registrar compra',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddProductDialog(
        uuid: _uuid,
        onSave: (product) async {
          try {
            await ref.read(addMenuProductProvider(product).future);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${product.imageEmoji} ${product.name} agregado al menú',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddItemDialog(
        onSave: (item) async {
          await ref.read(addInventoryItemProvider(item).future);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Tab: Insumos ─────────────────────────────────────────────────────────────

class _InsumosTab extends ConsumerWidget {
  const _InsumosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync   = ref.watch(inventoryItemsProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    return itemsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.caramel)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) => CustomScrollView(
        slivers: [
          // Banner de alerta
          lowStockAsync.when(
            data: (lowItems) => lowItems.isNotEmpty
              ? SliverToBoxAdapter(child: LowStockBanner(count: lowItems.length))
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          if (items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Sin insumos registrados')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InventoryItemTile(item: items[i]),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab: Compras ─────────────────────────────────────────────────────────────

class _ComprasTab extends ConsumerWidget {
  const _ComprasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);

    return purchasesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.caramel)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (purchases) => purchases.isEmpty
        ? const Center(child: Text('Sin compras registradas'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: purchases.length,
            itemBuilder: (_, i) => _PurchaseTile(purchase: purchases[i]),
          ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final Purchase purchase;
  const _PurchaseTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.caramel.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: AppColors.caramel),
        ),
        title: Text(purchase.inventoryItemName,
          style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${purchase.quantity} ${''} · ${purchase.supplier}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${purchase.cost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.coffeeBrown, fontWeight: FontWeight.w700),
            ),
            Text(
              '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo para agregar insumo ───────────────────────────────────────────────

class _AddItemDialog extends StatefulWidget {
  final Future<void> Function(InventoryItem) onSave;
  const _AddItemDialog({required this.onSave});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr    = TextEditingController();
  final _unitCtr    = TextEditingController(text: 'unidad');
  final _stockCtr   = TextEditingController(text: '0');
  final _minCtr     = TextEditingController(text: '0');
  final _costCtr    = TextEditingController(text: '0');
  final _supplierCtr= TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtr.dispose(); _unitCtr.dispose(); _stockCtr.dispose();
    _minCtr.dispose(); _costCtr.dispose(); _supplierCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo insumo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_nameCtr, 'Nombre del insumo', required: true),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_unitCtr, 'Unidad (kg, lts...)')),
                const SizedBox(width: 10),
                Expanded(child: _field(_stockCtr, 'Stock inicial', isNum: true)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_minCtr, 'Stock mínimo', isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_costCtr, 'Costo/unidad', isNum: true)),
              ]),
              const SizedBox(height: 10),
              _field(_supplierCtr, 'Proveedor (opcional)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctr, String label,
      {bool required = false, bool isNum = false}) {
    return TextFormField(
      controller: ctr,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
        : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = InventoryItem(
      id:           '',
      name:         _nameCtr.text.trim(),
      unit:         _unitCtr.text.trim(),
      currentStock: double.tryParse(_stockCtr.text) ?? 0,
      minimumStock: double.tryParse(_minCtr.text) ?? 0,
      costPerUnit:  double.tryParse(_costCtr.text) ?? 0,
      supplier:     _supplierCtr.text.trim(),
    );

    await widget.onSave(item);
    if (mounted) setState(() => _saving = false);
  }
}

// ── Tab: Menú (gestión de productos del menú) ─────────────────────────────────

class _MenuTab extends ConsumerWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.caramel)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) => products.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☕', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('Sin productos en el menú',
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Toca "+ Agregar al menú" para comenzar',
                  style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ProductManagementTile(product: products[i]),
          ),
    );
  }
}

class _ProductManagementTile extends ConsumerWidget {
  final Product product;
  const _ProductManagementTile({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(product.imageEmoji,
                style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                    style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.caramel.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.caramel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: AppColors.coffeeBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: product.isAvailable,
                  onChanged: (val) {
                    ref.read(
                      toggleProductProvider(
                        (id: product.id, isAvailable: val),
                      ).future,
                    );
                  },
                  activeColor: AppColors.success,
                ),
                Text(
                  product.isAvailable ? 'Activo' : 'Pausado',
                  style: TextStyle(
                    fontSize: 10,
                    color: product.isAvailable
                      ? AppColors.success
                      : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo: agregar producto al menú ─────────────────────────────────────────

class _AddProductDialog extends StatefulWidget {
  final Uuid uuid;
  final Future<void> Function(Product) onSave;
  const _AddProductDialog({required this.uuid, required this.onSave});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtr   = TextEditingController();
  final _priceCtr  = TextEditingController();
  final _descCtr   = TextEditingController();
  String _category = 'Cafés';
  String _emoji    = '☕';
  bool _saving     = false;

  static const List<String> _categories = [
    'Cafés', 'Especiales', 'Alimentos', 'Bebidas', 'Otros',
  ];

  static const List<String> _emojis = [
    '☕', '🫧', '🥛', '🧊', '🍵', '🥤', '🧋', '🍶',
    '🥐', '🧁', '🍰', '🥞', '🍩', '🍪', '🥗', '🍽️',
    '🥪', '🧆', '🍫', '🧃', '🍹', '🥂', '🍾', '✨',
  ];

  @override
  void dispose() {
    _nameCtr.dispose();
    _priceCtr.dispose();
    _descCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Text('Nuevo producto',
                    style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const Divider(height: 24),

              TextFormField(
                controller: _nameCtr,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto *',
                  prefixIcon: Icon(Icons.coffee_outlined),
                ),
                validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      prefixText: '\$ ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      if (double.parse(v) <= 0) return 'Mayor a cero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtr,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              Text('Elige un ícono:',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis.map((e) {
                  final isSelected = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppColors.coffeeBrown.withOpacity(0.15)
                          : AppColors.creamDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                            ? AppColors.coffeeBrown
                            : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                        : const Text('Agregar al menú'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      id:          widget.uuid.v4(),
      name:        _nameCtr.text.trim(),
      description: _descCtr.text.trim(),
      price:       double.parse(_priceCtr.text),
      category:    _category,
      imageEmoji:  _emoji,
      isAvailable: true,
      modifiers:   const [],
      createdAt:   DateTime.now(),
    );

    await widget.onSave(product);
    if (mounted) setState(() => _saving = false);
  }
}
