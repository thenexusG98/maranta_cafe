import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/low_stock_banner.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
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
                Tab(text: 'Compras'),
              ],
            ),
          ),
        ),
      ),

      body: tab == 0
        ? const _InsumosTab()
        : const _ComprasTab(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tab == 0) {
            _showAddItemDialog();
          } else {
            context.push(AppRouter.addPurchase);
          }
        },
        backgroundColor: AppColors.coffeeBrown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          tab == 0 ? 'Nuevo insumo' : 'Registrar compra',
          style: const TextStyle(color: Colors.white),
        ),
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
