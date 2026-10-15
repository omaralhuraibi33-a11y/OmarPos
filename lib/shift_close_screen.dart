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
  final String userId;
  final String userName;
  
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
    required this.userId,
    required this.userName,
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
  final AppUser currentUser; // استقبال المستخدم الحالي للتحقق من الصلاحيات

  const ShiftCloseScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  bool _isLoading = true;
  List<ShiftSummary> _allUsersSummaries = [];
  ShiftSummary? _currentSummary;
  
  // لمدير النظام: اختيار عرض ملخص مستخدم معين أو الكل ('all' أو userId)
  String _selectedUserFilter = 'all'; 

  final TextEditingController _actualCashController = TextEditingController();
  double _cashDifference = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShiftSummaries();
  }

  Future<void> _loadShiftSummaries() async {
    setState(() => _isLoading = true);

    final int currentShiftId = await DBHelper.getCurrentShiftId();
    final allUnclosedInvoices = await DBHelper.getUnclosedInvoices();
    final allReturnInvoices = await DBHelper.getUnclosedReturnInvoices();
    final allUsers = await DBHelper.getAllUsers();

    List<ShiftSummary> summaries = [];

    // إذا كان المستخدم الحالي مديراً، نقوم بتسخين حسابات المبيعات والمرتجعات لكل كاشير/مستخدم على حدة
    if (widget.currentUser.isAdmin) {
      for (var user in allUsers) {
        // فواتير المستخدم عبر ملاحظات الفاتورة التي تحتوي على اسم المستخدم
        final userInvoices = allUnclosedInvoices.where((inv) => inv.shiftId == currentShiftId && inv.notes.contains(user.name)).toList();
        final userReturns = allReturnInvoices.where((inv) => inv.shiftId == currentShiftId && inv.notes.contains(user.name)).toList();

        if (userInvoices.isNotEmpty || userReturns.isNotEmpty || user.id == widget.currentUser.id) {
          double cashSales = userInvoices.where((i) => i.paymentType == 'cash' || i.paymentType == 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
          double creditSales = userInvoices.where((i) => i.paymentType != 'cash' && i.paymentType != 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
          double cashReturns = userReturns.where((i) => i.paymentType == 'cash' || i.paymentType == 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
          double creditReturns = userReturns.where((i) => i.paymentType != 'cash' && i.paymentType != 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);

          double netCash = cashSales - cashReturns;

          summaries.add(ShiftSummary(
            shiftNumber: currentShiftId,
            userId: user.id,
            userName: user.name,
            salesCount: userInvoices.length,
            cashSales: cashSales,
            creditSales: creditSales,
            totalSales: cashSales + creditSales,
            returnsCount: userReturns.length,
            cashReturns: cashReturns,
            creditReturns: creditReturns,
            totalReturns: cashReturns + creditReturns,
            netCashInDrawer: netCash < 0 ? 0.0 : netCash,
          ));
        }
      }
    }

    // حساب ملخص المستخدم الحالي فقط (أو إجمالي الوردية للكاشير العادي)
    final currentUserInvoices = allUnclosedInvoices.where((inv) => inv.shiftId == currentShiftId && (widget.currentUser.isAdmin || inv.notes.contains(widget.currentUser.name))).toList();
    final currentUserReturns = allReturnInvoices.where((inv) => inv.shiftId == currentShiftId && (widget.currentUser.isAdmin || inv.notes.contains(widget.currentUser.name))).toList();

    double curCashSales = currentUserInvoices.where((i) => i.paymentType == 'cash' || i.paymentType == 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
    double curCreditSales = currentUserInvoices.where((i) => i.paymentType != 'cash' && i.paymentType != 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
    double curCashReturns = currentUserReturns.where((i) => i.paymentType == 'cash' || i.paymentType == 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
    double curCreditReturns = currentUserReturns.where((i) => i.paymentType != 'cash' && i.paymentType != 'نقدي').fold(0.0, (sum, i) => sum + i.totalAmount);
    double curNetCash = curCashSales - curCashReturns;

    _currentSummary = ShiftSummary(
      shiftNumber: currentShiftId,
      userId: widget.currentUser.id,
      userName: widget.currentUser.name,
      salesCount: currentUserInvoices.length,
      cashSales: curCashSales,
      creditSales: curCreditSales,
      totalSales: curCashSales + curCreditSales,
      returnsCount: currentUserReturns.length,
      cashReturns: curCashReturns,
      creditReturns: curCreditReturns,
      totalReturns: curCashReturns + curCreditReturns,
      netCashInDrawer: curNetCash < 0 ? 0.0 : curNetCash,
    );

    setState(() {
      _allUsersSummaries = summaries;
      _actualCashController.text = _currentSummary!.netCashInDrawer.toStringAsFixed(2);
      _cashDifference = 0.0;
      _isLoading = false;
    });
  }

  void _updateDifference(String val) {
    final actual = double.tryParse(val) ?? 0.0;
    final targetNet = _selectedUserFilter == 'all' 
        ? _allUsersSummaries.fold(0.0, (sum, s) => sum + s.netCashInDrawer)
        : (_currentSummary?.netCashInDrawer ?? 0.0);

    setState(() {
      _cashDifference = actual - targetNet;
    });
  }

  String _formatNum(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  Future<void> _printShiftReportDirect(double actualCash, String targetUserName) async {
    if (_currentSummary == null) return;

    try {
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      
      final reportPrinters = printers.where((p) {
        final usage = p['usage'] ?? 'زبون';
        final bool isAutoPrint = p['autoPrint'] ?? true;
        return isAutoPrint && (usage == 'تقرير' || usage == 'زبون');
      }).toList();

      if (reportPrinters.isEmpty) return;

      final storeName = await DBHelper.getSetting('store_name') ?? 'مذاق سبأ';
      final ScreenshotController screenshotController = ScreenshotController();
      final profile = await CapabilityProfile.load();

      for (var printer in reportPrinters) {
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

        final reportWidget = Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.white,
            child: Container(
              width: receiptWidth,
              padding: EdgeInsets.all(10.0 * fontScale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(storeName, style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 4 * fontScale),
                  Text('*** تقرير إغلاق الوردية والصندوق ***', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 6 * fontScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('رقم الوردية: #${_currentSummary!.shiftNumber}', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('التاريخ: $formattedDateTime', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                    ],
                  ),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('--- تفاصيل المبيعات ---', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  SizedBox(height: 2 * fontScale),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('عدد فواتير المبيعات:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text('${_currentSummary!.salesCount}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مبيعات كاش:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.cashSales), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مبيعات آجل:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.creditSales), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('إجمالي المبيعات:', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.totalSales), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('--- تفاصيل المرتجعات ---', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  SizedBox(height: 2 * fontScale),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('عدد فواتير المرتجعات:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text('${_currentSummary!.returnsCount}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مرتجعات كاش:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.cashReturns), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('مرتجعات آجل:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.creditReturns), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('إجمالي المرتجعات:', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.totalReturns), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('النقدية المتوقعة:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                    Text(_formatNum(_currentSummary!.netCashInDrawer), style: TextStyle(fontSize: 11 * fontScale, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('النقدية الفعلية:', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(actualCash), style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('الفارق (عجز/فائض):', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(_formatNum(_cashDifference), style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  Text('------------------------------------------------------------------------', style: TextStyle(fontSize: 10 * fontScale, color: Colors.black)),
                  SizedBox(height: 4 * fontScale),
                  
                  // اسم المستخدم وطابع الطباعة في أسفل الفاتورة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المستخدم: $targetUserName', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('الطابع: $formattedDateTime', style: TextStyle(fontSize: 9 * fontScale, color: Colors.black54)),
                    ],
                  ),
                  SizedBox(height: 6 * fontScale),
                  Text('تم إغلاق الوردية والصندوق بنجاح', textAlign: TextAlign.center, style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: Colors.black)),
                  SizedBox(height: 10 * fontScale),
                ],
              ),
            ),
          ),
        );

        final pngBytes = await screenshotController.captureFromWidget(reportWidget, delay: const Duration(milliseconds: 50));
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
          final String ip = (printer['ip'] ?? '').toString().trim();
          if (ip.isNotEmpty) {
            try {
              final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 4));
              socket.add(bytes);
              await socket.flush();
              await socket.close();
            } catch (_) {}
          }
        } else if (connectionType == 'بلوتوث') {
          final String mac = (printer['macAddress'] ?? '').toString().trim();
          if (mac.isNotEmpty) {
            try {
              bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
              if (connected) {
                await PrintBluetoothThermal.writeBytes(bytes);
                await PrintBluetoothThermal.disconnect;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _confirmCloseShift() async {
    if (_currentSummary == null) return;

    final actualCash = double.tryParse(_actualCashController.text.trim()) ?? _currentSummary!.netCashInDrawer;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد إغلاق الصندوق والوردية رقم (${_currentSummary!.shiftNumber})'),
        content: Text(
          'سيتم إغلاق الوردية، طباعة التقرير، وتصفير المبيعات.\n\n'
          'المستخدم المسئول: ${widget.currentUser.name}\n'
          'النقدية الفعلية: ${actualCash.toStringAsFixed(2)}',
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processShiftClosure(actualCash);
            },
            child: const Text('تأكيد وإغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processShiftClosure(double actualCash) async {
    setState(() => _isLoading = true);

    await _printShiftReportDirect(actualCash, widget.currentUser.name);

    await DBHelper.closeShift(
      shiftNumber: _currentSummary!.shiftNumber,
      expectedCash: _currentSummary!.netCashInDrawer,
      actualCash: actualCash,
      difference: _cashDifference,
      totalSales: _currentSummary!.totalSales,
      totalReturns: _currentSummary!.totalReturns,
      transferredToMainVault: actualCash,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إغلاق الوردية بواسطة ${widget.currentUser.name} بنجاح!'), backgroundColor: Colors.green.shade700),
      );
      _loadShiftSummaries();
    }
  }

  Widget _buildItemRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isBold ? 15 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentUser.isAdmin ? 'إغلاق الصندوق (صلاحية المدير)' : 'إغلاق الصندوق (كاشير: ${widget.currentUser.name})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentSummary == null
              ? const Center(child: Text('لا توجد بيانات للوردية'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // إذا كان المستخدم مديراً، تظهر له قائمة لاختيار عرض مستخدم معين أو جميع المستخدمين
                      if (widget.currentUser.isAdmin) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('لوحة المدير: اختيار حساب المستخدم أو عرض الكل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedUserFilter,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text('جميع المستخدمين (إجمالي الصندوق)')),
                                  ..._allUsersSummaries.map((s) => DropdownMenuItem(value: s.userId, child: Text('المستخدم: ${s.userName} (مبيعات: ${_formatNum(s.totalSales)})'))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedUserFilter = val;
                                      if (val != 'all') {
                                        final found = _allUsersSummaries.firstWhere((s) => s.userId == val);
                                        // تحديث عرض الملخص للمستخدم المحدد
                                        _actualCashController.text = found.netCashInDrawer.toStringAsFixed(2);
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // كارت ملخص المبيعات بناءً على الفلتر أو المستخدم
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.currentUser.isAdmin && _selectedUserFilter == 'all' ? 'إجمالي المبيعات (لكافة المستخدمين)' : 'تفاصيل المبيعات (${widget.currentUser.name})',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                              const Divider(),
                              _buildItemRow('عدد الفواتير:', '${_currentSummary!.salesCount}'),
                              _buildItemRow('مبيعات كاش:', '${_currentSummary!.cashSales.toStringAsFixed(2)}'),
                              _buildItemRow('مبيعات آجل:', '${_currentSummary!.creditSales.toStringAsFixed(2)}', color: Colors.orange.shade800),
                              const Divider(),
                              _buildItemRow('إجمالي المبيعات:', '${_currentSummary!.totalSales.toStringAsFixed(2)}', isBold: true),
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
                              const Text('النقدية المتوقعة بالصندوق', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                              const Divider(),
                              _buildItemRow('الصافي النقدي:', '${_currentSummary!.netCashInDrawer.toStringAsFixed(2)}', isBold: true, color: Colors.green.shade900),
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
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.lock),
                          label: Text(
                            widget.currentUser.isAdmin ? 'إغلاق وترحيل الصندوق (بصفتك مدير)' : 'تأكيد إغلاق الوردية',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _confirmCloseShift,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
