import 'modifier.dart';

enum ProductCategory { cafes, especiales, alimentos, bebidas, otros }

/// Entidad de producto del menú
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageEmoji;
  final bool isAvailable;
  final List<Modifier> modifiers;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageEmoji = '☕',
    this.isAvailable = true,
    this.modifiers = const [],
    required this.createdAt,
  });

  bool get hasModifiers => modifiers.isNotEmpty;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageEmoji,
    bool? isAvailable,
    List<Modifier>? modifiers,
    DateTime? createdAt,
  }) => Product(
    id:          id          ?? this.id,
    name:        name        ?? this.name,
    description: description ?? this.description,
    price:       price       ?? this.price,
    category:    category    ?? this.category,
    imageEmoji:  imageEmoji  ?? this.imageEmoji,
    isAvailable: isAvailable ?? this.isAvailable,
    modifiers:   modifiers   ?? this.modifiers,
    createdAt:   createdAt   ?? this.createdAt,
  );
}
