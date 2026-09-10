import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.inventory_2, size: 36, color: Colors.teal),
                title: const Text('إدارة المخزون والأصناف', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('متابعة الكميات الجرد والتحويلات'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة المخزن جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
