import 'dart:convert';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.total,
    required super.paymentMethod,
    required super.status,
    required super.createdAt,
    super.notes,
    super.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) =>
    OrderModel(
      id:            map['id'] as String,
      orderNumber:   map['order_number'] as int,
      total:         (map['total'] as num).toDouble(),
      paymentMethod: PaymentMethodX.fromString(map['payment_method'] as String),
      status:        OrderStatus.completed,
      createdAt:     DateTime.parse(map['created_at'] as String),
      notes:         map['notes'] as String? ?? '',
      items:         items,
    );

  Map<String, dynamic> toMap() => {
    'id':             id,
    'order_number':   orderNumber,
    'total':          total,
    'payment_method': paymentMethod.name,
    'status':         status.name,
    'created_at':     createdAt.toIso8601String(),
    'notes':          notes,
  };
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.selectedModifiers,
    required super.subtotal,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final modifiersJson = map['modifiers_selected'] as String? ?? '[]';
    final modifiersList = (jsonDecode(modifiersJson) as List)
        .map((e) => SelectedModifierOption.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderItemModel(
      id:                 map['id'] as String,
      orderId:            map['order_id'] as String,
      productId:          map['product_id'] as String,
      productName:        map['product_name'] as String,
      quantity:           map['quantity'] as int,
      unitPrice:          (map['unit_price'] as num).toDouble(),
      selectedModifiers:  modifiersList,
      subtotal:           (map['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                 id,
    'order_id':           orderId,
    'product_id':         productId,
    'product_name':       productName,
    'quantity':           quantity,
    'unit_price':         unitPrice,
    'modifiers_selected': jsonEncode(selectedModifiers.map((m) => m.toJson()).toList()),
    'subtotal':           subtotal,
  };
}
