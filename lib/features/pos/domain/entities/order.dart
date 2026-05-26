import 'order_item.dart';

enum PaymentMethod { cash, card, transfer }
enum OrderStatus   { completed, cancelled, pending }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:     return 'Efectivo';
      case PaymentMethod.card:     return 'Tarjeta';
      case PaymentMethod.transfer: return 'Transferencia';
    }
  }

  String get emoji {
    switch (this) {
      case PaymentMethod.cash:     return '💵';
      case PaymentMethod.card:     return '💳';
      case PaymentMethod.transfer: return '📲';
    }
  }

  static PaymentMethod fromString(String s) {
    switch (s) {
      case 'card':     return PaymentMethod.card;
      case 'transfer': return PaymentMethod.transfer;
      default:         return PaymentMethod.cash;
    }
  }
}

/// Orden completa con sus ítems
class Order {
  final String id;
  final int orderNumber;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final String notes;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.notes = '',
    this.items = const [],
  });

  int get totalItems => items.fold(0, (acc, item) => acc + item.quantity);
}
