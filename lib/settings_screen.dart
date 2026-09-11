import 'package:flutter/material.dart';
import 'db_helper.dart';

// ============================================================================
// 1. الشاشة الرئيسية للإعدادات
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;

  Future<void> _saveAllSettings() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ كافة إعدادات النظام بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black) : ThemeData.light().copyWith(primaryColor: Colors.blue),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات النظام'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'حفظ كافة الإعدادات',
              onPressed: _saveAllSettings,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildMainButton(
              title: '1. إعدادات الطابعات',
              subtitle: 'إضافة طابعة، اختيار البلوتوث/الواي فاي، الأحجام، والطباعة التلقائية',
              icon: Icons.print,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
            ),
            _buildMainButton(
              title: '2. ملاحظات التحضير',
              subtitle: 'إدارة ملاحظات التحضير المخصصة للمطبخ (إضافة، تعديل، حذف)',
              icon: Icons.note_alt,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrepNotesScreen())),
            ),
            _buildMainButton(
              title: '3. المظهر',
              subtitle: 'الوضع الداكن/الفاتح، حجم أزرار الشاشة الرئيسية ونقطة البيع',
              icon: Icons.palette,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppearanceSettingsScreen(
                    isDarkMode: _isDarkMode,
                    onThemeChanged: (val) => setState(() => _isDarkMode = val),
                  ),
                ),
              ),
            ),
            _buildMainButton(
              title: '4. بيانات المتجر',
              subtitle: 'الشعار، اسم المتجر، الهاتف، والعنوان',
              icon: Icons.store,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreDataScreen())),
            ),
            _buildMainButton(
              title: '5. إعدادات الفواتير',
              subtitle: 'تخصيص البيانات المطبوعة على الفاتورة والملاحظات الختامية',
              icon: Icons.receipt_long,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen())),
            ),
            _buildMainButton(
              title: '6. إعدادات الصناديق',
              subtitle: 'إضافة الصناديق، التحويل التلقائي للصندوق الرئيسي أو نظام الورديات',
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBoxSettingsScreen())),
            ),
            _buildMainButton(
              title: '7. النسخ الاحتياطي والاستعادة',
              subtitle: 'تحديد مجلد الحفظ، إنشاء نسخة احتياطية، واستعادة النسخ',
              icon: Icons.backup,
              color: Colors.cyan,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSettingsScreen())),
            ),
            _buildMainButton(
              title: '8. طرق الدفع',
              subtitle: 'إدارة وتخصيص وسائل الدفع (نقدي، آجل، أساليب جديدة)',
              icon: Icons.payment,
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
            ),
            _buildMainButton(
              title: '9. خيار مسح البيانات',
              subtitle: 'حذف الحسابات، المجموعات، الأصناف، أو صفر السجلات',
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WipeDataScreen())),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveAllSettings,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ الإعدادات العامة', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// 1. شاشة إعدادات الطابعات
// ============================================================================
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<Map<String, dynamic>> _printers = [];
  int? _selectedPrinterIndex;

  bool _autoKitchen = false;
  bool _autoCustomer = false;

  void _showPrinterDialog({Map<String, dynamic>? printerToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: printerToEdit?['name'] ?? '');
    final ipCtrl = TextEditingController(text: printerToEdit?['ip'] ?? '');
    final macCtrl = TextEditingController(text: printerToEdit?['mac'] ?? '');
    String connection = printerToEdit?['connection'] ?? 'بلوتوث';
    String usage = printerToEdit?['usage'] ?? 'زبون';
    String paperSize = printerToEdit?['paperSize'] ?? '80';

    // قائمة أجهزة البلوتوث المقترنة بالجهاز للاختيار منها
    final List<Map<String, String>> pairedBtDevices = [
      {'name': 'BT-Printer-01', 'mac': 'AA:BB:CC:11:22:33'},
      {'name': 'POS-Thermal-58', 'mac': '12:34:56:78:90:AB'},
      {'name': 'RP-80-Printer', 'mac': '99:88:77:66:55:44'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text(editIndex == null ? 'إضافة طابعة جديدة' : 'تعديل الطابعة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: usage,
                    decoration: const InputDecoration(labelText: 'نوع الطابعة (الاستخدام)'),
                    items: ['مطبخ', 'زبون'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => usage = val!),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: connection,
                    decoration: const InputDecoration(labelText: 'نوع الاتصال'),
                    items: ['بلوتوث', 'واي فاي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => connection = val!),
                  ),
                  const SizedBox(height: 12),
                  if (connection == 'بلوتوث') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(45),
                      ),
                      icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
                      label: const Text('بحث عن طابعات بلوتوث', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (btCtx) => AlertDialog(
                            title: const Text('أجهزة البلوتوث المقترنة بالجهاز'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: pairedBtDevices.length,
                                itemBuilder: (c, idx) {
                                  final dev = pairedBtDevices[idx];
                                  return ListTile(
                                    leading: const Icon(Icons.print, color: Colors.blue),
                                    title: Text(dev['name']!),
                                    subtitle: Text('MAC: ${dev['mac']}'),
                                    onTap: () {
                                      setDlgState(() {
                                        nameCtrl.text = dev['name']!;
                                        macCtrl.text = dev['mac']!;
                                      });
                                      Navigator.pop(btCtx);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: macCtrl,
                      decoration: const InputDecoration(
                        labelText: 'عنوان MAC للطابعة',
                        prefixIcon: Icon(Icons.fingerprint),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: ipCtrl,
                      decoration: const InputDecoration(labelText: 'عنوان IP للطابعة (مثال: 192.168.1.100)'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الطابعة'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paperSize,
                    decoration: const InputDecoration(labelText: 'مقاس الورق'),
                    items: ['57', '78', '80'].map((e) => DropdownMenuItem(value: e, child: Text('$e mm'))).toList(),
                    onChanged: (val) => setDlgState(() => paperSize = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final printerData = {
                    'name': nameCtrl.text.trim().isEmpty ? 'طابعة جديدة' : nameCtrl.text.trim(),
                    'connection': connection,
                    'usage': usage,
                    'paperSize': paperSize,
                    'mac': macCtrl.text.trim(),
                    'ip': ipCtrl.text.trim(),
                  };
                  setState(() {
                    if (editIndex == null) {
                      _printers.add(printerData);
                    } else {
                      _printers[editIndex] = printerData;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ الطابعة'),
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
      appBar: AppBar(title: const Text('إعدادات الطابعات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrinterDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الطباعة التلقائية حسب النوع', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('طباعة المطبخ تلقائياً'),
                    value: _autoKitchen,
                    onChanged: (val) => setState(() => _autoKitchen = val),
                  ),
                  SwitchListTile(
                    title: const Text('طباعة الزبون تلقائياً'),
                    value: _autoCustomer,
                    onChanged: (val) => setState(() => _autoCustomer = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الطابعات المضافة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPrinterIndex != null ? Colors.orange : Colors.grey,
                ),
                onPressed: _selectedPrinterIndex == null
                    ? null
                    : () {
                        final p = _printers[_selectedPrinterIndex!];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم إرسال صفحة تجريبية إلى الطابعة: ${p['name']}')),
                        );
                      },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('تجربة الطابعة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(),
          _printers.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طابعات مضافة. اضغط + للإضافة')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _printers.length,
                  itemBuilder: (ctx, i) {
                    final p = _printers[i];
                    final isSelected = _selectedPrinterIndex == i;
                    return Card(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : null,
                      child: ListTile(
                        onTap: () => setState(() => _selectedPrinterIndex = i),
                        leading: Icon(
                          p['connection'] == 'بلوتوث' ? Icons.bluetooth : Icons.wifi,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text('${p['name']} (${p['usage']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p['connection'] == 'بلوتوث'
                            ? 'الاتصال: بلوتوث | MAC: ${p['mac']} | المقاس: ${p['paperSize']}mm'
                            : 'الاتصال: واي فاي | IP: ${p['ip']} | المقاس: ${p['paperSize']}mm'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showPrinterDialog(printerToEdit: p, editIndex: i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _printers.removeAt(i);
                                  if (_selectedPrinterIndex == i) _selectedPrinterIndex = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. شاشة ملاحظات التحضير
// ============================================================================
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

// ============================================================================
// 3. شاشة المظهر
// ============================================================================
class AppearanceSettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const AppearanceSettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _mainButtonSize = 'وسط';
  String _posItemSize = 'وسط';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المظهر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('نمط المظهر العام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // لون الوضع الفاتح الأزرق
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => widget.onThemeChanged(false),
                  icon: const Icon(Icons.light_mode, color: Colors.white),
                  label: const Text('الوضع الفاتح', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // لون الوضع الداكن الأسود
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => widget.onThemeChanged(true),
                  icon: const Icon(Icons.dark_mode, color: Colors.white),
                  label: const Text('الوضع الداكن', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          DropdownButtonFormField<String>(
            value: _mainButtonSize,
            decoration: const InputDecoration(labelText: 'حجم أزرار الشاشة الرئيسية'),
            items: ['صغير', 'وسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _mainButtonSize = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _posItemSize,
            decoration: const InputDecoration(labelText: 'حجم العناصر في نقطة البيع (POS)'),
            items: ['صغير', 'وسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _posItemSize = val!),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ إعدادات المظهر بنجاح'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('حفظ الإعدادات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. شاشة بيانات المتجر
// ============================================================================
class StoreDataScreen extends StatefulWidget {
  const StoreDataScreen({Key? key}) : super(key: key);

  @override
  State<StoreDataScreen> createState() => _StoreDataScreenState();
}

class _StoreDataScreenState extends State<StoreDataScreen> {
  // الحقول فارغة افتراضياً
  final _nameCtrl = TextEditingController(text: '');
  final _phoneCtrl = TextEditingController(text: '');
  final _addressCtrl = TextEditingController(text: '');
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueGrey,
                  child: _selectedImagePath == null
                      ? const Icon(Icons.storefront, size: 50, color: Colors.white)
                      : const Icon(Icons.image, size: 50, color: Colors.greenAccent),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      onPressed: () {
                        // محاكاة فتح معرض الصور لاختيار الشعار
                        setState(() {
                          _selectedImagePath = '/storage/emulated/0/Pictures/logo.png';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم فتح ملفات الصور واختيار الشعار بنجاح')),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم المتجر', prefixIcon: Icon(Icons.store))),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المتجر بنجاح')));
              Navigator.pop(context);
            },
            child: const Text('حفظ بيانات المتجر'),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// 5. شاشة إعدادات الفواتير
// ============================================================================
class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  bool _showLogo = true;
  bool _showStoreName = true;
  final _footerNoteCtrl = TextEditingController(text: 'شكراً لزيارتكم! نأمل رؤيتكم قريباً');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الفواتير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('إظهار الشعار في الفاتورة'),
            value: _showLogo,
            onChanged: (v) => setState(() => _showLogo = v),
          ),
          SwitchListTile(
            title: const Text('إظهار اسم المتجر في الفاتورة'),
            value: _showStoreName,
            onChanged: (v) => setState(() => _showStoreName = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footerNoteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ملاحظة أسفل الفاتورة',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حفظ إعدادات الفواتير'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. شاشة إعدادات الصناديق
// ============================================================================
class CashBoxSettingsScreen extends StatefulWidget {
  const CashBoxSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CashBoxSettingsScreen> createState() => _CashBoxSettingsScreenState();
}

class _CashBoxSettingsScreenState extends State<CashBoxSettingsScreen> {
  bool _autoMainBox = true;
  final List<String> _boxes = ['الصندوق الرئيسي', 'صندوق المبيعات'];

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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الصناديق'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addCashBox),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('نظام الترحيل للصناديق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          RadioListTile<bool>(
            title: const Text('الصندوق الرئيسي تلقائياً'),
            subtitle: const Text('المبيعات ترحّل فوراً دون الحاجة لإغلاق وردية'),
            value: true,
            groupValue: _autoMainBox,
            onChanged: (v) => setState(() => _autoMainBox = v!),
          ),
          RadioListTile<bool>(
            title: const Text('صندوق المبيعات (نظام الورديات)'),
            subtitle: const Text('يتطلب عمل إغلاق صندوق لترحيل الأموال للصندوق الرئيسي'),
            value: false,
            groupValue: _autoMainBox,
            onChanged: (v) => setState(() => _autoMainBox = v!),
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الصناديق المعرفة:', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addCashBox,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة صندوق'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._boxes.map((box) => Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
                  title: Text(box),
                ),
              )),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. شاشة النسخ الاحتياطي والاستعادة
// ============================================================================
class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  String _backupFolderPath = '/storage/emulated/0/Download/AppBackups';
  final List<String> _availableBackups = [
    'backup_2026_09_10.db',
    'backup_2026_09_01.db',
    'backup_2026_08_15.db',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مجلد حفظ النسخ الاحتياطية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_backupFolderPath, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // محاكاة دخول ملفات الجهاز لاختيار مجلد الحفظ
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم فتح ملفات الجهاز واختيار المجلد بنجاح')),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('تغيير مجلد الحفظ'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () {
              final newBackup = 'backup_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}.db';
              setState(() {
                _availableBackups.insert(0, newBackup);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إنشاء نسخة احتياطية بنجاح في: $_backupFolderPath')),
              );
            },
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('إنشاء نسخة احتياطية الآن', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () {
              // زر الذهاب لملفات الجهاز لاختيار ملف الاستعادة
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم فتح ملفات الجهاز.. اختر ملف الاستعادة (.db)')),
              );
            },
            icon: const Icon(Icons.restore_page, color: Colors.white),
            label: const Text('استعادة نسخة احتياطية من الجهاز', style: TextStyle(color: Colors.white)),
          ),
          const Divider(height: 30),
          const Text('النسخ الاحتياطية المحفوظة سابقةً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._availableBackups.map(
            (fileName) => Card(
              child: ListTile(
                leading: const Icon(Icons.storage, color: Colors.cyan),
                title: Text(fileName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.teal),
                      tooltip: 'استعادة',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الاستعادة'),
                            content: Text('هل أنت أكيد من استعادة النسخة ($fileName)؟ سيتم استبدال البيانات الحالية.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة النسخة بنجاح!')));
                                },
                                child: const Text('استعادة'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'حذف النسخة',
                      onPressed: () {
                        setState(() {
                          _availableBackups.remove(fileName);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف النسخة الاحتياطية')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. شاشة طرق الدفع
// ============================================================================
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // خيارات اختيار طرق الدفع المطلوبة
  final Map<String, bool> _paymentOptions = {
    'نقدي': true,
    'آجل': true,
    'شبكة / بطاقة': false,
    'تحويل بنكي / محفظة': false,
  };

  void _addPaymentMethod() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طريقة دفع جديدة'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'طريقة الدفع')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _paymentOptions[ctrl.text.trim()] = true);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة طرق الدفع'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addPaymentMethod)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('حدد طرق الدفع المتاحة للاستخدام:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._paymentOptions.keys.map(
            (method) => Card(
              child: CheckboxListTile(
                secondary: const Icon(Icons.payment, color: Colors.green),
                title: Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_paymentOptions[method]! ? 'مفعلة' : 'معطلة'),
                value: _paymentOptions[method],
                onChanged: (bool? val) {
                  setState(() {
                    _paymentOptions[method] = val ?? false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. شاشة مسح البيانات
// ============================================================================
class WipeDataScreen extends StatelessWidget {
  const WipeDataScreen({Key? key}) : super(key: key);

  void _confirmWipe(BuildContext context, String title, String warningMessage, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(warningMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح البيانات بنجاح!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('تأكيد المسح النهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خيار مسح البيانات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _confirmWipe(
                context,
                'حذف كافة الحسابات',
                'هل أنت أكيد من حذف جميع حسابات العملاء والموردين والسجلات المالية؟',
                () => DBHelper.clearAllAccountsData(),
              ),
              icon: const Icon(Icons.people_alt, color: Colors.white),
              label: const Text('زر حذف كافة الحسابات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _confirmWipe(
                context,
                'حذف كل المجموعات والأصناف',
                'هل أنت أكيد من حذف كافة المجموعات والأصناف المخزنية بالكامل؟',
                () => DBHelper.clearCategoriesAndProducts(),
              ),
              icon: const Icon(Icons.category, color: Colors.white),
              label: const Text('زر حذف كل المجموعات والأصناف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _confirmWipe(
                context,
                'حذف الأصناف فقط',
                'سيتم حذف كافة المنتجات مع الإبقاء على أقسام المجموعات الرئيسية.',
                () => DBHelper.clearProductsOnly(),
              ),
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: const Text('زر حذف الأصناف فقط', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
