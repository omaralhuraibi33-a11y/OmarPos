import 'package:flutter/material.dart';

class CashBoxModel {
  String name;
  bool isMain;
  bool autoPost; // للترحيل التلقائي في الصندوق الرئيسي
  bool requireClose; // لخيار إغلاق الصندوق في الصناديق الفرعية

  CashBoxModel({
    required this.name,
    this.isMain = false,
    this.autoPost = true,
    this.requireClose = false,
  });
}

class CashBoxSettingsScreen extends StatefulWidget {
  const CashBoxSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CashBoxSettingsScreen> createState() => _CashBoxSettingsScreenState();
}

class _CashBoxSettingsScreenState extends State<CashBoxSettingsScreen> {
  // القائمة الأولية مع تعيين الصندوق الرئيسي وحمايته
  final List<CashBoxModel> _boxes = [
    CashBoxModel(
      name: 'الصندوق الرئيسي',
      isMain: true,
      autoPost: true,
      requireClose: false,
    ),
    CashBoxModel(
      name: 'صندوق درج الكاشير 1',
      isMain: false,
      autoPost: false,
      requireClose: true,
    ),
  ];

  void _showBoxDialog({CashBoxModel? boxToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: boxToEdit?.name ?? '');
    bool isMain = boxToEdit?.isMain ?? false;
    bool autoPost = boxToEdit?.autoPost ?? false;
    bool requireClose = boxToEdit?.requireClose ?? true;

    // التحقق من حالة الترحيل التلقائي في الصندوق الرئيسي لاستخدامها كشرط
    final mainBox = _boxes.firstWhere((b) => b.isMain, orElse: () => _boxes.first);
    bool isMainAutoPostActive = mainBox.autoPost;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text(editIndex == null
                ? 'إضافة صندوق جديد'
                : (isMain ? 'تعديل الصندوق الرئيسي' : 'تعديل الصندوق')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الصندوق',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isMain) ...[
                    // خيارات الصندوق الرئيسي
                    SwitchListTile(
                      title: const Text('ترحيل تلقائي'),
                      subtitle: const Text(
                        'عند التفعيل: تُرحل المبالغ مباشرة ولا يلزم إغلاق الورديات/الصندوق.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: autoPost,
                      onChanged: (val) {
                        setDlgState(() => autoPost = val);
                      },
                    ),
                  ] else ...[
                    // خيارات الصناديق الفرعية
                    SwitchListTile(
                      title: const Text('يتطلب إغلاق صندوق / وردية'),
                      subtitle: Text(
                        isMainAutoPostActive
                            ? 'معطل حالياً لأن الصندوق الرئيسي مفعّل فيه "الترحيل التلقائي".'
                            : 'تجمع المبالغ هنا ويلزم إغلاق الصندوق لترحيلها للصندوق الرئيسي.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMainAutoPostActive ? Colors.red : Colors.grey.shade700,
                        ),
                      ),
                      value: isMainAutoPostActive ? false : requireClose,
                      onChanged: isMainAutoPostActive
                          ? null // تعطيل المفتاح إذا كان الترحيل التلقائي يعطل الحاجة للتقفيل
                          : (val) {
                              setDlgState(() => requireClose = val);
                            },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      if (editIndex == null) {
                        _boxes.add(CashBoxModel(
                          name: nameCtrl.text.trim(),
                          isMain: false,
                          autoPost: false,
                          requireClose: requireClose,
                        ));
                      } else {
                        _boxes[editIndex].name = nameCtrl.text.trim();
                        _boxes[editIndex].autoPost = autoPost;
                        _boxes[editIndex].requireClose = requireClose;
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الصناديق')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBoxDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _boxes.length,
        itemBuilder: (ctx, i) {
          final box = _boxes[i];
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: box.isMain ? Colors.amber : Colors.blue,
              ),
              title: Row(
                children: [
                  Text(
                    box.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (box.isMain) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'رئيسي',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                box.isMain
                    ? (box.autoPost ? 'ترحيل تلقائي: مفعّل (لا يلزم إغلاق)' : 'ترحيل تلقائي: معطّل')
                    : (box.requireClose ? 'يتطلب إغلاق وردية وترحيل' : 'ترحيل مباشر بدون إغلاق'),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showBoxDialog(boxToEdit: box, editIndex: i),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: box.isMain ? Colors.grey : Colors.red,
                    ),
                    // حظر حذف الصندوق الرئيسي
                    onPressed: box.isMain
                        ? null
                        : () {
                            setState(() => _boxes.removeAt(i));
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
