import 'package:flutter/material.dart';
import 'db_helper.dart';

class CashBoxScreen extends StatelessWidget {
  const CashBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إجمالي الصندوق'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text('عرض رصيد الصندوق الحالي'),
          onPressed: () => _showCashBoxDialog(context),
        ),
      ),
    );
  }

  static Future<void> _showCashBoxDialog(BuildContext context) async {
    double balance = await DBHelper.getMainVaultBalance();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إجمالي الصندوق الحالي',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 50, color: Colors.green),
            const SizedBox(height: 15),
            Text(
              '${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
