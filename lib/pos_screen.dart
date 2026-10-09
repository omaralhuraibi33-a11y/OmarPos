import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'db_helper.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;
  String preparationNotes;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.preparationNotes = '',
  });

  double get total => quantity * unitPrice;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  bool _isTouchMode = true;
  bool _isInvoiceExpanded = false;
  bool _isProductsFullScreen = false;
  bool _isReturnMode = false;
  bool _isHeaderExpanded = true; // للتحكم برفع وتنزيل رأس الشاشة

  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  List<String> _prepNotesList = [];
  List<String> _paymentMethods = [];

  Customer? _selectedCustomer;
  String _selectedCategoryId = 'all';
  final TextEditingController _searchController = TextEditingController();

  List<CartItem> _cart = [];
  bool _isLoading = true;

  String _mainButtonSizeSetting = 'وسط';
  String _posItemSizeSetting = 'وسط';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await DBHelper.getActivePOSCategories();
    final prods = await DBHelper.getActivePOSProducts();
    final custs = await DBHelper.getAllCustomers();
    final notes = await DBHelper.getPreparationNotes();
    final dbPaymentMethods = await DBHelper.getPaymentMethods();
    final defaultCust = await DBHelper.getOrCreateDefaultCustomer();

    final savedMainBtnSize = await DBHelper.getSetting('main_button_size');
    final savedPosItemSize = await DBHelper.getSetting('pos_item_size');

    if (!custs.any((c) => c.id == defaultCust.id)) {
      custs.insert(0, defaultCust);
    }

    if (!mounted) return;
    setState(() {
      _categories = cats;
      _allProducts = prods;
      _filteredProducts = prods;
      _customers = custs;
      _selectedCustomer = custs.firstWhere((c) => c.id == defaultCust.id, orElse: () => defaultCust);
      _prepNotesList = notes.isNotEmpty ? notes : ['بدون شطة', 'زيادة صوص', 'بدون ثوم', 'سفري', 'محلي'];
      _paymentMethods = dbPaymentMethods.isNotEmpty ? dbPaymentMethods : ['نقدي', 'آجل'];
      if (savedMainBtnSize != null) _mainButtonSizeSetting = savedMainBtnSize;
      if (savedPosItemSize != null) _posItemSizeSetting = savedPosItemSize;
      _isLoading = false;
    });
  }

  Future<void> _printReceiptDirect({
    required String invoiceId,
    required String paymentMethod,
    List<CartItem>? customCart,
    String? customerName,
    double? customTotal,
    double discountAmount = 0.0,
    bool isReturn = false,
  }) async {
    try {
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      if (printers.isEmpty) return;

      final storeName = await DBHelper.getSetting('store_name') ?? 'omarsoft';
      final storePhone = await DBHelper.getSetting('store_phone') ?? '771987636';
      final storeAddress = await DBHelper.getSetting('store_address') ?? '';
      final invoiceFooter = await DBHelper.getSetting('invoice_footer') ?? 'شكراً لزيارتكم!';
      final storeImagePath = await DBHelper.getSetting('store_image_path') ?? '';
      final showItemCount = await DBHelper.getSetting('show_item_count') == 'true';

      final activeCart = customCart ?? _cart;
      final activeSubTotal = customTotal ?? _totalAmount;
      final activeDiscount = discountAmount;
      final activeNetTotal = (activeSubTotal - activeDiscount) < 0 ? 0.0 : (activeSubTotal - activeDiscount);
      final activeCustomer = customerName ?? (_selectedCustomer?.name ?? 'عميل نقدي');

      final ScreenshotController screenshotController = ScreenshotController();
      final profile = await CapabilityProfile.load();

      for (var printer in printers) {
        final usage = printer['usage'] ?? 'زبون';
        final bool isAutoPrint = printer['autoPrint'] ?? true;
        if (!isAutoPrint || (usage != 'زبون' && usage != 'تقرير')) continue;

        final String paperSizeStr = printer['paperSize'] ?? '80';
        final paperSizeVal = paperSizeStr == '57' ? PaperSize.mm58 : PaperSize.mm80;
        final double receiptWidth = paperSizeStr == '57' ? 384.0 : 576.0;
        final int targetImageWidth = paperSizeStr == '57' ? 384 : 576;

        final receiptWidget = Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.white,
            child: Container(
              width: receiptWidth,
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(storeAddress, style: const TextStyle(fontSize: 10)),
                  Text('هاتف: $storePhone', style: const TextStyle(fontSize: 10)),
                  const Text('------------------------------------------------------------------------'),
                  Text('رقم الفاتورة: $invoiceId | الدفع: $paymentMethod'),
                  Text('العميل: $activeCustomer'),
                  const Text('------------------------------------------------------------------------'),
                  Text('الإجمالي: ${_formatNum(activeSubTotal)} | الخصم: ${_formatNum(activeDiscount)}'),
                  Text('الصافي: ${_formatNum(activeNetTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('------------------------------------------------------------------------'),
                  Text(invoiceFooter, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );

        final pngBytes = await screenshotController.captureFromWidget(receiptWidget, delay: const Duration(milliseconds: 50));
        final img.Image? rawImage = img.decodeImage(pngBytes);
        if (rawImage == null) continue;

        final img.Image decodedImage = img.copyResize(rawImage, width: targetImageWidth);
        for (int y = 0; y < decodedImage.height; y++) {
          for (int x = 0; x < decodedImage.width; x++) {
            final pixel = decodedImage.getPixel(x, y);
            if (img.getLuminance(pixel) > 160) {
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

        if (printer['connection'] == 'واي فاي') {
          final String ip = (printer['ip'] ?? '').trim();
          if (ip.isNotEmpty) {
            try {
              final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 3));
              socket.add(bytes);
              await socket.flush();
              await socket.close();
            } catch (_) {}
          }
        } else if (printer['connection'] == 'بلوتوث') {
          final String mac = (printer['macAddress'] ?? '').trim();
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

  void _openInvoicesHistoryPage() async {
    final salesInvoices = await DBHelper.getAllInvoices();
    final returnInvoices = await DBHelper.getAllReturnInvoices();
    salesInvoices.sort((a, b) => b.date.compareTo(a.date));
    returnInvoices.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicesHistoryPage(
          salesInvoices: salesInvoices,
          returnInvoices: returnInvoices,
          onPrintDirect: _printReceiptDirect,
        ),
      ),
    );
  }

  int _getGridCrossAxisCount() {
    if (_isProductsFullScreen) {
      switch (_posItemSizeSetting) {
        case 'صغير': return 6;
        case 'كبير': return 4;
        case 'وسط': default: return 5;
      }
    } else {
      switch (_posItemSizeSetting) {
        case 'صغير': return 4;
        case 'كبير': return 2;
        case 'وسط': default: return 3;
      }
    }
  }

  double _getItemFontSize() {
    switch (_posItemSizeSetting) {
      case 'صغير': return 12.0;
      case 'كبير': return 16.0;
      case 'وسط': default: return 14.0;
    }
  }

  double _getBottomButtonHeight() {
    switch (_mainButtonSizeSetting) {
      case 'صغير': return 40.0;
      case 'كبير': return 56.0;
      case 'وسط': default: return 48.0;
    }
  }

  double _getBottomButtonFontSize() {
    switch (_mainButtonSizeSetting) {
      case 'صغير': return 13.0;
      case 'كبير': return 18.0;
      case 'وسط': default: return 15.0;
    }
  }

  bool get _isCashCustomer =>
      _selectedCustomer == null ||
      _selectedCustomer!.id == 'cash_default' ||
      _selectedCustomer!.name == 'عميل نقدي';

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesQuery = p.name.contains(query);
        final matchesCat = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
        return matchesQuery && matchesCat;
      }).toList();
    });
  }

  void _filterByCategory(String catId) {
    setState(() {
      _selectedCategoryId = catId;
      _filterProducts(_searchController.text);
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _cart[index].quantity += 1;
      } else {
        _cart.add(CartItem(product: product, unitPrice: product.sellPrice));
      }
    });
  }

  void _clearInvoice() {
    setState(() {
      _cart.clear();
      _selectedCustomer = _customers.firstWhere(
        (c) => c.id == 'cash_default',
        orElse: () => Customer(id: 'cash_default', name: 'عميل نقدي', phone: '', address: '', balance: 0.0),
      );
    });
  }

  double get _totalAmount => _cart.fold(0.0, (sum, item) => sum + item.total);

  String _formatNum(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  void _selectCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختيار العميل'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final c = _customers[index];
              final isCash = c.id == 'cash_default';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCash ? Colors.amber.shade100 : Colors.blue.shade100,
                  child: Icon(isCash ? Icons.point_of_sale : Icons.person, color: isCash ? Colors.orange.shade900 : Colors.blue),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isCash ? 'عميل نقدي افتراضي' : 'هاتف: ${c.phone} | الرصيد: ${_formatNum(c.balance)}'),
                onTap: () {
                  setState(() => _selectedCustomer = c);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPrepNotesDialog(CartItem item) {
    final customNoteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text('ملاحظات تحضير: ${item.product.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _prepNotesList.map((note) {
                      final isSelected = item.preparationNotes.contains(note);
                      return FilterChip(
                        label: Text(note, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: Colors.deepOrange,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              item.preparationNotes = item.preparationNotes.isEmpty ? note : '${item.preparationNotes} - $note';
                            } else {
                              item.preparationNotes = item.preparationNotes.replaceAll(note, '').replaceAll(' -  - ', ' - ').trim();
                            }
                          });
                          setDlgState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  TextField(
                    controller: customNoteCtrl,
                    decoration: const InputDecoration(labelText: 'إضافة ملاحظة جديدة', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (customNoteCtrl.text.trim().isNotEmpty) {
                    final newNote = customNoteCtrl.text.trim();
                    if (!_prepNotesList.contains(newNote)) {
                      await DBHelper.addPreparationNote(newNote);
                      _prepNotesList.add(newNote);
                    }
                    setState(() {
                      item.preparationNotes = item.preparationNotes.isEmpty ? newNote : '${item.preparationNotes} - $newNote';
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('حفظ الملاحظة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentDialog() {
    String selectedMethod = _isCashCustomer ? 'نقدي' : (_paymentMethods.isNotEmpty ? _paymentMethods.first : 'نقدي');
    final TextEditingController discountController = TextEditingController(text: '0');
    final TextEditingController paidController = TextEditingController(text: _formatNum(_totalAmount));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final availableMethods = _isCashCustomer ? ['نقدي'] : _paymentMethods;
          
          double total = _totalAmount;
          double discount = double.tryParse(discountController.text) ?? 0.0;
          double netTotal = total - discount;
          if (netTotal < 0) netTotal = 0;

          double paidAmount = double.tryParse(paidController.text) ?? 0.0;
          double change = paidAmount - netTotal;
          if (change < 0) change = 0;

          return AlertDialog(
            title: Text(_isReturnMode ? 'إتمام مرتجع المبيعات' : 'إتمام الدفع واختيار طريقة الدفع'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المبلغ الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_formatNum(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'مبلغ الخصم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money_off),
                    ),
                    onChanged: (val) {
                      setDlgState(() {
                        double newDiscount = double.tryParse(val) ?? 0.0;
                        double newNet = total - newDiscount;
                        if (newNet < 0) newNet = 0;
                        paidController.text = _formatNum(newNet);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                        Text(_formatNum(netTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isReturnMode ? Colors.orange.shade800 : Colors.green.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: availableMethods.contains(selectedMethod) ? selectedMethod : availableMethods.first,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'طريقة الدفع'),
                    items: availableMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedMethod = val);
                    },
                  ),
                  if (selectedMethod == 'نقدي') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'المبلغ المدفوع', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)),
                      onChanged: (val) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade300), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الباقي للعميل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(_formatNum(change), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green),
                icon: const Icon(Icons.print, color: Colors.white),
                label: Text(_isReturnMode ? 'طباعة وحفظ المرتجع' : 'طباعة وحفظ الفاتورة', style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _processCheckout(selectedMethod, netTotal, discount);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processCheckout(String paymentMethod, double finalAmount, double discountAmount) async {
    final cartSnapshot = List<CartItem>.from(_cart);
    final totalSnapshot = finalAmount;
    final customerNameSnapshot = _selectedCustomer?.name ?? 'عميل نقدي';
    final now = DateTime.now().toString().split('.')[0];
    final shiftId = await DBHelper.getCurrentShiftId();
    final customerId = _selectedCustomer?.id ?? 'cash_default';
    final isCredit = paymentMethod == 'آجل' || paymentMethod == 'أجل';

    if (_isReturnMode) {
      final returnInvoices = await DBHelper.getAllReturnInvoices();
      int maxReturnId = 0;
      for (var inv in returnInvoices) {
        int? parsedId = int.tryParse(inv.id);
        if (parsedId != null && parsedId > maxReturnId) maxReturnId = parsedId;
      }
      final invoiceId = (maxReturnId + 1).toString();

      final returnInvoice = Invoice(
        id: invoiceId,
        invoiceType: 'return',
        paymentType: isCredit ? 'credit' : 'cash',
        totalAmount: totalSnapshot,
        date: now,
        customerId: customerId,
        customerName: customerNameSnapshot,
        shiftId: shiftId,
        isClosed: false,
      );
      await DBHelper.saveReturnInvoice(returnInvoice);

      for (var item in cartSnapshot) {
        await DBHelper.saveReturnInvoiceItem(InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
          total: item.total,
          notes: item.preparationNotes,
        ));
        await DBHelper.updateProductStock(item.product.id, item.quantity);
      }

      await _printReceiptDirect(
        invoiceId: 'RET-${invoiceId.padLeft(6, '0')}',
        paymentMethod: paymentMethod,
        customCart: cartSnapshot,
        customerName: customerNameSnapshot,
        customTotal: _totalAmount,
        discountAmount: discountAmount,
        isReturn: true,
      );
    } else {
      final salesInvoices = await DBHelper.getAllInvoices();
      int maxSaleId = 0;
      for (var inv in salesInvoices) {
        int? parsedId = int.tryParse(inv.id);
        if (parsedId != null && parsedId > maxSaleId) maxSaleId = parsedId;
      }
      final invoiceId = (maxSaleId + 1).toString();

      final saleInvoice = Invoice(
        id: invoiceId,
        invoiceType: 'sale',
        paymentType: isCredit ? 'credit' : 'cash',
        totalAmount: totalSnapshot,
        date: now,
        customerId: customerId,
        customerName: customerNameSnapshot,
        shiftId: shiftId,
        isClosed: false,
      );
      await DBHelper.saveInvoice(saleInvoice);

      for (var item in cartSnapshot) {
        await DBHelper.saveInvoiceItem(InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
          total: item.total,
          notes: item.preparationNotes,
        ));
        await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      await _printReceiptDirect(
        invoiceId: 'INV-${invoiceId.padLeft(6, '0')}',
        paymentMethod: paymentMethod,
        customCart: cartSnapshot,
        customerName: customerNameSnapshot,
        customTotal: _totalAmount,
        discountAmount: discountAmount,
        isReturn: false,
      );
    }

    await _loadData();
    _clearInvoice();
    if (_isReturnMode) setState(() => _isReturnMode = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isReturnMode ? Colors.orange.shade800 : null,
        title: Row(
          children: [
            if (!_isReturnMode)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isTouchMode ? 'مبيعات لمس' : 'مبيعات عادية', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Switch(value: _isTouchMode, onChanged: (val) => setState(() => _isTouchMode = val), activeColor: Colors.amber),
                ],
              )
            else
              const Text('مرتجع مبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // زر طي/فرد رأس الشاشة لتوفير المساحة
          IconButton(
            tooltip: _isHeaderExpanded ? 'طي الشريط العلوي' : 'إظهار الشريط العلوي',
            icon: Icon(_isHeaderExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onPressed: () => setState(() => _isHeaderExpanded = !_isHeaderExpanded),
          ),
          IconButton(
            tooltip: 'سجل الفواتير والمرتجعات',
            icon: const Icon(Icons.receipt_long, color: Colors.amberAccent),
            onPressed: _openInvoicesHistoryPage,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: Icon(_isReturnMode ? Icons.shopping_cart : Icons.assignment_return, color: Colors.amber),
              label: Text(_isReturnMode ? 'وضع البيع' : 'مرتجع', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                setState(() {
                  _isReturnMode = !_isReturnMode;
                  _clearInvoice();
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // الشريط العلوي القابل للطي والتنزيل (العميل ومعلومات المبيعات)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _isHeaderExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Container(
                    color: _isReturnMode ? Colors.orange.shade50 : Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(_isReturnMode ? Icons.assignment_return : Icons.account_circle, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'العميل: ${_selectedCustomer?.name ?? "عميل نقدي"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: _selectCustomerDialog,
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('تغيير العميل'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (!_isInvoiceExpanded)
                        Expanded(
                          flex: _isProductsFullScreen ? 10 : 3,
                          child: Column(
                            children: [
                              // مربع البحث يظهر فقط عندما لا يكون في وضع اللمس (أي نوع المبيعات عادية)
                              if (!_isTouchMode)
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: _filterProducts,
                                          decoration: InputDecoration(
                                            hintText: 'بحث باسم الصنف أو الباركود...',
                                            prefixIcon: const Icon(Icons.search),
                                            contentPadding: const EdgeInsets.all(8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(_isProductsFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.indigo),
                                        onPressed: () => setState(() => _isProductsFullScreen = !_isProductsFullScreen),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isTouchMode)
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4.0),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _selectedCategoryId == 'all' ? Colors.blue.shade900 : Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => _filterByCategory('all'),
                                          child: const Text('الكل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                      ..._categories.map((cat) {
                                        Color catColor = Colors.teal;
                                        try { catColor = Color(int.parse(cat.colorHex)); } catch (_) {}
                                        final isSelected = _selectedCategoryId == cat.id;

                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4.0),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: isSelected ? catColor.withOpacity(0.8) : catColor),
                                            onPressed: () => _filterByCategory(cat.id),
                                            child: Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              Expanded(child: _isTouchMode ? _buildTouchProductGrid() : _buildStandardProductList()),
                            ],
                          ),
                        ),
                      if (!_isProductsFullScreen)
                        InkWell(
                          onTap: () => setState(() => _isInvoiceExpanded = !_isInvoiceExpanded),
                          child: Container(
                            width: 24,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Icon(_isInvoiceExpanded ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 16),
                            ),
                          ),
                        ),
                      if (!_isProductsFullScreen)
                        Expanded(
                          flex: _isInvoiceExpanded ? 1 : 2,
                          child: Container(color: Colors.grey.shade100, child: _buildInvoicePanel()),
                        ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildTouchProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCrossAxisCount(),
        childAspectRatio: 1.1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, index) {
        final prod = _filteredProducts[index];
        Color cardColor = _isReturnMode ? Colors.deepOrange.shade700 : Colors.blue.shade700;
        final itemFontSize = _getItemFontSize();

        return InkWell(
          onTap: () => _addToCart(prod),
          child: Card(
            elevation: 3,
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prod.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: itemFontSize, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                    child: Text(_formatNum(prod.sellPrice), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: itemFontSize - 1)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandardProductList() {
    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, index) {
        final prod = _filteredProducts[index];
        return ListTile(
          title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('السعر: ${_formatNum(prod.sellPrice)} | الكمية: ${_formatNum(prod.quantity)}'),
          trailing: IconButton(
            icon: Icon(_isReturnMode ? Icons.remove_shopping_cart : Icons.add_shopping_cart, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
            onPressed: () => _addToCart(prod),
          ),
        );
      },
    );
  }

  Widget _buildInvoicePanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: _isReturnMode ? Colors.orange.shade200 : Colors.blueGrey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isReturnMode ? 'الصنف المراد إرجاعه' : 'الصنف / الملاحظات', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('العدد', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(child: Text(_isReturnMode ? 'قائمة المرتجع فارغة' : 'الفاتورة فارغة'))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (ctx, index) {
                    final item = _cart[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (item.quantity > 1) {
                                            item.quantity--;
                                          } else {
                                            _cart.removeAt(index);
                                          }
                                        });
                                      },
                                      child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(_formatNum(item.quantity)),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => item.quantity++),
                                      child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text(_formatNum(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (!_isReturnMode)
                              InkWell(
                                onTap: () => _showPrepNotesDialog(item),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.note_alt_outlined, size: 14, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.preparationNotes.isEmpty ? '+ ملاحظات تحضير' : item.preparationNotes,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: item.preparationNotes.isEmpty ? Colors.grey : Colors.deepOrange,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isReturnMode ? 'إجمالي المسترجع:' : 'الإجمالي:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _formatNum(_totalAmount),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final btnHeight = _getBottomButtonHeight();
    final btnFontSize = _getBottomButtonFontSize();

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: btnHeight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                icon: const Icon(Icons.cleaning_services, color: Colors.white, size: 20),
                label: Text('تعليق', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                onPressed: _clearInvoice,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: btnHeight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                label: Text('إلغاء', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                onPressed: _clearInvoice,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: btnHeight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green.shade700),
                icon: Icon(_isReturnMode ? Icons.assignment_return : Icons.payment, color: Colors.white, size: 22),
                label: Text(_isReturnMode ? 'إتمام المرتجع' : 'دفع وطباعة', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                onPressed: _cart.isEmpty ? null : _showPaymentDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// كلاسات سجل الفواتير وتفاصيل الفاتورة تبقى كما هي بدون تغيير...
class InvoicesHistoryPage extends StatelessWidget {
  final List<Invoice> salesInvoices;
  final List<Invoice> returnInvoices;
  final Function onPrintDirect;
  const InvoicesHistoryPage({super.key, required this.salesInvoices, required this.returnInvoices, required this.onPrintDirect});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الفواتير')),
      body: const Center(child: Text('سجل الفواتير')),
    );
  }
}
