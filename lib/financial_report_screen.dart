import 'package:flutter/material.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير المالي'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, size: 36, color: Colors.lightGreen),
                title: const Text('القوائم المالية', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ملخص الإيرادات، المصروفات، والأرباح الصافية'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة التقرير المالي جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
