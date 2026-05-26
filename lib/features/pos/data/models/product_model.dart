import 'dart:convert';
import '../../domain/entities/product.dart';
import '../../domain/entities/modifier.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.category,
    required super.imageEmoji,
    required super.isAvailable,
    required super.modifiers,
    required super.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, {List<Modifier> modifiers = const []}) =>
    ProductModel(
      id:          map['id'] as String,
      name:        map['name'] as String,
      description: map['description'] as String? ?? '',
      price:       (map['price'] as num).toDouble(),
      category:    map['category'] as String? ?? 'General',
      imageEmoji:  map['image_emoji'] as String? ?? '☕',
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      modifiers:   modifiers,
      createdAt:   DateTime.parse(map['created_at'] as String),
    );

  Map<String, dynamic> toMap() => {
    'id':          id,
    'name':        name,
    'description': description,
    'price':       price,
    'category':    category,
    'image_emoji': imageEmoji,
    'is_available':isAvailable ? 1 : 0,
    'created_at':  createdAt.toIso8601String(),
  };
}

class ModifierModel extends Modifier {
  const ModifierModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.isRequired,
    super.options,
  });

  factory ModifierModel.fromMap(Map<String, dynamic> map, {List<ModifierOption> options = const []}) =>
    ModifierModel(
      id:         map['id'] as String,
      productId:  map['product_id'] as String,
      name:       map['name'] as String,
      isRequired: (map['is_required'] as int? ?? 0) == 1,
      options:    options,
    );

  Map<String, dynamic> toMap() => {
    'id':          id,
    'product_id':  productId,
    'name':        name,
    'is_required': isRequired ? 1 : 0,
  };
}

class ModifierOptionModel extends ModifierOption {
  const ModifierOptionModel({
    required super.id,
    required super.modifierId,
    required super.name,
    required super.extraCost,
  });

  factory ModifierOptionModel.fromMap(Map<String, dynamic> map) =>
    ModifierOptionModel(
      id:         map['id'] as String,
      modifierId: map['modifier_id'] as String,
      name:       map['name'] as String,
      extraCost:  (map['extra_cost'] as num? ?? 0).toDouble(),
    );

  Map<String, dynamic> toMap() => {
    'id':          id,
    'modifier_id': modifierId,
    'name':        name,
    'extra_cost':  extraCost,
  };
}
