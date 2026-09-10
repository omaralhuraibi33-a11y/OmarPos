import 'package:flutter/material.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير المالي'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة التقرير المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
