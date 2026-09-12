import 'package:flutter/material.dart';
import 'db_helper.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({Key? key}) : super(key: key);

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  bool _isLoading = true;

  // القيم المالية
  double _totalSales = 0.0;             // إجمالي المبيعات
  double _salesCost = 0.0;              // تكلفة المبيعات
  double _totalPurchases = 0.0;         // إجمالي المشتريات
  double _totalRevenues = 0.0;          // إجمالي الإيرادات
  double _totalExpenses = 0.0;          // إجمالي المصروفات
  double _suppliersBalance = 0.0;       // إجمالي الباقي للموردين
  double _customersBalance = 0.0;       // إجمالي الباقي على العملاء
  double _mainVaultBalance = 0.0;       // إجمالي الصندوق الرئيسي
  double _salesReturns = 0.0;           // إجمالي مردود المبيعات
  double _purchasesReturns = 0.0;       // إجمالي مردود المشتريات

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);

    try {
      // جلب البيانات من دالة DBHelper (قم بربط كل دالة طبقاً لما هو معرف لديك في DBHelper)
      final sales = await DBHelper.getTotalSales();
      final cost = await DBHelper.getSalesCost();
      final purchases = await DBHelper.getTotalPurchases();
      final revenues = await DBHelper.getTotalRevenues();
      final expenses = await DBHelper.getTotalExpenses();
      final suppBal = await DBHelper.getSuppliersTotalBalance();
      final custBal = await DBHelper.getCustomersTotalBalance();
      final vaultBal = await DBHelper.getMainVaultBalance();
      final sReturns = await DBHelper.getSalesReturnsTotal();
      final pReturns = await DBHelper.getPurchasesReturnsTotal();

      setState(() {
        _totalSales = sales;
        _salesCost = cost;
        _totalPurchases = purchases;
        _totalRevenues = revenues;
        _totalExpenses = expenses;
        _suppliersBalance = suppBal;
        _customersBalance = custBal;
        _mainVaultBalance = vaultBal;
        _salesReturns = sReturns;
        _purchasesReturns = pReturns;
        _isLoading = false;
      });
    } catch (e) {
      // في حال لم تكن الدوال موجودة بنفس الاسم بعد في DBHelper، تجنباً لإيقاف التطبيق
      setState(() => _isLoading = false);
    }
  }

  // حساب صافي الربح
  // (المبيعات الصافية - تكلفة المبيعات) + الإيرادات الأخرى - المصروفات
  double get _netProfit {
    final netSales = _totalSales - _salesReturns;
    final grossProfit = netSales - _salesCost;
    return grossProfit + _totalRevenues - _totalExpenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير المالي العام'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: _loadFinancialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // كارت صافي الربح الرئيسي
                    _buildNetProfitCard(),

                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'ملخص الحركة المالية:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // شبكة المؤشرات المالية
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard('إجمالي المبيعات', _totalSales, Icons.point_of_sale, Colors.teal),
                        _buildStatCard('إجمالي مردود المبيعات', _salesReturns, Icons.assignment_return, Colors.deepOrange),
                        _buildStatCard('تكلفة المبيعات', _salesCost, Icons.inventory_2_outlined, Colors.brown),
                        _buildStatCard('إجمالي المشتريات', _totalPurchases, Icons.shopping_bag, Colors.blue),
                        _buildStatCard('إجمالي مردود المشتريات', _purchasesReturns, Icons.assignment_return_outlined, Colors.purple),
                        _buildStatCard('إجمالي الإيرادات', _totalRevenues, Icons.add_chart, Colors.green),
                        _buildStatCard('إجمالي المصروفات', _totalExpenses, Icons.money_off, Colors.red),
                        _buildStatCard('الباقي على العملاء', _customersBalance, Icons.people_outline, Colors.indigo),
                        _buildStatCard('الباقي للموردين', _suppliersBalance, Icons.business_center_outlined, Colors.amber.shade900),
                        _buildStatCard('الصندوق الرئيسي', _mainVaultBalance, Icons.account_balance_wallet, Colors.lightBlue.shade800),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ودجت بطاقة صافي الربح (تتغير ألوانها بحسب الربح/الخسارة)
  Widget _buildNetProfitCard() {
    final isProfit = _netProfit >= 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isProfit ? 'صافي الربح' : 'صافي الخسارة',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_netProfit.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت تصميم البطاقات الفرعية
  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
