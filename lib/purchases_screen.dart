import 'package:flutter/material.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتريات'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, size: 36, color: Colors.orange),
                title: const Text('إدارة المشتريات', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تسجيل فواتير المشتريات والموردين'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة المشتريات جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
