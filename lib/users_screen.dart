import 'package:flutter/material.dart';
import 'db_helper.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final data = await DBHelper.getAllUsers();
    setState(() {
      users = data;
      isLoading = false;
    });
  }

  void _showUserDialog({AppUser? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: isEditing ? user.name : '');
    final pinController = TextEditingController(text: isEditing ? user.pin : '');
    bool showInLogin = isEditing ? user.showInLogin : true;
    final bool isAdmin = isEditing ? user.isAdmin : false;

    Map<String, bool> permissions = {};
    for (var module in DBHelper.allModules) {
      permissions[module] = isEditing ? (user.permissions[module] ?? false) : false;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل بيانات: ${user.name}' : 'إضافة مستخدم جديد'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'رمز الدخول (PIN)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('الظهور في تسجيل الدخول'),
                        value: showInLogin,
                        onChanged: (val) => setDialogState(() => showInLogin = val),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (!isAdmin)
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  bool allChecked = permissions.values.every((e) => e);
                                  permissions.updateAll((k, v) => !allChecked);
                                });
                              },
                              child: Text(permissions.values.every((e) => e) ? 'إلغاء الكل' : 'تحديد الكل'),
                            ),
                        ],
                      ),
                      ...DBHelper.allModules.map((module) {
                        return CheckboxListTile(
                          title: Text(module),
                          value: isAdmin ? true : (permissions[module] ?? false),
                          enabled: !isAdmin,
                          onChanged: (val) {
                            setDialogState(() => permissions[module] = val ?? false);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    AppUser updatedUser = AppUser(
                      id: isEditing ? user.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      pin: pinController.text.trim(),
                      isAdmin: isAdmin,
                      showInLogin: showInLogin,
                      permissions: isAdmin ? {for (var m in DBHelper.allModules) m: true} : permissions,
                    );

                    await DBHelper.saveUser(updatedUser);
                    if (mounted) Navigator.pop(context);
                    _loadUsers();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(AppUser user) {
    if (user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حذف المدير الرئيسي!')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت أؤكد حذف المستخدم "${user.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await DBHelper.deleteUser(user.id);
              if (mounted) Navigator.pop(context);
              _loadUsers();
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
      appBar: AppBar(title: const Text('إدارة المستخدمين والصلاحيات'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isAdmin ? Colors.deepOrange : Colors.indigo,
                      foregroundColor: Colors.white,
                      child: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.person),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.showInLogin ? 'يظهر في تسجيل الدخول' : 'مخفي من تسجيل الدخول'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUserDialog(user: user)),
                        if (!user.isAdmin)
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(user)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
