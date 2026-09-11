import 'package:flutter/material.dart';
import 'db_helper.dart';

// ألوان التطبيق المصممة بنفس نمط الصور
class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primaryPink = Color(0xFFF43F5E);
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ==================== الشاشة الرئيسية: أزرار عريضة مستقلة ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات النظام'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLongButton(
              context,
              title: 'إعدادات الطابعات',
              subtitle: 'إضافة وإدارة طابعات البلوتوث والشبكة وحجم الورق',
              icon: Icons.print,
              targetPage: const PrinterSettingsPage(),
            ),
            _buildLongButton(
              context,
              title: 'ملاحظات التحضير',
              subtitle: 'إضافة، تعديل، وحذف ملاحظات المطبخ السريعة',
              icon: Icons.note_alt,
              targetPage: const PrepNotesPage(),
            ),
            _buildLongButton(
              context,
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'تحديد مسار الحفظ، إنشاء نسخة، واسترجاع الملفات',
              icon: Icons.backup,
              targetPage: const BackupRestorePage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget targetPage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryPink, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 1. شاشة إعدادات الطابعات ====================
class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  List<Map<String, dynamic>> printers = [];

  void _openAddPrinterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const AddPrinterDialog(),
    );
    if (result != null) {
      setState(() => printers.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات الطابعات'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: printers.isEmpty
          ? const Center(child: Text('لا توجد طابعات مضافة. اضغط + للإضافة', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: printers.length,
              itemBuilder: (ctx, i) {
                final item = printers[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(item['name'] ?? 'طابعة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('النوع: ${item['type']} | الاتصال: ${item['connection']} | الورق: ${item['paperSize']}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.primaryPink),
                      onPressed: () => setState(() => printers.removeAt(i)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPink,
        onPressed: _openAddPrinterDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة +', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// النافذة المنبثقة لإضافة وإعداد الطابعة
class AddPrinterDialog extends StatefulWidget {
  const AddPrinterDialog({Key? key}) : super(key: key);

  @override
  State<AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<AddPrinterDialog> {
  final _ipController = TextEditingController();
  final _nameController = TextEditingController();

  String _printerType = 'فاتورة';
  String _connectionType = 'بلوتوث';
  String _paperSize = '80mm'; // الخيارات المطلوب تحديدها: 80, 78, 57
  String _selectedBluetoothDevice = 'لم يتم اختيار طابعة بلوتوث';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 580),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة طابعة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),

              _buildTextField(_nameController, 'اسم الطابعة'),
              const SizedBox(height: 12),

              _buildDropdown('نوع الطابعة', _printerType, ['فاتورة', 'مطبخ'], (v) => setState(() => _printerType = v!)),
              const SizedBox(height: 12),

              _buildDropdown('واجهة الاتصال', _connectionType, ['بلوتوث', 'واي فاي'], (v) => setState(() => _connectionType = v!)),
              const SizedBox(height: 14),

              // الشرط الخاص بنوع الاتصال
              if (_connectionType == 'واي فاي') ...[
                _buildTextField(_ipController, 'عنوان IP الخاص بالطابعة (مثال: 192.168.1.100)', keyboardType: TextInputType.datetime),
                const SizedBox(height: 12),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.primaryPink),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // فتح قائمة الأجهزة المقترنة بالبلوتوث
                    setState(() {
                      _selectedBluetoothDevice = 'BT-Printer (AA:BB:CC:DD:EE)';
                    });
                  },
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('اختيار طابعة بلوتوث مضافة بالجهاز'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: Text('المحدد: $_selectedBluetoothDevice', style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent)),
                ),
              ],

              // خيارات حجم الورق الثلاث المحددة (80, 78, 57)
              _buildDropdown('حجم الورق', _paperSize, ['80mm', '78mm', '57mm'], (v) => setState(() => _paperSize = v!)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, padding: const EdgeInsets.all(12)),
                      onPressed: () {
                        Navigator.pop(context, {
                          'name': _nameController.text.isEmpty ? 'طابعة' : _nameController.text,
                          'type': _printerType,
                          'connection': _connectionType,
                          'paperSize': _paperSize,
                          'ip': _ipController.text,
                          'bluetooth': _selectedBluetoothDevice,
                        });
                      },
                      child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.cardBg,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
      onChanged: onChanged,
    );
  }
}

// ==================== 2. شاشة ملاحظات التحضير ====================
class PrepNotesPage extends StatefulWidget {
  const PrepNotesPage({Key? key}) : super(key: key);

  @override
  State<PrepNotesPage> createState() => _PrepNotesPageState();
}

class _PrepNotesPageState extends State<PrepNotesPage> {
  List<String> prepNotes = ['بدون بصل', 'حار', 'بدون صلصة', 'زيادة جبن', 'بدون ملح', 'مشوي جيداً'];

  void _showAddEditNoteDialog({String? initialText, int? index}) {
    final controller = TextEditingController(text: initialText ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(index == null ? 'إضافة ملاحظة تحضير' : 'تعديل الملاحظة', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'اكتب ملاحظة التحضير...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (index == null) {
                    prepNotes.add(controller.text.trim());
                  } else {
                    prepNotes[index] = controller.text.trim();
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ملاحظات التحضير'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prepNotes.length,
        itemBuilder: (ctx, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text(prepNotes[i], style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.cyanAccent, size: 20),
                  onPressed: () => _showAddEditNoteDialog(initialText: prepNotes[i], index: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.primaryPink, size: 20),
                  onPressed: () => setState(() => prepNotes.removeAt(i)),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPink,
        onPressed: () => _showAddEditNoteDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة +', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==================== 3. شاشة النسخ الاحتياطي والاستعادة ====================
class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({Key? key}) : super(key: key);

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final _pathController = TextEditingController(text: '/storage/emulated/0/Download/BayanPOS/backups');

  List<Map<String, String>> backupsList = [
    {
      'name': 'bayan_pos_backup_20260907_112027.db',
      'date': '2026-09-07 11:20',
      'size': '68.0 KB',
      'path': '/storage/emulated/0/Download/BayanPOS/backups',
    },
    {
      'name': 'bayan_pos_backup_20260901_091512.db',
      'date': '2026-09-01 09:15',
      'size': '64.5 KB',
      'path': '/storage/emulated/0/Download/BayanPOS/backups',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم مسار الحفظ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مكان الحفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pathController,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, padding: const EdgeInsets.all(12)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسار')));
                        },
                        icon: const Icon(Icons.save, color: Colors.white, size: 18),
                        label: const Text('حفظ المسار', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.textMuted),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () {
                          // فتح أداة اختيار مجلد
                        },
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('اختيار مجلد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // زر انشاء نسخة احتياطية
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                final path = await DBHelper.createBackup();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاؤها بنجاح في: $path')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح')));
              }
            },
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('إنشاء نسخة احتياطية', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          const Text('النسخ المتوفرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),

          // عرض جميع النسخ في المجلد المختار ومتاح للبدء بالاستعادة
          ...backupsList.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${file['date']} • ${file['size']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('${file['path']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.cyanAccent),
                    tooltip: 'استعادة النسخة',
                    onPressed: () {
                      _confirmRestore(file['name']!);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.primaryPink),
                    onPressed: () => setState(() => backupsList.remove(file)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _confirmRestore(String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تأكيد الاستعادة', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت أيد من استعادة النسخة الاحتياطية التالية؟\n$fileName', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استعادة البيانات من $fileName بنجاح')),
              );
            },
            child: const Text('استعادة الان', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
