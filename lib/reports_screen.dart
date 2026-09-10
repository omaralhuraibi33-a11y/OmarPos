import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.bar_chart, size: 36, color: Colors.green),
                title: const Text('تقارير المبيعات والأرباح', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('عَرَض حركة المبيعات اليومية والشهرية'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة التقارير جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
