import 'package:flutter/material.dart';
import 'db_helper.dart';

class ShiftSummary {
  final int shiftNumber;
  
  // تفاصيل المبيعات
  final int salesCount;
  final double cashSales;
  final double creditSales;
  final double totalSales;
  
  // تفاصيل المرتجعات
  final int returnsCount;
  final double cashReturns;
  final double creditReturns;
  final double totalReturns;
  
  final double netCashInDrawer; // النقدية المتوقعة بالصندوق (تقتصر على المبيعات والمرتجعات النقدية فقط)

  ShiftSummary({
    required this.shiftNumber,
    required this.salesCount,
    required this.cashSales,
    required this.creditSales,
    required this.totalSales,
    required this.returnsCount,
    required this.cashReturns,
    required this.creditReturns,
    required this.totalReturns,
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

    // 1. جلب رقم الوردية التالية
    final int nextShiftNumber = await DBHelper.getNextShiftNumber();

    // 2. جلب الفواتير غير المغلقة فقط للوردية الحالية
    final invoices = await DBHelper.getUnclosedInvoices(); 

    int salesCount = 0;
    double cashSales = 0.0;
    double creditSales = 0.0;
    
    int returnsCount = 0;
    double cashReturns = 0.0;
    double creditReturns = 0.0;

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
        if (inv.paymentType == 'cash') {
          cashReturns += inv.totalAmount;
        } else {
          creditReturns += inv.totalAmount;
        }
      }
    }

    double totalSales = cashSales + creditSales;
    double totalReturns = cashReturns + creditReturns;
    
    // صافي النقد المفروض توفره في الدرج بناءً على المبيعات والمرتجعات النقدية فقط (تم إستبعاد السندات تماماً)
    double netCashInDrawer = cashSales - cashReturns;

    setState(() {
      _summary = ShiftSummary(
        shiftNumber: nextShiftNumber,
        salesCount: salesCount,
        cashSales: cashSales,
        creditSales: creditSales,
        totalSales: totalSales,
        returnsCount: returnsCount,
        cashReturns: cashReturns,
        creditReturns: creditReturns,
        totalReturns: totalReturns,
        netCashInDrawer: netCashInDrawer < 0 ? 0.0 : netCashInDrawer,
      );
      _actualCashController.text = _summary!.netCashInDrawer.toStringAsFixed(2);
      _cashDifference = 0.0;
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد إغلاق الوردية رقم (${_summary!.shiftNumber})'),
        content: Text(
          'سيتم إغلاق الوردية وتصفير المبالغ المعلقة وتوريد النقدية الفعلية إلى الصندوق الرئيسي.\n\n'
          'النقدية المتوقعة: ${_summary!.netCashInDrawer.toStringAsFixed(2)}\n'
          'النقدية الفعلية: ${actualCash.toStringAsFixed(2)}\n'
          'الفارق: ${_cashDifference.toStringAsFixed(2)}',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processShiftClosure(actualCash);
            },
            child: const Text('تأكيد وإغلاق الوردية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processShiftClosure(double actualCash) async {
    setState(() => _isLoading = true);

    // إرسال البيانات لدالة الإغلاق (مع تمرير النقدية الفعلية للدرج ليتم توريدها للصندوق العام)
    await DBHelper.closeShift(
      shiftNumber: _summary!.shiftNumber,
      expectedCash: _summary!.netCashInDrawer,
      actualCash: actualCash,
      difference: _cashDifference,
      totalSales: _summary!.totalSales,
      totalReturns: _summary!.totalReturns,
      transferredToMainVault: actualCash, 
    );

    _printShiftReport();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إغلاق الوردية رقم (${_summary!.shiftNumber}) بنجاح وبدء وردية جديدة!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _calculateShiftSummary();
    }
  }

  void _printShiftReport() {
    // أمر إرسال تقرير إغلاق الوردية إلى الطابعة الحرارية
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
              fontSize: isBold ? 15 : 14,
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
        backgroundColor: Colors.blue.shade800,
        title: Text(
          _summary != null ? 'إغلاق الوردية (رقم: ${_summary!.shiftNumber})' : 'إغلاق الصندوق / الوردية',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('حدث خطأ أثناء احتساب بيانات الوردية'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // كارت رقم الوردية
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم الوردية الحالية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Chip(
                              backgroundColor: Colors.blue.shade800,
                              label: Text(
                                '# ${_summary!.shiftNumber}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const Divider(),
                              _buildItemRow('عدد فواتير المبيعات:', '${_summary!.salesCount} فاتورة'),
                              _buildItemRow('المبيعات نقداً (كاش):', '${_summary!.cashSales.toStringAsFixed(2)}'),
                              _buildItemRow('المبيعات الآجلة:', '${_summary!.creditSales.toStringAsFixed(2)}', color: Colors.orange.shade800),
                              const Divider(),
                              _buildItemRow('إجمالي المبيعات:', '${_summary!.totalSales.toStringAsFixed(2)}', isBold: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // كارت تفاصيل المرتجعات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تفاصيل المرتجعات',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                              const Divider(),
                              _buildItemRow('عدد فواتير المرتجعات:', '${_summary!.returnsCount} فاتورة'),
                              _buildItemRow('المرتجعات نقداً (كاش):', '${_summary!.cashReturns.toStringAsFixed(2)}', color: Colors.red),
                              _buildItemRow('المرتجعات الآجلة:', '${_summary!.creditReturns.toStringAsFixed(2)}', color: Colors.orange.shade800),
                              const Divider(),
                              _buildItemRow('إجمالي المرتجعات:', '${_summary!.totalReturns.toStringAsFixed(2)}', isBold: true, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // كارت ملخص الصندوق والنقدية المتوقعة (بدون سندات)
                      Card(
                        color: Colors.green.shade50,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('النقدية المتوقعة بالصندوق (الدرج)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                              const Divider(),
                              _buildItemRow(
                                'الصافي المعلق للتصفير والترحيل:',
                                '${_summary!.netCashInDrawer.toStringAsFixed(2)}',
                                isBold: true,
                                color: Colors.green.shade900,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // إدخال النقدية الفعلية
                      TextField(
                        controller: _actualCashController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _updateDifference,
                        decoration: InputDecoration(
                          labelText: 'إجمالي النقدية الفعلية بالدرج',
                          prefixIcon: const Icon(Icons.point_of_sale, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                      if (_cashDifference != 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          _cashDifference > 0
                              ? 'فائض بمقدار: +${_cashDifference.toStringAsFixed(2)}'
                              : 'عجز بمقدار: ${_cashDifference.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _cashDifference > 0 ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      // زر تأكيد إغلاق الوردية
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.lock, color: Colors.white),
                          label: const Text(
                            'تأكيد إغلاق الوردية وتصفير الصندوق',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
