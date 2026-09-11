import 'package:flutter/material.dart';
import 'db_helper.dart';

// ============================================================================
// 1. الشاشة الرئيسية للإعدادات (تحوي الـ 9 أزرار الطولية)
// ============================================================================
class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({Key? key}) : super(key: key);

  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
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
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
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
    String connection = printerToEdit?['connection'] ?? 'بلوتوث';
    String usage = printerToEdit?['usage'] ?? 'زبون';
    String paperSize = printerToEdit?['paperSize'] ?? '80';
    String selectedBtDevice = printerToEdit?['btDevice'] ?? '';

    List<String> pairedBtDevices = ['BT-Printer-01 (AA:BB:CC)', 'POS-Thermal-58 (12:34:56)', 'RP-80-Printer (99:88:77)'];

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
                  const SizedBox(height: 8),
                  if (connection == 'بلوتوث') ...[
                    DropdownButtonFormField<String>(
                      value: selectedBtDevice.isNotEmpty && pairedBtDevices.contains(selectedBtDevice) ? selectedBtDevice : null,
                      hint: const Text('اختر طابعة من أجهزة الجوال المقترنة'),
                      decoration: const InputDecoration(labelText: 'الطابعات المقترنة بالجهاز'),
                      items: pairedBtDevices.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {
                        setDlgState(() {
                          selectedBtDevice = val!;
                          if (nameCtrl.text.isEmpty) nameCtrl.text = val.split(' ').first;
                        });
                      },
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
                    decoration: const InputDecoration(labelText: 'اسم الطابعة (تلقائي/تعديل)'),
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
                    'btDevice': selectedBtDevice,
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
                        subtitle: Text('الاتصال: ${p['connection']} | المقاس: ${p['paperSize']}mm'),
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
                    backgroundColor: !widget.isDarkMode ? Colors.blue : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => widget.onThemeChanged(false),
                  icon: const Icon(Icons.light_mode, color: Colors.yellow),
                  label: const Text('الوضع الفاتح', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkMode ? Colors.blue : Colors.grey.shade800,
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
  final _nameCtrl = TextEditingController(text: 'مذاق سبأ');
  final _phoneCtrl = TextEditingController(text: '770000000');
  final _addressCtrl = TextEditingController(text: 'تعز - قدس');

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
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.storefront, size: 50, color: Colors.white),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تغيير الشعار')));
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
            onPressed: () => Navigator.pop(context),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختيار مجلد جديد')));
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('تغيير مجلد الحفظ'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إنشاء نسخة احتياطية بنجاح في: $_backupFolderPath')),
              );
            },
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('إنشاء نسخة احتياطية الآن', style: TextStyle(color: Colors.white)),
          ),
          const Divider(height: 30),
          const Text('استعادة نسخة احتياطية من المجلد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._availableBackups.map(
            (fileName) => Card(
              child: ListTile(
                leading: const Icon(Icons.storage, color: Colors.cyan),
                title: Text(fileName),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تأكيد الاستعادة'),
                        content: Text('هل أنت أيد من استعادة النسخة ($fileName)؟ سيتم استبدال البيانات الحالية.'),
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
                  child: const Text('استعادة', style: TextStyle(color: Colors.white)),
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
  final List<String> _methods = ['نقدي', 'آجل'];

  void _addPaymentMethod() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طريقة دفع جديدة'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'طريقة الدفع (مثال: شبكة / تحويل)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _methods.add(ctrl.text.trim()));
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
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _methods.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.payment, color: Colors.green),
            title: Text(_methods[i]),
            trailing: _methods[i] == 'نقدي' || _methods[i] == 'آجل'
                ? const Chip(label: Text('افتراضي'))
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _methods.removeAt(i)),
                  ),
          ),
        ),
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
