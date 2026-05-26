import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';
import '../models/inventory_item_model.dart';

class InventoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ── Insumos ──────────────────────────────────────────────────────────────

  Future<List<InventoryItem>> getAllItems() async {
    final rows = await _db.queryAll('inventory_items');
    return rows.map((r) => InventoryItemModel.fromMap(r)).toList();
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final rows = await _db.rawQuery(
      'SELECT * FROM inventory_items WHERE current_stock <= minimum_stock'
    );
    return rows.map((r) => InventoryItemModel.fromMap(r)).toList();
  }

  Future<void> addItem(InventoryItem item) async {
    await _db.insert('inventory_items', InventoryItemModel(
      id:           item.id.isEmpty ? _uuid.v4() : item.id,
      name:         item.name,
      unit:         item.unit,
      currentStock: item.currentStock,
      minimumStock: item.minimumStock,
      costPerUnit:  item.costPerUnit,
      supplier:     item.supplier,
    ).toMap());
  }

  Future<void> updateItem(InventoryItem item) async {
    await _db.update(
      'inventory_items',
      InventoryItemModel(
        id:           item.id,
        name:         item.name,
        unit:         item.unit,
        currentStock: item.currentStock,
        minimumStock: item.minimumStock,
        costPerUnit:  item.costPerUnit,
        supplier:     item.supplier,
      ).toMap(),
      'id = ?',
      [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    await _db.delete('inventory_items', 'id = ?', [id]);
  }

  // ── Compras ──────────────────────────────────────────────────────────────

  Future<List<Purchase>> getAllPurchases() async {
    final rows = await _db.rawQuery('''
      SELECT p.*, i.name as item_name
      FROM purchases p
      LEFT JOIN inventory_items i ON p.inventory_item_id = i.id
      ORDER BY p.purchase_date DESC
    ''');
    return rows.map((r) => PurchaseModel.fromMap(r)).toList();
  }

  Future<void> registerPurchase(Purchase purchase) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      final purchaseId = purchase.id.isEmpty ? _uuid.v4() : purchase.id;

      await txn.insert('purchases', {
        'id':                purchaseId,
        'inventory_item_id': purchase.inventoryItemId,
        'supplier':          purchase.supplier,
        'quantity':          purchase.quantity,
        'cost':              purchase.cost,
        'purchase_date':     purchase.purchaseDate.toIso8601String(),
        'notes':             purchase.notes,
      });

      // Suman al stock actual
      await txn.rawUpdate(
        'UPDATE inventory_items SET current_stock = current_stock + ?, cost_per_unit = ? WHERE id = ?',
        [purchase.quantity, purchase.unitCost, purchase.inventoryItemId],
      );
    });
  }
}
