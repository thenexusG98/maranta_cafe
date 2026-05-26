import 'modifier.dart';

/// Opción seleccionada dentro de un modificador al pedir
class SelectedModifierOption {
  final String modifierId;
  final String modifierName;
  final String optionId;
  final String optionName;
  final double extraCost;

  const SelectedModifierOption({
    required this.modifierId,
    required this.modifierName,
    required this.optionId,
    required this.optionName,
    required this.extraCost,
  });

  Map<String, dynamic> toJson() => {
    'modifier_id':   modifierId,
    'modifier_name': modifierName,
    'option_id':     optionId,
    'option_name':   optionName,
    'extra_cost':    extraCost,
  };

  factory SelectedModifierOption.fromJson(Map<String, dynamic> json) =>
    SelectedModifierOption(
      modifierId:   json['modifier_id'] as String,
      modifierName: json['modifier_name'] as String,
      optionId:     json['option_id'] as String,
      optionName:   json['option_name'] as String,
      extraCost:    (json['extra_cost'] as num).toDouble(),
    );
}

/// Ítem dentro de una orden (producto + cantidad + modificadores)
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final List<SelectedModifierOption> selectedModifiers;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.selectedModifiers,
    required this.subtotal,
  });

  double get modifiersCost =>
    selectedModifiers.fold(0.0, (acc, m) => acc + m.extraCost);

  double get effectiveUnitPrice => unitPrice + modifiersCost;

  String get modifiersDescription =>
    selectedModifiers.map((m) => m.optionName).join(', ');
}
