// كود زر الصندوق في الشاشة الرئيسية
IconButton(
  icon: const Icon(Icons.account_balance_wallet),
  tooltip: 'إجمالي الصندوق',
  onPressed: () async {
    // جلب الرصيد الإجمالي من قاعدة البيانات
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
  },
);
