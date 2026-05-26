import '../../../../core/database/database_helper.dart';
import '../../domain/entities/daily_stats.dart';
import '../../../pos/domain/entities/order.dart';
import '../../../pos/data/models/order_model.dart';

class DashboardRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<DailyStats> getDailyStats(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // ── Órdenes del día ───────────────────────────────────────────────
    final orderRows = await _db.queryWhere(
      'orders',
      where: "created_at LIKE ? AND status = 'completed'",
      whereArgs: ['$dateStr%'],
    );

    if (orderRows.isEmpty) {
      return DailyStats.empty().copyWith(date: date);
    }

    final double totalSales = orderRows.fold(0.0, (acc, r) => acc + (r['total'] as num).toDouble());
    final int totalOrders   = orderRows.length;
    final double avgTicket  = totalOrders > 0 ? totalSales / totalOrders : 0;

    // ── Por método de pago ────────────────────────────────────────────
    final Map<String, int> salesByPayment = {};
    for (final row in orderRows) {
      final method = row['payment_method'] as String;
      salesByPayment[method] = (salesByPayment[method] ?? 0) + 1;
    }

    // ── Top productos ─────────────────────────────────────────────────
    final topRows = await _db.rawQuery('''
      SELECT
        oi.product_id,
        oi.product_name,
        COALESCE(p.image_emoji, '☕') as image_emoji,
        SUM(oi.quantity) as total_qty,
        SUM(oi.subtotal) as total_revenue
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at LIKE ? AND o.status = 'completed'
      GROUP BY oi.product_id, oi.product_name
      ORDER BY total_qty DESC
      LIMIT 3
    ''', ['$dateStr%']);

    final topProducts = topRows.map((r) => TopProduct(
      productId:    r['product_id'] as String,
      productName:  r['product_name'] as String,
      imageEmoji:   r['image_emoji'] as String? ?? '☕',
      quantitySold: (r['total_qty'] as num).toInt(),
      totalRevenue: (r['total_revenue'] as num).toDouble(),
    )).toList();

    // ── Ventas por hora ───────────────────────────────────────────────
    final hourlyRows = await _db.rawQuery('''
      SELECT
        CAST(strftime('%H', created_at) AS INTEGER) as hour,
        SUM(total) as total_amount,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at LIKE ? AND status = 'completed'
      GROUP BY strftime('%H', created_at)
      ORDER BY hour
    ''', ['$dateStr%']);

    final hourlySalesMap = <int, HourlySales>{};
    for (final row in hourlyRows) {
      final h = (row['hour'] as int?) ?? 0;
      hourlySalesMap[h] = HourlySales(
        hour:    h,
        amount:  (row['total_amount'] as num? ?? 0).toDouble(),
        orders:  (row['order_count'] as int? ?? 0),
      );
    }

    // Rellenar horas sin ventas (6am - 10pm)
    final hourlySales = List.generate(17, (i) {
      final h = i + 6;
      return hourlySalesMap[h] ?? HourlySales(hour: h, amount: 0, orders: 0);
    });

    return DailyStats(
      totalSales:           totalSales,
      totalOrders:          totalOrders,
      avgTicket:            avgTicket,
      salesByPaymentMethod: salesByPayment,
      topProducts:          topProducts,
      hourlySales:          hourlySales,
      date:                 date,
    );
  }

  Future<DailyStats> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

    final orderRows = await _db.queryWhere(
      'orders',
      where: "created_at >= ? AND status = 'completed'",
      whereArgs: ['$startStr 00:00:00'],
    );

    final double totalSales = orderRows.fold(0.0, (acc, r) => acc + (r['total'] as num).toDouble());
    final int totalOrders   = orderRows.length;
    final double avgTicket  = totalOrders > 0 ? totalSales / totalOrders : 0;

    final Map<String, int> salesByPayment = {};
    for (final row in orderRows) {
      final method = row['payment_method'] as String;
      salesByPayment[method] = (salesByPayment[method] ?? 0) + 1;
    }

    // Top semanal
    final topRows = await _db.rawQuery('''
      SELECT
        oi.product_id,
        oi.product_name,
        COALESCE(p.image_emoji, '☕') as image_emoji,
        SUM(oi.quantity) as total_qty,
        SUM(oi.subtotal) as total_revenue
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.status = 'completed'
      GROUP BY oi.product_id, oi.product_name
      ORDER BY total_qty DESC
      LIMIT 3
    ''', ['$startStr 00:00:00']);

    final topProducts = topRows.map((r) => TopProduct(
      productId:    r['product_id'] as String,
      productName:  r['product_name'] as String,
      imageEmoji:   r['image_emoji'] as String? ?? '☕',
      quantitySold: (r['total_qty'] as num).toInt(),
      totalRevenue: (r['total_revenue'] as num).toDouble(),
    )).toList();

    return DailyStats(
      totalSales:           totalSales,
      totalOrders:          totalOrders,
      avgTicket:            avgTicket,
      salesByPaymentMethod: salesByPayment,
      topProducts:          topProducts,
      hourlySales:          [],
      date:                 now,
    );
  }
}

extension _DailyStatsCopyWith on DailyStats {
  DailyStats copyWith({DateTime? date}) => DailyStats(
    totalSales:           totalSales,
    totalOrders:          totalOrders,
    avgTicket:            avgTicket,
    salesByPaymentMethod: salesByPaymentMethod,
    topProducts:          topProducts,
    hourlySales:          hourlySales,
    date:                 date ?? this.date,
  );
}
