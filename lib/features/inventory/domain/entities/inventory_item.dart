/// Insumo / materia prima del inventario
class InventoryItem {
  final String id;
  final String name;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double costPerUnit;
  final String supplier;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    required this.costPerUnit,
    this.supplier = '',
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? costPerUnit,
    String? supplier,
  }) => InventoryItem(
    id:           id           ?? this.id,
    name:         name         ?? this.name,
    unit:         unit         ?? this.unit,
    currentStock: currentStock ?? this.currentStock,
    minimumStock: minimumStock ?? this.minimumStock,
    costPerUnit:  costPerUnit  ?? this.costPerUnit,
    supplier:     supplier     ?? this.supplier,
  );
}
