/// Resumen de estadísticas diarias/semanales para el Dashboard
class DailyStats {
  final double totalSales;
  final int totalOrders;
  final double avgTicket;
  final Map<String, int> salesByPaymentMethod;
  final List<TopProduct> topProducts;
  final List<HourlySales> hourlySales;
  final DateTime date;

  const DailyStats({
    required this.totalSales,
    required this.totalOrders,
    required this.avgTicket,
    required this.salesByPaymentMethod,
    required this.topProducts,
    required this.hourlySales,
    required this.date,
  });

  static DailyStats empty() => DailyStats(
    totalSales: 0,
    totalOrders: 0,
    avgTicket: 0,
    salesByPaymentMethod: {},
    topProducts: [],
    hourlySales: [],
    date: DateTime.now(),
  );
}

/// Producto más vendido
class TopProduct {
  final String productId;
  final String productName;
  final String imageEmoji;
  final int quantitySold;
  final double totalRevenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.imageEmoji,
    required this.quantitySold,
    required this.totalRevenue,
  });
}

/// Ventas por hora del día
class HourlySales {
  final int hour;   // 0-23
  final double amount;
  final int orders;

  const HourlySales({
    required this.hour,
    required this.amount,
    required this.orders,
  });

  String get label => '${hour.toString().padLeft(2, '0')}:00';
}
