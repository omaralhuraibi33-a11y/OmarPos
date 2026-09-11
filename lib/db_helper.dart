import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ==================== نموذج المستخدم ====================
class AppUser {
  String id;
  String name;
  String pin;
  bool isAdmin;
  bool showInLogin;
  Map<String, bool> permissions;

  AppUser({
    required this.id,
    required this.name,
    required this.pin,
    this.isAdmin = false,
    this.showInLogin = true,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'isAdmin': isAdmin ? 1 : 0,
      'showInLogin': showInLogin ? 1 : 0,
      'permissions': jsonEncode(permissions),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      pin: map['pin'],
      isAdmin: map['isAdmin'] == 1,
      showInLogin: map['showInLogin'] == 1,
      permissions: Map<String, bool>.from(jsonDecode(map['permissions'])),
    );
  }
}

// ==================== نموذج العميل ====================
class Customer {
  String id;
  String name;
  String phone;
  String address;
  double balance;
  String notes;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.balance = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'] ?? '',
      balance: (map['balance'] as num).toDouble(),
      notes: map['notes'] ?? '',
    );
  }
}

// ==================== نموذج المجموعة (التصنيف) ====================
class Category {
  String id;
  String name;
  String colorHex; // كود اللون
  bool isKitchenPrint; // طباعة للمطبخ
  bool isActive; // نشط في نقطة البيع

  Category({
    required this.id,
    required this.name,
    this.colorHex = '0xFF2196F3',
    this.isKitchenPrint = false,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'isKitchenPrint': isKitchenPrint ? 1 : 0,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      colorHex: map['colorHex'] ?? '0xFF2196F3',
      isKitchenPrint: map['isKitchenPrint'] == 1,
      isActive: map['isActive'] == 1,
    );
  }
}

// ==================== نموذج الصنف (المنتج) ====================
class Product {
  String id;
  String name;
  String categoryId;
  double purchasePrice;
  double sellPrice;
  double quantity;
  bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.purchasePrice = 0.0,
    this.sellPrice = 0.0,
    this.quantity = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'] ?? '',
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      sellPrice: (map['sellPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      isActive: map['isActive'] == 1,
    );
  }
}

// ==================== مدير قاعدة البيانات ====================
class DBHelper {
  static Database? _db;

  static const List<String> allModules = [
    'نقطة البيع',
    'المشتريات',
    'المخزن',
    'العملاء',
    'الموردين',
    'التقارير',
    'إعدادات النظام',
    'إدارة المستخدمين',
    'إغلاق الصندوق / الوردية',
    'التقرير المالي',
    'السندات',
    'الصندوق',
  ];

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String pathName = join(dbPath, 'omar_pos.db');

    return await openDatabase(
      pathName,
      version: 3, // التحديث للنسخة 3
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT,
            pin TEXT,
            isAdmin INTEGER,
            showInLogin INTEGER,
            permissions TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE customers(
            id TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT,
            address TEXT,
            balance REAL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT,
            colorHex TEXT,
            isKitchenPrint INTEGER,
            isActive INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY,
            name TEXT,
            categoryId TEXT,
            purchasePrice REAL,
            sellPrice REAL,
            quantity REAL,
            isActive INTEGER
          )
        ''');

        final allPerms = {for (var m in allModules) m: true};
        final cashierPerms = {
          for (var m in allModules) m: (m == 'نقطة البيع' || m == 'إغلاق الصندوق / الوردية')
        };
        final supervisorPerms = {
          for (var m in allModules) m: (m != 'إدارة المستخدمين' && m != 'إعدادات النظام')
        };

        await db.insert('users', AppUser(id: '1', name: 'المدير العام', pin: '1234', isAdmin: true, showInLogin: true, permissions: allPerms).toMap());
        await db.insert('users', AppUser(id: '2', name: 'كاشير 1', pin: '0000', isAdmin: false, showInLogin: true, permissions: cashierPerms).toMap());
        await db.insert('users', AppUser(id: '3', name: 'كاشير 2', pin: '0000', isAdmin: false, showInLogin: true, permissions: cashierPerms).toMap());
        await db.insert('users', AppUser(id: '4', name: 'مشرف', pin: '1111', isAdmin: false, showInLogin: true, permissions: supervisorPerms).toMap());
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE customers(
              id TEXT PRIMARY KEY,
              name TEXT,
              phone TEXT,
              address TEXT,
              balance REAL,
              notes TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE categories(
              id TEXT PRIMARY KEY,
              name TEXT,
              colorHex TEXT,
              isKitchenPrint INTEGER,
              isActive INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE products(
              id TEXT PRIMARY KEY,
              name TEXT,
              categoryId TEXT,
              purchasePrice REAL,
              sellPrice REAL,
              quantity REAL,
              isActive INTEGER
            )
          ''');
        }
      },
    );
  }

  // ==================== المستخدمين والعملاء ====================
  static Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  static Future<List<AppUser>> getLoginUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'showInLogin = ?', whereArgs: [1]);
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  static Future<void> saveUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  static Future<void> saveCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== عمليات المجموعات (Categories) ====================
  static Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  static Future<List<Category>> getActivePOSCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories', where: 'isActive = ?', whereArgs: [1]);
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  static Future<void> saveCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== عمليات الأصناف (Products) ====================
  static Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  static Future<List<Product>> getActivePOSProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'isActive = ?', whereArgs: [1]);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  static Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // تحديث كمية الصنف (سيتم استخدامها في البيع والمشتريات)
  static Future<void> updateProductStock(String id, double deltaQuantity) async {
    final db = await database;
    await db.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [deltaQuantity, id]);
  }
}
