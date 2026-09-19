import 'package:flutter/material.dart';
import 'package:omar_pos/db_helper.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _footerController = TextEditingController();
  bool _showLogo = true;
  bool _showTaxNo = true;
  bool _autoKitchen = false;
  bool _autoCustomer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// قراءة الإعدادات من قاعدة البيانات عند فتح الشاشة
  Future<void> _loadSettings() async {
    final footer = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.');
    final logo = await DBHelper.getSetting('show_logo', defaultValue: 'true');
    final tax = await DBHelper.getSetting('show_tax_no', defaultValue: 'true');
    final autoKitchen = await DBHelper.getSetting('auto_kitchen', defaultValue: 'false');
    final autoCustomer = await DBHelper.getSetting('auto_customer', defaultValue: 'false');

    if (mounted) {
      setState(() {
        _footerController.text = footer ?? '';
        _showLogo = logo == 'true';
        _showTaxNo = tax == 'true';
        _autoKitchen = autoKitchen == 'true';
        _autoCustomer = autoCustomer == 'true';
        _isLoading = false;
      });
    }
  }

  /// حفظ الإعدادات في قاعدة البيانات
  Future<void> _saveSettings() async {
    await DBHelper.saveSetting('invoice_footer', _footerController.text.trim());
    await DBHelper.saveSetting('show_logo', _showLogo.toString());
    await DBHelper.saveSetting('show_tax_no', _showTaxNo.toString());
    await DBHelper.saveSetting('auto_kitchen', _autoKitchen.toString());
    await DBHelper.saveSetting('auto_customer', _autoCustomer.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ إعدادات الفواتير والطباعة بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الفواتير والطباعة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'إعدادات مظهر الفاتورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const Divider(),
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
                const SizedBox(height: 24),
                const Text(
                  'إعدادات الطباعة التلقائية عند الحفظ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('الطباعة التلقائية لمطبخ التحضير'),
                  subtitle: const Text('إرسال نسخة للطابعة المخصصة للمطبخ تلقائياً عند حفظ الفاتورة'),
                  value: _autoKitchen,
                  onChanged: (val) => setState(() => _autoKitchen = val),
                ),
                SwitchListTile(
                  title: const Text('الطباعة التلقائية لفاتورة العميل'),
                  subtitle: const Text('إرسال نسخة للطابعة المخصصة للزبون تلقائياً عند حفظ الفاتورة'),
                  value: _autoCustomer,
                  onChanged: (val) => setState(() => _autoCustomer = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveSettings,
                  child: const Text('حفظ جميع الإعدادات', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}
