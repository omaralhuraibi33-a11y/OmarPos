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
      permissions: Map<String, bool>.from(jsonDecode(map['permissions'] ?? '{}')),
    );
  }
}

// ==================== نموذج الفاتورة (مبيعات ومشتريات) ====================
class Invoice {
  String id;
  String invoiceType; // 'sale', 'return', 'purchase', 'purchase_return'
  String paymentType; // 'cash' or 'credit'
  double totalAmount;
  String date;
  String? customerId;
  String? customerName;
  String? supplierId;
  String? supplierName;
  String notes;
  int shiftId;
  bool isClosed;

  Invoice({
    required this.id,
    required this.invoiceType,
    required this.paymentType,
    required this.totalAmount,
    required this.date,
    this.customerId,
    this.customerName,
    this.supplierId,
    this.supplierName,
    this.notes = '',
    this.shiftId = 1,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceType': invoiceType,
      'paymentType': paymentType,
      'totalAmount': totalAmount,
      'date': date,
      'customerId': customerId,
      'customerName': customerName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'notes': notes,
      'shiftId': shiftId,
      'isClosed': isClosed ? 1 : 0,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceType: map['invoiceType'] ?? 'sale',
      paymentType: map['paymentType'] ?? 'cash',
      totalAmount: (map['totalAmount'] as num).toDouble(),
      date: map['date'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
      notes: map['notes'] ?? '',
      shiftId: map['shiftId'] ?? 1,
      isClosed: map['isClosed'] == 1,
    );
  }
}

// ==================== نموذج صنف الفاتورة ====================
class InvoiceItem {
  String id;
  String invoiceId;
  String productId;
  String productName;
  double quantity;
  double price;
  double total;
  String notes;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
      'notes': notes,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] ?? '',
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
      phone: map['phone'] ?? '',
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

// ==================== نموذج السندات والمصروفات ====================
class Voucher {
  String id;
  String voucherType;
  String targetType;
  String? targetId;
  String? targetName;
  double amount;
  String date;
  String paymentMethod;
  String notes;
  int shiftId;
  bool isClosed;

