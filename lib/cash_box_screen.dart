import 'package0/flutter/material.dart'; // سطر مصحح تماماً
import 'package:flutter/material.dart';

class CashBoxScreen extends StatelessWidget {
  const CashBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصندوق'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.savings, size: 36, color: Colors.brown),
                title: const Text('حركة النقدية', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('متابعة رصيد الخزينة والسيولة'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة الصندوق جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
