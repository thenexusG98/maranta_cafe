import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton que maneja la base de datos SQLite local.
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'maranta_cafe.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id               TEXT PRIMARY KEY,
        name             TEXT    NOT NULL,
        description      TEXT    DEFAULT '',
        price            REAL    NOT NULL,
        category         TEXT    NOT NULL DEFAULT 'General',
        image_emoji      TEXT    DEFAULT '☕',
        is_available     INTEGER DEFAULT 1,
        created_at       TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE modifiers (
        id          TEXT PRIMARY KEY,
        product_id  TEXT NOT NULL,
        name        TEXT NOT NULL,
        is_required INTEGER DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE modifier_options (
        id          TEXT PRIMARY KEY,
        modifier_id TEXT NOT NULL,
        name        TEXT NOT NULL,
        extra_cost  REAL DEFAULT 0.0,
        FOREIGN KEY (modifier_id) REFERENCES modifiers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items (
        id            TEXT PRIMARY KEY,
        name          TEXT NOT NULL,
        unit          TEXT NOT NULL DEFAULT 'unidad',
        current_stock REAL DEFAULT 0.0,
        minimum_stock REAL DEFAULT 0.0,
        cost_per_unit REAL DEFAULT 0.0,
        supplier      TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id                TEXT PRIMARY KEY,
        product_id        TEXT NOT NULL,
        inventory_item_id TEXT NOT NULL,
        quantity_used     REAL NOT NULL,
        FOREIGN KEY (product_id)        REFERENCES products (id)         ON DELETE CASCADE,
        FOREIGN KEY (inventory_item_id) REFERENCES inventory_items (id)  ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id                TEXT PRIMARY KEY,
        inventory_item_id TEXT NOT NULL,
        supplier          TEXT NOT NULL DEFAULT '',
        quantity          REAL NOT NULL,
        cost              REAL NOT NULL,
        purchase_date     TEXT NOT NULL,
        notes             TEXT DEFAULT '',
        FOREIGN KEY (inventory_item_id) REFERENCES inventory_items (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id             TEXT PRIMARY KEY,
        order_number   INTEGER NOT NULL,
        total          REAL    NOT NULL,
        payment_method TEXT    NOT NULL,
        status         TEXT    NOT NULL DEFAULT 'completed',
        created_at     TEXT    NOT NULL,
        notes          TEXT    DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id                 TEXT PRIMARY KEY,
        order_id           TEXT NOT NULL,
        product_id         TEXT NOT NULL,
        product_name       TEXT NOT NULL,
        quantity           INTEGER NOT NULL,
        unit_price         REAL NOT NULL,
        modifiers_selected TEXT DEFAULT '[]',
        subtotal           REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Índices para mejorar consultas por fecha
    await db.execute('CREATE INDEX idx_orders_date ON orders (created_at)');
    await db.execute('CREATE INDEX idx_order_items_product ON order_items (product_id)');

    await _insertSampleData(db);
  }

  /// Inserta datos de ejemplo para iniciar la app con contenido
  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // ── Productos de ejemplo ──────────────────────────────────────────
    final List<Map<String, dynamic>> sampleProducts = [
      {'id': 'p1', 'name': 'Café Americano',   'price': 45.0,  'category': 'Cafés',    'image_emoji': '☕',  'description': 'Café negro clásico',         'is_available': 1, 'created_at': now},
      {'id': 'p2', 'name': 'Cappuccino',        'price': 65.0,  'category': 'Cafés',    'image_emoji': '🫧',  'description': 'Espresso con leche espumada', 'is_available': 1, 'created_at': now},
      {'id': 'p3', 'name': 'Latte',             'price': 70.0,  'category': 'Cafés',    'image_emoji': '🥛',  'description': 'Espresso con leche vaporizada','is_available': 1, 'created_at': now},
      {'id': 'p4', 'name': 'Cold Brew',         'price': 75.0,  'category': 'Cafés',    'image_emoji': '🧊',  'description': 'Café frío de extracción lenta','is_available': 1, 'created_at': now},
      {'id': 'p5', 'name': 'Matcha Latte',      'price': 80.0,  'category': 'Especiales','image_emoji': '🍵', 'description': 'Matcha con leche',             'is_available': 1, 'created_at': now},
      {'id': 'p6', 'name': 'Croissant',         'price': 40.0,  'category': 'Alimentos','image_emoji': '🥐',  'description': 'Croissant de mantequilla',    'is_available': 1, 'created_at': now},
      {'id': 'p7', 'name': 'Muffin',            'price': 35.0,  'category': 'Alimentos','image_emoji': '🧁',  'description': 'Muffin de arándanos',         'is_available': 1, 'created_at': now},
    ];

    for (final p in sampleProducts) {
      await db.insert('products', p);
    }

    // ── Modificadores para Latte ──────────────────────────────────────
    await db.insert('modifiers', {'id': 'm1', 'product_id': 'p3', 'name': 'Tipo de leche', 'is_required': 1});
    await db.insert('modifier_options', {'id': 'mo1', 'modifier_id': 'm1', 'name': 'Entera',   'extra_cost': 0.0});
    await db.insert('modifier_options', {'id': 'mo2', 'modifier_id': 'm1', 'name': 'Almendra', 'extra_cost': 10.0});
    await db.insert('modifier_options', {'id': 'mo3', 'modifier_id': 'm1', 'name': 'Avena',    'extra_cost': 10.0});
    await db.insert('modifier_options', {'id': 'mo4', 'modifier_id': 'm1', 'name': 'Coco',     'extra_cost': 15.0});

    await db.insert('modifiers', {'id': 'm2', 'product_id': 'p3', 'name': 'Tipo de café', 'is_required': 0});
    await db.insert('modifier_options', {'id': 'mo5', 'modifier_id': 'm2', 'name': 'Regular',      'extra_cost': 0.0});
    await db.insert('modifier_options', {'id': 'mo6', 'modifier_id': 'm2', 'name': 'Descafeinado', 'extra_cost': 0.0});

    // Modificadores para Cappuccino
    await db.insert('modifiers', {'id': 'm3', 'product_id': 'p2', 'name': 'Tipo de leche', 'is_required': 0});
    await db.insert('modifier_options', {'id': 'mo7',  'modifier_id': 'm3', 'name': 'Entera',   'extra_cost': 0.0});
    await db.insert('modifier_options', {'id': 'mo8',  'modifier_id': 'm3', 'name': 'Almendra', 'extra_cost': 10.0});
    await db.insert('modifier_options', {'id': 'mo9',  'modifier_id': 'm3', 'name': 'Avena',    'extra_cost': 10.0});

    await db.insert('modifiers', {'id': 'm4', 'product_id': 'p2', 'name': 'Extras', 'is_required': 0});
    await db.insert('modifier_options', {'id': 'mo10', 'modifier_id': 'm4', 'name': 'Shot extra',  'extra_cost': 15.0});
    await db.insert('modifier_options', {'id': 'mo11', 'modifier_id': 'm4', 'name': 'Canela',      'extra_cost': 5.0});
    await db.insert('modifier_options', {'id': 'mo12', 'modifier_id': 'm4', 'name': 'Vainilla',    'extra_cost': 10.0});

    // ── Insumos de ejemplo ───────────────────────────────────────────
    final List<Map<String, dynamic>> sampleInventory = [
      {'id': 'i1', 'name': 'Granos de café',   'unit': 'kg',    'current_stock': 5.0,  'minimum_stock': 1.0,  'cost_per_unit': 250.0, 'supplier': 'Café Veracruz'},
      {'id': 'i2', 'name': 'Leche entera',     'unit': 'lts',   'current_stock': 10.0, 'minimum_stock': 2.0,  'cost_per_unit': 22.0,  'supplier': 'Liconsa'},
      {'id': 'i3', 'name': 'Leche de almendra','unit': 'lts',   'current_stock': 3.0,  'minimum_stock': 1.0,  'cost_per_unit': 65.0,  'supplier': 'S/N'},
      {'id': 'i4', 'name': 'Matcha en polvo',  'unit': 'g',     'current_stock': 200.0,'minimum_stock': 50.0, 'cost_per_unit': 1.2,   'supplier': 'Importadora Zen'},
      {'id': 'i5', 'name': 'Azúcar',           'unit': 'kg',    'current_stock': 3.0,  'minimum_stock': 0.5,  'cost_per_unit': 24.0,  'supplier': 'Comercial'},
      {'id': 'i6', 'name': 'Vasos 12oz',       'unit': 'pieza', 'current_stock': 80.0, 'minimum_stock': 20.0, 'cost_per_unit': 2.5,   'supplier': 'Empaque Total'},
    ];

    for (final item in sampleInventory) {
      await db.insert('inventory_items', item);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers de bajo nivel
  // ─────────────────────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    required String where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> row, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<void> rawExecute(String sql, [List<dynamic>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
