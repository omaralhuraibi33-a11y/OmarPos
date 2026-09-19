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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final footer = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.');
    final logo = await DBHelper.getSetting('show_logo', defaultValue: 'true');
    final tax = await DBHelper.getSetting('show_tax_no', defaultValue: 'true');

    if (mounted) {
      setState(() {
        _footerController.text = footer ?? '';
        _showLogo = logo == 'true';
        _showTaxNo = tax == 'true';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await DBHelper.saveSetting('invoice_footer', _footerController.text.trim());
    await DBHelper.saveSetting('show_logo', _showLogo.toString());
    await DBHelper.saveSetting('show_tax_no', _showTaxNo.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ إعدادات مظهر الفاتورة بنجاح'),
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
      appBar: AppBar(title: const Text('إعدادات مظهر الفاتورة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                const SizedBox(height: 16),
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
                  child: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}
