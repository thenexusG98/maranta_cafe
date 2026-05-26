import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/add_purchase_screen.dart';
import '../../features/inventory/presentation/screens/add_product_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/pos/presentation/screens/order_summary_screen.dart';
import '../../features/sync/presentation/screens/sync_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

class AppRouter {
  AppRouter._();

  static const String home       = '/';
  static const String pos        = '/pos';
  static const String orderSummary = '/pos/summary';
  static const String inventory  = '/inventory';
  static const String addPurchase= '/inventory/add-purchase';
  static const String addProduct = '/inventory/add-product';
  static const String dashboard  = '/dashboard';
  static const String sync       = '/sync';

  static final GoRouter router = GoRouter(
    initialLocation: pos,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: pos,
            builder: (context, state) => const PosScreen(),
            routes: [
              GoRoute(
                path: 'summary',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return OrderSummaryScreen(orderData: extra);
                },
              ),
            ],
          ),
          GoRoute(
            path: inventory,
            builder: (context, state) => const InventoryScreen(),
            routes: [
              GoRoute(
                path: 'add-purchase',
                builder: (context, state) {
                  final itemId = state.extra as String?;
                  return AddPurchaseScreen(preselectedItemId: itemId);
                },
              ),
              GoRoute(
                path: 'add-product',
                builder: (context, state) => const AddProductScreen(),
              ),
            ],
          ),
          GoRoute(
            path: dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: sync,
            builder: (context, state) => const SyncScreen(),
          ),
        ],
      ),
    ],
  );
}
