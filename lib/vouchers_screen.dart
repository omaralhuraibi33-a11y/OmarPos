import 'package:flutter/material.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السندات'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.receipt_long, size: 36, color: Colors.amber),
                title: const Text('سندات القبض والصرف', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تسجيل المبالغ المقبوضة والمصروفات'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة السندات جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
