import 'package:flutter/material.dart';
import 'db_helper.dart';

import 'screens/printer_settings_screen.dart';
import 'screens/prep_notes_screen.dart';
import 'screens/appearance_settings_screen.dart';
import 'screens/store_data_screen.dart';
import 'screens/invoice_settings_screen.dart';
import 'screens/cash_box_settings_screen.dart';
import 'screens/backup_settings_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/wipe_data_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildMainButton(
            title: '1. إعدادات الطابعات',
            subtitle: 'إضافة/ضبط خيار البلوتوث/الواي فاي وطباعة الفواتير',
            icon: Icons.print,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
          _buildMainButton(
            title: '2. ملاحظات التحضير',
            subtitle: 'إدارة الملاحظات المجهزة للمطبخ (بدون تعديل، حاد...)',
            icon: Icons.note_alt,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrepNotesScreen()),
            ),
          ),
          _buildMainButton(
            title: '3. المظهر',
            subtitle: 'وضع الليل/النهار، حجم أزرار الشاشة الرئيسية ونقطة البيع',
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreDataScreen()),
            ),
          ),
          _buildMainButton(
            title: '5. إعدادات الفاتورة',
            subtitle: 'رأس وخلفية الفاتورة، الرقم الضريبي، رسالة الشكر',
            icon: Icons.receipt,
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen()),
            ),
          ),
          _buildMainButton(
            title: '6. إعدادات الدرج والصندوق',
            subtitle: 'فتح الدرج تلقائياً، المبالغ الافتراضية للوردية',
            icon: Icons.lock,
            color: Colors.brown,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashBoxSettingsScreen()),
            ),
          ),
          _buildMainButton(
            title: '7. النسخ الاحتياطي والاستعادة',
            subtitle: 'نسخ قواطع البيانات محلياً أو سحابياً واسترجاعها',
            icon: Icons.backup,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
            ),
          ),
          _buildMainButton(
            title: '8. طرق الدفع المتاحة',
            subtitle: 'إضافة/تعديل خيارات الدفع (نقدي، أجل، إضافة طرق جديدة)',
            icon: Icons.payment,
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
            ),
          ),
          _buildMainButton(
            title: '9. مسح البيانات والتصفير',
            subtitle: 'تصفير المبيعات أو تهيئة النظام بالكامل (منطقة خطرة)',
            icon: Icons.delete_forever,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WipeDataScreen()),
            ),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
