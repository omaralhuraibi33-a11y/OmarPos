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
  List<Invoice> _allPurchaseInvoices = [];
  List<Invoice> _allReturnInvoices = [];
  List<Invoice> _allPurchaseReturnInvoices = [];
  List<Voucher> _allVouchers = [];
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // عدد التبويبات 8
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
    final purchaseInvoices = await DBHelper.getAllPurchaseInvoices();
    final returnInvoices = await DBHelper.getAllReturnInvoices();
    final purchaseReturnInvoices = await DBHelper.getAllPurchaseReturnInvoices();
    final vouchers = await DBHelper.getAllVouchers();
    final products = await DBHelper.getAllProducts();

    bool filterDate(String dateStr) {
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      return date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          date.isBefore(_endDate.add(const Duration(seconds: 1)));
    }

    setState(() {
      _allInvoices = invoices.where((inv) => filterDate(inv.date)).toList();
      _allPurchaseInvoices = purchaseInvoices.where((inv) => filterDate(inv.date)).toList();
      _allReturnInvoices = returnInvoices.where((inv) => filterDate(inv.date)).toList();
      _allPurchaseReturnInvoices = purchaseReturnInvoices.where((inv) => filterDate(inv.date)).toList();
      _allVouchers = vouchers.where((v) => filterDate(v.date)).toList();
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
            Tab(icon: Icon(Icons.assignment_return), text: 'مرتجع المبيعات'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'المشتريات'),
            Tab(icon: Icon(Icons.remove_shopping_cart), text: 'مرتجع المشتريات'),
            Tab(icon: Icon(Icons.lock_clock), text: 'إغلاق الصندوق'),
            Tab(icon: Icon(Icons.money_off), text: 'المصروفات'),
            Tab(icon: Icon(Icons.attach_money), text: 'المقبوضات'),
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
                      _buildReturnSalesReport(),
                      _buildPurchasesReport(),
                      _buildPurchaseReturnsReport(),
                      _buildShiftsReport(),
                      _buildExpensesReport(),
                      _buildReceiptsReport(),
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

  // 2. تقرير مرتجع المبيعات
  Widget _buildReturnSalesReport() {
    double totalReturns = _allReturnInvoices.fold(0, (sum, item) => sum + item.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي مرتجعات المبيعات', totalReturns.toStringAsFixed(2), Colors.orange, [
            _buildRowDetail('عدد فواتير المرتجع:', '${_allReturnInvoices.length} فاتورة'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allReturnInvoices.length,
            itemBuilder: (ctx, i) {
              final inv = _allReturnInvoices[i];
              return Card(
                child: ListTile(
                  title: Text('مرتجع رقم: #${inv.id}'),
                  subtitle: Text('التاريخ: ${inv.date} | العميل: ${inv.customerName ?? "نقدي"}'),
                  trailing: Text('-${inv.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. تقرير المشتريات
  Widget _buildPurchasesReport() {
    double totalPurchases = _allPurchaseInvoices.fold(0, (sum, item) => sum + item.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي المشتريات', totalPurchases.toStringAsFixed(2), Colors.indigo, [
            _buildRowDetail('عدد فواتير الشراء:', '${_allPurchaseInvoices.length} فاتورة'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allPurchaseInvoices.length,
            itemBuilder: (ctx, i) {
              final inv = _allPurchaseInvoices[i];
              return Card(
                child: ListTile(
                  title: Text('شراء رقم: #${inv.id}'),
                  subtitle: Text('التاريخ: ${inv.date} | المورد: ${inv.customerName ?? "غير محدد"}'),
                  trailing: Text('${inv.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. تقرير مرتجع المشتريات
  Widget _buildPurchaseReturnsReport() {
    double totalPurchaseReturns = _allPurchaseReturnInvoices.fold(0, (sum, item) => sum + item.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي مرتجع المشتريات', totalPurchaseReturns.toStringAsFixed(2), Colors.purple, [
            _buildRowDetail('عدد الفواتير:', '${_allPurchaseReturnInvoices.length} فاتورة'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allPurchaseReturnInvoices.length,
            itemBuilder: (ctx, i) {
              final inv = _allPurchaseReturnInvoices[i];
              return Card(
                child: ListTile(
                  title: Text('مرتجع شراء رقم: #${inv.id}'),
                  subtitle: Text('التاريخ: ${inv.date} | المورد: ${inv.customerName ?? "غير محدد"}'),
                  trailing: Text('${inv.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. تقرير إغلاق الصندوق
  Widget _buildShiftsReport() {
    // جلب سندات القبض والتوريد الناتجة عن إغلاقات الصندوق ضمن الفترة الزمنية الحالية
    final shiftVouchers = _allVouchers.where((v) => v.notes.contains('إغلاق الوردية')).toList();
    double totalTransferred = shiftVouchers.fold(0, (sum, item) => sum + item.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي المبالغ المُرحّلة للصندوق', totalTransferred.toStringAsFixed(2), Colors.blueGrey, [
            _buildRowDetail('عدد عمليات الإغلاق:', '${shiftVouchers.length} وردية'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shiftVouchers.length,
            itemBuilder: (ctx, i) {
              final v = shiftVouchers[i];
              return Card(
                child: ListTile(
                  title: Text(v.targetName ?? 'إغلاق وردية'),
                  subtitle: Text('التاريخ: ${v.date} | ملاحظات: ${v.notes}'),
                  trailing: Text('${v.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 6. تقرير المصروفات
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

  // 7. تقرير المقبوضات
  Widget _buildReceiptsReport() {
    final receipts = _allVouchers.where((v) => v.voucherType == 'receipt').toList();
    double totalReceipts = receipts.fold(0, (sum, item) => sum + item.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard('إجمالي المقبوضات', totalReceipts.toStringAsFixed(2), Colors.green, [
            _buildRowDetail('عدد السندات:', '${receipts.length} سند'),
          ]),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: receipts.length,
            itemBuilder: (ctx, i) {
              final rec = receipts[i];
              return Card(
                child: ListTile(
                  title: Text(rec.targetName ?? 'سند قبض عام'),
                  subtitle: Text('${rec.date} | ${rec.notes}'),
                  trailing: Text('+${rec.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. تقرير جرد المخزن
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
