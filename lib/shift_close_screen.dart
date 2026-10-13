import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'db_helper.dart';

class ShiftSummary {
  final int shiftNumber;
  final int salesCount;
  final double cashSales;
  final double creditSales;
  final double totalSales;
  final int returnsCount;
  final double cashReturns;
  final double creditReturns;
  final double totalReturns;
  final double netCashInDrawer;

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

  String _formatNum(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  Future<void> _printShiftReportDirect(double actualCash) async {
    if (_summary == null) return;

    try {
      final savedPrinters = await DBHelper.getSavedPrinters();
      if (savedPrinters.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ طباعة: لا توجد أي طابعة مسجلة في الإعدادات!'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final storeName = await DBHelper.getSetting('store_name') ?? 'مذاق سبأ';
      final ScreenshotController screenshotController = ScreenshotController();
      final profile = await CapabilityProfile.load();

      for (var printer in savedPrinters) {
        final usage = printer['usage'] ?? 'زبون';
        final bool isAutoPrint = printer['autoPrint'] ?? true;
        if (!isAutoPrint) continue;
        if (usage != 'زبون' && usage != 'تقرير') continue;

        final String paperSizeStr = printer['paperSize'] ?? '80';
        final paperSizeVal = paperSizeStr == '57' ? PaperSize.mm58 : PaperSize.mm80;
        final double receiptWidth = paperSizeStr == '57' ? 384.0 : 576.0;
        final int targetImageWidth = paperSizeStr == '57' ? 384 : 576;

        String fontSizeSetting = printer['fontSize'] ?? 'normal';
        double fontScale = 1.0;
        switch (fontSizeSetting) {
          case 'medium': fontScale = 1.25; break;
          case 'large': fontScale = 1.5; break;
          case 'huge': fontScale = 2.0; break;
          case 'normal': default: fontScale = 1.0; break;
        }

        final now = DateTime.now();
        final formattedDateTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        final shiftReportWidget = Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.white,
            child: Container(
              width: receiptWidth,
              padding: EdgeInsets.all(12.0 * fontScale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(storeName, style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 4 * fontScale),
                  Text('*** تقرير إغلاق الوردية والصندوق ***', style: TextStyle(fontSize: 14 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 6 * fontScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('رقم الوردية: #${_summary!.shiftNumber}', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('التاريخ: $formattedDateTime', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                    ],
                  ),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('--- تفاصيل المبيعات ---', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  SizedBox(height: 2 * fontScale),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('عدد الفواتير:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text('${_summary!.salesCount}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مبيعات كاش:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_summary!.cashSales), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مبيعات آجل:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_summary!.creditSales), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('إجمالي المبيعات:', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_summary!.totalSales), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('--- تفاصيل المرتجعات ---', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  SizedBox(height: 2 * fontScale),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('عدد المرتجعات:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text('${_summary!.returnsCount}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مرتجعات كاش:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_summary!.cashReturns), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مرتجعات آجل:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_summary!.creditReturns), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('إجمالي المرتجعات:', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_summary!.totalReturns), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('النقدية المتوقعة:', style: TextStyle(fontSize: 12 * fontScale, color: Colors.black)),
                    Text(_formatNum(_summary!.netCashInDrawer), style: TextStyle(fontSize: 12 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('النقدية الفعلية:', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(actualCash), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('الفارق (عجز/فائض):', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_cashDifference), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                  SizedBox(height: 4 * fontScale),
                  Text('تم إغلاق الوردية والصندوق بنجاح', textAlign: TextAlign.center, style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 10 * fontScale),
                ],
              ),
            ),
          ),
        );

        final pngBytes = await screenshotController.captureFromWidget(shiftReportWidget, delay: const Duration(milliseconds: 50));
        final img.Image? rawImage = img.decodeImage(pngBytes);
        if (rawImage == null) continue;

        final img.Image decodedImage = img.copyResize(rawImage, width: targetImageWidth);
        for (int y = 0; y < decodedImage.height; y++) {
          for (int x = 0; x < decodedImage.width; x++) {
            final pixel = decodedImage.getPixel(x, y);
            final luminance = img.getLuminance(pixel);
            if (luminance > 160) {
              decodedImage.setPixelRgba(x, y, 255, 255, 255, 255);
            } else {
              decodedImage.setPixelRgba(x, y, 0, 0, 0, 255);
            }
          }
        }

        final generator = Generator(paperSizeVal, profile);
        List<int> bytes = [];
        bytes += generator.image(decodedImage);
        bytes += generator.feed(2);
        bytes += generator.cut();

        final String connectionType = (printer['connection'] ?? 'بلوتوث').toString();

        if (connectionType == 'واي فاي') {
          final String ip = (printer['ip'] ?? printer['ipAddress'] ?? '').toString().trim();
          if (ip.isNotEmpty) {
            try {
              final socket = await PrintBluetoothThermal.writeBytes(bytes);
            } catch (e) {
              debugPrint('فشل طباعة تقرير الإغلاق عبر الواي فاي: $e');
            }
          }
        } else if (connectionType == 'بلوتوث') {
          final String mac = (printer['macAddress'] ?? printer['address'] ?? '').toString().trim();
          if (mac.isNotEmpty) {
            try {
              bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
              if (connected) {
                await PrintBluetoothThermal.writeBytes(bytes);
                await PrintBluetoothThermal.disconnect;
              }
            } catch (e) {
              debugPrint('فشل طباعة تقرير الإغلاق عبر البلوتوث: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ استثنائي في طباعة تقرير الإغلاق: $e');
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

    await _printShiftReportDirect(actualCash);

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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isBold ? 14 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 14 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
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
