import 'package:flutter/material.dart';

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
