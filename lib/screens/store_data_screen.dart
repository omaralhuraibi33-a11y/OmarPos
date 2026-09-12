import 'package:flutter/material.dart';

class StoreDataScreen extends StatefulWidget {
  const StoreDataScreen({Key? key}) : super(key: key);

  @override
  State<StoreDataScreen> createState() => _StoreDataScreenState();
}

class _StoreDataScreenState extends State<StoreDataScreen> {
  final _nameController = TextEditingController(text: 'متجر جديد');
  final _phoneController = TextEditingController(text: '770000000');
  final _addressController = TextEditingController(text: 'العنوان الرئيس');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.storefront, size: 50),
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
