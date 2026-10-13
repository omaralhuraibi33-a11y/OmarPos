import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
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
  
  final double netCashInDrawer; // النقدية المتوقعة بالصندوق

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

    final int currentShiftId = await DBHelper.getCurrentShiftId();

    final allUnclosedInvoices = await DBHelper.getUnclosedInvoices();
    final invoices = allUnclosedInvoices.where((inv) => inv.shiftId == currentShiftId).toList();

    final allReturnInvoices = await DBHelper.getUnclosedReturnInvoices();
    final returnInvoices = allReturnInvoices.where((inv) => inv.shiftId == currentShiftId).toList();

    int salesCount = invoices.length;
    double cashSales = 0.0;
    double creditSales = 0.0;

    for (var inv in invoices) {
      if (inv.paymentType == 'cash') {
        cashSales += inv.totalAmount;
      } else {
        creditSales += inv.totalAmount;
      }
    }

    int returnsCount = returnInvoices.length;
    double cashReturns = 0.0;
    double creditReturns = 0.0;

    for (var ret in returnInvoices) {
      if (ret.paymentType == 'cash') {
        cashReturns += ret.totalAmount;
      } else {
        creditReturns += ret.totalAmount;
      }
    }

    double totalSales = cashSales + creditSales;
    double totalReturns = cashReturns + creditReturns;
    double netCashInDrawer = cashSales - cashReturns;

    setState(() {
      _summary = ShiftSummary(
        shiftNumber: currentShiftId,
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

  // ==================== دالة إرسال تقرير الإغلاق للطباعة عبر البلوتوث ====================
  Future<void> _printShiftReport(double actualCash) async {
    if (_summary == null) return;

    try {
      // 1. التحقق من حالة الاتصال بالبلوتوث
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        // في حال عدم وجود اتصال مباشر، جلب الطابعة المسجلة وإعادة الاتصال بها
        final printers = await DBHelper.getSavedPrinters();
        if (printers.isNotEmpty && printers.first['macAddress'] != null) {
          String macAddress = printers.first['macAddress'];
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
        }
      }

      // 2. تجهيز البروفايل والأوامر الحرارية عبر esc_pos_utils_plus
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.setGlobalCodeTable('CP1256'); // للغة العربية
      bytes += generator.text('تقرير إغلاق الوردية',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.feed(1);

      bytes += generator.text('رقم الوردية: #${_summary!.shiftNumber}', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('التاريخ: ${DateTime.now().toString().split('.')[0]}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // تفاصيل المبيعات
      bytes += generator.text('[ تفاصيل المبيعات ]', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('عدد الفواتير: ${_summary!.salesCount}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('مبيعات كاش: ${_summary!.cashSales.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('مبيعات آجل: ${_summary!.creditSales.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('إجمالي المبيعات: ${_summary!.totalSales.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // تفاصيل المرتجعات
      bytes += generator.text('[ تفاصيل المرتجعات ]', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('عدد المرتجعات: ${_summary!.returnsCount}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('مرتجعات كاش: ${_summary!.cashReturns.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('مرتجعات آجل: ${_summary!.creditReturns.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('إجمالي المرتجعات: ${_summary!.totalReturns.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // الأرصدة والنقدية
      bytes += generator.text('النقدية المتوقعة: ${_summary!.netCashInDrawer.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('النقدية الفعلية: ${actualCash.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.text('الفارق: ${_cashDifference.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right, bold: true));
      bytes += generator.feed(1);
      bytes += generator.text('تم الإغلاق بنجاح', styles: const PosStyles(align: PosAlign.center, bold: true));
      
      bytes += generator.feed(2);
      bytes += generator.cut(); // قص الورقة

      // 3. إرسال البايتات إلى طابعة البلوتوث
      await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('خطأ في الطباعة: $e');
    }
  }

  Future<void> _confirmCloseShift() async {
    if (_summary == null) return;

    final actualCash = double.tryParse(_actualCashController.text.trim()) ?? _summary!.netCashInDrawer;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد إغلاق الوردية رقم (${_summary!.shiftNumber})'),
        content: Text(
          'سيتم طباعة تقرير الإغلاق، إغلاق الوردية الحالية، وترحيل المبيعات والمرتجعات النقدية إلى الصندوق، وبدء وردية جديدة برقم جديد وتصفير العدادات.\n\n'
          'النقدية المتوقعة بالدرج: ${_summary!.netCashInDrawer.toStringAsFixed(2)}\n'
          'النقدية الفعلية: ${actualCash.toStringAsFixed(2)}\n'
          'الفارق: ${_cashDifference.toStringAsFixed(2)}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processShiftClosureWithPrint(actualCash);
            },
            child: const Text('طباعة وإغلاق الوردية', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processShiftClosureWithPrint(double actualCash) async {
    setState(() => _isLoading = true);

    // 1. إرسال أمر الطباعة للبلوتوث أولاً
    await _printShiftReport(actualCash);

    // 2. إغلاق الوردية وتسجيل البيانات في الداتابيز
    await DBHelper.closeShift(
      shiftNumber: _summary!.shiftNumber,
      expectedCash: _summary!.netCashInDrawer,
      actualCash: actualCash,
      difference: _cashDifference,
      totalSales: _summary!.totalSales,
      totalReturns: _summary!.totalReturns,
      transferredToMainVault: actualCash, 
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت طباعة التقرير وإغلاق الوردية رقم (${_summary!.shiftNumber}) بنجاح!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _calculateShiftSummary();
    }
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
              color: color,
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
        title: Text(
          _summary != null ? 'إغلاق الوردية (رقم: ${_summary!.shiftNumber})' : 'إغلاق الصندوق / الوردية',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم الوردية الحالية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Chip(
                              backgroundColor: Theme.of(context).primaryColor,
                              label: Text(
                                '# ${_summary!.shiftNumber}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // تفاصيل المبيعات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تفاصيل المبيعات (الوردية الحالية)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
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

                      // تفاصيل المرتجعات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تفاصيل مرتجعات المبيعات (الوردية الحالية)',
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

                      // صافي النقدية المتوقعة للترحيل للصندوق
                      Card(
                        color: Colors.green.shade50,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('النقدية المتوقعة بالصندوق عند الإغلاق (مبيعات - مرتجعات كاش)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                              const Divider(),
                              _buildItemRow(
                                'الصافي القابل للترحيل للصندوق:',
                                '${_summary!.netCashInDrawer.toStringAsFixed(2)}',
                                isBold: true,
                                color: Colors.green.shade900,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: _actualCashController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _updateDifference,
                        decoration: InputDecoration(
                          labelText: 'إجمالي النقدية الفعلية بالدرج',
                          prefixIcon: Icon(Icons.point_of_sale, color: Theme.of(context).primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

                      // زر إغلاق الوردية مع الطباعة عبر البلوتوث
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text(
                            'طباعة وتأكيد إغلاق الوردية والصندوق',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
