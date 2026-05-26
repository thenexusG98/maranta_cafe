import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/database/database_helper.dart';

/// Resultado de la sincronización
class SyncResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  final int ordersCount;
  final double totalAmount;

  const SyncResult({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.ordersCount,
    required this.totalAmount,
  });
}

/// Servicio que construye el payload y envía los datos a Google Sheets
/// mediante un Google Apps Script Web App (HTTP POST con JSON).
///
/// SETUP EN GOOGLE APPS SCRIPT:
/// 1. Ir a script.google.com → Nuevo proyecto
/// 2. Pegar el código doPost() de Apps Script (ver README)
/// 3. Publicar → "Implementar como aplicación web"
///    - Ejecutar como: "Yo"
///    - Acceso: "Cualquier usuario" (o "Cualquier usuario, incluso anónimo")
/// 4. Copiar la URL y pegarla en [webAppUrl]
class GoogleSheetsService {
  // ⚠️  CAMBIA esta URL por la de tu Apps Script Web App
  static const String _webAppUrl =
    'https://script.google.com/macros/s/TU_DEPLOYMENT_ID_AQUI/exec';

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Recolecta todos los datos del día y los envía a Google Sheets.
  Future<SyncResult> syncToday() async {
    final now     = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    // ── 1. Órdenes del día ────────────────────────────────────────────
    final orderRows = await _db.queryWhere(
      'orders',
      where: "created_at LIKE ? AND status = 'completed'",
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at ASC',
    );

    if (orderRows.isEmpty) {
      return SyncResult(
        success:     false,
        message:     'No hay ventas del día para sincronizar.',
        timestamp:   now,
        ordersCount: 0,
        totalAmount: 0,
      );
    }

    // ── 2. Detalle de ítems por orden ─────────────────────────────────
    final ordersWithItems = <Map<String, dynamic>>[];
    double totalAmount = 0;

    for (final order in orderRows) {
      final items = await _db.queryWhere('order_items',
        where: 'order_id = ?', whereArgs: [order['id']]);

      totalAmount += (order['total'] as num).toDouble();

      ordersWithItems.add({
        'order_id':       order['id'],
        'order_number':   order['order_number'],
        'total':          order['total'],
        'payment_method': order['payment_method'],
        'created_at':     order['created_at'],
        'notes':          order['notes'],
        'items': items.map((item) {
          final modifiers = jsonDecode(item['modifiers_selected'] as String? ?? '[]') as List;
          return {
            'product_name':      item['product_name'],
            'quantity':          item['quantity'],
            'unit_price':        item['unit_price'],
            'modifiers':         modifiers.map((m) => m['option_name']).join(', '),
            'subtotal':          item['subtotal'],
          };
        }).toList(),
      });
    }

    // ── 3. Inventario actual ──────────────────────────────────────────
    final inventoryRows = await _db.queryAll('inventory_items');
    final inventory = inventoryRows.map((item) => {
      'name':          item['name'],
      'unit':          item['unit'],
      'current_stock': item['current_stock'],
      'minimum_stock': item['minimum_stock'],
      'is_low_stock':  (item['current_stock'] as num) <= (item['minimum_stock'] as num),
    }).toList();

    // ── 4. Resumen de ventas por método de pago ───────────────────────
    final Map<String, Map<String, dynamic>> paymentSummary = {};
    for (final order in orderRows) {
      final method = order['payment_method'] as String;
      paymentSummary.putIfAbsent(method, () => {'count': 0, 'total': 0.0});
      paymentSummary[method]!['count'] = (paymentSummary[method]!['count'] as int) + 1;
      paymentSummary[method]!['total'] =
        (paymentSummary[method]!['total'] as double) + (order['total'] as num).toDouble();
    }

    // ── 5. Construir payload JSON ──────────────────────────────────────
    final payload = {
      'sync_date':       dateStr,
      'synced_at':       now.toIso8601String(),
      'summary': {
        'total_sales':   totalAmount,
        'total_orders':  orderRows.length,
        'avg_ticket':    orderRows.isNotEmpty ? totalAmount / orderRows.length : 0,
        'by_payment':    paymentSummary,
      },
      'orders':    ordersWithItems,
      'inventory': inventory,
    };

    // ── 6. Enviar HTTP POST ────────────────────────────────────────────
    try {
      final response = await http.post(
        Uri.parse(_webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final ok = responseBody['status'] == 'success' || responseBody['result'] == 'success';
        return SyncResult(
          success:     ok,
          message:     ok
            ? 'Datos enviados exitosamente (${orderRows.length} órdenes)'
            : 'El servidor respondió con error: ${response.body}',
          timestamp:   now,
          ordersCount: orderRows.length,
          totalAmount: totalAmount,
        );
      } else {
        return SyncResult(
          success:     false,
          message:     'Error HTTP ${response.statusCode}: ${response.body}',
          timestamp:   now,
          ordersCount: orderRows.length,
          totalAmount: totalAmount,
        );
      }
    } on Exception catch (e) {
      return SyncResult(
        success:     false,
        message:     'Error de conexión: $e',
        timestamp:   now,
        ordersCount: orderRows.length,
        totalAmount: totalAmount,
      );
    }
  }
}
