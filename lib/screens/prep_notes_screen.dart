import 'package:flutter/material.dart';
import 'package:omar_pos/db_helper.dart';

class PrepNotesScreen extends StatefulWidget {
  const PrepNotesScreen({Key? key}) : super(key: key);

  @override
  State<PrepNotesScreen> createState() => _PrepNotesScreenState();
}

class _PrepNotesScreenState extends State<PrepNotesScreen> {
  List<String> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrepNotes();
  }

  // جلب الملاحظات من جدول prep_notes في قاعدة البيانات
  Future<void> _loadPrepNotes() async {
    setState(() => _isLoading = true);
    try {
      final savedNotes = await DBHelper.getPrepNotes();
      setState(() {
        _notes = savedNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // إضافة ملاحظة جديدة مباشرة إلى قاعدة البيانات
  Future<void> _addNote(String note) async {
    await DBHelper.addPrepNote(note);
    await _loadPrepNotes(); // إعادة تحميل القائمة من القاعدة
  }

  // حذف ملاحظة من قاعدة البيانات
  Future<void> _deleteNote(String note) async {
    await DBHelper.deletePrepNote(note);
    await _loadPrepNotes(); // إعادة تحميل القائمة من القاعدة
  }

  void _showAddEditDialog({String? initialValue}) {
    final ctrl = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initialValue == null ? 'إضافة ملاحظة تحضير' : 'تعديل الملاحظة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'الملاحظة (مثال: بدون ملح)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final trimmedText = ctrl.text.trim();
              if (trimmedText.isNotEmpty) {
                Navigator.pop(ctx);
                
                // إذا كان تعديلاً، نحذف القديمة ونضيف الجديدة أو نتعامل معها
                if (initialValue != null && initialValue != trimmedText) {
                  await DBHelper.deletePrepNote(initialValue);
                }
                
                await _addNote(trimmedText);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الحفظ بنجاح في قاعدة البيانات'),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة ملاحظات التحضير'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد ملاحظات مضافة حالياً',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        _notes[i],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditDialog(initialValue: _notes[i]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteNote(_notes[i]);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف الملاحظة'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(milliseconds: 1500),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
