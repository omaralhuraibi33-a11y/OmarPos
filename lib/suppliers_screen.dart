import 'package:flutter/material.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.local_shipping, size: 36, color: Colors.indigo),
                title: const Text('سجل الموردين', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إدارة بيانات الموردين والديون'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة الموردين جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
