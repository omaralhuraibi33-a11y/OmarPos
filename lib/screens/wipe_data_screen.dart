import 'package:flutter/material.dart';
import 'db_helper.dart';

class WipeDataScreen extends StatelessWidget {
  const WipeDataScreen({Key? key}) : super(key: key);

  void _confirmWipe(BuildContext context, String actionType, Future<void> Function() onAction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد $actionType'),
        content: Text('هل أنت متأكد من $actionType؟ هذه العملية نهائية ولا يمكن التراجع عنها.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await onAction();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم $actionType بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء التنفيذ: $e')),
                  );
                }
              }
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
      appBar: AppBar(
        title: const Text('مسح البيانات والتصفير'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. زر تصفير السجلات وحركات الأرقام فقط
          Card(
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.history_edu, color: Colors.orange, size: 32),
              title: const Text(
                'تصفير جميع السجلات والأرقام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text(
                'مسح الفواتير والسندات وتصفير كميات المخزن والأرصدة دون حذف الأصناف أو العملاء/الموردين',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => _confirmWipe(
                context, 
                'تصفير جميع السجلات والأرقام', 
                DBHelper.resetAllRecordsAndBalances,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. زر تصفير كامل النظام
          Card(
            elevation: 3,
            color: Colors.red.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.restore_from_trash, color: Colors.red, size: 36),
              title: const Text(
                'تصفير كامل للنظام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
              subtitle: const Text(
                'مسح شامل لجميع البيانات، المجموعات، الأصناف، العملاء والموردين وإعادة النظام للحالة الافتراضية',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
              onTap: () => _confirmWipe(
                context, 
                'تصفير كامل للنظام', 
                DBHelper.resetFullSystemToDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
