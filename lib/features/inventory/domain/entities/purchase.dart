/// Registro de compra de insumos
class Purchase {
  final String id;
  final String inventoryItemId;
  final String inventoryItemName;
  final String supplier;
  final double quantity;
  final double cost;
  final DateTime purchaseDate;
  final String notes;

  const Purchase({
    required this.id,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.supplier,
    required this.quantity,
    required this.cost,
    required this.purchaseDate,
    this.notes = '',
  });

  double get unitCost => quantity > 0 ? cost / quantity : 0;
}
