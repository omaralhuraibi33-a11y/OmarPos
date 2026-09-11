import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // بيانات المتجر والفواتير
  final _storeNameController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _footerNoteController = TextEditingController();

  // خيارات المظهر والأزرار
  String _buttonSize = 'متوسط';
  String _posItemSize = 'متوسط';

  // إعدادات الطابعات
  bool _autoPrintKitchen = false;
  bool _autoPrintCustomer = false;
  List<Map<String, String>> _printers = [];
  String? _selectedTestPrinter;

  // إعدادات الصناديق
  bool _autoMainBox = true;
  List<String> _cashBoxes = ['الصندوق الرئيسي', 'صندوق المبيعات'];

  // طرق الدفع
  List<String> _paymentMethods = ['نقدي', 'آجل'];

  // ملاحظات التحضير
  List<String> _prepNotes = ['بدون شطة', 'زيادة بهارات', 'سفري', 'محلي'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);

    _storeNameController.text = await SettingsDBHelper.getSetting('store_name', defaultValue: 'مذاق سبأ') ?? '';
    _storePhoneController.text = await SettingsDBHelper.getSetting('store_phone', defaultValue: '') ?? '';
    _footerNoteController.text = await SettingsDBHelper.getSetting('footer_note', defaultValue: 'شكراً لزيارتكم!') ?? '';

    _buttonSize = await SettingsDBHelper.getSetting('button_size', defaultValue: 'متوسط') ?? 'متوسط';
    _posItemSize = await SettingsDBHelper.getSetting('pos_item_size', defaultValue: 'متوسط') ?? 'متوسط';

    _autoPrintKitchen = (await SettingsDBHelper.getSetting('auto_kitchen', defaultValue: 'false')) == 'true';
    _autoPrintCustomer = (await SettingsDBHelper.getSetting('auto_customer', defaultValue: 'false')) == 'true';
    _autoMainBox = (await SettingsDBHelper.getSetting('auto_main_box', defaultValue: 'true')) == 'true';

    _paymentMethods = await SettingsDBHelper.getPaymentMethods();

    setState(() => _isLoading = false);
  }

  Future<void> _saveGeneralSettings() async {
    await SettingsDBHelper.saveSetting('store_name', _storeNameController.text.trim());
    await SettingsDBHelper.saveSetting('store_phone', _storePhoneController.text.trim());
    await SettingsDBHelper.saveSetting('footer_note', _footerNoteController.text.trim());
    await SettingsDBHelper.saveSetting('button_size', _buttonSize);
    await SettingsDBHelper.saveSetting('pos_item_size', _posItemSize);
    await SettingsDBHelper.saveSetting('auto_kitchen', _autoPrintKitchen.toString());
    await SettingsDBHelper.saveSetting('auto_customer', _autoPrintCustomer.toString());
    await SettingsDBHelper.saveSetting('auto_main_box', _autoMainBox.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح'), backgroundColor: Colors.green),
      );
    }
  }

  // --- 1. إضافة طابعة جديدة ---
  void _showAddPrinterDialog() {
    String printerType = 'زبون';
    String connectionType = 'بلوتوث';
    String paperSize = '80mm';
    String selectedDevice = 'طابعة بلوتوث افتراضية (BT-Printer)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidget(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة طابعة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: paperSize,
                  decoration: const InputDecoration(labelText: 'حجم الطابعة'),
                  items: ['80mm', '58mm'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDlgState(() => paperSize = val!),
                ),
                DropdownButtonFormField<String>(
                  value: connectionType,
                  decoration: const InputDecoration(labelText: 'نوع الاتصال'),
                  items: ['بلوتوث', 'واي فاي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDlgState(() => connectionType = val!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDevice,
                  decoration: const InputDecoration(labelText: 'اختر الطابعة المقترنة'),
                  items: [
                    'طابعة بلوتوث افتراضية (BT-Printer)',
                    'طابعة المطبخ (192.168.1.100)',
                    'طابعة الفواتير (192.168.1.101)',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setDlgState(() => selectedDevice = val!),
                ),
                DropdownButtonFormField<String>(
                  value: printerType,
                  decoration: const InputDecoration(labelText: 'نوع الاستخدام'),
                  items: ['زبون', 'مطبخ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDlgState(() => printerType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _printers.add({
                    'name': selectedDevice,
                    'type': printerType,
                    'connection': connectionType,
                    'size': paperSize,
                  });
                  _selectedTestPrinter = selectedDevice;
                });
                Navigator.pop(ctx);
              },
              child: const Text('حفظ الطابعة'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. إدارة طرق الدفع ---
  void _showAddPaymentDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طريقة دفع جديدة'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'اسم طريقة الدفع (مثال: شبكة / تحويل)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await SettingsDBHelper.addPaymentMethod(nameCtrl.text.trim());
                Navigator.pop(ctx);
                _loadAllSettings();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // --- 3. مسح البيانات المحددة ---
  void _confirmWipeData(String title, String warning, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(warning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await onConfirm();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم المسح بنجاح!'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ الإعدادات',
            onPressed: _saveGeneralSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 1. إعدادات الطابعات
                _buildSectionHeader('1. إعدادات الطابعات', Icons.print),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showAddPrinterDialog,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('إضافة طابعة'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedTestPrinter != null ? Colors.orange : Colors.grey,
                              ),
                              onPressed: _selectedTestPrinter == null
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تم إرسال صفحة تجربة إلى: $_selectedTestPrinter')),
                                      );
                                    },
                              icon: const Icon(Icons.print, color: Colors.white),
                              label: const Text('تجربة الطابعة', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('طباعة المطبخ تلقائياً'),
                          value: _autoPrintKitchen,
                          onChanged: (val) => setState(() => _autoPrintKitchen = val),
                        ),
                        SwitchListTile(
                          title: const Text('طباعة الزبون تلقائياً'),
                          value: _autoPrintCustomer,
                          onChanged: (val) => setState(() => _autoPrintCustomer = val),
                        ),
                        if (_printers.isNotEmpty) ...[
                          const Divider(),
                          ..._printers.map((p) => ListTile(
                                leading: const Icon(Icons.print_sharp),
                                title: Text('${p['name']} (${p['type']})'),
                                subtitle: Text('النوع: ${p['connection']} | الحجم: ${p['size']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _printers.remove(p)),
                                ),
                              )),
                        ]
                      ],
                    ),
                  ),
                ),

                // 2. ملاحظات التحضير
                _buildSectionHeader('2. ملاحظات التحضير السريعة', Icons.note_alt),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ..._prepNotes.map((note) => Chip(
                              label: Text(note),
                              onDeleted: () => setState(() => _prepNotes.remove(note)),
                            )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة ملاحظة'),
                          onPressed: () {
                            final ctrl = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('ملاحظة تحضير جديدة'),
                                content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'الملاحظة')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (ctrl.text.isNotEmpty) {
                                        setState(() => _prepNotes.add(ctrl.text.trim()));
                                        Navigator.pop(ctx);
                                      }
                                    },
                                    child: const Text('إضافة'),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 & 4. المظهر وبيانات المتجر والفاتورة
                _buildSectionHeader('3 & 4. المظهر وبيانات المتجر والفواتير', Icons.store),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(labelText: 'اسم المتجر / النشاط التجاري', prefixIcon: Icon(Icons.storefront)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _storePhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _footerNoteController,
                          decoration: const InputDecoration(labelText: 'ملاحظة أسفل الفاتورة', prefixIcon: Icon(Icons.subtitles)),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Expanded(child: Text('حجم أزرار الرئيسية:')),
                            DropdownButton<String>(
                              value: _buttonSize,
                              items: ['صغير', 'متوسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) => setState(() => _buttonSize = val!),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Expanded(child: Text('حجم عناصر نقطة البيع:')),
                            DropdownButton<String>(
                              value: _posItemSize,
                              items: ['صغير', 'متوسط', 'كبير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) => setState(() => _posItemSize = val!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. إعدادات الصناديق
                _buildSectionHeader('5. إعدادات الصناديق', Icons.account_balance_wallet),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('الصندوق الرئيسي تلقائياً'),
                        subtitle: const Text('المبيعات تُرحّل فوراً دون الحاجة لإغلاق وردية'),
                        value: true,
                        groupValue: _autoMainBox,
                        onChanged: (val) => setState(() => _autoMainBox = val!),
                      ),
                      RadioListTile<bool>(
                        title: const Text('نظام صندوق المبيعات (الورديات)'),
                        subtitle: const Text('يتطلب عمل إغلاق صندوق لترحل الأموال للصندوق الرئيسي'),
                        value: false,
                        groupValue: _autoMainBox,
                        onChanged: (val) => setState(() => _autoMainBox = val!),
                      ),
                    ],
                  ),
                ),

                // 6. طرق الدفع
                _buildSectionHeader('6. طرق الدفع', Icons.payment),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: _paymentMethods.map((m) => Chip(label: Text(m))).toList(),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddPaymentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة طريقة دفع'),
                        )
                      ],
                    ),
                  ),
                ),

                // 7. النسخ الاحتياطي
                _buildSectionHeader('7. النسخ الاحتياطي والاستعادة', Icons.backup),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            onPressed: () async {
                              try {
                                final path = await SettingsDBHelper.createBackup();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم إنشاء النسخة في:\n$path'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cloud_upload, color: Colors.white),
                            label: const Text('إنشاء نسخة احتياطية', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 8. منطقة مسح البيانات الحساسة
                _buildSectionHeader('8. مسح البيانات الحساسة', Icons.delete_forever, color: Colors.red),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(40)),
                          onPressed: () => _confirmWipeData(
                            'حذف كافة الحسابات',
                            'هل أنت أيد من حذف جميع حسابات العملاء والموردين والسجلات المالية؟',
                            () => SettingsDBHelper.clearAllAccountsData(),
                          ),
                          icon: const Icon(Icons.people_alt, color: Colors.white),
                          label: const Text('زر حذف كافة الحسابات', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, minimumSize: const Size.fromHeight(40)),
                          onPressed: () => _confirmWipeData(
                            'حذف المجموعات والأصناف',
                            'هل أنت أكيد من حذف كافة المجموعات والأصناف بالمخزن؟',
                            () => SettingsDBHelper.clearCategoriesAndProducts(),
                          ),
                          icon: const Icon(Icons.category, color: Colors.white),
                          label: const Text('زر حذف كل المجموعات والأصناف', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, minimumSize: const Size.fromHeight(40)),
                          onPressed: () => _confirmWipeData(
                            'حذف الأصناف فقط',
                            'سيتم حذف جميع الأصناف مع الإبقاء على أقسام المجموعات.',
                            () => SettingsDBHelper.clearProductsOnly(),
                          ),
                          icon: const Icon(Icons.inventory_2, color: Colors.white),
                          label: const Text('زر حذف الأصناف فقط', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                  onPressed: _saveGeneralSettings,
                  child: const Text('حفظ جميع الإعدادات', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
