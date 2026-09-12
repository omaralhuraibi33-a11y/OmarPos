import 'package:flutter/material.dart';

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
