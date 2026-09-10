import 'package:flutter/material.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.point_of_sale, size: 36, color: Colors.blue),
                title: const Text('واجهة المبيعات السريعة', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إصدار الفواتير وطباعة الايصالات'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة نقطة البيع جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
