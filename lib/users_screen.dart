import 'package:flutter/material.dart';

// نموذج بيانات المستخدم
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
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // قائمة الأقسام/الأزرار الـ 12 في الشاشة الرئيسية
  final List<String> allModules = [
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

  // قائمة المستخدمين الافتراضية
  late List<AppUser> users;

  @override
  void initState() {
    super.initState();
    users = [
      AppUser(
        id: '1',
        name: 'المدير العام',
        pin: '1234',
        isAdmin: true,
        showInLogin: true,
        permissions: {for (var m in allModules) m: true}, // كامل الوصول
      ),
      AppUser(
        id: '2',
        name: 'الكاشير',
        pin: '0000',
        isAdmin: false,
        showInLogin: true,
        permissions: {
          'نقطة البيع': true,
          'إغلاق الصندوق / الوردية': true,
          'المشتريات': false,
          'المخزن': false,
          'العملاء': false,
          'الموردين': false,
          'التقارير': false,
          'إعدادات النظام': false,
          'إدارة المستخدمين': false,
          'التقرير المالي': false,
          'السندات': false,
          'الصندوق': false,
        },
      ),
      AppUser(
        id: '3',
        name: 'المحاسب',
        pin: '1111',
        isAdmin: false,
        showInLogin: true,
        permissions: {
          'نقطة البيع': false,
          'المشتريات': true,
          'المخزن': true,
          'العملاء': true,
          'الموردين': true,
          'التقارير': true,
          'إعدادات النظام': false,
          'إدارة المستخدمين': false,
          'إغلاق الصندوق / الوردية': true,
          'التقرير المالي': true,
          'السندات': true,
          'الصندوق': true,
        },
      ),
    ];
  }

  // نافذة إضافة أو تعديل مستخدم
  void _showUserDialog({AppUser? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: isEditing ? user.name : '');
    final pinController = TextEditingController(text: isEditing ? user.pin : '');
    bool showInLogin = isEditing ? user.showInLogin : true;
    final bool isAdmin = isEditing ? user.isAdmin : false;

    // تهيئة جدول الصلاحيات للنافذة
    Map<String, bool> permissions = {};
    for (var module in allModules) {
      if (isEditing) {
        permissions[module] = user.permissions[module] ?? false;
      } else {
        permissions[module] = false;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'تعديل بيانات: ${user.name}' : 'إضافة مستخدم جديد',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'رمز الدخول (PIN)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('الظهور في شاشة تسجيل الدخول', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('عند التفعيل يظهر اسمه بداخل قائمة خيارات الدخول'),
                        value: showInLogin,
                        onChanged: (val) {
                          setDialogState(() {
                            showInLogin = val;
                          });
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صلاحيات الوصول للأقسام:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (!isAdmin)
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  bool allChecked = permissions.values.every((e) => e);
                                  permissions.updateAll((key, value) => !allChecked);
                                });
                              },
                              child: Text(permissions.values.every((e) => e) ? 'إلغاء الكل' : 'تحديد الكل'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // قائمة الصلاحيات الـ 12
                      ...allModules.map((module) {
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(module, style: const TextStyle(fontSize: 14)),
                          value: isAdmin ? true : (permissions[module] ?? false),
                          enabled: !isAdmin, // المدير يملك الكل دائماً
                          onChanged: (bool? value) {
                            setDialogState(() {
                              permissions[module] = value ?? false;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال اسم المستخدم')),
                      );
                      return;
                    }

                    setState(() {
                      if (isEditing) {
                        user.name = nameController.text.trim();
                        user.pin = pinController.text.trim();
                        user.showInLogin = showInLogin;
                        if (!user.isAdmin) {
                          user.permissions = permissions;
                        }
                      } else {
                        users.add(
                          AppUser(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            pin: pinController.text.trim(),
                            isAdmin: false,
                            showInLogin: showInLogin,
                            permissions: permissions,
                          ),
                        );
                      }
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'تم حفظ التعديلات بنجاح' : 'تم إضافة المستخدم بنجاح'),
                      ),
                    );
                  },
                  child: Text(isEditing ? 'حفظ' : 'إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // حذف مستخدم
  void _deleteUser(AppUser user) {
    if (user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف حساب المدير الرئيسي!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت أؤكد حذف المستخدم "${user.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                users.removeWhere((u) => u.id == user.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين والصلاحيات'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final activePermissionsCount = user.isAdmin
              ? allModules.length
              : user.permissions.values.where((v) => v).length;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: user.isAdmin ? Colors.deepOrange : Colors.indigo,
                        foregroundColor: Colors.white,
                        child: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (user.isAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'مدير النظام',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isAdmin
                                  ? 'صلاحية كاملة لكل أجزاء النظام'
                                  : 'الصلاحيات المتاحة: $activePermissionsCount من ${allModules.length}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'تعديل البيانات والصلاحيات',
                        onPressed: () => _showUserDialog(user: user),
                      ),
                      if (!user.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'حذف',
                          onPressed: () => _deleteUser(user),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            user.showInLogin ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: user.showInLogin ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.showInLogin ? 'يظهر في شاشة تسجيل الدخول' : 'مخفي من شاشة تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 12,
                              color: user.showInLogin ? Colors.green.shade800 : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'رمز (PIN): ****',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مستخدم'),
      ),
    );
  }
}
