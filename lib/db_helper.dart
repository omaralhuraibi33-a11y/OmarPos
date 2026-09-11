import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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

// ==================== نموذج المورد ====================
class Supplier {
  String id;
  String name;
  String phone;
  String notes;
  double balance;

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'balance': balance,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      notes: map['notes'] ?? '',
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

// ==================== نموذج المجموعة (التصنيف) ====================
class Category {
  String id;
  String name;
  String colorHex;
  bool isKitchenPrint;
  bool isActive;

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

// ==================== نموذج الطابعة ====================
class PrinterModel {
  String id;
  String name;
  String type; // مطبخ / زبون
  String connectionType; // بلوتوث / واي فاي
  String paperSize; // 80mm / 58mm
  bool autoPrint;

  PrinterModel({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionType,
    required this.paperSize,
    this.autoPrint = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'connectionType': connectionType,
      'paperSize': paperSize,
      'autoPrint': autoPrint ? 1 : 0,
    };
  }

  factory PrinterModel.fromMap(Map<String, dynamic> map) {
    return PrinterModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      connectionType: map['connectionType'],
      paperSize: map['paperSize'],
      autoPrint: map['autoPrint'] == 1,
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
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String pathName = join(dbPath, 'omar_pos.db');

    return await openDatabase(
      pathName,
      version: 5, // التحديث للنسخة 5 لدعم جداول الإعدادات والطابعات والصناديق
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

        await db.execute('''
          CREATE TABLE suppliers(
            id TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT,
            notes TEXT,
            balance REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE supplier_transactions(
            id TEXT PRIMARY KEY,
            supplierId TEXT,
            type TEXT,
            date TEXT,
            credit REAL,
            debit REAL,
            runningBalance REAL
          )
        ''');

        // جداول الإعدادات الجديدة
        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE printers(
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            connectionType TEXT,
            paperSize TEXT,
            autoPrint INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE prep_notes(
            id TEXT PRIMARY KEY,
            note TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE payment_methods(
            id TEXT PRIMARY KEY,
            name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_boxes(
            id TEXT PRIMARY KEY,
            name TEXT,
            isMain INTEGER
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
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE suppliers(
              id TEXT PRIMARY KEY,
              name TEXT,
              phone TEXT,
              notes TEXT,
              balance REAL
            )
          ''');

          await db.execute('''
            CREATE TABLE supplier_transactions(
              id TEXT PRIMARY KEY,
              supplierId TEXT,
              type TEXT,
              date TEXT,
              credit REAL,
              debit REAL,
              runningBalance REAL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS printers(
              id TEXT PRIMARY KEY,
              name TEXT,
              type TEXT,
              connectionType TEXT,
              paperSize TEXT,
              autoPrint INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS prep_notes(
              id TEXT PRIMARY KEY,
              note TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS payment_methods(
              id TEXT PRIMARY KEY,
              name TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS cash_boxes(
              id TEXT PRIMARY KEY,
              name TEXT,
              isMain INTEGER
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

  // ==================== الموردين وحساباتهم ====================
  static Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('suppliers');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  static Future<void> saveSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert('suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    await db.delete('supplier_transactions', where: 'supplierId = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getSupplierStatement(String supplierId) async {
    final db = await database;
    return await db.query(
      'supplier_transactions',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
  }

  static Future<void> addSupplierTransaction({
    required String supplierId,
    required String type,
    required double credit,
    required double debit,
  }) async {
    final db = await database;
    final supList = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
    if (supList.isEmpty) return;

    double currentBalance = (supList.first['balance'] as num).toDouble();
    double newBalance = currentBalance + credit - debit;

    await db.update('suppliers', {'balance': newBalance}, where: 'id = ?', whereArgs: [supplierId]);

    await db.insert('supplier_transactions', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'supplierId': supplierId,
      'type': type,
      'date': DateTime.now().toString().split('.')[0],
      'credit': credit,
      'debit': debit,
      'runningBalance': newBalance,
    });
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

  static Future<void> updateProductStock(String id, double deltaQuantity) async {
    final db = await database;
    await db.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [deltaQuantity, id]);
  }

  // ==================== إعدادات النظام العامـة ====================
  static Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSetting(String key, {String? defaultValue}) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return defaultValue;
  }

  // ==================== إدارة الطابعات ====================
  static Future<List<PrinterModel>> getAllPrinters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('printers');
    return maps.map((m) => PrinterModel.fromMap(m)).toList();
  }

  static Future<void> savePrinter(PrinterModel printer) async {
    final db = await database;
    await db.insert('printers', printer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deletePrinter(String id) async {
    final db = await database;
    await db.delete('printers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ملاحظات التحضير السريعة ====================
  static Future<List<String>> getPrepNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('prep_notes');
    if (maps.isEmpty) {
      final defaults = ['بدون شطة', 'زيادة بهارات', 'سفري', 'محلي'];
      for (var note in defaults) {
        await addPrepNote(note);
      }
      return defaults;
    }
    return maps.map((m) => m['note'] as String).toList();
  }

  static Future<void> addPrepNote(String note) async {
    final db = await database;
    await db.insert('prep_notes', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${note.hashCode}',
      'note': note,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deletePrepNote(String note) async {
    final db = await database;
    await db.delete('prep_notes', where: 'note = ?', whereArgs: [note]);
  }

  // ==================== إدارة طرق الدفع ====================
  static Future<List<String>> getPaymentMethods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payment_methods');
    if (maps.isEmpty) {
      await addPaymentMethod('نقدي');
      await addPaymentMethod('آجل');
      return ['نقدي', 'آجل'];
    }
    return maps.map((m) => m['name'] as String).toList();
  }

  static Future<void> addPaymentMethod(String name) async {
    final db = await database;
    await db.insert('payment_methods', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deletePaymentMethod(String name) async {
    final db = await database;
    await db.delete('payment_methods', where: 'name = ?', whereArgs: [name]);
  }

  // ==================== إدارة الصناديق ====================
  static Future<List<String>> getCashBoxes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cash_boxes');
    if (maps.isEmpty) {
      await addCashBox('الصندوق الرئيسي', isMain: true);
      await addCashBox('صندوق المبيعات', isMain: false);
      return ['الصندوق الرئيسي', 'صندوق المبيعات'];
    }
    return maps.map((m) => m['name'] as String).toList();
  }

  static Future<void> addCashBox(String name, {bool isMain = false}) async {
    final db = await database;
    await db.insert('cash_boxes', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
      'name': name,
      'isMain': isMain ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteCashBox(String name) async {
    final db = await database;
    await db.delete('cash_boxes', where: 'name = ?', whereArgs: [name]);
  }

  // ==================== مسح البيانات الحساسة ====================

  // 1) حذف كافة الحسابات (عملاء + موردين + حركات مالية)
  static Future<void> clearAllAccountsData() async {
    final db = await database;
    await db.delete('suppliers');
    await db.delete('supplier_transactions');
    await db.delete('customers');
  }

  // 2) حذف كل المجموعات والأصناف
  static Future<void> clearCategoriesAndProducts() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
  }

  // 3) حذف الأصناف فقط
  static Future<void> clearProductsOnly() async {
    final db = await database;
    await db.delete('products');
  }

  // ==================== النسخ الاحتياطي والاستعادة ====================
  static Future<void> closeDatabase() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<String> createBackup() async {
    final dbPath = await getDatabasesPath();
    final pathName = join(dbPath, 'omar_pos.db');

    final appDocDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${backupDir.path}/backup_$timestamp.db';

    final dbFile = File(pathName);
    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
      return backupPath;
    } else {
      throw Exception("ملف قاعدة البيانات غير موجود");
    }
  }

  static Future<void> restoreBackup(String backupFilePath) async {
    final dbPath = await getDatabasesPath();
    final pathName = join(dbPath, 'omar_pos.db');

    final backupFile = File(backupFilePath);
    if (await backupFile.exists()) {
      await closeDatabase();
      await backupFile.copy(pathName);
    } else {
      throw Exception("ملف النسخة الاحتياطية غير صالح");
    }
  }
}
