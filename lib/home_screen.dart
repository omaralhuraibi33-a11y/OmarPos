import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {'title': 'نقطة البيع', 'icon': Icons.point_of_sale, 'color': Colors.blue},
      {'title': 'المشتريات', 'icon': Icons.shopping_cart, 'color': Colors.orange},
      {'title': 'المخزن', 'icon': Icons.inventory_2, 'color': Colors.teal},
      {'title': 'العملاء', 'icon': Icons.people, 'color': Colors.purple},
      {'title': 'الموردين', 'icon': Icons.local_shipping, 'color': Colors.indigo},
      {'title': 'التقارير', 'icon': Icons.bar_chart, 'color': Colors.green},
      {'title': 'إعدادات النظام', 'icon': Icons.settings, 'color': Colors.blueGrey},
      {'title': 'إدارة المستخدمين', 'icon': Icons.admin_panel_settings, 'color': Colors.deepOrange},
      {'title': 'إغلاق الصندوق / الوردية', 'icon': Icons.lock_clock, 'color': Colors.red},
      {'title': 'التقرير المالي', 'icon': Icons.account_balance_wallet, 'color': Colors.lightGreen},
      {'title': 'السندات', 'icon': Icons.receipt_long, 'color': Colors.amber.shade800},
      {'title': 'الصندوق', 'icon': Icons.savings, 'color': Colors.brown},
    ];

    void onModuleClick(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري فتح قسم: $title'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                tooltip: 'قائمة الأقسام',
                onSelected: (value) => onModuleClick(value),
                itemBuilder: (BuildContext context) {
                  return modules.map((module) {
                    return PopupMenuItem<String>(
                      value: module['title'],
                      child: Row(
                        children: [
                          Icon(module['icon'], color: module['color'], size: 20),
                          const SizedBox(width: 10),
                          Text(module['title']),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'الصفحة الرئيسية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Directionality(
                            textDirection: TextDirection.rtl,
                            child: LoginScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = modules[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onModuleClick(item['title']),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 34,
                            color: item['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
