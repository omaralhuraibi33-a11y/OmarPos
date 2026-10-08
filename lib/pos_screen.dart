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

  // دالة تحويل مقاس الخط من إعدادات الطابعة إلى PosTextSize الخاص بمكتبة الطباعة
  PosTextSize _getPosTextSize(String sizeStr) {
    switch (sizeStr) {
      case 'medium':
        return PosTextSize.size1;
      case 'large':
        return PosTextSize.size2;
      case 'huge':
        return PosTextSize.size3;
      case 'normal':
      default:
        return PosTextSize.size1;
    }
  }

  // ==========================================
  // دالة الطباعة المعدلة: تقرأ مقاس الخط من إعدادات الطابعة وتطبقه
  // ==========================================
  Future<void> _printReceiptDirect({
    required String invoiceId,
    required String paymentMethod,
    List<CartItem>? customCart,
    String? customerName,
    double? customTotal,
    bool isReturn = false,
  }) async {
    try {
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ طباعة: لا توجد أي طابعة مسجلة في "إعدادات الطابعات"!'), 
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return; 
      }

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      
      if (printers.isEmpty) return;

      final storeName = await DBHelper.getSetting('store_name') ?? 'متجري';
      final storePhone = await DBHelper.getSetting('store_phone') ?? '';
      final taxNumber = await DBHelper.getSetting('tax_number') ?? '';
      final invoiceFooter = await DBHelper.getSetting('invoice_footer') ?? 'شكرا لزيارتكم';
      final showItemCount = await DBHelper.getSetting('show_item_count') == 'true';

      final activeCart = customCart ?? _cart;
      final activeTotal = customTotal ?? _totalAmount;
      final activeCustomer = customerName ?? (_selectedCustomer?.name ?? 'عميل نقدي');

      final ScreenshotController screenshotController = ScreenshotController();
      const double receiptWidth = 384.0;

      final profile = await CapabilityProfile.load();
      bool printedSuccessfully = false;
      String lastErrorDetails = '';
      int attemptedPrintersCount = 0;

      for (var printer in printers) {
        final usage = printer['usage'] ?? 'زبون';
        final bool isAutoPrint = printer['autoPrint'] ?? true;
        
        if (!isAutoPrint) continue;
        if (usage != 'زبون' && usage != 'تقرير') continue; // تخصيص للعملاء

        attemptedPrintersCount++;
        final printerName = printer['name'] ?? 'طابعة';
        final paperSizeVal = printer['paperSize'] == '57' ? PaperSize.mm58 : PaperSize.mm80;
        
        // جلب حجم الخط المخصص لهذه الطابعة من الإعدادات
        String fontSizeSetting = printer['fontSize'] ?? 'normal';
        PosTextSize textSize = _getPosTextSize(fontSizeSetting);

        // بناء ويدجت الإيصال مع تطبيق مقاس الخط المختار
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
                  Text(storeName, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 24 : (textSize == PosTextSize.size2 ? 20 : 16), fontWeight: FontWeight.bold, color: Colors.black)),
                  if (storePhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('هاتف: $storePhone', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                  ],
                  if (taxNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('الرقم الضريبي: $taxNumber', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                  ],
                  const Text('------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black)),
                  
                  if (isReturn) ...[
                    const Text('*** سند مرتجع مبيعات ***', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 4),
                  ],

                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('رقم الفاتورة: $invoiceId', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                        Text('العميل: $activeCustomer', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                        Text('طريقة الدفع: $paymentMethod', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                        Text('التاريخ: ${DateTime.now().toString().split('.')[0]}', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, color: Colors.black)),
                      ],
                    ),
                  ),
                  const Text('------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black)),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('الصنف', textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                              Container(width: 1, height: 24, color: Colors.black),
                              Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                              Container(width: 1, height: 24, color: Colors.black),
                              Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('السعر', textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                              Container(width: 1, height: 24, color: Colors.black),
                              Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('الإجمالي', textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                            ],
                          ),
                        ),
                        ...activeCart.map((item) {
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black38, width: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(item.product.name, textAlign: TextAlign.right, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                                    Container(width: 1, color: Colors.black38),
                                    Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(_formatNum(item.quantity), textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, color: Colors.black)))),
                                    Container(width: 1, color: Colors.black38),
                                    Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(_formatNum(item.unitPrice), textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, color: Colors.black)))),
                                    Container(width: 1, color: Colors.black38),
                                    Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(_formatNum(item.total), textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 15 : 11, fontWeight: FontWeight.bold, color: Colors.black)))),
                                  ],
                                ),
                                if (item.preparationNotes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0, bottom: 2.0),
                                    child: Text('ملاحظات: ${item.preparationNotes}', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 13 : 9, fontStyle: FontStyle.italic, color: Colors.black)),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const Text('------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black)),

                  if (showItemCount) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('إجمالي عدد الأصناف: ${_formatNum(activeCart.fold(0.0, (sum, i) => sum + i.quantity))}', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    const SizedBox(height: 4),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatNum(activeTotal), style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 20 : 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('الإجمالي العام:', style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 18 : 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const Text('------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(invoiceFooter, textAlign: TextAlign.center, style: TextStyle(fontSize: textSize == PosTextSize.size3 ? 16 : 12, color: Colors.black)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );

        final pngBytes = await screenshotController.captureFromWidget(
          receiptWidget,
          delay: const Duration(milliseconds: 50),
        );

        final img.Image? rawImage = img.decodeImage(pngBytes);
        if (rawImage == null) continue;

        const int printerWidth = 384;
        final img.Image decodedImage = img.copyResize(rawImage, width: printerWidth);
        
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

        if (printer['connection'] == 'واي فاي') {
          final String ip = (printer['ip'] ?? '').trim();
          if (ip.isEmpty) continue;
          try {
            final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 4));
            socket.add(bytes);
            await socket.flush();
            await socket.close();
            printedSuccessfully = true;
          } catch (e) {
            lastErrorDetails = 'فشل الاتصال بالواي فاي ($printerName - $ip): $e';
            debugPrint(lastErrorDetails);
          }
        } else if (printer['connection'] == 'بلوتوث') {
          final String mac = (printer['macAddress'] ?? '').trim();
          if (mac.isEmpty) continue;
          try {
            bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
            if (connected) {
              await PrintBluetoothThermal.writeBytes(bytes);
              await PrintBluetoothThermal.disconnect;
              printedSuccessfully = true;
            } else {
              lastErrorDetails = 'تعذر الاتصال بطابعة البلوتوث ($printerName)';
            }
          } catch (e) {
            lastErrorDetails = 'خطأ بلوتوث ($printerName): $e';
            debugPrint(lastErrorDetails);
          }
        }
      }

      if (mounted) {
        if (attemptedPrintersCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تنبيه: تم الحفظ، ولكن جميع الطابعات المسجلة معطلة أو غير موجهة للزبائن!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (printedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الحفظ وطباعة الفاتورة بحجم الخط المختار بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشلت الطباعة. السبب: ${lastErrorDetails.isNotEmpty ? lastErrorDetails : "تأكد من تشغيل الطابعة والاتصال"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ استثنائي في الطباعة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع أثناء الطباعة: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final availableMethods = _isCashCustomer ? ['نقدي'] : _paymentMethods;

          return AlertDialog(
            title: Text(_isReturnMode ? 'إتمام مرتجع المبيعات' : 'إتمام الدفع واختيار طريقة الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي: ${_formatNum(_totalAmount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isReturnMode ? Colors.orange.shade800 : Colors.green),
                ),
                const SizedBox(height: 12),
                Text('العميل الحالي: ${_selectedCustomer?.name ?? "عميل نقدي"}'),
                if (_isCashCustomer)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('تنبيه: العميل النقدي لا يقبل سوى الدفع النقدي.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: availableMethods.contains(selectedMethod) ? selectedMethod : availableMethods.first,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'طريقة الدفع'),
                  items: availableMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedMethod = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green),
                icon: const Icon(Icons.print, color: Colors.white),
                label: Text(_isReturnMode ? 'طباعة وحفظ المرتجع' : 'طباعة وحفظ الفاتورة', style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _processCheckout(selectedMethod);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processCheckout(String paymentMethod) async {
    final cartSnapshot = List<CartItem>.from(_cart);
    final totalSnapshot = _totalAmount;
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
        if (parsedId != null && parsedId > maxReturnId) {
          maxReturnId = parsedId;
        }
      }
      final nextReturnNumber = maxReturnId + 1;
      final invoiceId = nextReturnNumber.toString();

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
        final returnItem = InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
          total: item.total,
          notes: item.preparationNotes,
        );
        await DBHelper.saveReturnInvoiceItem(returnItem);
        await DBHelper.updateProductStock(item.product.id, item.quantity);
      }

      final formattedPrintId = 'RET-${invoiceId.padLeft(6, '0')}';

      await _printReceiptDirect(
        invoiceId: formattedPrintId,
        paymentMethod: paymentMethod,
        customCart: cartSnapshot,
        customerName: customerNameSnapshot,
        customTotal: totalSnapshot,
        isReturn: true,
      );

    } else {
      final salesInvoices = await DBHelper.getAllInvoices();
      int maxSaleId = 0;
      for (var inv in salesInvoices) {
        int? parsedId = int.tryParse(inv.id);
        if (parsedId != null && parsedId > maxSaleId) {
          maxSaleId = parsedId;
        }
      }
      final nextSaleNumber = maxSaleId + 1;
      final invoiceId = nextSaleNumber.toString();

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
        final invoiceItem = InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
          total: item.total,
          notes: item.preparationNotes,
        );
        await DBHelper.saveInvoiceItem(invoiceItem);
        await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      final formattedPrintId = 'INV-${invoiceId.padLeft(6, '0')}';

      await _printReceiptDirect(
        invoiceId: formattedPrintId,
        paymentMethod: paymentMethod,
        customCart: cartSnapshot,
        customerName: customerNameSnapshot,
        customTotal: totalSnapshot,
        isReturn: false,
      );
    }

    await _loadData();
    _clearInvoice();
    if (_isReturnMode) {
      setState(() => _isReturnMode = false);
    }
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
                Container(
                  color: _isReturnMode ? Colors.orange.shade50 : Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(_isReturnMode ? Icons.assignment_return : Icons.account_circle, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
                      const SizedBox(width: 8),
                      Text('العميل: ${_selectedCustomer?.name ?? "عميل نقدي"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                        onPressed: _selectCustomerDialog,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('تغيير العميل'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (!_isInvoiceExpanded)
                        Expanded(
                          flex: _isProductsFullScreen ? 10 : 3,
                          child: Column(
                            children: [
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
                                        try {
                                          catColor = Color(int.parse(cat.colorHex));
                                        } catch (_) {}

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
                              Expanded(
                                child: _isTouchMode ? _buildTouchProductGrid() : _buildStandardProductList(),
                              ),
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
              const Text('العدد', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('الإجمالي', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(_isReturnMode ? 'إجمالي المسترجع:' : 'الإجمالي العام:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// ==========================================
// صفحة سجل الفواتير والمرتجعات (شاشة كاملة)
// ==========================================
class InvoicesHistoryPage extends StatefulWidget {
  final List<Invoice> salesInvoices;
  final List<Invoice> returnInvoices;
  final Function({
    required String invoiceId,
    required String paymentMethod,
    List<CartItem>? customCart,
    String? customerName,
    double? customTotal,
    bool isReturn,
  }) onPrintDirect;

  const InvoicesHistoryPage({
    super.key,
    required this.salesInvoices,
    required this.returnInvoices,
    required this.onPrintDirect,
  });

  @override
  State<InvoicesHistoryPage> createState() => _InvoicesHistoryPageState();
}

class _InvoicesHistoryPageState extends State<InvoicesHistoryPage> {
  late List<Invoice> _salesInvoices;
  late List<Invoice> _returnInvoices;

  String _salesSearchQuery = '';
  String _returnsSearchQuery = '';
  String _dateFilterType = 'today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _salesInvoices = widget.salesInvoices;
    _returnInvoices = widget.returnInvoices;
  }

  bool _isDateMatching(String dateStr) {
    try {
      final invDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_dateFilterType == 'today') {
        final invDay = DateTime(invDate.year, invDate.month, invDate.day);
        return invDay.isAtSameMomentAs(today);
      } else if (_dateFilterType == 'yesterday') {
        final yesterday = today.subtract(const Duration(days: 1));
        final invDay = DateTime(invDate.year, invDate.month, invDate.day);
        return invDay.isAtSameMomentAs(yesterday);
      } else if (_dateFilterType == 'week') {
        final weekAgo = today.subtract(const Duration(days: 7));
        return invDate.isAfter(weekAgo) || invDate.isAtSameMomentAs(weekAgo);
      } else if (_dateFilterType == 'month') {
        final monthAgo = today.subtract(const Duration(days: 30));
        return invDate.isAfter(monthAgo) || invDate.isAtSameMomentAs(monthAgo);
      } else if (_dateFilterType == 'year') {
        final yearAgo = today.subtract(const Duration(days: 365));
        return invDate.isAfter(yearAgo) || invDate.isAtSameMomentAs(yearAgo);
      } else if (_dateFilterType == 'custom') {
        if (_customStartDate == null || _customEndDate == null) return true;
        final start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        final end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
        return (invDate.isAfter(start) || invDate.isAtSameMomentAs(start)) &&
               (invDate.isBefore(end) || invDate.isAtSameMomentAs(end));
      }
    } catch (_) {}
    return true;
  }

  String _getDateFilterLabel() {
    switch (_dateFilterType) {
      case 'today': return 'اليوم';
      case 'yesterday': return 'أمس';
      case 'week': return 'آخر أسبوع';
      case 'month': return 'آخر شهر';
      case 'year': return 'آخر سنة';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate.toString().split(' ')[0]} إلى ${_customEndDate.toString().split(' ')[0]}';
        }
        return 'مخصص';
      default: return 'الكل';
    }
  }

  String _formatNum(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('سجل الفواتير والمرتجعات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث السجلات',
              onPressed: () async {
                final freshSales = await DBHelper.getAllInvoices();
                final freshReturns = await DBHelper.getAllReturnInvoices();
                freshSales.sort((a, b) => b.date.compareTo(a.date));
                freshReturns.sort((a, b) => b.date.compareTo(a.date));
                if (!mounted) return;
                setState(() {
                  _salesInvoices = freshSales;
                  _returnInvoices = freshReturns;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text('الفترة: ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_getDateFilterLabel(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.calendar_month, color: textColor),
                      tooltip: 'تغيير الفترة الزمنية',
                      onSelected: (val) async {
                        if (val == 'custom') {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _dateFilterType = 'custom';
                              _customStartDate = picked.start;
                              _customEndDate = picked.end;
                            });
                          }
                        } else {
                          setState(() => _dateFilterType = val);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'today', child: Text('اليوم')),
                        const PopupMenuItem(value: 'yesterday', child: Text('أمس')),
                        const PopupMenuItem(value: 'week', child: Text('خلال أسبوع')),
                        const PopupMenuItem(value: 'month', child: Text('خلال شهر')),
                        const PopupMenuItem(value: 'year', child: Text('خلال سنة')),
                        const PopupMenuItem(value: 'custom', child: Text('تحديد فترة مخصصة...')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue.shade800,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textColor,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt, size: 18),
                          SizedBox(width: 6),
                          Text('فواتير المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_return, size: 18),
                          SizedBox(width: 6),
                          Text('سجل المرتجعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _salesSearchQuery = val),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'بحث برقم فاتورة المبيعات...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2A2A3D) : Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final filteredSales = _salesInvoices.where((inv) {
                                final matchesDate = _isDateMatching(inv.date);
                                if (!matchesDate) return false;
                                if (_salesSearchQuery.isEmpty) return true;
                                return inv.id.toLowerCase().contains(_salesSearchQuery.toLowerCase());
                              }).toList();

                              if (filteredSales.isEmpty) {
                                return Center(child: Text('لا توجد مبيعات مطابقة للفترة المحددة', style: TextStyle(color: textColor)));
                              }

                              return ListView.builder(
                                itemCount: filteredSales.length,
                                itemBuilder: (context, index) {
                                  final inv = filteredSales[index];
                                  final formattedId = 'INV-${inv.id.padLeft(6, '0')}';
                                  return _buildInvoiceCardItem(context, inv, formattedId, false, isDark, textColor);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _returnsSearchQuery = val),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'بحث برقم سند المرتجع...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.orange),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2A2A3D) : Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final filteredReturns = _returnInvoices.where((inv) {
                                final matchesDate = _isDateMatching(inv.date);
                                if (!matchesDate) return false;
                                if (_returnsSearchQuery.isEmpty) return true;
                                return inv.id.toLowerCase().contains(_returnsSearchQuery.toLowerCase());
                              }).toList();

                              if (filteredReturns.isEmpty) {
                                return Center(child: Text('لا توجد مرتجعات مطابقة للفترة المحددة', style: TextStyle(color: textColor)));
                              }

                              return ListView.builder(
                                itemCount: filteredReturns.length,
                                itemBuilder: (context, index) {
                                  final inv = filteredReturns[index];
                                  final formattedId = 'RET-${inv.id.padLeft(6, '0')}';
                                  return _buildInvoiceCardItem(context, inv, formattedId, true, isDark, textColor);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCardItem(BuildContext context, Invoice inv, String formattedId, bool isReturn, bool isDark, Color textColor) {
    return InkWell(
      onTap: () async {
        final items = isReturn 
            ? await DBHelper.getReturnInvoiceItems(inv.id)
            : await DBHelper.getInvoiceItems(inv.id);
        if (!context.mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetailsPage(
              inv: inv,
              items: items,
              formattedId: formattedId,
              isReturn: isReturn,
              onPrintDirect: widget.onPrintDirect,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isReturn 
              ? (isDark ? const Color(0xFF332211) : Colors.orange.shade900)
              : (isDark ? const Color(0xFF252538) : Colors.blue.shade900),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isReturn ? Colors.orange.shade700 : Colors.blue.shade700).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isReturn ? Icons.assignment_return : Icons.receipt, color: isReturn ? Colors.orangeAccent : Colors.cyanAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(formattedId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isReturn ? Colors.orange.shade800 : Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isReturn ? 'مرتجع' : 'بيع', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 13),
                      const SizedBox(width: 4),
                      Text(inv.date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.payment, color: Colors.white54, size: 13),
                      const SizedBox(width: 4),
                      Text(inv.paymentType == 'cash' || inv.paymentType == 'نقدي' ? 'نقداً' : 'آجل', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('الإجمالي', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  _formatNum(inv.totalAmount),
                  style: TextStyle(
                    color: isReturn ? Colors.orangeAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// صفحة تفاصيل الفاتورة (شاشة كاملة مستقلة)
// ==========================================
class InvoiceDetailsPage extends StatelessWidget {
  final Invoice inv;
  final List<InvoiceItem> items;
  final String formattedId;
  final bool isReturn;
  final Function({
    required String invoiceId,
    required String paymentMethod,
    List<CartItem>? customCart,
    String? customerName,
    double? customTotal,
    bool isReturn,
  }) onPrintDirect;

  const InvoiceDetailsPage({
    super.key,
    required this.inv,
    required this.items,
    required this.formattedId,
    required this.isReturn,
    required this.onPrintDirect,
  });

  String _formatNum(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('$formattedId تفاصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة الفاتورة',
            onPressed: () async {
              final cartItems = items.map((i) => CartItem(
                product: Product(id: i.productId, name: i.productName, categoryId: '', sellPrice: i.price),
                quantity: i.quantity,
                unitPrice: i.price,
                preparationNotes: i.notes,
              )).toList();

              await onPrintDirect(
                invoiceId: formattedId,
                paymentMethod: inv.paymentType,
                customCart: cartItems,
                customerName: inv.customerName,
                customTotal: inv.totalAmount,
                isReturn: isReturn,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text('الدفع: ${inv.paymentType == 'cash' || inv.paymentType == 'نقدي' ? 'نقداً' : 'آجل'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isReturn ? Colors.orange.shade800 : Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(isReturn ? 'مرتجع معتمد' : 'بيع معتمد', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('الوقت والتاريخ: ${inv.date}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('العميل: ${inv.customerName}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            const Text('قائمة الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final itm = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(itm.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              ),
                              Text(_formatNum(itm.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isReturn ? Colors.orange : Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('السعر: ${_formatNum(itm.price)} | الكمية: ${_formatNum(itm.quantity)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                              if (itm.notes.isNotEmpty)
                                Text('ملاحظات: ${itm.notes}', style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isReturn ? Colors.orange.shade900.withOpacity(0.2) : Colors.blue.shade900.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الإجمالي العام:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  Text(
                    _formatNum(inv.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isReturn ? Colors.orangeAccent : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
