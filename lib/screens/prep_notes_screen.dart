import 'package:flutter/material.dart';

class PrepNotesScreen extends StatefulWidget {
  const PrepNotesScreen({Key? key}) : super(key: key);

  @override
  State<PrepNotesScreen> createState() => _PrepNotesScreenState();
}

class _PrepNotesScreenState extends State<PrepNotesScreen> {
  final List<String> _notes = ['بدون شطة', 'زيادة بهارات', 'سفري', 'محلي', 'بدون ثوم'];

  void _showAddEditDialog({String? initialValue, int? index}) {
    final ctrl = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'إضافة ملاحظة تحضير' : 'تعديل الملاحظة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'الملاحظة (مثال: بدون ملح)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  if (index == null) {
                    _notes.add(ctrl.text.trim());
                  } else {
                    _notes[index] = ctrl.text.trim();
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة ملاحظات التحضير')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            title: Text(_notes[i]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddEditDialog(initialValue: _notes[i], index: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _notes.removeAt(i)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
