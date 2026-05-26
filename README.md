# Maranta Cafe | Cafetería Móvil ☕

Aplicación móvil de gestión interna para **Maranta Cafe**. Construida con Flutter, arquitectura limpia y Riverpod.

---

## Estructura del proyecto

```
maranta_cafe/
├── lib/
│   ├── main.dart                        # Punto de entrada
│   ├── app.dart                         # MaterialApp + Router
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart          # Paleta de colores café
│   │   │   ├── app_theme.dart           # Material 3 Theme
│   │   │   └── app_strings.dart         # Textos de la app
│   │   ├── database/
│   │   │   └── database_helper.dart     # SQLite singleton + schema
│   │   └── router/
│   │       └── app_router.dart          # GoRouter - rutas
│   │
│   ├── features/
│   │   ├── pos/                         # 🧾 Punto de Venta
│   │   │   ├── data/
│   │   │   │   ├── models/              # ProductModel, OrderModel...
│   │   │   │   └── repositories/        # PosRepository (SQLite)
│   │   │   ├── domain/entities/         # Product, Order, Modifier...
│   │   │   └── presentation/
│   │   │       ├── providers/           # cartProvider, productsProvider
│   │   │       ├── screens/             # PosScreen, OrderSummaryScreen
│   │   │       └── widgets/             # ProductCard, CartDrawer, ModifierSheet
│   │   │
│   │   ├── inventory/                   # 📦 Inventario
│   │   │   ├── data/repositories/       # InventoryRepository
│   │   │   ├── domain/entities/         # InventoryItem, Purchase
│   │   │   └── presentation/
│   │   │       ├── providers/           # inventoryItemsProvider, purchasesProvider
│   │   │       ├── screens/             # InventoryScreen, AddPurchaseScreen
│   │   │       └── widgets/             # InventoryItemTile, LowStockBanner
│   │   │
│   │   ├── dashboard/                   # 📊 Estadísticas
│   │   │   ├── data/repositories/       # DashboardRepository (queries SQL)
│   │   │   ├── domain/entities/         # DailyStats, TopProduct, HourlySales
│   │   │   └── presentation/
│   │   │       ├── providers/           # dailyStatsProvider, dashboardModeProvider
│   │   │       ├── screens/             # DashboardScreen
│   │   │       └── widgets/             # StatsCard, TopProductsPodium, HourlyChart
│   │   │
│   │   └── sync/                        # ☁️ Sincronización Google Sheets
│   │       ├── data/services/           # GoogleSheetsService (HTTP POST)
│   │       └── presentation/
│   │           ├── providers/           # syncProvider (SyncNotifier)
│   │           └── screens/             # SyncScreen
│   │
│   └── shared/
│       └── widgets/
│           └── main_scaffold.dart       # BottomNavigationBar principal
│
├── apps_script.gs                       # Código Google Apps Script
└── pubspec.yaml
```

---

## Stack Tecnológico

| Capa         | Tecnología                       |
|--------------|----------------------------------|
| UI Framework | Flutter 3.x (Material 3)         |
| Estado       | **flutter_riverpod** ^2.5        |
| Base de datos| **sqflite** (SQLite local)        |
| Navegación   | **go_router** ^14                |
| Gráficas     | **fl_chart** ^0.68               |
| HTTP / API   | **http** ^1.2                    |
| Fuentes      | **google_fonts** (Poppins)        |

---

## Instalación

### Requisitos previos
- Flutter SDK ≥ 3.3.0 instalado y en PATH
- Dart SDK ≥ 3.3.0

### Pasos

```bash
# 1. Entrar al directorio del proyecto
cd maranta_cafe

# 2. Si aún no tienes la estructura de plataformas, ejecuta:
flutter create . --org com.maranta --project-name maranta_cafe --platforms android,ios

# 3. Instalar dependencias
flutter pub get

# 4. Ejecutar en modo debug
flutter run
```

---

## Configuración de Google Sheets (Sincronización)

### Paso 1 — Crear el Apps Script

1. Abre tu Google Sheets → **Extensiones → Apps Script**
2. Borrsa el código existente y pega el contenido de **`apps_script.gs`**
3. Guarda el proyecto (Ctrl+S)

### Paso 2 — Publicar como Aplicación Web

1. Clic en **"Implementar"** → **"Nueva implementación"**
2. Tipo: **Aplicación web**
3. Ejecutar como: **Yo**
4. Acceso: **Cualquier usuario** (para que la app móvil pueda llamarla sin autenticación)
5. Clic en **"Implementar"** y copia la URL generada

### Paso 3 — Conectar la app

Abre el archivo:
```
lib/features/sync/data/services/google_sheets_service.dart
```

Reemplaza la URL de ejemplo:
```dart
// Antes:
static const String _webAppUrl =
  'https://script.google.com/macros/s/TU_DEPLOYMENT_ID_AQUI/exec';

// Después (con tu URL real):
static const String _webAppUrl =
  'https://script.google.com/macros/s/AKfycb...tu_id_real.../exec';
```

### Resultado en Google Sheets

Al sincronizar, se crean/actualizan 3 hojas:
- **`Pedidos_2025_05_25`** — Detalle de cada venta del día
- **`Resumen Diario`** — Acumulado histórico por fecha
- **`Inventario`** — Estado actual de los insumos

---

## Módulos

### 🧾 Punto de Venta (POS)
- Grid de productos por categoría (chips de filtro)
- Modificadores de producto en bottom sheet (tipo de leche, extras, etc.)
- Carrito con contador en badge
- Selección de método de pago: 💵 Efectivo | 💳 Tarjeta | 📲 Transferencia
- Al finalizar: descuenta automáticamente insumos del inventario (si hay receta configurada)
- Pantalla de confirmación con resumen del pedido

### 📦 Inventario
- Lista de insumos con barra de progreso de stock
- Alerta visual (badge en nav + banner) cuando algún insumo está por debajo del mínimo
- Registro de compras: suma al stock actual y actualiza costo por unidad
- Historial de compras con proveedor y fecha

### 📊 Dashboard
- Toggle **Hoy / Semana**
- KPIs: Venta total, # Pedidos, Ticket promedio, Desglose por método de pago
- **Podio Top 3** productos más vendidos (🥇🥈🥉)
- **Gráfico de barras** de ventas por hora (6am–10pm), con destacado de hora pico

### ☁️ Sincronización
- Botón manual único — **jamás automático**
- Muestra fecha de última sincronización
- Muestra qué datos se envían antes de confirmar
- Instrucciones de configuración desplegables directamente en la pantalla

---

## Datos de ejemplo

La app incluye datos precargados al instalar:
- **7 productos** de menú (cafés, especiales, alimentos)
- **Modificadores** para Latte y Cappuccino (tipo de leche, extras)
- **6 insumos** de inventario con stocks iniciales

---

## Notas de seguridad

- La URL del Apps Script funciona como "contraseña" — no la compartas públicamente.
- Para mayor seguridad en producción, considera agregar un parámetro secreto en el POST y validarlo en el Apps Script.
- Los datos son 100% locales en SQLite — sin nube excepto cuando el usuario presiona "Sincronizar".
