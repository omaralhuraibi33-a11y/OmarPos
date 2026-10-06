import 'package:flutter/material.dart';
import 'package:omar_pos/db_helper.dart';
import 'dart:convert'; // للتعامل مع حفظ القائمة بصيغة JSON

class PrepNotesScreen extends StatefulWidget {
  const PrepNotesScreen({Key? key}) : super(key: key);

  @override
  State<PrepNotesScreen> createState() => _PrepNotesScreenState();
}

class _PrepNotesScreenState extends State<PrepNotesScreen> {
  List<String> _notes = ['بدون شطة', 'زيادة بهارات', 'سفري', 'محلي', 'بدون ثوم'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrepNotes();
  }

  // جلب الملاحظات المخزنة من قاعدة البيانات
  Future<void> _loadPrepNotes() async {
    final savedNotesJson = await DBHelper.getSetting('prep_notes');
    
    if (savedNotesJson != null && savedNotesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedNotesJson);
        setState(() {
          _notes = decoded.map((e) => e.toString()).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  // حفظ الملاحظات في قاعدة البيانات
  Future<void> _savePrepNotes() async {
    final encodedNotes = jsonEncode(_notes);
    await DBHelper.saveSetting('prep_notes', encodedNotes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ ملاحظات التحضير بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddEditDialog({String? initialValue, int? index}) {
    final ctrl = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'إضافة ملاحظة تحضير' : 'تعديل الملاحظة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'الملاحظة (مثال: بدون ملح)',
            border: OutlineInputBorder(),
          ),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // زر حفظ علوي سريع
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ التغييرات',
            onPressed: _savePrepNotes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notes.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_notes[i], style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ),
                // زر الحفظ الرئيسي في أسفل الشاشة
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _savePrepNotes,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ ملاحظات التحضير', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
