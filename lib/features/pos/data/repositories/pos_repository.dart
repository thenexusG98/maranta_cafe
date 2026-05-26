import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/modifier.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class PosRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTOS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final rows = await _db.queryAll('products');
    final products = <Product>[];

    for (final row in rows) {
      final modifiers = await _getModifiersForProduct(row['id'] as String);
      products.add(ProductModel.fromMap(row, modifiers: modifiers));
    }
    return products;
  }

  Future<List<Product>> getAvailableProducts() async {
    final rows = await _db.queryWhere('products', where: 'is_available = ?', whereArgs: [1]);
    final products = <Product>[];

    for (final row in rows) {
      final modifiers = await _getModifiersForProduct(row['id'] as String);
      products.add(ProductModel.fromMap(row, modifiers: modifiers));
    }
    return products;
  }

  Future<void> addProduct(Product product) async {
    await _db.insert('products', ProductModel(
      id:          product.id.isEmpty ? _uuid.v4() : product.id,
      name:        product.name,
      description: product.description,
      price:       product.price,
      category:    product.category,
      imageEmoji:  product.imageEmoji,
      isAvailable: product.isAvailable,
      modifiers:   product.modifiers,
      createdAt:   product.createdAt,
    ).toMap());
  }

  Future<void> updateProductAvailability(String productId, bool isAvailable) async {
    await _db.update('products', {'is_available': isAvailable ? 1 : 0},
      'id = ?', [productId]);
  }

  Future<List<Modifier>> _getModifiersForProduct(String productId) async {
    final modRows = await _db.queryWhere('modifiers',
      where: 'product_id = ?', whereArgs: [productId]);
    final modifiers = <Modifier>[];

    for (final modRow in modRows) {
      final optRows = await _db.queryWhere('modifier_options',
        where: 'modifier_id = ?', whereArgs: [modRow['id']]);
      final options = optRows.map((o) => ModifierOptionModel.fromMap(o)).toList();
      modifiers.add(ModifierModel.fromMap(modRow, options: options));
    }
    return modifiers;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ÓRDENES
  // ─────────────────────────────────────────────────────────────────────────

  Future<int> _getNextOrderNumber() async {
    final result = await _db.rawQuery(
      'SELECT MAX(order_number) as max_num FROM orders'
    );
    final max = result.first['max_num'] as int?;
    return (max ?? 0) + 1;
  }

  Future<Order> createOrder({
    required List<OrderItem> items,
    required PaymentMethod paymentMethod,
    String notes = '',
  }) async {
    final db = await DatabaseHelper.instance.database;
    final orderId = _uuid.v4();
    final orderNumber = await _getNextOrderNumber();
    final now = DateTime.now();

    final double total = items.fold(0.0, (acc, item) => acc + item.subtotal);

    final order = OrderModel(
      id:            orderId,
      orderNumber:   orderNumber,
      total:         total,
      paymentMethod: paymentMethod,
      status:        OrderStatus.completed,
      createdAt:     now,
      notes:         notes,
      items:         items,
    );

    await db.transaction((txn) async {
      await txn.insert('orders', order.toMap());

      for (final item in items) {
        final itemModel = OrderItemModel(
          id:                item.id.isEmpty ? _uuid.v4() : item.id,
          orderId:           orderId,
          productId:         item.productId,
          productName:       item.productName,
          quantity:          item.quantity,
          unitPrice:         item.unitPrice,
          selectedModifiers: item.selectedModifiers,
          subtotal:          item.subtotal,
        );
        await txn.insert('order_items', itemModel.toMap());
      }

      // Descontar insumos del inventario
      for (final item in items) {
        final recipes = await txn.query('recipes',
          where: 'product_id = ?', whereArgs: [item.productId]);

        for (final recipe in recipes) {
          final qtyUsed = (recipe['quantity_used'] as num).toDouble() * item.quantity;
          await txn.rawUpdate(
            'UPDATE inventory_items SET current_stock = MAX(0, current_stock - ?) WHERE id = ?',
            [qtyUsed, recipe['inventory_item_id']],
          );
        }
      }
    });

    return order;
  }

  Future<List<Order>> getOrdersForDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final rows = await _db.queryWhere(
      'orders',
      where: "created_at LIKE ? AND status = 'completed'",
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );

    final orders = <Order>[];
    for (final row in rows) {
      final itemRows = await _db.queryWhere('order_items',
        where: 'order_id = ?', whereArgs: [row['id']]);
      final items = itemRows.map((r) => OrderItemModel.fromMap(r)).toList();
      orders.add(OrderModel.fromMap(row, items: items));
    }
    return orders;
  }

  Future<List<Order>> getOrdersForWeek() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

    final rows = await _db.queryWhere(
      'orders',
      where: "created_at >= ? AND status = 'completed'",
      whereArgs: ['$startStr 00:00:00'],
      orderBy: 'created_at DESC',
    );

    final orders = <Order>[];
    for (final row in rows) {
      final itemRows = await _db.queryWhere('order_items',
        where: 'order_id = ?', whereArgs: [row['id']]);
      final items = itemRows.map((r) => OrderItemModel.fromMap(r)).toList();
      orders.add(OrderModel.fromMap(row, items: items));
    }
    return orders;
  }
}
