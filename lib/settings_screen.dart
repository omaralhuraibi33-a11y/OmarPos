import 'package:flutter/material.dart';
import 'db_helper.dart';

// الثوابت اللونية للمظهر الداكن حسب الصور
class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primaryPink = Color(0xFFF43F5E);
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ==================== الشاشة الرئيسية للإعدادات ====================
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
            _buildMainCategoryTile(
              context,
              title: 'إعدادات الطابعات',
              subtitle: 'ربط طابعات البلوتوث والشبكة وإعدادات الورق',
              icon: Icons.print,
              targetScreen: const PrinterSettingsScreen(),
            ),
            _buildMainCategoryTile(
              context,
              title: 'ملاحظات التحضير',
              subtitle: 'إدارة الملاحظات السريعة للمطبخ والوجبات',
              icon: Icons.note_alt,
              targetScreen: const PrepNotesScreen(),
            ),
            _buildMainCategoryTile(
              context,
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'تحديد مسار الحفظ، إنشاء وحفظ النسخ الاحتياطية',
              icon: Icons.backup,
              targetScreen: const BackupScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategoryTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget targetScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryPink),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: printers.isEmpty
          ? const Center(child: Text('لا توجد طابعات مضافة حالياً', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: printers.length,
              itemBuilder: (ctx, i) {
                final item = printers[i];
                return Card(
                  color: AppColors.cardBg,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item['name'] ?? 'طابعة'),
                    subtitle: Text('${item['type']} - ${item['connection']} (${item['paperSize']})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
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

// نافذة إضافة طابعة المنبثقة
class AddPrinterDialog extends StatefulWidget {
  const AddPrinterDialog({Key? key}) : super(key: key);

  @override
  State<AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<AddPrinterDialog> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9100');

  String _type = 'فاتورة';
  String _connection = 'بلوتوث';
  String _paperSize = '80mm';
  String _printMode = 'صورة (موصى به للعربية)';
  String _lineSpacing = 'متوسطة';
  String _itemSpacing = 'متوسطة';

  bool _isDefault = false;
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة طابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),

              _buildTextField(_nameController, 'اسم الطابعة'),
              const SizedBox(height: 10),

              _buildDropdown('النوع', _type, ['فاتورة', 'مطبخ'], (v) => setState(() => _type = v!)),
              const SizedBox(height: 10),

              _buildDropdown('واجهة الاتصال', _connection, ['بلوتوث', 'واي فاي'], (v) => setState(() => _connection = v!)),
              const SizedBox(height: 10),

              // الشروط الخاصة بالبلوتوث والواي فاي
              if (_connection == 'بلوتوث') ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.primaryPink),
                    minimumSize: const Size.fromHeight(45),
                  ),
                  onPressed: () {
                    // اختيار طابعة بلوتوث مقترنة
                  },
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('بحث عن طابعات بلوتوث'),
                ),
                const SizedBox(height: 10),
              ] else ...[
                _buildTextField(_ipController, 'عنوان (IP) العنوان'),
                const SizedBox(height: 10),
                _buildTextField(_portController, 'المنفذ'),
                const SizedBox(height: 10),
              ],

              _buildDropdown('حجم الورق', _paperSize, ['80mm', '72mm', '58mm'], (v) => setState(() => _paperSize = v!)),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'عرض الورق الفعلي للطابعة (80 / 72 / 58). خيار «ضيقة» أدناه للمسافات وليس لحجم الورق.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),

              _buildDropdown('وضع الطباعة', _printMode, ['صورة (موصى به للعربية)', 'نص (ESC/POS)'], (v) => setState(() => _printMode = v!)),
              const SizedBox(height: 12),

              const Text('مسافة الأسطر', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              _buildSegmentedControl(_lineSpacing, (v) => setState(() => _lineSpacing = v)),
              const SizedBox(height: 12),

              const Text('المسافة بين الكمية والاسم والسعر', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              _buildSegmentedControl(_itemSpacing, (v) => setState(() => _itemSpacing = v)),
              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('افتراضي', style: TextStyle(fontSize: 14)),
                value: _isDefault,
                activeColor: AppColors.cyanAccent,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              SwitchListTile(
                title: const Text('نشط', style: TextStyle(fontSize: 14)),
                value: _isActive,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, padding: const EdgeInsets.all(12)),
                      onPressed: () {
                        Navigator.pop(context, {
                          'name': _nameController.text.isEmpty ? 'طابعة جديدة' : _nameController.text,
                          'type': _type,
                          'connection': _connection,
                          'paperSize': _paperSize,
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
      style: const TextStyle(color: Colors.white, fontSize: 14),
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

  Widget _buildSegmentedControl(String selected, ValueChanged<String> onSelect) {
    final options = ['واسعة', 'متوسطة', 'ضيقة'];
    return Row(
      children: options.map((opt) {
        final isSel = selected == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primaryPurple : AppColors.cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSel ? AppColors.primaryPurple : Colors.white24),
              ),
              child: Center(
                child: Text(opt, style: TextStyle(color: isSel ? Colors.white : AppColors.textMuted, fontSize: 12)),
              ),
            ),
          ),
        );
      }).toList(),
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
  List<String> prepNotes = [
    'بدون بصل',
    'حار',
    'بدون صلصة',
    'زيادة جبن',
    'بدون ملح',
    'مشوي جيداً',
  ];

  void _showAddEditNoteDialog({String? initialText, int? index}) {
    final controller = TextEditingController(text: initialText ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(index == null ? 'إضافة ملاحظة' : 'تعديل الملاحظة', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'أدخل الملاحظة هنا', hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prepNotes.length,
        itemBuilder: (ctx, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prepNotes[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('نشط', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
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
  final _pathController = TextEditingController(text: '/storage/emulated/0/Download/BayanPOS/backups');

  List<Map<String, String>> existingBackups = [
    {
      'name': 'bayan_pos_backup_20260907_112027.db',
      'info': '2026-09-07 11:20 • 68.0 KB',
      'path': '/storage/emulated/0/Download/BayanPOS/backups',
    },
    {
      'name': 'bayan_pos_backup_20260907_112027.db',
      'info': '2026-09-07 11:20 • 68.0 KB',
      'path': '/sdcard/Download/BayanPOS/backups',
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // كارت مكان الحفظ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مكان الحفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('المسار المحفوظ حالياً', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('حفظ المسار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.primaryPink),
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.folder_open),
                  label: const Text('اختيار مجلد'),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                        onPressed: () {},
                        child: const Text('الافتراضي', style: TextStyle(color: AppColors.primaryPink)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                        onPressed: () {},
                        child: const Text('التنزيلات', style: TextStyle(color: AppColors.primaryPink)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // زر إنشاء نسخة احتياطية
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                final path = await DBHelper.createBackup();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ في: $path')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('إنشاء نسخة احتياطية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          // زر استرجاع من ملف
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.folder, color: Colors.white),
            label: const Text('...استرجاع من ملف', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          const Text('النسخ المتوفرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),

          // قائمة النسخ المتوفرة
          ...existingBackups.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(item['info']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text(item['path']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.cyanAccent),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.primaryPink),
                    onPressed: () => setState(() => existingBackups.remove(item)),
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