  Voucher({
    required this.id,
    required this.voucherType,
    required this.targetType,
    this.targetId,
    this.targetName,
    required this.amount,
    required this.date,
    this.paymentMethod = 'نقدي',
    this.notes = '',
    this.shiftId = 1,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherType': voucherType,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'amount': amount,
      'date': date,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'shiftId': shiftId,
      'isClosed': isClosed ? 1 : 0,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'],
      voucherType: map['voucherType'],
      targetType: map['targetType'],
      targetId: map['targetId'],
      targetName: map['targetName'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
      paymentMethod: map['paymentMethod'] ?? 'نقدي',
      notes: map['notes'] ?? '',
      shiftId: map['shiftId'] ?? 1,
      isClosed: map['isClosed'] == 1,
    );
  }
}

// ==================== نموذج التصنيف ====================
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
      version: 12,
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
          CREATE TABLE invoices(
            id TEXT PRIMARY KEY,
            invoiceType TEXT,
            paymentType TEXT,
            totalAmount REAL,
            date TEXT,
            customerId TEXT,
            customerName TEXT,
            notes TEXT,
            shiftId INTEGER DEFAULT 1,
            isClosed INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE invoice_items(
            id TEXT PRIMARY KEY,
            invoiceId TEXT,
            productId TEXT,
            productName TEXT,
            quantity REAL,
            price REAL,
            total REAL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE return_invoices(
            id TEXT PRIMARY KEY,
            invoiceType TEXT,
            paymentType TEXT,
            totalAmount REAL,
            date TEXT,
            customerId TEXT,
            customerName TEXT,
            notes TEXT,
            shiftId INTEGER DEFAULT 1,
            isClosed INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE return_invoice_items(
            id TEXT PRIMARY KEY,
            invoiceId TEXT,
            productId TEXT,
            productName TEXT,
            quantity REAL,
            price REAL,
            total REAL,
            notes TEXT
          )
        ''');

        // جداول المشتريات والمرتجع المستقلة
        await db.execute('''
          CREATE TABLE purchase_invoices(
            id TEXT PRIMARY KEY,
            invoiceType TEXT,
            paymentType TEXT,
            totalAmount REAL,
            date TEXT,
            supplierId TEXT,
            supplierName TEXT,
            notes TEXT,
            shiftId INTEGER DEFAULT 1,
            isClosed INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE purchase_invoice_items(
            id TEXT PRIMARY KEY,
            invoiceId TEXT,
            productId TEXT,
            productName TEXT,
            quantity REAL,
            price REAL,
            total REAL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE purchase_return_invoices(
            id TEXT PRIMARY KEY,
            invoiceType TEXT,
            paymentType TEXT,
            totalAmount REAL,
            date TEXT,
            supplierId TEXT,
            supplierName TEXT,
            notes TEXT,
            shiftId INTEGER DEFAULT 1,
            isClosed INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE purchase_return_invoice_items(
            id TEXT PRIMARY KEY,
            invoiceId TEXT,
            productId TEXT,
            productName TEXT,
            quantity REAL,
            price REAL,
            total REAL,
            notes TEXT
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
          CREATE TABLE customer_transactions(
            id TEXT PRIMARY KEY,
            customerId TEXT,
            type TEXT,
            date TEXT,
            credit REAL,
            debit REAL,
            runningBalance REAL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE vouchers(
            id TEXT PRIMARY KEY,
            voucherType TEXT,
            targetType TEXT,
            targetId TEXT,
            targetName TEXT,
            amount REAL,
            date TEXT,
            paymentMethod TEXT,
            notes TEXT,
            shiftId INTEGER DEFAULT 1,
            isClosed INTEGER DEFAULT 0
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
            runningBalance REAL,
            notes TEXT
          )
        ''');

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

        await db.execute('''
          CREATE TABLE shifts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime TEXT,
            endTime TEXT,
            userId TEXT,
            userName TEXT,
            totalSales REAL,
            totalExpenses REAL,
            transferredToMainVault REAL,
            status TEXT
          )
        ''');

        // البيانات الافتراضية
        final allPerms = {for (var m in allModules) m: true};
        final cashierPerms = {for (var m in allModules) m: (m == 'نقطة البيع' || m == 'إغلاق الصندوق / الوردية')};
        final supervisorPerms = {for (var m in allModules) m: (m != 'إدارة المستخدمين' && m != 'إعدادات النظام')};

        await db.insert('users', AppUser(id: '1', name: 'المدير العام', pin: '1234', isAdmin: true, showInLogin: true, permissions: allPerms).toMap());
        await db.insert('users', AppUser(id: '2', name: 'كاشير 1', pin: '0000', isAdmin: false, showInLogin: true, permissions: cashierPerms).toMap());
        await db.insert('users', AppUser(id: '3', name: 'كاشير 2', pin: '0000', isAdmin: false, showInLogin: true, permissions: supervisorPerms).toMap());
        await db.insert('users', AppUser(id: '4', name: 'مشرف', pin: '1111', isAdmin: false, showInLogin: true, permissions: supervisorPerms).toMap());

        await db.insert('customers', Customer(id: 'cash_default', name: 'عميل نقدي', phone: '', balance: 0.0).toMap());
        await db.insert('payment_methods', {'id': '1', 'name': 'نقدي'});
        await db.insert('payment_methods', {'id': '2', 'name': 'آجل'});

        await db.insert('shifts', {
          'startTime': DateTime.now().toString(),
          'userId': '1',
          'userName': 'المدير العام',
          'totalSales': 0.0,
          'totalExpenses': 0.0,
          'transferredToMainVault': 0.0,
          'status': 'open'
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 12) {
          await db.execute('CREATE TABLE IF NOT EXISTS purchase_invoices (id TEXT PRIMARY KEY, invoiceType TEXT, paymentType TEXT, totalAmount REAL, date TEXT, supplierId TEXT, supplierName TEXT, notes TEXT, shiftId INTEGER DEFAULT 1, isClosed INTEGER DEFAULT 0)');
          await db.execute('CREATE TABLE IF NOT EXISTS purchase_invoice_items (id TEXT PRIMARY KEY, invoiceId TEXT, productId TEXT, productName TEXT, quantity REAL, price REAL, total REAL, notes TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS purchase_return_invoices (id TEXT PRIMARY KEY, invoiceType TEXT, paymentType TEXT, totalAmount REAL, date TEXT, supplierId TEXT, supplierName TEXT, notes TEXT, shiftId INTEGER DEFAULT 1, isClosed INTEGER DEFAULT 0)');
          await db.execute('CREATE TABLE IF NOT EXISTS purchase_return_invoice_items (id TEXT PRIMARY KEY, invoiceId TEXT, productId TEXT, productName TEXT, quantity REAL, price REAL, total REAL, notes TEXT)');
        }
      },
    );
  }

  // ==================== الإعدادات (Settings) ====================
  static Future<String?> getSetting(String key, {String? defaultValue}) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return defaultValue;
  }

  static Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== إدارة الوردية ====================
  static Future<int> getCurrentShiftId() async {
    final db = await database;
    final res = await db.query('shifts', where: "status = 'open'", orderBy: 'id DESC', limit: 1);
    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return await db.insert('shifts', {
      'startTime': DateTime.now().toString(),
      'userId': '1',
      'userName': 'المدير العام',
      'totalSales': 0.0,
      'totalExpenses': 0.0,
      'transferredToMainVault': 0.0,
      'status': 'open'
    });
  }

  static Future<int> getNextShiftNumber() async {
    final db = await database;
    final res = await db.rawQuery('SELECT MAX(id) as max_id FROM shifts');
    if (res.isNotEmpty && res.first['max_id'] != null) {
      return (res.first['max_id'] as int) + 1;
    }
    return 1;
  }

  static Future<void> closeShift({
    String? userId,
    String? userName,
    double totalSales = 0.0,
    double totalExpenses = 0.0,
    double transferredToMainVault = 0.0,
    int? shiftNumber,
  }) async {
    final db = await database;
    int currentShiftId = shiftNumber ?? await getCurrentShiftId();

    await db.update(
      'shifts',
      {
        'endTime': DateTime.now().toString(),
        'userId': userId ?? '1',
        'userName': userName ?? 'المدير العام',
        'totalSales': totalSales,
        'totalExpenses': totalExpenses,
        'transferredToMainVault': transferredToMainVault,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [currentShiftId],
    );

    await db.update('invoices', {'isClosed': 1}, where: 'shiftId = ?', whereArgs: [currentShiftId]);
    await db.update('return_invoices', {'isClosed': 1}, where: 'shiftId = ?', whereArgs: [currentShiftId]);
    await db.update('purchase_invoices', {'isClosed': 1}, where: 'shiftId = ?', whereArgs: [currentShiftId]);
    await db.update('purchase_return_invoices', {'isClosed': 1}, where: 'shiftId = ?', whereArgs: [currentShiftId]);
    await db.update('vouchers', {'isClosed': 1}, where: 'shiftId = ?', whereArgs: [currentShiftId]);

    await db.insert('shifts', {
      'startTime': DateTime.now().toString(),
      'userId': userId ?? '1',
      'userName': userName ?? 'المدير العام',
      'totalSales': 0.0,
      'totalExpenses': 0.0,
      'transferredToMainVault': 0.0,
      'status': 'open'
    });
  }

  // ==================== المبيعات ====================
  static Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('invoices', orderBy: 'date DESC');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  static Future<void> saveInvoice(Invoice invoice) async {
    final db = await database;
    if (invoice.shiftId <= 0) invoice.shiftId = await getCurrentShiftId();
    await db.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

    if (invoice.paymentType == 'credit' && invoice.customerId != null) {
      if (invoice.invoiceType == 'sale') {
        await addCustomerTransaction(
          customerId: invoice.customerId!,
          type: 'فاتورة مبيعات أجلة',
          credit: 0.0,
          debit: invoice.totalAmount,
          date: invoice.date,
          notes: invoice.notes,
        );
      }
    }
  }

  static Future<void> saveInvoiceItem(InvoiceItem item) async {
    final db = await database;
    if (!item.id.contains('_item_')) {
      item.id = '${item.invoiceId}_${item.productId}_${DateTime.now().microsecondsSinceEpoch}';
    }
    await db.insert('invoice_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  // ==================== مرتجع المبيعات ====================
  static Future<List<Invoice>> getAllReturnInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('return_invoices', orderBy: 'date DESC');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  static Future<void> saveReturnInvoice(Invoice invoice) async {
    final db = await database;
    if (invoice.shiftId <= 0) invoice.shiftId = await getCurrentShiftId();
    await db.insert('return_invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

    if (invoice.paymentType == 'credit' && invoice.customerId != null) {
      await addCustomerTransaction(
        customerId: invoice.customerId!,
        type: 'مرتجع مبيعات',
        credit: invoice.totalAmount,
        debit: 0.0,
        date: invoice.date,
        notes: invoice.notes,
      );
    }
  }

  static Future<void> saveReturnInvoiceItem(InvoiceItem item) async {
    final db = await database;
    if (!item.id.contains('_item_')) {
      item.id = '${item.invoiceId}_${item.productId}_${DateTime.now().microsecondsSinceEpoch}';
    }
    await db.insert('return_invoice_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<InvoiceItem>> getReturnInvoiceItems(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('return_invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  // ==================== فواتير المشتريات ====================
  static Future<List<Invoice>> getAllPurchaseInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_invoices', orderBy: 'date DESC');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  static Future<void> savePurchaseInvoice(Invoice invoice) async {
    final db = await database;
    if (invoice.shiftId <= 0) invoice.shiftId = await getCurrentShiftId();
    await db.insert('purchase_invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

    if (invoice.supplierId != null) {
      await addSupplierTransaction(
        supplierId: invoice.supplierId!,
        type: invoice.paymentType == 'credit' ? 'فاتورة مشتريات أجلة' : 'فاتورة مشتريات نقدية',
        credit: invoice.paymentType == 'credit' ? invoice.totalAmount : 0.0,
        debit: 0.0,
        date: invoice.date,
        notes: invoice.notes,
      );
    }
  }

  static Future<void> savePurchaseInvoiceItem(InvoiceItem item) async {
    final db = await database;
    if (!item.id.contains('_item_')) {
      item.id = '${item.invoiceId}_${item.productId}_${DateTime.now().microsecondsSinceEpoch}';
    }
    await db.insert('purchase_invoice_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<InvoiceItem>> getPurchaseInvoiceItems(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  // ==================== مرتجع المشتريات ====================
  static Future<List<Invoice>> getAllPurchaseReturnInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_return_invoices', orderBy: 'date DESC');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  static Future<void> savePurchaseReturnInvoice(Invoice invoice) async {
    final db = await database;
    if (invoice.shiftId <= 0) invoice.shiftId = await getCurrentShiftId();
    await db.insert('purchase_return_invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

    if (invoice.supplierId != null) {
      await addSupplierTransaction(
        supplierId: invoice.supplierId!,
        type: 'مرتجع مشتريات',
        credit: 0.0,
        debit: invoice.totalAmount,
        date: invoice.date,
        notes: invoice.notes,
      );
    }
  }

  static Future<void> savePurchaseReturnInvoiceItem(InvoiceItem item) async {
    final db = await database;
    if (!item.id.contains('_item_')) {
      item.id = '${item.invoiceId}_${item.productId}_${DateTime.now().microsecondsSinceEpoch}';
    }
    await db.insert('purchase_return_invoice_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<InvoiceItem>> getPurchaseReturnInvoiceItems(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_return_invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  // ==================== الأصناف والمخزن ====================
  static Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
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

  // ==================== التصنيفات (Categories) ====================
  static Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
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

  // ==================== العملاء والحركات ====================
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

  static Future<Customer> getOrCreateDefaultCustomer() async {
    final db = await database;
    final res = await db.query('customers', where: "id = 'cash_default'");
    if (res.isNotEmpty) {
      return Customer.fromMap(res.first);
    }
    final defaultCust = Customer(id: 'cash_default', name: 'عميل نقدي', phone: '', balance: 0.0);
    await db.insert('customers', defaultCust.toMap());
    return defaultCust;
  }

  static Future<void> addCustomerTransaction({
    required String customerId,
    required String type,
    required double credit,
    required double debit,
    String? date,
    String? notes,
  }) async {
    final db = await database;
    final cust = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
    if (cust.isEmpty) return;

    double currentBalance = (cust.first['balance'] as num).toDouble();
    double newBalance = currentBalance + debit - credit;

    await db.update('customers', {'balance': newBalance}, where: 'id = ?', whereArgs: [customerId]);

    await db.insert('customer_transactions', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'customerId': customerId,
      'type': type,
      'date': date ?? DateTime.now().toString().split('.')[0],
      'credit': credit,
      'debit': debit,
      'runningBalance': newBalance,
      'notes': notes ?? '',
    });
  }

  static Future<List<CustomerTransaction>> getCustomerTransactions(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_transactions',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => CustomerTransaction.fromMap(m)).toList();
  }

  // ==================== الموردين والحركات ====================
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
  }

  static Future<void> addSupplierTransaction({
    required String supplierId,
    required String type,
    required double credit,
    required double debit,
    String? date,
    String? notes,
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
      'date': date ?? DateTime.now().toString().split('.')[0],
      'credit': credit,
      'debit': debit,
      'runningBalance': newBalance,
      'notes': notes ?? '',
    });
  }

  static Future<List<Map<String, dynamic>>> getSupplierStatement(String supplierId) async {
    final db = await database;
    return await db.query('supplier_transactions', where: 'supplierId = ?', whereArgs: [supplierId], orderBy: 'date DESC');
  }

  // ==================== السندات (Vouchers) ====================
  static Future<List<Voucher>> getAllVouchers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vouchers', orderBy: 'date DESC');
    return maps.map((m) => Voucher.fromMap(m)).toList();
  }

  static Future<void> addVoucher(Voucher voucher) async {
    final db = await database;
    if (voucher.shiftId <= 0) voucher.shiftId = await getCurrentShiftId();
    await db.insert('vouchers', voucher.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==================== المستخدمين والصلاحيات ====================
  static Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
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

  // ==================== التقارير المالية والإحصائيات ====================
  static Future<double> getTotalSales() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices WHERE invoiceType = ?', ['sale']);
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getTotalPurchases() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(totalAmount) as total FROM purchase_invoices');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getSalesCost() async {
    return 0.0; // يمكن تعديلها حسب رغبتك لحساب التكلفة الفعلية
  }

  static Future<double> getTotalRevenues() async {
    final db = await database;
    final res = await db.rawQuery("SELECT SUM(amount) as total FROM vouchers WHERE voucherType = 'سند قبض'");
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getTotalExpenses() async {
    final db = await database;
    final res = await db.rawQuery("SELECT SUM(amount) as total FROM vouchers WHERE voucherType = 'سند صرف' OR voucherType = 'مصروفات'");
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getSuppliersTotalBalance() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(balance) as total FROM suppliers');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getCustomersTotalBalance() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(balance) as total FROM customers');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getMainVaultBalance() async {
    final sales = await getTotalSales();
    final revenues = await getTotalRevenues();
    final expenses = await getTotalExpenses();
    return sales + revenues - expenses;
  }

  static Future<double> getSalesReturnsTotal() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(totalAmount) as total FROM return_invoices');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> getPurchasesReturnsTotal() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(totalAmount) as total FROM purchase_return_invoices');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // ==================== الملاحظات وطرق الدفع والطابعات ====================
  static Future<List<Map<String, dynamic>>> getPreparationNotes() async {
    final db = await database;
    return await db.query('prep_notes');
  }

  static Future<void> addPreparationNote(String note) async {
    final db = await database;
    await db.insert('prep_notes', {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'note': note});
  }

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final db = await database;
    return await db.query('payment_methods');
  }

  static Future<List<Map<String, dynamic>>> getUnclosedInvoices() async {
    final db = await database;
    return await db.query('invoices', where: 'isClosed = 0');
  }

  static Future<List<Map<String, dynamic>>> getUnclosedVouchers() async {
    final db = await database;
    return await db.query('vouchers', where: 'isClosed = 0');
  }

  static Future<void> resetAllRecordsAndBalances() async {
    final db = await database;
    await db.delete('invoices');
    await db.delete('invoice_items');
    await db.delete('return_invoices');
    await db.delete('return_invoice_items');
    await db.delete('purchase_invoices');
    await db.delete('purchase_invoice_items');
    await db.delete('purchase_return_invoices');
    await db.delete('purchase_return_invoice_items');
    await db.delete('vouchers');
    await db.delete('customer_transactions');
    await db.delete('supplier_transactions');
    await db.update('customers', {'balance': 0.0});
    await db.update('suppliers', {'balance': 0.0});
    await db.update('products', {'quantity': 0.0});
  }

  static Future<void> resetFullSystemToDefault() async {
    final db = await database;
    await db.delete('invoices');
    await db.delete('invoice_items');
    await db.delete('return_invoices');
    await db.delete('return_invoice_items');
    await db.delete('purchase_invoices');
    await db.delete('purchase_invoice_items');
    await db.delete('purchase_return_invoices');
    await db.delete('purchase_return_invoice_items');
    await db.delete('vouchers');
    await db.delete('customers');
    await db.delete('suppliers');
    await db.delete('products');
    await db.delete('categories');
    
    // إعادة إنشاء العميل النقدي الافتراضي
    await db.insert('customers', Customer(id: 'cash_default', name: 'عميل نقدي', phone: '', balance: 0.0).toMap());
  }

  // ==================== النسخ الاحتياطي ====================
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
}
