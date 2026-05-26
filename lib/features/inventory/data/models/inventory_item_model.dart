import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchase.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.name,
    required super.unit,
    required super.currentStock,
    required super.minimumStock,
    required super.costPerUnit,
    super.supplier,
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) =>
    InventoryItemModel(
      id:           map['id'] as String,
      name:         map['name'] as String,
      unit:         map['unit'] as String? ?? 'unidad',
      currentStock: (map['current_stock'] as num? ?? 0).toDouble(),
      minimumStock: (map['minimum_stock'] as num? ?? 0).toDouble(),
      costPerUnit:  (map['cost_per_unit'] as num? ?? 0).toDouble(),
      supplier:     map['supplier'] as String? ?? '',
    );

  Map<String, dynamic> toMap() => {
    'id':            id,
    'name':          name,
    'unit':          unit,
    'current_stock': currentStock,
    'minimum_stock': minimumStock,
    'cost_per_unit': costPerUnit,
    'supplier':      supplier,
  };
}

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.inventoryItemId,
    required super.inventoryItemName,
    required super.supplier,
    required super.quantity,
    required super.cost,
    required super.purchaseDate,
    super.notes,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map) =>
    PurchaseModel(
      id:                map['id'] as String,
      inventoryItemId:   map['inventory_item_id'] as String,
      inventoryItemName: map['item_name'] as String? ?? '',
      supplier:          map['supplier'] as String? ?? '',
      quantity:          (map['quantity'] as num).toDouble(),
      cost:              (map['cost'] as num).toDouble(),
      purchaseDate:      DateTime.parse(map['purchase_date'] as String),
      notes:             map['notes'] as String? ?? '',
    );

  Map<String, dynamic> toMap() => {
    'id':                id,
    'inventory_item_id': inventoryItemId,
    'supplier':          supplier,
    'quantity':          quantity,
    'cost':              cost,
    'purchase_date':     purchaseDate.toIso8601String(),
    'notes':             notes,
  };
}
