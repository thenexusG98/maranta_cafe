/**
 * apps_script.gs
 * ─────────────────────────────────────────────────────────────────────────────
 * Código para Google Apps Script que recibe el POST desde Maranta Cafe App
 * y escribe los datos en Google Sheets.
 *
 * INSTRUCCIONES:
 * 1. Abre Google Sheets → Extensiones → Apps Script
 * 2. Pega TODO este código y guarda
 * 3. Implementar → Nueva implementación → Aplicación web
 *    - Ejecutar como: Yo (tu cuenta)
 *    - Acceso: Cualquier usuario (anónimo)
 * 4. Copia la URL y pégala en google_sheets_service.dart
 * ─────────────────────────────────────────────────────────────────────────────
 */

var SPREADSHEET_ID = SpreadsheetApp.getActiveSpreadsheet().getId();

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var ss   = SpreadsheetApp.openById(SPREADSHEET_ID);

    writeOrdersSheet(ss, data);
    writeSummarySheet(ss, data);
    writeInventorySheet(ss, data);

    return ContentService
      .createTextOutput(JSON.stringify({ status: 'success', message: 'Datos guardados correctamente' }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ status: 'error', message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ── Hoja: Pedidos del día ──────────────────────────────────────────────────

function writeOrdersSheet(ss, data) {
  var sheetName = 'Pedidos_' + data.sync_date.replace(/-/g, '_');
  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  } else {
    sheet.clearContents();
  }

  // Encabezados
  var headers = [
    '# Orden', 'Hora', 'Producto', 'Cantidad', 'Precio Unitario',
    'Modificadores', 'Subtotal', 'Total Orden', 'Método de Pago'
  ];
  sheet.getRange(1, 1, 1, headers.length).setValues([headers])
    .setBackground('#3E1C00').setFontColor('#FFFFFF').setFontWeight('bold');

  var rows = [];
  (data.orders || []).forEach(function(order) {
    (order.items || []).forEach(function(item) {
      rows.push([
        '#' + String(order.order_number).padStart(4, '0'),
        order.created_at.substr(11, 5),
        item.product_name,
        item.quantity,
        item.unit_price,
        item.modifiers || '—',
        item.subtotal,
        order.total,
        _paymentLabel(order.payment_method)
      ]);
    });
  });

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, headers.length).setValues(rows);
    // Formato moneda
    sheet.getRange(2, 5, rows.length, 1).setNumberFormat('$#,##0.00');
    sheet.getRange(2, 7, rows.length, 2).setNumberFormat('$#,##0.00');
  }

  sheet.autoResizeColumns(1, headers.length);
}

// ── Hoja: Resumen del día ──────────────────────────────────────────────────

function writeSummarySheet(ss, data) {
  var sheet = ss.getSheetByName('Resumen Diario');
  if (!sheet) {
    sheet = ss.insertSheet('Resumen Diario');
  }

  // Buscar la siguiente fila disponible
  var lastRow = sheet.getLastRow();
  if (lastRow === 0) {
    // Primera vez: poner encabezados
    var headers = [
      'Fecha', 'Total Ventas', 'Pedidos', 'Ticket Promedio',
      'Efectivo', 'Tarjeta', 'Transferencia', 'Sincronizado a las'
    ];
    sheet.getRange(1, 1, 1, headers.length).setValues([headers])
      .setBackground('#C8861E').setFontColor('#FFFFFF').setFontWeight('bold');
    lastRow = 1;
  }

  var summary = data.summary || {};
  var byPayment = summary.by_payment || {};

  var newRow = [
    data.sync_date,
    summary.total_sales || 0,
    summary.total_orders || 0,
    summary.avg_ticket || 0,
    (byPayment.cash && byPayment.cash.total) || 0,
    (byPayment.card && byPayment.card.total) || 0,
    (byPayment.transfer && byPayment.transfer.total) || 0,
    data.synced_at.substr(11, 5)
  ];

  sheet.getRange(lastRow + 1, 1, 1, newRow.length).setValues([newRow]);
  // Formato moneda columnas 2,4,5,6,7
  var moneyRange = sheet.getRange(lastRow + 1, 2, 1, 1);
  moneyRange.setNumberFormat('$#,##0.00');

  sheet.autoResizeColumns(1, 8);
}

// ── Hoja: Inventario ──────────────────────────────────────────────────────

function writeInventorySheet(ss, data) {
  var sheet = ss.getSheetByName('Inventario');
  if (!sheet) {
    sheet = ss.insertSheet('Inventario');
  } else {
    sheet.clearContents();
  }

  var headers = ['Insumo', 'Unidad', 'Stock Actual', 'Stock Mínimo', 'Estado', 'Última actualización'];
  sheet.getRange(1, 1, 1, headers.length).setValues([headers])
    .setBackground('#6B3A2A').setFontColor('#FFFFFF').setFontWeight('bold');

  var rows = (data.inventory || []).map(function(item) {
    return [
      item.name,
      item.unit,
      item.current_stock,
      item.minimum_stock,
      item.is_low_stock ? '⚠️ BAJO' : '✅ OK',
      data.sync_date
    ];
  });

  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, headers.length).setValues(rows);

    // Colorear filas con stock bajo
    rows.forEach(function(row, i) {
      if (row[4].indexOf('BAJO') !== -1) {
        sheet.getRange(i + 2, 1, 1, headers.length)
          .setBackground('#FFF3E0');
      }
    });
  }

  sheet.autoResizeColumns(1, headers.length);
}

function _paymentLabel(key) {
  var labels = { 'cash': 'Efectivo', 'card': 'Tarjeta', 'transfer': 'Transferencia' };
  return labels[key] || key;
}

// ── Test manual ───────────────────────────────────────────────────────────────
function testSync() {
  var fakeData = {
    sync_date: '2025-01-15',
    synced_at: '2025-01-15T14:30:00',
    summary: {
      total_sales: 850.0,
      total_orders: 12,
      avg_ticket: 70.83,
      by_payment: {
        cash:     { count: 6, total: 400 },
        card:     { count: 4, total: 320 },
        transfer: { count: 2, total: 130 }
      }
    },
    orders: [
      {
        order_id: 'test-1',
        order_number: 1,
        total: 70,
        payment_method: 'cash',
        created_at: '2025-01-15T09:15:00',
        items: [
          { product_name: 'Latte', quantity: 1, unit_price: 70, modifiers: 'Almendra', subtotal: 80 }
        ]
      }
    ],
    inventory: [
      { name: 'Granos de café', unit: 'kg', current_stock: 4.5, minimum_stock: 1.0, is_low_stock: false }
    ]
  };

  var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  writeOrdersSheet(ss, fakeData);
  writeSummarySheet(ss, fakeData);
  writeInventorySheet(ss, fakeData);
  Logger.log('Test completado!');
}
