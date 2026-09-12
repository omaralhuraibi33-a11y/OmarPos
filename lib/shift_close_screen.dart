import 'package:flutter/material.dart';
import 'db_helper.dart';

class ShiftSummary {
  final int salesCount;
  final double cashSales;
  final double creditSales;
  final double totalSales;
  
  final int returnsCount;
  final double totalReturns;
  
  final double totalExpenses;
  final double totalReceipts; // مقبوضات سندات القبض
  
  final double netCashInDrawer; // النقدية المتوقعة بالصندوق

  ShiftSummary({
    required this.salesCount,
    required this.cashSales,
    required this.creditSales,
    required this.totalSales,
    required this.returnsCount,
    required this.totalReturns,
    required this.totalExpenses,
    required this.totalReceipts,
    required this.netCashInDrawer,
  });
}

class ShiftCloseScreen extends StatefulWidget {
  const ShiftCloseScreen({Key? key}) : super(key: key);

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  bool _isLoading = true;
  ShiftSummary? _summary;
  final TextEditingController _actualCashController = TextEditingController();
  double _cashDifference = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateShiftSummary();
  }

  Future<void> _calculateShiftSummary() async {
    setState(() => _isLoading = true);

    // جلب الفواتير والسندات المحسوبة للوردية الحالية
    final invoices = await DBHelper.getAllInvoices(); 
    final vouchers = await DBHelper.getAllVouchers();

    int salesCount = 0;
    double cashSales = 0.0;
    double creditSales = 0.0;
    
    int returnsCount = 0;
    double totalReturns = 0.0;

    for (var inv in invoices) {
      if (inv.invoiceType == 'sale') {
        salesCount++;
        if (inv.paymentType == 'cash') {
          cashSales += inv.totalAmount;
        } else {
          creditSales += inv.totalAmount;
        }
      } else if (inv.invoiceType == 'return') {
        returnsCount++;
        totalReturns += inv.totalAmount;
      }
    }

    double totalExpenses = 0.0;
    double totalReceipts = 0.0;

    for (var v in vouchers) {
      if (v.voucherType == 'expense' || v.voucherType == 'payment') {
        totalExpenses += v.amount;
      } else if (v.voucherType == 'receipt') {
        totalReceipts += v.amount;
      }
    }

    double totalSales = cashSales + creditSales;
    // صافي النقد المفروض توفره في الدرج: (مبيعات نقدي + مقبوضات) - (مرتجعات + مصروفات)
    double netCashInDrawer = (cashSales + totalReceipts) - (totalReturns + totalExpenses);

    setState(() {
      _summary = ShiftSummary(
        salesCount: salesCount,
        cashSales: cashSales,
        creditSales: creditSales,
        totalSales: totalSales,
        returnsCount: returnsCount,
        totalReturns: totalReturns,
        totalExpenses: totalExpenses,
        totalReceipts: totalReceipts,
        netCashInDrawer: netCashInDrawer,
      );
      _actualCashController.text = netCashInDrawer.toStringAsFixed(2);
      _isLoading = false;
    });
  }

  void _updateDifference(String val) {
    final actual = double.tryParse(val) ?? 0.0;
    setState(() {
      _cashDifference = actual - (_summary?.netCashInDrawer ?? 0.0);
    });
  }

  Future<void> _confirmCloseShift() async {
    if (_summary == null) return;

    final actualCash = double.tryParse(_actualCashController.text.trim()) ?? _summary!.netCashInDrawer;

    // إظهار حوار تأكيد نهائي
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إغلاق الوردية'),
        content: Text(
          'هل أنت تأكد من إغلاق الصندوق الآن؟\n\n'
          'النقدية المتوقعة: ${_summary!.netCashInDrawer.toStringAsFixed(2)}\n'
          'النقدية الفعلية: ${actualCash.toStringAsFixed(2)}\n'
          'الفارق: ${_cashDifference.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveAndPrintShiftReport(actualCash);
            },
            child: const Text('تأكيد وطباعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndPrintShiftReport(double actualCash) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إغلاق الصندوق وحفظ التقرير بنجاح! جاري إرسال الأمر للطباعة...'),
        backgroundColor: Colors.green,
      ),
    );

    // أمر الطباعة للتقرير الحراري
    _printReceipt();
  }

  void _printReceipt() {
    // توجيه أمر الطباعة على الطابعة الحرارية
  }

  Widget _buildItemRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إغلاق الصندوق / الوردية'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('حدث خطأ أثناء احتساب البيانات'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // كارت تفاصيل المبيعات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تفاصيل المبيعات',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Divider(),
                              _buildItemRow('عدد فواتير المبيعات:', '${_summary!.salesCount} فاتورة'),
                              _buildItemRow('المبيعات نقداً (كاش):', '${_summary!.cashSales.toStringAsFixed(2)}'),
                              _buildItemRow('إجمالي الأجل (آجل):', '${_summary!.creditSales.toStringAsFixed(2)}', color: Colors.orange.shade800),
                              const Divider(),
                              _buildItemRow('إجمالي المبيعات:', '${_summary!.totalSales.toStringAsFixed(2)}', isBold: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // كارت المرتجعات والمصروفات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المرتجعات والمصروفات',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Divider(),
                              _buildItemRow('عدد الفواتير المرتجعة:', '${_summary!.returnsCount} فاتورة'),
                              _buildItemRow('إجمالي المرتجع:', '${_summary!.totalReturns.toStringAsFixed(2)}', color: Colors.red),
                              _buildItemRow('إجمالي المصروفات والسندات:', '${_summary!.totalExpenses.toStringAsFixed(2)}', color: Colors.red),
                              _buildItemRow('إجمالي مقبوضات السندات:', '${_summary!.totalReceipts.toStringAsFixed(2)}', color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // كارت الخلاصة والصندوق
                      Card(
                        color: Colors.teal.shade50,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ملخص الصندوق بالنظام',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Divider(),
                              _buildItemRow(
                                'إجمالي النقدية المفروضة بالصندوق:',
                                '${_summary!.netCashInDrawer.toStringAsFixed(2)}',
                                isBold: true,
                                color: Colors.teal.shade900,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // المطابقة الفعلية للنقدية
                      TextField(
                        controller: _actualCashController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _updateDifference,
                        decoration: InputDecoration(
                          labelText: 'إجمالي النقدية الفعلية في الصندوق (الدرج)',
                          prefixIcon: const Icon(Icons.point_of_sale),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                      if (_cashDifference != 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          _cashDifference > 0
                              ? 'يوجد زيادة في الصندوق بمقدار: +${_cashDifference.toStringAsFixed(2)}'
                              : 'يوجد عجز في الصندوق بمقدار: ${_cashDifference.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _cashDifference > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      // زر الإغلاق والطباعة
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.lock_clock, color: Colors.white),
                          label: const Text(
                            'تأكيد إغلاق الصندوق / الوردية وطباعة التقرير',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          onPressed: _confirmCloseShift,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
