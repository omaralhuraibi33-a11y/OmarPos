import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingTile(
            context,
            icon: Icons.store,
            title: 'بيانات المتجر',
            subtitle: 'تعديل اسم المتجر، اللوجو، وبيانات التواصل',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreInfoSubScreen()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.print,
            title: 'إعدادات الطابعات',
            subtitle: 'ربط طابعات البلوتوث والحرارية وإدارة النماذج',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSettingsSubScreen()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.payment,
            title: 'طرق الدفع',
            subtitle: 'إدارة طرق الدفع النقدي والشبكة والآجل',
            onTap: () => _showPlaceHolder(context, 'طرق الدفع'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.receipt_long,
            title: 'إعدادات الفواتير',
            subtitle: 'تخصيص الترويسة، التذييل، والضرائب',
            onTap: () => _showPlaceHolder(context, 'إعدادات الفواتير'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.badge,
            title: 'الموظفون والصلاحيات',
            subtitle: 'إضافة الكاشير وإدارة الأدوار',
            onTap: () => _showPlaceHolder(context, 'الموظفون والصلاحيات'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.backup,
            title: 'النسخ الاحتياطي والاستعادة',
            subtitle: 'حفظ واستعادة قاعدة البيانات محلياً',
            onTap: () => _showPlaceHolder(context, 'النسخ الاحتياطي'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.tune,
            title: 'إعدادات النظام العامة',
            subtitle: 'اللغة، العملة، وضع الشاشة',
            onTap: () => _showPlaceHolder(context, 'إعدادات النظام العامة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showPlaceHolder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('شاشة $title قيد التطوير')),
    );
  }
}

// ==========================================
// 1. شاشة بيانات المتجر (اختيار الصور الحقيقي)
// ==========================================
class StoreInfoSubScreen extends StatefulWidget {
  const StoreInfoSubScreen({Key? key}) : super(key: key);

  @override
  State<StoreInfoSubScreen> createState() => _StoreInfoSubScreenState();
}

class _StoreInfoSubScreenState extends State<StoreInfoSubScreen> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        _imagePath != null ? FileImage(File(_imagePath!)) : null,
                    child: _imagePath == null
                        ? const Icon(Icons.store, size: 50, color: Colors.grey)
                        : null,
                  ),
                  InkWell(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المتجر',
                prefixIcon: Icon(Icons.storefront),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ بيانات المتجر بنجاح')),
                  );
                },
                child: const Text('حفظ بيانات المتجر'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. شاشة إعدادات الطابعات (البلوتوث الحقيقي)
// ==========================================
class PrinterSettingsSubScreen extends StatefulWidget {
  const PrinterSettingsSubScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsSubScreen> createState() => _PrinterSettingsSubScreenState();
}

class _PrinterSettingsSubScreenState extends State<PrinterSettingsSubScreen> {
  List<BluetoothInfo> _devices = [];
  bool _isLoading = false;

  Future<void> _scanBluetoothDevices() async {
    setState(() => _isLoading = true);
    try {
      final List<BluetoothInfo> pairedDevices =
          await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _devices = pairedDevices;
        _isLoading = false;
      });

      _showDevicesDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في البحث عن الأجهزة: $e')),
      );
    }
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('أجهزة البلوتوث المقترنة بالجهاز'),
          content: SizedBox(
            width: double.maxFinite,
            child: _devices.isEmpty
                ? const Text('لا توجد أجهزة بلوتوث مقترنة بالجوال حالياً.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.print, color: Colors.blue),
                        title: Text(device.name.isNotEmpty ? device.name : 'طابعة بدون اسم'),
                        subtitle: Text('MAC: ${device.macAdress}'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تحديد الطابعة: ${device.name}')),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الطابعات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('إضافة طابعة بلوتوث جديد'),
                subtitle: const Text('البحث عن الطابعات المقترنة بالجوال'),
                trailing: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.bluetooth_searching, color: Colors.blue),
                onTap: _scanBluetoothDevices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
