import 'package:flutter/material.dart';

class WipeDataScreen extends StatelessWidget {
  const WipeDataScreen({Key? key}) : super(key: key);

  void _confirmWipe(BuildContext context, String target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد مسح $target'),
        content: Text('هل أنت تأكد من مسح $target؟ هذه العملية لا يمكن التراجع عنها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم مسح $target بنجاح')),
              );
            },
            child: const Text('مسح نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح البيانات والتصفير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.red),
            title: const Text('مسح جميع المنتجات والمجموعات'),
            onTap: () => _confirmWipe(context, 'المنتجات والمجموعات'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt, color: Colors.red),
            title: const Text('مسح جميع فواتير المبيعات والسجلات'),
            onTap: () => _confirmWipe(context, 'الفواتير والسجلات'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.red),
            title: const Text('مسح بيانات العملاء والموردين'),
            onTap: () => _confirmWipe(context, 'العملاء والموردين'),
          ),
        ],
      ),
    );
  }
}
