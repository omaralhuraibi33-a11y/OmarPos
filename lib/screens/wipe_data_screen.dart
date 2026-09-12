import 'package:flutter/material.dart';

class WipeDataScreen extends StatelessWidget {
  const WipeDataScreen({Key? key}) : super(key: key);

  void _confirmWipe(BuildContext context, String target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد مسح $target'),
        content: Text('هل أنت متأكد من $target؟ هذه العملية لا يمكن التراجع عنها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم $target بنجاح')),
              );
            },
            child: const Text('تأكيد المسح', style: TextStyle(color: Colors.white)),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.category, color: Colors.red),
              title: const Text(
                'مسح جميع المجموعات والأصناف',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _confirmWipe(context, 'مسح جميع المجموعات والأصناف'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.red),
              title: const Text(
                'مسح جميع الأصناف',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _confirmWipe(context, 'مسح جميع الأصناف'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.red),
              title: const Text(
                'مسح جميع السجلات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _confirmWipe(context, 'مسح جميع السجلات'),
            ),
          ),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.restore_from_trash, color: Colors.red, size: 30),
              title: const Text(
                'تصفير كامل لكل النظام',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () => _confirmWipe(context, 'تصفير كامل لكل النظام'),
            ),
          ),
        ],
      ),
    );
  }
}
