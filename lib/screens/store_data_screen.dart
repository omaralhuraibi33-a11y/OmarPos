import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'omar_pos/db_helper.dart'; // تأكد من مطابقة مسار الاستيراد لديك

class StoreDataScreen extends StatefulWidget {
  const StoreDataScreen({Key? key}) : super(key: key);

  @override
  State<StoreDataScreen> createState() => _StoreDataScreenState();
}

class _StoreDataScreenState extends State<StoreDataScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _footerController = TextEditingController();

  bool _isLoading = true;
  String? _storeImagePath; // متغير لتخزين مسار الصورة المكتسبة

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  // جلب البيانات المخزنة من قاعدة البيانات
  Future<void> _loadStoreData() async {
    final name = await DBHelper.getSetting('store_name', defaultValue: 'omarsoft');
    final phone = await DBHelper.getSetting('store_phone', defaultValue: '771987636');
    final address = await DBHelper.getSetting('store_address', defaultValue: 'شارع تونس - خلف محطة اليرموك');
    final footer = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.');
    final imagePath = await DBHelper.getSetting('store_image_path', defaultValue: '');

    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _phoneController.text = phone ?? '';
        _addressController.text = address ?? '';
        _footerController.text = footer ?? '';
        _storeImagePath = (imagePath != null && imagePath.isNotEmpty) ? imagePath : null;
        _isLoading = false;
      });
    }
  }

  // دالة اختيار صورة من المعرض
  Future<void> _pickStoreImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _storeImagePath = image.path;
      });
    }
  }

  // حفظ البيانات في قاعدة البيانات
  Future<void> _saveStoreData() async {
    await DBHelper.saveSetting('store_name', _nameController.text.trim());
    await DBHelper.saveSetting('store_phone', _phoneController.text.trim());
    await DBHelper.saveSetting('store_address', _addressController.text.trim());
    await DBHelper.saveSetting('invoice_footer', _footerController.text.trim());
    if (_storeImagePath != null) {
      await DBHelper.saveSetting('store_image_path', _storeImagePath!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ بيانات المتجر بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات المتجر'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickStoreImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.indigoAccent,
                          backgroundImage: (_storeImagePath != null && File(_storeImagePath!).existsSync())
                              ? FileImage(File(_storeImagePath!))
                              : null,
                          child: (_storeImagePath == null || !File(_storeImagePath!).existsSync())
                              ? const Icon(Icons.storefront, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.amber,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                            onPressed: _pickStoreImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المتجر',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _footerController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة تذييل الفاتورة (النص الختامي أسفل الفاتورة)',
                    prefixIcon: Icon(Icons.note),
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
                  onPressed: _saveStoreData,
                  child: const Text('حفظ بيانات المتجر', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}
