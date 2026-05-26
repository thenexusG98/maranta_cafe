/// Opción dentro de un modificador (Ej: "Almendra +$10")
class ModifierOption {
  final String id;
  final String modifierId;
  final String name;
  final double extraCost;

  const ModifierOption({
    required this.id,
    required this.modifierId,
    required this.name,
    required this.extraCost,
  });

  ModifierOption copyWith({String? id, String? modifierId, String? name, double? extraCost}) =>
    ModifierOption(
      id:         id         ?? this.id,
      modifierId: modifierId ?? this.modifierId,
      name:       name       ?? this.name,
      extraCost:  extraCost  ?? this.extraCost,
    );
}

/// Grupo de modificadores para un producto (Ej: "Tipo de leche")
class Modifier {
  final String id;
  final String productId;
  final String name;
  final bool isRequired;
  final List<ModifierOption> options;

  const Modifier({
    required this.id,
    required this.productId,
    required this.name,
    required this.isRequired,
    this.options = const [],
  });

  Modifier copyWith({
    String? id,
    String? productId,
    String? name,
    bool? isRequired,
    List<ModifierOption>? options,
  }) => Modifier(
    id:         id         ?? this.id,
    productId:  productId  ?? this.productId,
    name:       name       ?? this.name,
    isRequired: isRequired ?? this.isRequired,
    options:    options    ?? this.options,
  );
}
