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

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  /// دالة عرض إجمالي المبالغ في الصندوق
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

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {'title': 'نقطة البيع', 'icon': Icons.point_of_sale, 'color': Colors.blue, 'page': const PosScreen()},
      {'title': 'المشتريات', 'icon': Icons.shopping_cart, 'color': Colors.orange, 'page': const PurchasesScreen()},
      {'title': 'المخزن', 'icon': Icons.inventory_2, 'color': Colors.teal, 'page': const InventoryScreen()},
      {'title': 'العملاء', 'icon': Icons.people, 'color': Colors.purple, 'page': const CustomersScreen()},
      {'title': 'الموردين', 'icon': Icons.local_shipping, 'color': Colors.indigo, 'page': const SuppliersScreen()},
      {'title': 'التقارير', 'icon': Icons.bar_chart, 'color': Colors.green, 'page': const ReportsScreen()},
      {'title': 'إعدادات النظام', 'icon': Icons.settings, 'color': Colors.blueGrey, 'page': const SettingsScreen()},
      {'title': 'إدارة المستخدمين', 'icon': Icons.admin_panel_settings, 'color': Colors.deepOrange, 'page': const UsersScreen()},
      {'title': 'إغلاق الصندوق / الوردية', 'icon': Icons.lock_clock, 'color': Colors.red, 'page': const ShiftCloseScreen()},
      {'title': 'التقرير المالي', 'icon': Icons.account_balance_wallet, 'color': Colors.lightGreen, 'page': const FinancialReportScreen()},
      {'title': 'السندات', 'icon': Icons.receipt_long, 'color': Colors.amber, 'page': const VouchersScreen()},
      {'title': 'الصندوق', 'icon': Icons.savings, 'color': Colors.brown, 'isCashBox': true},
    ];

    void navigateToScreen(Map<String, dynamic> item) {
      String title = item['title'];
      bool hasPermission = currentUser.isAdmin || (currentUser.permissions[title] ?? false);

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عفواً، لا تملك صلاحية الوصول لقسم: $title'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // إذا كان العنصر هو زر الصندوق، يفتح نافذة الإجمالي مباشرة
      if (item['isCashBox'] == true) {
        _showCashBoxDialog(context);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Directionality(textDirection: TextDirection.rtl, child: item['page']),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          title: Text('الصفحة الرئيسية (${currentUser.name})'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            )
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final item = modules[index];
            bool hasAccess = currentUser.isAdmin || (currentUser.permissions[item['title']] ?? false);

            return Card(
              elevation: hasAccess ? 3 : 1,
              color: hasAccess ? Colors.white : Colors.grey.shade200,
              child: InkWell(
                onTap: () => navigateToScreen(item),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      size: 36,
                      color: hasAccess ? item['color'] : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasAccess ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    if (!hasAccess)
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
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
