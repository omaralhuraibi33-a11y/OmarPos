import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // المحدد الزمني
  String _selectedPeriod = 'today'; // 'today', 'month', 'year', 'custom'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // البيانات المجلوبة
  List<Invoice> _allInvoices = [];
  List<Voucher> _allVouchers = [];
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setPeriod('today');
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      if (period == 'today') {
        _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (period == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (period == 'year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
    });
    _loadReportData();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final invoices = await DBHelper.getAllInvoices();
    final vouchers = await DBHelper.getAllVouchers();
    final products = await DBHelper.getAllProducts();

    setState(() {
      _allInvoices = invoices.where((inv) {
        final date = DateTime.tryParse(inv.date) ?? DateTime.now();
        return date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_endDate.add(const Duration(seconds: 1)));
      }).toList();

      _allVouchers = vouchers.where((v) {
        final date = DateTime.tryParse(v.date) ?? DateTime.now();
        return date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_endDate.add(const Duration(seconds: 1)));
      }).toList();

      _allProducts = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الشاملة'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.point_of_sale), text: 'المبيعات'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'المشتريات'),
            Tab(icon: Icon(Icons.lock_clock), text: 'الإغلاقات'),
            Tab(icon: Icon(Icons.money_off), text: 'المصروفات'),
            Tab(icon: Icon(Icons.inventory_2), text: 'جرد المخزن'),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط اختيار الفترة الزمنية
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('اليوم'),
                  selected: _selectedPeriod == 'today',
                  onSelected: (_) => _setPeriod('today'),
                ),
                const SizedBox(width: 5),
                FilterChip(
                  label: const Text('هذا الشهر'),
                  selected: _selectedPeriod == 'month',
                  onSelected: (_) => _setPeriod('month'),
                ),
                const SizedBox(width: 5),
                FilterChip(
                  label: const Text('هذه السنة'),
                  selected: _selectedPeriod == 'year',
                  onSelected: (_) => _setPeriod('year'),
                ),
                const SizedBox(width: 5),
                FilterChip(
                  label: Text(_selectedPeriod == 'custom'
                      ? '${dateFormat.format(_startDate)} -> ${dateFormat.format(_endDate)}'
                      : 'مخصص'),
                  selected: _selectedPeriod == 'custom',
                  onSelected: (_) => _selectCustomDateRange(),
                ),
              ],
            ),
          ),

          // محتوى التقرير
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesReport(),
                      _buildPurchasesReport(),
                      _buildShiftsReport(),
                      _buildExpensesReport(),
                      _buildInventoryReport(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 1. تقرير المبيعات
  Widget _buildSalesReport() {
    final salesInvoices = _allInvoices.where((i) => i.invoiceType == 'sale').toList();
    double totalCash = 0;
    double totalCredit = 0;

    for (var inv in salesInvoices) {
      if (inv.paymentType == 'cash') {
        totalCash += inv.totalAmount;
      } else {
        totalCredit += inv.totalAmount;
      }
    }
    double totalSales = totalCash + totalCredit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي المبيعات', totalSales.toStringAsFixed(2), Colors.teal, [
            _buildRowDetail('عدد الفواتير:', '${salesInvoices.length} فاتورة'),
            _buildRowDetail('المبيعات النقدي:', totalCash.toStringAsFixed(2)),
            _buildRowDetail('المبيعات الآجل:', totalCredit.toStringAsFixed(2)),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: salesInvoices.length,
            itemBuilder: (ctx, i) {
              final inv = salesInvoices[i];
              return Card(
                child: ListTile(
                  title: Text('فاتورة رقم: #${inv.id}'),
                  subtitle: Text('التاريخ: ${inv.date} | النوع: ${inv.paymentType == "cash" ? "نقدي" : "آجل"}'),
                  trailing: Text('${inv.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. تقرير المشتريات
  Widget _buildPurchasesReport() {
    return const Center(child: Text('جدول المشتريات ينشط عند تسجيل فواتير الشراء'));
  }

  // 3. تقرير الإغلاقات والورديات
  Widget _buildShiftsReport() {
    return const Center(child: Text('سجل إغلاقات الصندوق المغلقة خلال هذه الفترة'));
  }

  // 4. تقرير المصروفات
  Widget _buildExpensesReport() {
    final expenses = _allVouchers.where((v) => v.voucherType == 'expense' || v.voucherType == 'payment').toList();
    double totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي المصروفات', totalExpenses.toStringAsFixed(2), Colors.red, [
            _buildRowDetail('عدد السندات:', '${expenses.length} سند'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (ctx, i) {
              final exp = expenses[i];
              return Card(
                child: ListTile(
                  title: Text(exp.targetName ?? 'مصروف عام'),
                  subtitle: Text('${exp.date} | ${exp.notes}'),
                  trailing: Text('-${exp.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. تقرير جرد المخزن
  Widget _buildInventoryReport() {
    double totalPurchaseValue = 0;
    double totalSellValue = 0;

    for (var p in _allProducts) {
      totalPurchaseValue += (p.purchasePrice * p.quantity);
      totalSellValue += (p.sellPrice * p.quantity);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('خلاصة جرد المخزن', '${_allProducts.length} صنف', Colors.blue, [
            _buildRowDetail('القيمة بسعر الشراء:', totalPurchaseValue.toStringAsFixed(2)),
            _buildRowDetail('القيمة المتوقعة بسعر البيع:', totalSellValue.toStringAsFixed(2)),
            _buildRowDetail('الأرباح المتوقعة عند البيع:', (totalSellValue - totalPurchaseValue).toStringAsFixed(2)),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allProducts.length,
            itemBuilder: (ctx, i) {
              final p = _allProducts[i];
              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text('الكمية الحالية: ${p.quantity} | سعر الشراء: ${p.purchasePrice}'),
                  trailing: Text('البيع: ${p.sellPrice}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String mainValue, Color color, List<Widget> details) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(mainValue, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const Divider(),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
