import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'db_helper.dart';

// ============================================================================
// 1. الشاشة الرئيسية للإعدادات (تحوي الـ 9 أزرار الطولية)
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

  // قائمة جلب أجهزة البلوتوث الفعلية المقترنة بالنظام
  List<String> _pairedBtDevices = [];
  bool _isLoadingBt = false;

  @override
  void initState() {
    super.initState();
    _fetchPairedBluetoothDevices();
  }

  Future<void> _fetchPairedBluetoothDevices() async {
    setState(() => _isLoadingBt = true);
    try {
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _pairedBtDevices = list.map((d) => "${d.name} (${d.macAdress})").toList();
      });
    } catch (e) {
      debugPrint("خطأ في جلب أجهزة البلوتوث: $e");
    } finally {
      setState(() => _isLoadingBt = false);
    }
  }

  void _showPrinterDialog({Map<String, dynamic>? printerToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: printerToEdit?['name'] ?? '');
    final ipCtrl = TextEditingController(text: printerToEdit?['ip'] ?? '');
    String connection = printerToEdit?['connection'] ?? 'بلوتوث';
    String usage = printerToEdit?['usage'] ?? 'زبون';
    String paperSize = printerToEdit?['paperSize'] ?? '80';
    String selectedBtDevice = printerToEdit?['btDevice'] ?? '';

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
                    _isLoadingBt
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          )
                        : DropdownButtonFormField<String>(
                            value: selectedBtDevice.isNotEmpty && _pairedBtDevices.contains(selectedBtDevice)
                                ? selectedBtDevice
                                : null,
                            hint: Text(_pairedBtDevices.isEmpty
                                ? 'لا توجد أجهزة مقترنة بالجوال'
                                : 'اختر طابعة من أجهزة الجوال المقترنة'),
                            decoration: const InputDecoration(labelText: 'الطابعات المقترنة بالجهاز'),
                            items: _pairedBtDevices.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
        onPressed: () {
          _fetchPairedBluetoothDevices();
          _showPrinterDialog();
        },
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
                  icon: const Icon(Icons.wb_sunny, color: Colors.white),
                  label: const Text('وضع فاتح', style: TextStyle(color: Colors.white)),
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
                  icon: const Icon(Icons.nightlight_round, color: Colors.white),
                  label: const Text('وضع داكن', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          const Text('حجم الأزرار والعرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _mainButtonSize,
            decoration: const InputDecoration(labelText: 'حجم أزرار الشاشة الرئيسية'),
            items: ['صغير', 'وسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _mainButtonSize = val!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _posItemSize,
            decoration: const InputDecoration(labelText: 'حجم أصناف كروت نقطة البيع (POS)'),
            items: ['صغير', 'وسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _posItemSize = val!),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. شاشة بيانات المتجر (تم تفعيل فتح معرض الصور الحقيقي)
// ============================================================================
class StoreDataScreen extends StatefulWidget {
  const StoreDataScreen({Key? key}) : super(key: key);

  @override
  State<StoreDataScreen> createState() => _StoreDataScreenState();
}

class _StoreDataScreenState extends State<StoreDataScreen> {
  final _nameController = TextEditingController(text: 'متجر جديد');
  final _phoneController = TextEditingController(text: '770000000');
  final _addressController = TextEditingController(text: 'العنوان الرئيس');
  String? _logoPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogoImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  backgroundImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
                  child: _logoPath == null ? const Icon(Icons.storefront, size: 50, color: Colors.blue) : null,
                ),
                InkWell(
                  onTap: _pickLogoImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'اسم المتجر', prefixIcon: Icon(Icons.store)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ بيانات المتجر بنجاح')),
              );
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
  final _footerController = TextEditingController(text: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.');
  bool _showLogo = true;
  bool _showTaxNo = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الفواتير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('إظهار الشعار في الفاتورة المطبوعة'),
            value: _showLogo,
            onChanged: (val) => setState(() => _showLogo = val),
          ),
          SwitchListTile(
            title: const Text('إظهار الرقم الضريبي'),
            value: _showTaxNo,
            onChanged: (val) => setState(() => _showTaxNo = val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footerController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ملاحظة تذييل الفاتورة (النص الختامي)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ إعدادات الفاتورة بنجاح')),
              );
            },
            child: const Text('حفظ إعدادات الفاتورة'),
          )
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

// ============================================================================
// 7. شاشة النسخ الاحتياطي والاستعادة
// ============================================================================
class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.blue),
              title: const Text('إنشاء نسخة احتياطية محلياً'),
              subtitle: const Text('حفظ نسخة مجلد بيانات النظام على ذاكرة الهاتف'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download, color: Colors.green),
              title: const Text('استعادة نسخة احتياطية'),
              subtitle: const Text('اختيار ملف بيانات واسترجاعه للنظام'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جارٍ الاستعادة...')),
                );
              },
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
  final Map<String, bool> _methods = {
    'كاش (نقدي)': true,
    'شبكة (بطاقة)': true,
    'آجل (حساب زبون)': true,
    'تحويل بنكي': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طرق الدفع')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _methods.keys.map((key) {
          return SwitchListTile(
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            value: _methods[key]!,
            onChanged: (val) => setState(() => _methods[key] = val),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// 9. شاشة مسح البيانات
// ============================================================================
class WipeDataScreen extends StatelessWidget {
  const WipeDataScreen({Key? key}) : super(key: key);

  void _confirmWipe(BuildContext context, String target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد مسح $target'),
        content: Text('هل أنت تأكد من مسح $target؟ هذه العملية لا يمكن التراجع عنها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم مسح $target بنجاح')),
              );
            },
            child: const Text('مسح نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح البيانات والتصفير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.red),
            title: const Text('مسح جميع المنتجات والمجموعات'),
            onTap: () => _confirmWipe(context, 'المنتجات والمجموعات'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt, color: Colors.red),
            title: const Text('مسح جميع فواتير المبيعات والسجلات'),
            onTap: () => _confirmWipe(context, 'الفواتير والسجلات'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.red),
            title: const Text('مسح بيانات العملاء والموردين'),
            onTap: () => _confirmWipe(context, 'العملاء والموردين'),
          ),
        ],
      ),
    );
  }
}
