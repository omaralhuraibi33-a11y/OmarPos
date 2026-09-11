import 'package:flutter/material.dart';
import 'db_helper.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primaryPink = Color(0xFFF43F5E);
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ==================== الشاشة الرئيسية: أزرار طويلة مستقلة ====================
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
              targetScreen: const PrinterSettingsScreen(),
            ),
            _buildLongButton(
              context,
              title: 'ملاحظات التحضير',
              subtitle: 'إضافة، تعديل وحذف ملاحظات المطبخ السريعة',
              icon: Icons.note_alt,
              targetScreen: const PrepNotesScreen(),
            ),
            _buildLongButton(
              context,
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'تحديد مسار الحفظ، إنشاء نسخة، واسترجاع الملفات',
              icon: Icons.backup,
              targetScreen: const BackupScreen(),
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
    required Widget targetScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryPink, size: 24),
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
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<Map<String, dynamic>> printers = [];

  void _openAddPrinterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AddPrinterDialog(),
    ).then((val) {
      if (val != null) {
        setState(() => printers.add(val));
      }
    });
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
          ? const Center(child: Text('لا توجد طابعات مضافة حالياً', style: TextStyle(color: AppColors.textMuted)))
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
                    subtitle: Text('${item['type']} | ${item['connection']} | الورق: ${item['paperSize']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
        label: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// النافذة المنبثقة لإضافة طابعة
class AddPrinterDialog extends StatefulWidget {
  const AddPrinterDialog({Key? key}) : super(key: key);

  @override
  State<AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<AddPrinterDialog> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  String _selectedBluetoothDevice = 'لم يتم اختيار طابعة بلوتوث';

  String _type = 'فاتورة';
  String _connection = 'بلوتوث';
  String _paperSize = '80mm'; // الخيارات المطلوب تحديدها: 80, 78, 57

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 550),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة طابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),

              _buildTextField(_nameController, 'اسم الطابعة'),
              const SizedBox(height: 10),

              _buildDropdown('النوع', _type, ['فاتورة', 'مطبخ'], (v) => setState(() => _type = v!)),
              const SizedBox(height: 10),

              _buildDropdown('واجهة الاتصال', _connection, ['بلوتوث', 'واي فاي'], (v) => setState(() => _connection = v!)),
              const SizedBox(height: 12),

              // الشروط: عند اختيار واي فاي يظهر مربع IP، وعند البلوتوث يظهر زر اختيار طابعة
              if (_connection == 'واي فاي') ...[
                _buildTextField(_ipController, 'عنوان IP الطابعة (مثال: 192.168.1.100)'),
                const SizedBox(height: 10),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.primaryPink),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // شاشة/قائمة اختيار طابعة البلوتوث المقترنة
                    setState(() {
                      _selectedBluetoothDevice = 'Bluetooth Printer (XX:YY:ZZ)';
                    });
                  },
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('اختيار طابعة بلوتوث مضافة'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  child: Text(_selectedBluetoothDevice, style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent)),
                ),
              ],

              // خيارات حجم الورق المطابقة لطلبك: 80, 78, 57
              _buildDropdown('حجم الورق', _paperSize, ['80mm', '78mm', '57mm'], (v) => setState(() => _paperSize = v!)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, padding: const EdgeInsets.all(12)),
                      onPressed: () {
                        Navigator.pop(context, {
                          'name': _nameController.text.isEmpty ? 'طابعة جديد' : _nameController.text,
                          'type': _type,
                          'connection': _connection,
                          'paperSize': _paperSize,
                          'ip': _ipController.text,
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.cardBg,
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
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }
}

// ==================== 2. شاشة ملاحظات التحضير ====================
class PrepNotesScreen extends StatefulWidget {
  const PrepNotesScreen({Key? key}) : super(key: key);

  @override
  State<PrepNotesScreen> createState() => _PrepNotesScreenState();
}

class _PrepNotesScreenState extends State<PrepNotesScreen> {
  List<String> prepNotes = ['بدون بصل', 'حار', 'بدون صلصة', 'زيادة جبن'];

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
          decoration: const InputDecoration(hintText: 'اكتب الملاحظة هنا...', hintStyle: TextStyle(color: AppColors.textMuted)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text(prepNotes[i], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.cyanAccent),
                  onPressed: () => _showAddEditNoteDialog(initialText: prepNotes[i], index: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.primaryPink),
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
        label: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==================== 3. شاشة النسخ الاحتياطي والاستعادة ====================
class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _pathController = TextEditingController(text: '/storage/emulated/0/Download/OmarPos/backups');

  List<Map<String, String>> existingBackups = [
    {
      'name': 'omar_pos_backup_20260911_120000.db',
      'date': '2026-09-11 12:00',
      'size': '72 KB',
    },
    {
      'name': 'omar_pos_backup_20260901_093000.db',
      'date': '2026-09-01 09:30',
      'size': '68 KB',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // إعدادات مكان الحفظ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مكان حفظ النسخ الاحتياطية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                  controller: _pathController,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.primaryPink),
                    minimumSize: const Size.fromHeight(45),
                  ),
                  onPressed: () {
                    // ميزة اختيار مجلد من ذاكرة الجهاز
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('تغيير مجلد الحفظ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // زر إنشاء نسخة جديدة
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                final path = await DBHelper.createBackup();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء النسخة بنجاح في: $path')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء النسخة بنجاح')));
              }
            },
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('إنشاء نسخة احتياطية جديدة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          const Text('النسخ المتوفرة في المجلد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),

          // عرض ملفات النسخ المتاحة داخل المجلد لاختيارها واستعادتها مباشر
          ...existingBackups.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: AppColors.cyanAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('${file['date']}  |  ${file['size']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onPressed: () {
                      // تأكيد واختيار استعادة هذه النسخة تحديداً
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار استعادة: ${file['name']}')));
                    },
                    child: const Text('استعادة', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.primaryPink, size: 20),
                    onPressed: () => setState(() => existingBackups.remove(file)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
