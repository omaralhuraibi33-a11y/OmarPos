import 'package:flutter/material.dart';

class ShiftCloseScreen extends StatelessWidget {
  const ShiftCloseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إغلاق الصندوق / الوردية'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.lock_clock, size: 36, color: Colors.red),
                title: const Text('إنهاء الوردية', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('مطابقة النقدية مع المبيعات وإغلاق الوردية'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة إغلاق الوردية جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
