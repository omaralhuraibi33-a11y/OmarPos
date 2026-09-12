import 'package:flutter/material.dart';

class CashBoxSettingsScreen extends StatefulWidget {
  const CashBoxSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CashBoxSettingsScreen> createState() => _CashBoxSettingsScreenState();
}

class _CashBoxSettingsScreenState extends State<CashBoxSettingsScreen> {
  final List<String> _boxes = ['الصندوق الرئيسي', 'صندوق درج الكاشير 1'];

  void _addCashBox() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة صندوق جديد'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'اسم الصندوق')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _boxes.add(ctrl.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الصناديق')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCashBox,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _boxes.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
            title: Text(_boxes[i]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _boxes.removeAt(i)),
            ),
          ),
        ),
      ),
    );
  }
}
