import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';
import '../../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

// ── Lista de insumos ──────────────────────────────────────────────────────────

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getAllItems();
});

// ── Items con stock bajo ──────────────────────────────────────────────────────

final lowStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});

// ── Historial de compras ──────────────────────────────────────────────────────

final purchasesProvider = FutureProvider<List<Purchase>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getAllPurchases();
});

// ── Tab activo (0 = Insumos, 1 = Compras) ────────────────────────────────────

final inventoryTabProvider = StateProvider<int>((ref) => 0);

// ── Acción: registrar compra ──────────────────────────────────────────────────

final registerPurchaseProvider = FutureProvider.family<void, Purchase>(
  (ref, purchase) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.registerPurchase(purchase);
    ref.invalidate(inventoryItemsProvider);
    ref.invalidate(lowStockItemsProvider);
    ref.invalidate(purchasesProvider);
  },
);

// ── Acción: agregar/actualizar insumo ────────────────────────────────────────

final updateInventoryItemProvider = FutureProvider.family<void, InventoryItem>(
  (ref, item) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.updateItem(item);
    ref.invalidate(inventoryItemsProvider);
    ref.invalidate(lowStockItemsProvider);
  },
);

final addInventoryItemProvider = FutureProvider.family<void, InventoryItem>(
  (ref, item) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.addItem(item);
    ref.invalidate(inventoryItemsProvider);
    ref.invalidate(lowStockItemsProvider);
  },
);
