import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/modifier.dart';
import '../../data/repositories/pos_repository.dart';

// ─── Providers de repositorio ────────────────────────────────────────────────

final posRepositoryProvider = Provider<PosRepository>((ref) => PosRepository());

// ─── Estado del carrito ──────────────────────────────────────────────────────

class CartItem {
  final String cartId;
  final Product product;
  final int quantity;
  final List<SelectedModifierOption> selectedModifiers;

  CartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.selectedModifiers,
  });

  double get modifiersCost =>
    selectedModifiers.fold(0.0, (acc, m) => acc + m.extraCost);

  double get effectiveUnitPrice => product.price + modifiersCost;
  double get subtotal => effectiveUnitPrice * quantity;

  String get modifiersDescription =>
    selectedModifiers.isEmpty
      ? ''
      : selectedModifiers.map((m) => m.optionName).join(', ');

  CartItem copyWith({int? quantity}) => CartItem(
    cartId:            cartId,
    product:           product,
    quantity:          quantity ?? this.quantity,
    selectedModifiers: selectedModifiers,
  );
}

class CartState {
  final List<CartItem> items;
  final PaymentMethod paymentMethod;

  const CartState({
    this.items = const [],
    this.paymentMethod = PaymentMethod.cash,
  });

  double get total => items.fold(0.0, (acc, item) => acc + item.subtotal);
  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    PaymentMethod? paymentMethod,
  }) => CartState(
    items:         items         ?? this.items,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
}

class CartNotifier extends StateNotifier<CartState> {
  final _uuid = const Uuid();

  CartNotifier() : super(const CartState());

  void addItem(Product product, List<SelectedModifierOption> modifiers) {
    // Si el mismo producto con los mismos modificadores ya está, incrementa qty
    final idx = state.items.indexWhere((item) =>
      item.product.id == product.id &&
      _modifiersMatch(item.selectedModifiers, modifiers)
    );

    if (idx >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(
          cartId:            _uuid.v4(),
          product:           product,
          quantity:          1,
          selectedModifiers: modifiers,
        )],
      );
    }
  }

  void removeItem(String cartId) {
    state = state.copyWith(
      items: state.items.where((i) => i.cartId != cartId).toList(),
    );
  }

  void incrementItem(String cartId) {
    state = state.copyWith(
      items: state.items.map((item) =>
        item.cartId == cartId ? item.copyWith(quantity: item.quantity + 1) : item
      ).toList(),
    );
  }

  void decrementItem(String cartId) {
    final item = state.items.firstWhere((i) => i.cartId == cartId);
    if (item.quantity <= 1) {
      removeItem(cartId);
    } else {
      state = state.copyWith(
        items: state.items.map((i) =>
          i.cartId == cartId ? i.copyWith(quantity: i.quantity - 1) : i
        ).toList(),
      );
    }
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = const CartState();
  }

  bool _modifiersMatch(
    List<SelectedModifierOption> a,
    List<SelectedModifierOption> b,
  ) {
    if (a.length != b.length) return false;
    final aIds = a.map((m) => m.optionId).toSet();
    final bIds = b.map((m) => m.optionId).toSet();
    return aIds.containsAll(bIds);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

// ─── Provider de productos ───────────────────────────────────────────────────

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(posRepositoryProvider);
  return repo.getAvailableProducts();
});

final productsByCategoryProvider = Provider<Map<String, List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  return productsAsync.when(
    data: (products) {
      final Map<String, List<Product>> map = {};
      for (final p in products) {
        map.putIfAbsent(p.category, () => []).add(p);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Categorías disponibles
final categoriesProvider = Provider<List<String>>((ref) {
  final map = ref.watch(productsByCategoryProvider);
  return ['Todos', ...map.keys];
});

// Categoría seleccionada en el POS
final selectedCategoryProvider = StateProvider<String>((ref) => 'Todos');

// Productos filtrados por categoría seleccionada
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.when(
    data: (products) {
      if (category == 'Todos') return products;
      return products.where((p) => p.category == category).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Submit order ────────────────────────────────────────────────────────────

final submitOrderProvider = FutureProvider.family<Order, CartState>((ref, cartState) async {
  final repo = ref.read(posRepositoryProvider);
  final uuid = const Uuid();

  final items = cartState.items.map((ci) => OrderItem(
    id:                uuid.v4(),
    orderId:           '',
    productId:         ci.product.id,
    productName:       ci.product.name,
    quantity:          ci.quantity,
    unitPrice:         ci.product.price,
    selectedModifiers: ci.selectedModifiers,
    subtotal:          ci.subtotal,
  )).toList();

  return repo.createOrder(
    items:         items,
    paymentMethod: cartState.paymentMethod,
  );
});
