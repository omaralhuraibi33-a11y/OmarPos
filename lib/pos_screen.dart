import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
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
  const PosScreen({Key? key}) : super(Key: key);
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  bool _isTouchMode = true;
  bool _isPrinterConnected = true;
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

  // إعدادات أحجام العرض
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

    // جلب إعدادات الأحجام المحفوظة
    final savedMainBtnSize = await DBHelper.getSetting('main_button_size');
    final savedPosItemSize = await DBHelper.getSetting('pos_item_size');

    if (!custs.any((c) => c.id == defaultCust.id)) {
      custs.insert(0, defaultCust);
    }

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

  // دالة الطباعة الموحدة المربوطة بإعدادات الطابعات المحفوظة
  Future<void> _printReceipt({
    required String invoiceId,
    required String paymentMethod,
    required String type, // 'زبون' أو 'مطبخ'
  }) async {
    final savedPrintersJson = await DBHelper.getSetting('printers_list');
    final autoKitchen = await DBHelper.getSetting('auto_kitchen') == 'true';
    final autoCustomer = await DBHelper.getSetting('auto_customer') == 'true';

    // التثبت من تفعيل الطباعة التلقائية حسب النوع
    if (type == 'مطبخ' && !autoKitchen) return;
    if (type == 'زبون' && !autoCustomer) return;

    if (savedPrintersJson == null || savedPrintersJson.isEmpty) return;

    final List<dynamic> decoded = jsonDecode(savedPrintersJson);
    final printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    // تصفية الطابعات المخصصة لهذا الاستخدام
    final targetPrinters = printers.where((p) => p['usage'] == type).toList();

    for (var printer in targetPrinters) {
      try {
        final profile = await CapabilityProfile.load();
        final generator = Generator(
          printer['paperSize'] == '57' ? PaperSize.mm58 : PaperSize.mm80,
          profile,
        );

        List<int> bytes = [];
        bytes += generator.text(
          _isReturnMode ? 'مرتجع مبيعات' : 'فاتورة مبيعات',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
        );
        bytes += generator.text('نوع الطباعة: $type', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text('رقم الفاتورة: $invoiceId', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text('العميل: ${_selectedCustomer?.name ?? "عميل نقدي"}', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text('طريقة الدفع: $paymentMethod', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

        for (var item in _cart) {
          bytes += generator.row([
            PosColumn(text: item.product.name, width: 6),
            PosColumn(text: _formatNum(item.quantity), width: 2),
            PosColumn(text: _formatNum(item.total), width: 4),
          ]);
          if (item.preparationNotes.isNotEmpty) {
            bytes += generator.text('  ملاحظة: ${item.preparationNotes}', styles: const PosStyles(align: PosAlign.left));
          }
        }

        bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text(
          'الإجمالي: ${_formatNum(_totalAmount)}',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size1),
        );
        bytes += generator.feed(2);
        bytes += generator.cut();

        // إرسال البيانات حسب طريقة الاتصال
        if (printer['connection'] == 'واي فاي') {
          final String ip = (printer['ip'] ?? '').trim();
          if (ip.isNotEmpty) {
            final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 4));
            socket.add(bytes);
            await socket.flush();
            await socket.close();
          }
        } else {
          final String mac = (printer['macAddress'] ?? '').trim();
          if (mac.isNotEmpty) {
            bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
            if (connected) {
              await PrintBluetoothThermal.writeBytes(bytes);
              await PrintBluetoothThermal.disconnect;
            }
          }
        }
      } catch (e) {
        debugPrint('خطأ في الطباعة ($type): $e');
      }
    }
  }

  // حساب أبعاد كروت أصناف الـ POS بحسب الإعداد المحفوظ
  int _getGridCrossAxisCount() {
    if (_isProductsFullScreen) {
      switch (_posItemSizeSetting) {
        case 'صغير':
          return 6;
        case 'كبير':
          return 4;
        case 'وسط':
        default:
          return 5;
      }
    } else {
      switch (_posItemSizeSetting) {
        case 'صغير':
          return 4;
        case 'كبير':
          return 2;
        case 'وسط':
        default:
          return 3;
      }
    }
  }

  double _getItemFontSize() {
    switch (_posItemSizeSetting) {
      case 'صغير':
        return 12.0;
      case 'كبير':
        return 16.0;
      case 'وسط':
      default:
        return 14.0;
    }
  }

  // حساب ارتفاع وبادنج أزرار أسفل الشاشة الرئيسية بحسب الإعداد المحفوظ
  double _getBottomButtonHeight() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 40.0;
      case 'كبير':
        return 56.0;
      case 'وسط':
      default:
        return 48.0;
    }
  }

  double _getBottomButtonFontSize() {
    switch (_mainButtonSizeSetting) {
      case 'صغير':
        return 13.0;
      case 'كبير':
        return 18.0;
      case 'وسط':
      default:
        return 15.0;
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
                  setState(() {
                    _selectedCustomer = c;
                  });
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
                    decoration: const InputDecoration(
                      labelText: 'إضافة ملاحظة جديدة',
                      border: OutlineInputBorder(),
                    ),
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
                  Navigator.pop(ctx);
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
            title: Text(_isReturnMode ? 'إتمام مرتجع المبيعات' : 'إتمام الدفع وااختيار طريقة الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي: ${_formatNum(_totalAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _isReturnMode ? Colors.orange.shade800 : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text('العميل الحالي: ${_selectedCustomer?.name ?? "عميل نقدي"}'),
                if (_isCashCustomer)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      'تنبيه: العميل النقدي لا يقبل سوى الدفع النقدي.',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green,
                ),
                icon: const Icon(Icons.print, color: Colors.white),
                label: Text(
                  _isReturnMode ? 'حفظ وطباعة المرتجع' : 'حفظ وطباعة الفاتورة',
                  style: const TextStyle(color: Colors.white),
                ),
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
    final now = DateTime.now().toString().split('.')[0];
    final shiftId = await DBHelper.getCurrentShiftId();
    final customerId = _selectedCustomer?.id ?? 'cash_default';
    final isCredit = paymentMethod == 'آجل' || paymentMethod == 'أجل';
    final invoiceType = _isReturnMode ? 'return' : 'sale';
    final invoiceId = DateTime.now().millisecondsSinceEpoch.toString();

    final invoice = Invoice(
      id: invoiceId,
      invoiceType: invoiceType,
      paymentType: isCredit ? 'credit' : 'cash',
      totalAmount: _totalAmount,
      date: now,
      customerId: customerId,
      customerName: _selectedCustomer?.name ?? 'عميل نقدي',
      shiftId: shiftId,
      isClosed: false,
    );

    await DBHelper.saveInvoice(invoice);

    for (var item in _cart) {
      double stockDelta = _isReturnMode ? item.quantity : -item.quantity;
      await DBHelper.updateProductStock(item.product.id, stockDelta);
    }

    final actionName = _isReturnMode ? 'مرتجع المبيعات' : 'الفاتورة';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ $actionName بنجاح ($paymentMethod)'),
          backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green,
        ),
      );
    }

    // التنفيذ الفلي للطباعة في حال كانت الطابعة مفعلة
    if (_isPrinterConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جاري إرسال $actionName للطابعة الحرارية...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // إرسال الأمر للطباعة (نسخة الزبون ونسخة المطبخ)
      await _printReceipt(invoiceId: invoiceId, paymentMethod: paymentMethod, type: 'زبون');
      await _printReceipt(invoiceId: invoiceId, paymentMethod: paymentMethod, type: 'مطبخ');
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
                  Text(
                    _isTouchMode ? 'مبيعات لمس' : 'مبيعات عادية',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isTouchMode,
                    onChanged: (val) => setState(() => _isTouchMode = val),
                    activeColor: Colors.amber,
                  ),
                ],
              )
            else
              const Text('مرتجع مبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isPrinterConnected ? 'الطابعة متصلة' : 'الطابعة مفصولة',
            icon: Icon(
              Icons.print,
              color: _isPrinterConnected ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              setState(() => _isPrinterConnected = !_isPrinterConnected);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(_isReturnMode ? Icons.shopping_cart : Icons.assignment_return, color: Colors.amber),
              label: Text(
                _isReturnMode ? 'وضع البيع' : 'مرتجع',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
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
                      Icon(
                        _isReturnMode ? Icons.assignment_return : Icons.account_circle,
                        color: _isReturnMode ? Colors.orange.shade800 : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'العميل: ${_selectedCustomer?.name ?? "عميل نقدي"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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
                                      icon: Icon(
                                        _isProductsFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                        color: Colors.indigo,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isProductsFullScreen = !_isProductsFullScreen;
                                        });
                                      },
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
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isSelected ? catColor.withOpacity(0.8) : catColor,
                                              elevation: isSelected ? 4 : 1,
                                            ),
                                            onPressed: () => _filterByCategory(cat.id),
                                            child: Text(
                                              cat.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                          onTap: () {
                            setState(() => _isInvoiceExpanded = !_isInvoiceExpanded);
                          },
                          child: Container(
                            width: 24,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Icon(
                                _isInvoiceExpanded ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      if (!_isProductsFullScreen)
                        Expanded(
                          flex: _isInvoiceExpanded ? 1 : 2,
                          child: Container(
                            color: Colors.grey.shade100,
                            child: _buildInvoicePanel(),
                          ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: itemFontSize,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatNum(prod.sellPrice),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: itemFontSize - 1,
                      ),
                    ),
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
            icon: Icon(
              _isReturnMode ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
              color: _isReturnMode ? Colors.orange.shade800 : Colors.blue,
            ),
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
              Text(_isReturnMode ? 'إجمالي المسترجع:' : 'الإجمالي العام:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _formatNum(_totalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isReturnMode ? Colors.orange.shade800 : Colors.blue,
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                ),
                onPressed: _clearInvoice,
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: Text(
                  _isReturnMode ? 'تفريغ المرتجع' : 'فاتورة جديدة',
                  style: TextStyle(color: Colors.white, fontSize: btnFontSize),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: btnHeight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green.shade700,
                ),
                onPressed: _cart.isEmpty ? null : _showPaymentDialog,
                icon: Icon(_isReturnMode ? Icons.assignment_return : Icons.payment, color: Colors.white),
                label: Text(
                  _isReturnMode ? 'إتمام المرتجع' : 'الدفع',
                  style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
