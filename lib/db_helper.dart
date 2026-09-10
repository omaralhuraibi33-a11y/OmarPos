import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 1,
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

        // إضافة المستخدمين الافتراضيين الموحدين
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
    );
  }

  // جلب كل المستخدمين
  static Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  // جلب المستخدمين المسموح بظهورهم في شاشة تسجيل الدخول
  static Future<List<AppUser>> getLoginUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'showInLogin = ?', whereArgs: [1]);
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  // إضافة/حفظ مستخدم
  static Future<void> saveUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // حذف مستخدم
  static Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
