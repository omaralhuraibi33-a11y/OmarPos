import 'package:flutter/material.dart';
import 'package:omar_pos/db_helper.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _storeNameController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _taxNoController = TextEditingController();
  final _footerController = TextEditingController();

  bool _showLogo = true;
  bool _showTaxNo = true;
  bool _showItemCount = true; // خيار إظهار عدد الأصناف في نهاية الفاتورة
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storeName = await DBHelper.getSetting('store_name', defaultValue: 'OMAR POS');
    final storePhone = await DBHelper.getSetting('store_phone', defaultValue: '');
    final taxNo = await DBHelper.getSetting('tax_number', defaultValue: '');
    final footer = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.');
    final logo = await DBHelper.getSetting('show_logo', defaultValue: 'true');
    final taxVisible = await DBHelper.getSetting('show_tax_no', defaultValue: 'true');
    final itemCountVisible = await DBHelper.getSetting('show_item_count', defaultValue: 'true');

    if (mounted) {
      setState(() {
        _storeNameController.text = storeName ?? '';
        _storePhoneController.text = storePhone ?? '';
        _taxNoController.text = taxNo ?? '';
        _footerController.text = footer ?? '';
        _showLogo = logo == 'true';
        _showTaxNo = taxVisible == 'true';
        _showItemCount = itemCountVisible == 'true';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await DBHelper.saveSetting('store_name', _storeNameController.text.trim());
    await DBHelper.saveSetting('store_phone', _storePhoneController.text.trim());
    await DBHelper.saveSetting('tax_number', _taxNoController.text.trim());
    await DBHelper.saveSetting('invoice_footer', _footerController.text.trim());
    await DBHelper.saveSetting('show_logo', _showLogo.toString());
    await DBHelper.saveSetting('show_tax_no', _showTaxNo.toString());
    await DBHelper.saveSetting('show_item_count', _showItemCount.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ تصميم وإعدادات الفاتورة بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _taxNoController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصميم وإعدادات الفاتورة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('بيانات رأس الفاتورة (Header)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                const SizedBox(height: 10),
                TextField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المتجر / المنشأة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storePhoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف / العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_showTaxNo) ...[
                  TextField(
                    controller: _taxNoController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم الضريبي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  title: const Text('إظهار الشعار في رأس الفاتورة'),
                  value: _showLogo,
                  onChanged: (val) => setState(() => _showLogo = val),
                ),
                SwitchListTile(
                  title: const Text('إظهار حقل الرقم الضريبي'),
                  value: _showTaxNo,
                  onChanged: (val) => setState(() => _showTaxNo = val),
                ),
                const Divider(height: 30),
                const Text('محتويات وتذييل الفاتورة (Footer & Summary)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('إظهار إجمالي عدد الأصناف والقطع أسفل الفاتورة'),
                  value: _showItemCount,
                  onChanged: (val) => setState(() => _showItemCount = val),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveSettings,
                  child: const Text('حفظ تصميم الفاتورة', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}
