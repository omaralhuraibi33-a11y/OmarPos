import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'login_screen.dart';

import 'pos_screen.dart';
import 'purchases_screen.dart';
import 'inventory_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';
import 'shift_close_screen.dart';
import 'financial_report_screen.dart';
import 'vouchers_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mainButtonSizeSetting = 'وسط';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedSize = await DBHelper.getSetting('main_button_size');
    if (mounted) {
      setState(() {
        if (savedSize != null) {
          _mainButtonSizeSetting = savedSize;
        }
        _isLoading = false;
      });
    }
  }

  int _getCrossAxisCount() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 3;
      case 'كبير':
        return 2;
      case 'وسط':
      default:
        return 2;
    }
  }

  double _getIconSize() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 28.0;
      case 'كبير':
        return 48.0;
      case 'وسط':
      default:
        return 36.0;
    }
  }

  double _getFontSize() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 12.0;
      case 'كبير':
        return 16.0;
      case 'وسط':
      default:
        return 14.0;
    }
  }

  double _getChildAspectRatio() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 1.0;
      case 'كبير':
        return 1.2;
      case 'وسط':
      default:
        return 1.1;
    }
  }

  void _showCashBoxDialog(BuildContext context) async {
    double balance = await DBHelper.getMainVaultBalance();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إجمالي الصندوق الحالي',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 50, color: Colors.green),
            const SizedBox(height: 15),
            Text(
              balance.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// نافذة تغيير كلمة المرور للمستخدم الحالي
  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تغيير رمز الدخول (PIN)', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز الدخول الحالي',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز الدخول الجديد',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تأكيد الرمز الجديد',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (oldPinController.text != widget.currentUser.pin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رمز الدخول الحالي غير صحيح!'), backgroundColor: Colors.red),
                );
                return;
              }

              if (newPinController.text.isEmpty || newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرمز الجديد غير متطابق!'), backgroundColor: Colors.red),
                );
                return;
              }

              // تحديث الرمز في قاعدة البيانات
              final updatedUser = AppUser(
                id: widget.currentUser.id,
                name: widget.currentUser.name,
                pin: newPinController.text,
                isAdmin: widget.currentUser.isAdmin,
                permissions: widget.currentUser.permissions,
              );

              await DBHelper.updateUser(updatedUser);
              
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تغيير رمز الدخول بنجاح!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    final List<Map<String, dynamic>> allModules = [
      {'title': 'نقطة البيع', 'icon': Icons.point_of_sale, 'color': Colors.blue, 'page': PosScreen(currentUser: widget.currentUser)},
      {'title': 'المشتريات', 'icon': Icons.shopping_cart, 'color': Colors.orange, 'page': const PurchasesScreen()},
      {'title': 'المخزن', 'icon': Icons.inventory_2, 'color': Colors.teal, 'page': const InventoryScreen()},
      {'title': 'العملاء', 'icon': Icons.people, 'color': Colors.purple, 'page': const CustomersScreen()},
      {'title': 'الموردين', 'icon': Icons.local_shipping, 'color': Colors.indigo, 'page': const SuppliersScreen()},
      {'title': 'التقارير', 'icon': Icons.bar_chart, 'color': Colors.green, 'page': const ReportsScreen()},
      {'title': 'إعدادات النظام', 'icon': Icons.settings, 'color': Colors.blueGrey, 'page': const SettingsScreen()},
      {'title': 'إدارة المستخدمين', 'icon': Icons.admin_panel_settings, 'color': Colors.deepOrange, 'page': const UsersScreen()},
      {'title': 'إغلاق الصندوق / الوردية', 'icon': Icons.lock_clock, 'color': Colors.red, 'page': ShiftCloseScreen(currentUser: widget.currentUser)},
      {'title': 'التقرير المالي', 'icon': Icons.account_balance_wallet, 'color': Colors.lightGreen, 'page': const FinancialReportScreen()},
      {'title': 'السندات', 'icon': Icons.receipt_long, 'color': Colors.amber, 'page': const VouchersScreen()},
      {'title': 'الصندوق', 'icon': Icons.savings, 'color': Colors.brown, 'isCashBox': true},
    ];

    // إظهار الأزرار المسموح بها فقط للمستخدم
    final visibleModules = allModules.where((item) {
      String title = item['title'];
      return widget.currentUser.isAdmin || (widget.currentUser.permissions[title] ?? false);
    }).toList();

    void navigateToScreen(Map<String, dynamic> item) async {
      if (item['isCashBox'] == true) {
        _showCashBoxDialog(context);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Directionality(textDirection: TextDirection.rtl, child: item['page']),
        ),
      );

      _loadSettings();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: Text('الصفحة الرئيسية (${widget.currentUser.name})'),
        ),
        // --- القائمة الجانبية السريعة ---
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: primaryColor),
                accountName: Text(
                  widget.currentUser.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(widget.currentUser.isAdmin ? 'مدير النظام' : 'مستخدم عادي'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: primaryColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.blue),
                title: const Text('تغيير رمز الدخول (PIN)'),
                onTap: () {
                  Navigator.pop(context); // إغلاق القائمة الجانبية
                  _showChangePinDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : visibleModules.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد صلاحيات متاحة لهذا الحساب',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleModules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: _getChildAspectRatio(),
                    ),
                    itemBuilder: (context, index) {
                      final item = visibleModules[index];

                      return Card(
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => navigateToScreen(item),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item['icon'],
                                size: _getIconSize(),
                                color: item['color'],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['title'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getFontSize(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
