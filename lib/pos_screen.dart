Import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'db_helper.dart';

class CartItem {
  Final Product product;
  Double quantity;
  Double unitPrice;
  String preparationNotes;

  CartItem({
    Required this.product,
    This.quantity = 1.0,
    Required this.unitPrice,
    This.preparationNotes = '',
  });

  Double get total => quantity * unitPrice;
}

class PosScreen extends StatefulWidget {
  Const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  Bool _isTouchMode = true;
  Bool _isPrinterConnected = true;
  Bool _isInvoiceExpanded = false;
  Bool _isProductsFullScreen = false;
  Bool _isReturnMode = false;

  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  List<String> _prepNotesList = [];
  List<String> _paymentMethods = [];

  Customer? _selectedCustomer;
  String _selectedCategoryId = 'all';
  Final TextEditingController _searchController = TextEditingController();

  List<CartItem> _cart = [];
  Bool _isLoading = true;

  String _mainButtonSizeSetting = 'وسط';
  String _posItemSizeSetting = 'وسط';

  @override
  Void initState() {
    Super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SetState(() => _isLoading = true);
    Final cats = await DBHelper.getActivePOSCategories();
    Final prods = await DBHelper.getActivePOSProducts();
    Final custs = await DBHelper.getAllCustomers();
    Final notes = await DBHelper.getPreparationNotes();
    Final dbPaymentMethods = await DBHelper.getPaymentMethods();
    Final defaultCust = await DBHelper.getOrCreateDefaultCustomer();

    Final savedMainBtnSize = await DBHelper.getSetting('main_button_size');
    Final savedPosItemSize = await DBHelper.getSetting('pos_item_size');

    If (!custs.any((c) => c.id == defaultCust.id)) {
      Custs.insert(0, defaultCust);
    }

    SetState(() {
      _categories = cats;
      _allProducts = prods;
      _filteredProducts = prods;
      _customers = custs;
      _selectedCustomer = custs.firstWhere((c) => c.id == defaultCust.id, orElse: () => defaultCust);
      _prepNotesList = notes.isNotEmpty ? notes : ['بدون شطة', 'زيادة صوص', 'بدون ثوم', 'سفري', 'محلي'];
      _paymentMethods = dbPaymentMethods.isNotEmpty ? dbPaymentMethods : ['نقدي', 'آجل'];
      If (savedMainBtnSize != null) _mainButtonSizeSetting = savedMainBtnSize;
      If (savedPosItemSize != null) _posItemSizeSetting = savedPosItemSize;
      _isLoading = false;
    });
  }

  Future<void> _printReceiptDirect({
    Required String invoiceId,
    Required String paymentMethod,
    List<CartItem>? customCart,
    String? customerName,
    Double? customTotal,
    Bool isReturn = false,
  }) async {
    If (!_isPrinterConnected) return;

    Try {
      Final savedPrintersJson = await DBHelper.getSetting('printers_list');
      If (savedPrintersJson == null || savedPrintersJson.isEmpty) return; 

      Final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      If (printers.isEmpty) return;

      Final autoCustomer = await DBHelper.getSetting('auto_customer') == 'true';
      Final autoKitchen = await DBHelper.getSetting('auto_kitchen') == 'true';

      Final storeName = await DBHelper.getSetting('store_name') ?? 'متجري';
      Final storePhone = await DBHelper.getSetting('store_phone') ?? '';
      Final taxNumber = await DBHelper.getSetting('tax_number') ?? '';
      Final invoiceFooter = await DBHelper.getSetting('invoice_footer') ?? 'شكرا لزيارتكم';
      Final showItemCount = await DBHelper.getSetting('show_item_count') == 'true';

      Final activeCart = customCart ?? _cart;
      Final activeTotal = customTotal ?? _totalAmount;
      Final activeCustomer = customerName ?? (_selectedCustomer?.name ?? 'عميل نقدي');

      Final profile = await CapabilityProfile.load();

      For (var printer in printers) {
        Final usage = printer['usage'] ?? 'زبون';

        If (usage == 'زبون' && !autoCustomer) continue;
        If (usage == 'مطبخ' && !autoKitchen) continue;

        Final paperSizeVal = printer['paperSize'] == '57' ? PaperSize.mm58 : PaperSize.mm80;
        Final generator = Generator(paperSizeVal, profile);

        List<int> bytes = [];

        If (usage == 'زبون') {
          Bytes += generator.text(storeName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
          If (storePhone.isNotEmpty) {
            Bytes += generator.text('هاتف: $storePhone', styles: const PosStyles(align: PosAlign.center));
          }
          If (taxNumber.isNotEmpty) {
            Bytes += generator.text('الرقم الضريبي: $taxNumber', styles: const PosStyles(align: PosAlign.center));
          }
          Bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
          
          If (isReturn) {
            Bytes += generator.text('*** سند مرتجع مبيعات ***', styles: const PosStyles(align: PosAlign.center, bold: true));
          }

          Bytes += generator.text('رقم الفاتورة: $invoiceId', styles: const PosStyles(align: PosAlign.right));
          Bytes += generator.text('العميل: $activeCustomer', styles: const PosStyles(align: PosAlign.right));
          Bytes += generator.text('طريقة الدفع: $paymentMethod', styles: const PosStyles(align: PosAlign.right));
          Bytes += generator.text('التاريخ: ${DateTime.now().toString().split('.')[0]}', styles: const PosStyles(align: PosAlign.right));
          Bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

          For (var item in activeCart) {
            Bytes += generator.text('${item.product.name} (${item.quantity} x ${item.unitPrice}) = ${_formatNum(item.total)}', styles: const PosStyles(align: PosAlign.right));
            If (item.preparationNotes.isNotEmpty) {
              Bytes += generator.text('  ملاحظات: ${item.preparationNotes}', styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB));
            }
          }

          Bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
          
          If (showItemCount) {
            Double totalItemsQty = activeCart.fold(0.0, (sum, i) => sum + i.quantity);
            Bytes += generator.text('إجمالي عدد الأصناف: ${_formatNum(totalItemsQty)}', styles: const PosStyles(align: PosAlign.right, bold: true));
          }

          Bytes += generator.text('الإجمالي العام: ${_formatNum(activeTotal)}', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
          
          Bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
          Bytes += generator.text(invoiceFooter, styles: const PosStyles(align: PosAlign.center));
        } else {
          Bytes += generator.text(
            IsReturn ? '--- مرتجع مطبخ ---' : '--- طلب مطبخ ---', 
            Styles: const PosStyles(
              Align: PosAlign.center, 
              Bold: true, 
              Height: PosTextSize.size2,
            ),
          );
          Bytes += generator.text('رقم الفاتورة: $invoiceId', styles: const PosStyles(align: PosAlign.center));
          Bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
          For (var item in activeCart) {
            Bytes += generator.text('${item.product.name}  x${item.quantity}', styles: const PosStyles(align: PosAlign.right, bold: true));
            If (item.preparationNotes.isNotEmpty) {
              Bytes += generator.text('  [${item.preparationNotes}]', styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB, bold: true));
            }
          }
        }

        Bytes += generator.feed(2);
        Bytes += generator.cut();

        If (printer['connection'] == 'واي فاي') {
          Final String ip = (printer['ip'] ?? '').trim();
          If (ip.isNotEmpty) {
            Final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 3));
            Socket.add(bytes);
            Await socket.flush();
            Await socket.close();
          }
        } else if (printer['connection'] == 'بلوتوث') {
          Final String mac = (printer['macAddress'] ?? '').trim();
          If (mac.isNotEmpty) {
            Bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
            If (connected) {
              Await PrintBluetoothThermal.writeBytes(bytes);
              Await PrintBluetoothThermal.disconnect;
            }
          }
        }
      }
    } catch (e) {
      DebugPrint('خطأ في الطباعة المباشرة: $e');
    }
  }

  Void _showInvoicesHistoryDialog() async {
    Final salesInvoices = await DBHelper.getAllInvoices();
    Final returnInvoices = await DBHelper.getAllReturnInvoices();

    SalesInvoices.sort((a, b) => b.date.compareTo(a.date));
    ReturnInvoices.sort((a, b) => b.date.compareTo(a.date));

    If (!mounted) return;

    Final isDark = Theme.of(context).brightness == Brightness.dark;
    Final textColor = isDark ? Colors.white : Colors.black;

    ShowDialog(
      Context: context,
      Builder: (ctx) => DefaultTabController(
        Length: 2,
        Child: StatefulBuilder(
          Builder: (context, setDialogState) {
            String salesSearchQuery = '';
            String returnsSearchQuery = '';
            
            // فلاتر التواريخ (الافتراضي: اليوم)
            String dateFilterType = 'today'; // options: today, yesterday, week, month, year, custom
            DateTime? customStartDate;
            DateTime? customEndDate;

            Bool isDateMatching(String dateStr) {
              Try {
                Final invDate = DateTime.parse(dateStr);
                Final now = DateTime.now();
                Final today = DateTime(now.year, now.month, now.day);

                If (dateFilterType == 'today') {
                  Final invDay = DateTime(invDate.year, invDate.month, invDate.day);
                  Return invDay.isAtSameMomentAs(today);
                } else if (dateFilterType == 'yesterday') {
                  Final yesterday = today.subtract(const Duration(days: 1));
                  Final invDay = DateTime(invDate.year, invDate.month, invDate.day);
                  Return invDay.isAtSameMomentAs(yesterday);
                } else if (dateFilterType == 'week') {
                  Final weekAgo = today.subtract(const Duration(days: 7));
                  Return invDate.isAfter(weekAgo) || invDate.isAtSameMomentAs(weekAgo);
                } else if (dateFilterType == 'month') {
                  Final monthAgo = today.subtract(const Duration(days: 30));
                  Return invDate.isAfter(monthAgo) || invDate.isAtSameMomentAs(monthAgo);
                } else if (dateFilterType == 'year') {
                  Final yearAgo = today.subtract(const Duration(days: 365));
                  Return invDate.isAfter(yearAgo) || invDate.isAtSameMomentAs(yearAgo);
                } else if (dateFilterType == 'custom') {
                  If (customStartDate == null || customEndDate == null) return true;
                  Final start = DateTime(customStartDate!.year, customStartDate!.month, customStartDate!.day);
                  Final end = DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59);
                  Return (invDate.isAfter(start) || invDate.isAtSameMomentAs(start)) &&
                         (invDate.isBefore(end) || invDate.isAtSameMomentAs(end));
                }
              } catch (_) {}
              Return true;
            }

            String getDateFilterLabel() {
              Switch (dateFilterType) {
                Case 'today': return 'اليوم';
                Case 'yesterday': return 'أمس';
                Case 'week': return 'آخر أسبوع';
                Case 'month': return 'آخر شهر';
                Case 'year': return 'آخر سنة';
                Case 'custom':
                  If (customStartDate != null && customEndDate != null) {
                    Return '${customStartDate.toString().split(' ')[0]} إلى ${customEndDate.toString().split(' ')[0]}';
                  }
                  Return 'مخصص';
                Default: return 'الكل';
              }
            }

            Return Dialog(
              BackgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              InsetPadding: const EdgeInsets.all(12),
              Child: Container(
                Width: double.maxFinite,
                Padding: const EdgeInsets.all(12),
                Child: Column(
                  Children: [
                    Row(
                      MainAxisAlignment: MainAxisAlignment.spaceBetween,
                      Children: [
                        IconButton(
                          Icon: Icon(Icons.refresh, color: textColor),
                          Tooltip: 'تحديث السجلات',
                          OnPressed: () async {
                            Final freshSales = await DBHelper.getAllInvoices();
                            Final freshReturns = await DBHelper.getAllReturnInvoices();
                            FreshSales.sort((a, b) => b.date.compareTo(a.date));
                            FreshReturns.sort((a, b) => b.date.compareTo(a.date));
                            SetDialogState(() {
                              SalesInvoices.clear();
                              SalesInvoices.addAll(freshSales);
                              ReturnInvoices.clear();
                              ReturnInvoices.addAll(freshReturns);
                            });
                          },
                        ),
                        Text('سجل الفواتير والمرتجعات', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          Icon: Icon(Icons.arrow_forward, color: textColor),
                          OnPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    ConstrainedBox(constraints: const BoxConstraints(height: 8)),
                    
                    // شريط الفلترة الزمنية
                    Container(
                      Padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      Decoration: BoxDecoration(
                        Color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade200,
                        BorderRadius: BorderRadius.circular(10),
                      ),
                      Child: Row(
                        MainAxisAlignment: MainAxisAlignment.spaceBetween,
                        Children: [
                          Row(
                            Children: [
                              Const Icon(Icons.filter_list, size: 18, color: Colors.blueAccent),
                              ConstrainedBox(constraints: const BoxConstraints(width: 6)),
                              Text('الفترة: ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              Container(
                                Padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                Decoration: BoxDecoration(
                                  Color: Colors.blue.shade800,
                                  BorderRadius: BorderRadius.circular(6),
                                ),
                                Child: Text(getDateFilterLabel(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            Icon: Icon(Icons.calendar_month, color: textColor),
                            Tooltip: 'تغيير الفترة الزمنية',
                            OnSelected: (val) async {
                              If (val == 'custom') {
                                Final picked = await showDateRangePicker(
                                  Context: context,
                                  FirstDate: DateTime(2020),
                                  LastDate: DateTime.now(),
                                );
                                If (picked != null) {
                                  SetDialogState(() {
                                    DateFilterType = 'custom';
                                    CustomStartDate = picked.start;
                                    CustomEndDate = picked.end;
                                  });
                                }
                              } else {
                                SetDialogState(() => dateFilterType = val);
                              }
                            },
                            ItemBuilder: (context) => [
                              Const PopupMenuItem(value: 'today', child: Text('اليوم')),
                              Const PopupMenuItem(value: 'yesterday', child: Text('أمس')),
                              Const PopupMenuItem(value: 'week', child: Text('خلال أسبوع')),
                              Const PopupMenuItem(value: 'month', child: Text('خلال شهر')),
                              Const PopupMenuItem(value: 'year', child: Text('خلال سنة')),
                              Const PopupMenuItem(value: 'custom', child: Text('تحديد فترة مخصصة...')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(constraints: const BoxConstraints(height: 8)),

                    Container(
                      Decoration: BoxDecoration(
                        Color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade200,
                        BorderRadius: BorderRadius.circular(10),
                      ),
                      Child: TabBar(
                        Indicator: BoxDecoration(
                          BorderRadius: BorderRadius.circular(10),
                          Color: Colors.blue.shade800,
                        ),
                        LabelColor: Colors.white,
                        UnselectedLabelColor: textColor,
                        Tabs: [
                          Tab(
                            Child: Row(
                              MainAxisAlignment: MainAxisAlignment.center,
                              Children: [
                                Const Icon(Icons.receipt, size: 18),
                                ConstrainedBox(constraints: const BoxConstraints(width: 6)),
                                Text('فواتير المبيعات', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Tab(
                            Child: Row(
                              MainAxisAlignment: MainAxisAlignment.center,
                              Children: [
                                Const Icon(Icons.assignment_return, size: 18),
                                ConstrainedBox(constraints: const BoxConstraints(width: 6)),
                                Text('سجل المرتجعات', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(constraints: const BoxConstraints(height: 10)),
                    Expanded(
                      Child: TabBarView(
                        Children: [
                          Column(
                            Children: [
                              TextField(
                                OnChanged: (val) => setDialogState(() => salesSearchQuery = val),
                                Style: TextStyle(color: textColor),
                                Decoration: InputDecoration(
                                  HintText: 'بحث برقم فاتورة المبيعات...',
                                  HintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                                  PrefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  Filled: true,
                                  FillColor: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade100,
                                  Border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ContentPadding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                              ConstrainedBox(constraints: const BoxConstraints(height: 8)),
                              Expanded(
                                Child: Builder(
                                  Builder: (context) {
                                    Final filteredSales = salesInvoices.where((inv) {
                                      Final matchesDate = isDateMatching(inv.date);
                                      If (!matchesDate) return false;
                                      If (salesSearchQuery.isEmpty) return true;
                                      Return inv.id.toLowerCase().contains(salesSearchQuery.toLowerCase());
                                    }).toList();

                                    If (filteredSales.isEmpty) {
                                      Return Center(child: Text('لا توجد مبيعات مطابقة للفترة المحددة', style: TextStyle(color: textColor)));
                                    }

                                    Return ListView.builder(
                                      ItemCount: filteredSales.length,
                                      ItemBuilder: (context, index) {
                                        Final inv = filteredSales[index];
                                        Final formattedId = 'INV-${inv.id.padLeft(6, '0')}';
                                        Return _buildInvoiceCardItem(context, inv, formattedId, false, isDark, textColor);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          Column(
                            Children: [
                              TextField(
                                OnChanged: (val) => setDialogState(() => returnsSearchQuery = val),
                                Style: TextStyle(color: textColor),
                                Decoration: InputDecoration(
                                  HintText: 'بحث برقم سند المرتجع...',
                                  HintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                                  PrefixIcon: const Icon(Icons.search, color: Colors.orange),
                                  Filled: true,
                                  FillColor: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade100,
                                  Border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ContentPadding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                              ConstrainedBox(constraints: const BoxConstraints(height: 8)),
                              Expanded(
                                Child: Builder(
                                  Builder: (context) {
                                    Final filteredReturns = returnInvoices.where((inv) {
                                      Final matchesDate = isDateMatching(inv.date);
                                      If (!matchesDate) return false;
                                      If (returnsSearchQuery.isEmpty) return true;
                                      Return inv.id.toLowerCase().contains(returnsSearchQuery.toLowerCase());
                                    }).toList();

                                    If (filteredReturns.isEmpty) {
                                      Return Center(child: Text('لا توجد مرتجعات مطابقة للفترة المحددة', style: TextStyle(color: textColor)));
                                    }

                                    Return ListView.builder(
                                      ItemCount: filteredReturns.length,
                                      ItemBuilder: (context, index) {
                                        Final inv = filteredReturns[index];
                                        Final formattedId = 'RET-${inv.id.padLeft(6, '0')}';
                                        Return _buildInvoiceCardItem(context, inv, formattedId, true, isDark, textColor);
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
            );
          },
        ),
      ),
    );
  }

  // --- تم تعديل هذه الدالة بالكامل حسب الترتيب المطلوب ---
  Widget _buildInvoiceCardItem(BuildContext context, Invoice inv, String formattedId, bool isReturn, bool isDark, Color textColor) {
    Return InkWell(
      OnTap: () async {
        Final items = isReturn 
            ? await DBHelper.getReturnInvoiceItems(inv.id)
            : await DBHelper.getInvoiceItems(inv.id);
        If (!context.mounted) return;
        
        ShowDialog(
          Context: context,
          Builder: (c) => Dialog(
            InsetPadding: const EdgeInsets.all(10),
            Child: Container(
              Padding: const EdgeInsets.all(12),
              Child: Column(
                MainAxisSize: MainAxisSize.min,
                CrossAxisAlignment: CrossAxisAlignment.stretch,
                Children: [
                  // شريط العنوان العلوي (رقم الفاتورة، زر الطباعة، وزر الإغلاق)
                  Row(
                    MainAxisAlignment: MainAxisAlignment.spaceBetween,
                    Children: [
                      Text('$formattedId تفاصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      Row(
                        Children: [
                          IconButton(
                            Icon: Icon(Icons.print, color: textColor),
                            Tooltip: 'طباعة الفاتورة',
                            OnPressed: () async {
                              Final cartItems = items.map((i) => CartItem(
                                Product: Product(id: i.productId, name: i.productName, categoryId: '', sellPrice: i.price),
                                Quantity: i.quantity,
                                UnitPrice: i.price,
                                PreparationNotes: i.notes,
                              )).toList();

                              Await _printReceiptDirect(
                                InvoiceId: formattedId,
                                PaymentMethod: inv.paymentType,
                                CustomCart: cartItems,
                                CustomerName: inv.customerName,
                                CustomTotal: inv.totalAmount,
                                IsReturn: isReturn,
                              );
                            },
                          ),
                          IconButton(
                            Icon: Icon(Icons.close, color: textColor),
                            OnPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ConstrainedBox(constraints: const BoxConstraints(height: 4)),
                  Const Divider(),
                  ConstrainedBox(constraints: const BoxConstraints(height: 6)),
                  
                  // 1. رأس الفاتورة: (طريقة الدفع، الحالة، التاريخ والوقت، واسم العميل)
                  Container(
                    Padding: const EdgeInsets.all(10),
                    Decoration: BoxDecoration(
                      Color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade100,
                      BorderRadius: BorderRadius.circular(8),
                    ),
                    Child: Column(
                      CrossAxisAlignment: CrossAxisAlignment.start,
                      Children: [
                        Row(
                          MainAxisAlignment: MainAxisAlignment.spaceBetween,
                          Children: [
                            Row(
                              Children: [
                                Const Icon(Icons.payment, size: 16, color: Colors.blueAccent),
                                ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                                Text('الدفع: ${inv.paymentType == 'cash' || inv.paymentType == 'نقدي' ? 'نقداً' : 'آجل'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                              ],
                            ),
                            Row(
                              Children: [
                                Icon(isReturn ? Icons.assignment_return : Icons.check_circle, size: 16, color: isReturn ? Colors.orange : Colors.green),
                                ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                                Text(isReturn ? 'مرتجع معتمد' : 'بيع معتمد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isReturn ? Colors.orange : Colors.green)),
                              ],
                            ),
                          ],
                        ),
                        ConstrainedBox(constraints: const BoxConstraints(height: 6)),
                        Row(
                          Children: [
                            Const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                            Text('التاريخ والوقت: ${inv.date}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                          ],
                        ),
                        If (inv.customerName.isNotEmpty) ...[
                          ConstrainedBox(constraints: const BoxConstraints(height: 4)),
                          Row(
                            Children: [
                              Const Icon(Icons.person, size: 16, color: Colors.grey),
                              ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                              Text('العميل: ${inv.customerName}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  ConstrainedBox(constraints: const BoxConstraints(height: 10)),
                  Text('قائمة الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ConstrainedBox(constraints: const BoxConstraints(height: 6)),

                  // 2. منتصف الفاتورة: قائمة الأصناف
                  Expanded(
                    Child: ListView.builder(
                      ShrinkWrap: true,
                      ItemCount: items.length,
                      ItemBuilder: (_, i) {
                        Final itm = items[i];
                        Return Card(
                          Margin: const EdgeInsets.symmetric(vertical: 4),
                          Child: Padding(
                            Padding: const EdgeInsets.all(10.0),
                            Child: Row(
                              MainAxisAlignment: MainAxisAlignment.spaceBetween,
                              Children: [
                                Expanded(
                                  Child: Column(
                                    CrossAxisAlignment: CrossAxisAlignment.start,
                                    Children: [
                                      Text(itm.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                      Text('السعر: ${_formatNum(itm.price)} | الكمية: ${_formatNum(itm.quantity)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
                                      If (itm.notes.isNotEmpty)
                                        Text('ملاحظات: ${itm.notes}', style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
                                    ],
                                  ),
                                ),
                                Text(_formatNum(itm.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isReturn ? Colors.orange : Colors.green)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ConstrainedBox(constraints: const BoxConstraints(height: 6)),
                  Const Divider(),
                  ConstrainedBox(constraints: const BoxConstraints(height: 6)),

                  // 3. أسفل الفاتورة: الإجمالي العام
                  Container(
                    Padding: const EdgeInsets.all(10),
                    Decoration: BoxDecoration(
                      Color: isReturn ? Colors.orange.shade900.withOpacity(0.2) : Colors.blue.shade900.withOpacity(0.2),
                      BorderRadius: BorderRadius.circular(8),
                    ),
                    Child: Row(
                      MainAxisAlignment: MainAxisAlignment.spaceBetween,
                      Children: [
                        Text('الإجمالي العام:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        Text(
                          _formatNum(inv.totalAmount),
                          Style: TextStyle(
                            FontWeight: FontWeight.bold,
                            FontSize: 18,
                            Color: isReturn ? Colors.orangeAccent : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      Child: Container(
        Margin: const EdgeInsets.symmetric(vertical: 6),
        Padding: const EdgeInsets.all(12),
        Decoration: BoxDecoration(
          Color: isReturn 
              ? (isDark ? const Color(0xFF332211) : Colors.orange.shade900)
              : (isDark ? const Color(0xFF252538) : Colors.blue.shade900),
          BorderRadius: BorderRadius.circular(14),
        ),
        Child: Row(
          Children: [
            Container(
              Padding: const EdgeInsets.all(8),
              Decoration: BoxDecoration(
                Color: (isReturn ? Colors.orange.shade700 : Colors.blue.shade700).withOpacity(0.4),
                BorderRadius: BorderRadius.circular(10),
              ),
              Child: Icon(isReturn ? Icons.assignment_return : Icons.receipt, color: isReturn ? Colors.orangeAccent : Colors.cyanAccent, size: 24),
            ),
            ConstrainedBox(constraints: const BoxConstraints(width: 12)),
            Expanded(
              Child: Column(
                CrossAxisAlignment: CrossAxisAlignment.start,
                Children: [
                  Row(
                    Children: [
                      Text(formattedId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ConstrainedBox(constraints: const BoxConstraints(width: 8)),
                      Container(
                        Padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        Decoration: BoxDecoration(
                          Color: isReturn ? Colors.orange.shade800 : Colors.teal.shade700,
                          BorderRadius: BorderRadius.circular(6),
                        ),
                        Child: Text(isReturn ? 'مرتجع' : 'بيع', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ConstrainedBox(constraints: const BoxConstraints(height: 4)),
                  Row(
                    Children: [
                      Const Icon(Icons.access_time, color: Colors.white54, size: 13),
                      ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                      Text(inv.date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ConstrainedBox(constraints: const BoxConstraints(width: 10)),
                      Const Icon(Icons.payment, color: Colors.white54, size: 13),
                      ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                      Text(inv.paymentType == 'cash' || inv.paymentType == 'نقدي' ? 'نقداً' : 'آجل', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              CrossAxisAlignment: CrossAxisAlignment.end,
              Children: [
                Const Text('الإجمالي', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ConstrainedBox(constraints: const BoxConstraints(height: 2)),
                Text(
                  _formatNum(inv.totalAmount),
                  Style: TextStyle(
                    Color: isReturn ? Colors.orangeAccent : Colors.greenAccent,
                    FontWeight: FontWeight.bold,
                    FontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Int _getGridCrossAxisCount() {
    If (_isProductsFullScreen) {
      Switch (_posItemSizeSetting) {
        Case 'صغير': return 6;
        Case 'كبير': return 4;
        Case 'وسط': default: return 5;
      }
    } else {
      Switch (_posItemSizeSetting) {
        Case 'صغير': return 4;
        Case 'كبير': return 2;
        Case 'وسط': default: return 3;
      }
    }
  }

  Double _getItemFontSize() {
    Switch (_posItemSizeSetting) {
      Case 'صغير': return 12.0;
      Case 'كبير': return 16.0;
      Case 'وسط': default: return 14.0;
    }
  }

  Double _getBottomButtonHeight() {
    Switch (_mainButtonSizeSetting) {
      Case 'صغير': return 40.0;
      Case 'كبير': return 56.0;
      Case 'وسط': default: return 48.0;
    }
  }

  Double _getBottomButtonFontSize() {
    Switch (_mainButtonSizeSetting) {
      Case 'صغير': return 13.0;
      Case 'كبير': return 18.0;
      Case 'وسط': default: return 15.0;
    }
  }

  Bool get _isCashCustomer =>
      _selectedCustomer == null ||
      _selectedCustomer!.id == 'cash_default' ||
      _selectedCustomer!.name == 'عميل نقدي';

  Void _filterProducts(String query) {
    SetState(() {
      _filteredProducts = _allProducts.where((p) {
        Final matchesQuery = p.name.contains(query);
        Final matchesCat = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
        Return matchesQuery && matchesCat;
      }).toList();
    });
  }

  Void _filterByCategory(String catId) {
    SetState(() {
      _selectedCategoryId = catId;
      _filterProducts(_searchController.text);
    });
  }

  Void _addToCart(Product product) {
    SetState(() {
      Final index = _cart.indexWhere((item) => item.product.id == product.id);
      If (index >= 0) {
        _cart[index].quantity += 1;
      } else {
        _cart.add(CartItem(product: product, unitPrice: product.sellPrice));
      }
    });
  }

  Void _clearInvoice() {
    SetState(() {
      _cart.clear();
      _selectedCustomer = _customers.firstWhere(
        (c) => c.id == 'cash_default',
        orElse: () => Customer(id: 'cash_default', name: 'عميل نقدي', phone: '', address: '', balance: 0.0),
      );
    });
  }

  Double get _totalAmount => _cart.fold(0.0, (sum, item) => sum + item.total);

  String _formatNum(double number) {
    Return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  Void _selectCustomerDialog() {
    ShowDialog(
      Context: context,
      Builder: (ctx) => AlertDialog(
        Title: const Text('اختيار العميل'),
        Content: SizedBox(
          Width: double.maxFinite,
          Child: ListView.builder(
            ShrinkWrap: true,
            ItemCount: _customers.length,
            ItemBuilder: (context, index) {
              Final c = _customers[index];
              Final isCash = c.id == 'cash_default';

              Return ListTile(
                Leading: CircleAvatar(
                  BackgroundColor: isCash ? Colors.amber.shade100 : Colors.blue.shade100,
                  Child: Icon(isCash ? Icons.point_of_sale : Icons.person, color: isCash ? Colors.orange.shade900 : Colors.blue),
                ),
                Title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Subtitle: Text(isCash ? 'عميل نقدي افتراضي' : 'هاتف: ${c.phone} | الرصيد: ${_formatNum(c.balance)}'),
                OnTap: () {
                  SetState(() => _selectedCustomer = c);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Void _showPrepNotesDialog(CartItem item) {
    Final customNoteCtrl = TextEditingController();
    ShowDialog(
      Context: context,
      Builder: (ctx) => StatefulBuilder(
        Builder: (context, setDlgState) {
          Return AlertDialog(
            Title: Text('ملاحظات تحضير: ${item.product.name}'),
            Content: SingleChildScrollView(
              Child: Column(
                MainAxisSize: MainAxisSize.min,
                Children: [
                  Wrap(
                    Spacing: 6,
                    RunSpacing: 6,
                    Children: _prepNotesList.map((note) {
                      Final isSelected = item.preparationNotes.contains(note);
                      Return FilterChip(
                        Label: Text(note, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                        Selected: isSelected,
                        SelectedColor: Colors.deepOrange,
                        OnSelected: (selected) {
                          SetState(() {
                            If (selected) {
                              Item.preparationNotes = item.preparationNotes.isEmpty ? note : '${item.preparationNotes} - $note';
                            } else {
                              Item.preparationNotes = item.preparationNotes.replaceAll(note, '').replaceAll(' -  - ', ' - ').trim();
                            }
                          });
                          SetDlgState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  Const Divider(),
                  TextField(
                    Controller: customNoteCtrl,
                    Decoration: const InputDecoration(labelText: 'إضافة ملاحظة جديدة', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            Actions: [
              TextButton(
                OnPressed: () async {
                  If (customNoteCtrl.text.trim().isNotEmpty) {
                    Final newNote = customNoteCtrl.text.trim();
                    If (!_prepNotesList.contains(newNote)) {
                      Await DBHelper.addPreparationNote(newNote);
                      _prepNotesList.add(newNote);
                    }
                    SetState(() {
                      Item.preparationNotes = item.preparationNotes.isEmpty ? newNote : '${item.preparationNotes} - $newNote';
                    });
                  }
                  Navigator.pop(ctx);
                },
                Child: const Text('حفظ الملاحظة'),
              ),
            ],
          );
        },
      ),
    );
  }

  Void _showPaymentDialog() {
    String selectedMethod = _isCashCustomer ? 'نقدي' : (_paymentMethods.isNotEmpty ? _paymentMethods.first : 'نقدي');

    ShowDialog(
      Context: context,
      Builder: (ctx) => StatefulBuilder(
        Builder: (context, setDlgState) {
          Final availableMethods = _isCashCustomer ? ['نقدي'] : _paymentMethods;

          Return AlertDialog(
            Title: Text(_isReturnMode ? 'إتمام مرتجع المبيعات' : 'إتمام الدفع واختيار طريقة الدفع'),
            Content: Column(
              MainAxisSize: MainAxisSize.min,
              CrossAxisAlignment: CrossAxisAlignment.start,
              Children: [
                Text(
                  'المبلغ الإجمالي: ${_formatNum(_totalAmount)}',
                  Style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isReturnMode ? Colors.orange.shade800 : Colors.green),
                ),
                ConstrainedBox(constraints: const BoxConstraints(height: 12)),
                Text('العميل الحالي: ${_selectedCustomer?.name ?? "عميل نقدي"}'),
                If (_isCashCustomer)
                  Const Padding(
                    Padding: EdgeInsets.symmetric(vertical: 6.0),
                    Child: Text('تنبيه: العميل النقدي لا يقبل سوى الدفع النقدي.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ConstrainedBox(constraints: const BoxConstraints(height: 8)),
                DropdownButtonFormField<String>(
                  Value: availableMethods.contains(selectedMethod) ? selectedMethod : availableMethods.first,
                  Decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'طريقة الدفع'),
                  Items: availableMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  OnChanged: (val) {
                    If (val != null) setDlgState(() => selectedMethod = val);
                  },
                ),
              ],
            ),
            Actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                Style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green),
                Icon: const Icon(Icons.print, color: Colors.white),
                Label: Text(_isReturnMode ? 'طباعة وحفظ المرتجع' : 'طباعة وحفظ الفاتورة', style: const TextStyle(color: Colors.white)),
                OnPressed: () {
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
    Final cartSnapshot = List<CartItem>.from(_cart);
    Final totalSnapshot = _totalAmount;
    Final customerNameSnapshot = _selectedCustomer?.name ?? 'عميل نقدي';
    
    Final now = DateTime.now().toString().split('.')[0];
    Final shiftId = await DBHelper.getCurrentShiftId();
    Final customerId = _selectedCustomer?.id ?? 'cash_default';
    Final isCredit = paymentMethod == 'آجل' || paymentMethod == 'أجل';
    
    If (_isReturnMode) {
      Final returnInvoices = await DBHelper.getAllReturnInvoices();
      int maxReturnId = 0;
      For (var inv in returnInvoices) {
        Int? parsedId = int.tryParse(inv.id);
        If (parsedId != null && parsedId > maxReturnId) {
          MaxReturnId = parsedId;
        }
      }
      Final nextReturnNumber = maxReturnId + 1;
      Final invoiceId = nextReturnNumber.toString();

      Final returnInvoice = Invoice(
        Id: invoiceId,
        InvoiceType: 'return',
        PaymentType: isCredit ? 'credit' : 'cash',
        TotalAmount: totalSnapshot,
        Date: now,
        CustomerId: customerId,
        CustomerName: customerNameSnapshot,
        ShiftId: shiftId,
        IsClosed: false,
      );
      
      Await DBHelper.saveReturnInvoice(returnInvoice);

      For (var item in cartSnapshot) {
        Final returnItem = InvoiceItem(
          Id: '${invoiceId}_${item.product.id}',
          InvoiceId: invoiceId,
          ProductId: item.product.id,
          ProductName: item.product.name,
          Quantity: item.quantity,
          Price: item.unitPrice,
          Total: item.total,
          Notes: item.preparationNotes,
        );
        Await DBHelper.saveReturnInvoiceItem(returnItem);
        Await DBHelper.updateProductStock(item.product.id, item.quantity);
      }

      Final formattedPrintId = 'RET-${invoiceId.padLeft(6, '0')}';

      If (_isPrinterConnected) {
        Await _printReceiptDirect(
          InvoiceId: formattedPrintId,
          PaymentMethod: paymentMethod,
          CustomCart: cartSnapshot,
          CustomerName: customerNameSnapshot,
          CustomTotal: totalSnapshot,
          IsReturn: true,
        );
      }

      If (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            Content: Text('تم حفظ مرتجع المبيعات بنجاح برقم ($formattedPrintId)'),
            BackgroundColor: Colors.orange.shade800,
          ),
        );
      }

    } else {
      Final salesInvoices = await DBHelper.getAllInvoices();
      int maxSaleId = 0;
      For (var inv in salesInvoices) {
        Int? parsedId = int.tryParse(inv.id);
        If (parsedId != null && parsedId > maxSaleId) {
          MaxSaleId = parsedId;
        }
      }
      Final nextSaleNumber = maxSaleId + 1;
      Final invoiceId = nextSaleNumber.toString();

      Final saleInvoice = Invoice(
        Id: invoiceId,
        InvoiceType: 'sale',
        PaymentType: isCredit ? 'credit' : 'cash',
        TotalAmount: totalSnapshot,
        Date: now,
        CustomerId: customerId,
        CustomerName: customerNameSnapshot,
        ShiftId: shiftId,
        IsClosed: false,
      );
      
      Await DBHelper.saveInvoice(saleInvoice);

      For (var item in cartSnapshot) {
        Final invoiceItem = InvoiceItem(
          Id: '${invoiceId}_${item.product.id}',
          InvoiceId: invoiceId,
          ProductId: item.product.id,
          ProductName: item.product.name,
          Quantity: item.quantity,
          Price: item.unitPrice,
          Total: item.total,
          Notes: item.preparationNotes,
        );
        Await DBHelper.saveInvoiceItem(invoiceItem);
        Await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      Final formattedPrintId = 'INV-${invoiceId.padLeft(6, '0')}';

      If (_isPrinterConnected) {
        Await _printReceiptDirect(
          InvoiceId: formattedPrintId,
          PaymentMethod: paymentMethod,
          CustomCart: cartSnapshot,
          CustomerName: customerNameSnapshot,
          CustomTotal: totalSnapshot,
          IsReturn: false,
        );
      }

      If (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            Content: Text('تم حفظ الفاتورة بنجاح برقم ($formattedPrintId)'),
            BackgroundColor: Colors.green,
          ),
        );
      }
    }

    Await _loadData();
    _clearInvoice();
    If (_isReturnMode) {
      SetState(() => _isReturnMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Return Scaffold(
      AppBar: AppBar(
        BackgroundColor: _isReturnMode ? Colors.orange.shade800 : null,
        Title: Row(
          Children: [
            If (!_isReturnMode)
              Row(
                MainAxisSize: MainAxisSize.min,
                Children: [
                  Text(_isTouchMode ? 'مبيعات لمس' : 'مبيعات عادية', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                  Switch(value: _isTouchMode, onChanged: (val) => setState(() => _isTouchMode = val), activeColor: Colors.amber),
                ],
              )
            else
              Const Text('مرتجع مبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Actions: [
          IconButton(
            Tooltip: 'سجل الفواتير والمرتجعات',
            Icon: const Icon(Icons.receipt_long, color: Colors.amberAccent),
            OnPressed: _showInvoicesHistoryDialog,
          ),
          IconButton(
            Tooltip: _isPrinterConnected ? 'الطابعة متصلة' : 'الطابعة مفصولة',
            Icon: Icon(Icons.print, color: _isPrinterConnected ? Colors.greenAccent : Colors.redAccent),
            OnPressed: () => setState(() => _isPrinterConnected = !_isPrinterConnected),
          ),
          Padding(
            Padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            Child: TextButton.icon(
              Style: TextButton.styleFrom(foregroundColor: Colors.white),
              Icon: Icon(_isReturnMode ? Icons.shopping_cart : Icons.assignment_return, color: Colors.amber),
              Label: Text(_isReturnMode ? 'وضع البيع' : 'مرتجع', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              OnPressed: () {
                SetState(() {
                  _isReturnMode = !_isReturnMode;
                  _clearInvoice();
                });
              },
            ),
          ),
        ],
      ),
      Body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              Children: [
                Container(
                  Color: _isReturnMode ? Colors.orange.shade50 : Colors.blue.shade50,
                  Padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  Child: Row(
                    Children: [
                      Icon(_isReturnMode ? Icons.assignment_return : Icons.account_circle, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
                      ConstrainedBox(constraints: const BoxConstraints(width: 8)),
                      Text('العميل: ${_selectedCustomer?.name ?? "عميل نقدي"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Const Spacer(),
                      ElevatedButton.icon(
                        Style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                        OnPressed: _selectCustomerDialog,
                        Icon: const Icon(Icons.person_add, size: 18),
                        Label: const Text('تغيير العميل'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  Child: Row(
                    Children: [
                      If (!_isInvoiceExpanded)
                        Expanded(
                          Flex: _isProductsFullScreen ? 10 : 3,
                          Child: Column(
                            Children: [
                              Padding(
                                Padding: const EdgeInsets.all(6.0),
                                Child: Row(
                                  Children: [
                                    Expanded(
                                      Child: TextField(
                                        Controller: _searchController,
                                        OnChanged: _filterProducts,
                                        Decoration: InputDecoration(
                                          HintText: 'بحث باسم الصنف أو الباركود...',
                                          PrefixIcon: const Icon(Icons.search),
                                          ContentPadding: const EdgeInsets.all(8),
                                          Border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      Icon: Icon(_isProductsFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.indigo),
                                      OnPressed: () => setState(() => _isProductsFullScreen = !_isProductsFullScreen),
                                    ),
                                  ],
                                ),
                              ),
                              If (_isTouchMode)
                                Container(
                                  Height: 48,
                                  Padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  Child: ListView(
                                    ScrollDirection: Axis.horizontal,
                                    Children: [
                                      Padding(
                                        Padding: const EdgeInsets.only(right: 4.0),
                                        Child: ElevatedButton(
                                          Style: ElevatedButton.styleFrom(
                                            BackgroundColor: _selectedCategoryId == 'all' ? Colors.blue.shade900 : Colors.blue,
                                            ForegroundColor: Colors.white,
                                          ),
                                          OnPressed: () => _filterByCategory('all'),
                                          Child: const Text('الكل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                      ..._categories.map((cat) {
                                        Color catColor = Colors.teal;
                                        Try {
                                          CatColor = Color(int.parse(cat.colorHex));
                                        } catch (_) {}

                                        Final isSelected = _selectedCategoryId == cat.id;

                                        Return Padding(
                                          Padding: const EdgeInsets.only(right: 4.0),
                                          Child: ElevatedButton(
                                            Style: ElevatedButton.styleFrom(backgroundColor: isSelected ? catColor.withOpacity(0.8) : catColor),
                                            OnPressed: () => _filterByCategory(cat.id),
                                            Child: Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              Expanded(
                                Child: _isTouchMode ? _buildTouchProductGrid() : _buildStandardProductList(),
                              ),
                            ],
                          ),
                        ),
                      If (!_isProductsFullScreen)
                        InkWell(
                          OnTap: () => setState(() => _isInvoiceExpanded = !_isInvoiceExpanded),
                          Child: Container(
                            Width: 24,
                            Color: Colors.grey.shade300,
                            Child: Center(
                              Child: Icon(_isInvoiceExpanded ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 16),
                            ),
                          ),
                        ),
                      If (!_isProductsFullScreen)
                        Expanded(
                          Flex: _isInvoiceExpanded ? 1 : 2,
                          Child: Container(color: Colors.grey.shade100, child: _buildInvoicePanel()),
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
    Return GridView.builder(
      Padding: const EdgeInsets.all(6),
      GridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        CrossAxisCount: _getGridCrossAxisCount(),
        ChildAspectRatio: 1.1,
        CrossAxisSpacing: 6,
        MainAxisSpacing: 6,
      ),
      ItemCount: _filteredProducts.length,
      ItemBuilder: (ctx, index) {
        Final prod = _filteredProducts[index];
        Color cardColor = _isReturnMode ? Colors.deepOrange.shade700 : Colors.blue.shade700;
        Final itemFontSize = _getItemFontSize();

        Return InkWell(
          OnTap: () => _addToCart(prod),
          Child: Card(
            Elevation: 3,
            Color: cardColor,
            Shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            Child: Padding(
              Padding: const EdgeInsets.all(6.0),
              Child: Column(
                MainAxisAlignment: MainAxisAlignment.center,
                Children: [
                  Text(
                    Prod.name,
                    TextAlign: TextAlign.center,
                    MaxLines: 2,
                    Style: TextStyle(fontWeight: FontWeight.bold, fontSize: itemFontSize, color: Colors.white),
                  ),
                  ConstrainedBox(constraints: const BoxConstraints(height: 6)),
                  Container(
                    Padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    Decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                    Child: Text(_formatNum(prod.sellPrice), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: itemFontSize - 1)),
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
    Return ListView.builder(
      ItemCount: _filteredProducts.length,
      ItemBuilder: (ctx, index) {
        Final prod = _filteredProducts[index];
        Return ListTile(
          Title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Subtitle: Text('السعر: ${_formatNum(prod.sellPrice)} | الكمية: ${_formatNum(prod.quantity)}'),
          Trailing: IconButton(
            Icon: Icon(_isReturnMode ? Icons.remove_shopping_cart : Icons.add_shopping_cart, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
            OnPressed: () => _addToCart(prod),
          ),
        );
      },
    );
  }

  Widget _buildInvoicePanel() {
    Return Column(
      Children: [
        Container(
          Padding: const EdgeInsets.all(8),
          Color: _isReturnMode ? Colors.orange.shade200 : Colors.blueGrey.shade100,
          Child: Row(
            MainAxisAlignment: MainAxisAlignment.spaceBetween,
            Children: [
              Text(_isReturnMode ? 'الصنف المراد إرجاعه' : 'الصنف / الملاحظات', style: const TextStyle(fontWeight: FontWeight.bold)),
              Const Text('العدد', style: TextStyle(fontWeight: FontWeight.bold)),
              Const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          Child: _cart.isEmpty
              ? Center(child: Text(_isReturnMode ? 'قائمة المرتجع فارغة' : 'الفاتورة فارغة'))
              : ListView.builder(
                  ItemCount: _cart.length,
                  ItemBuilder: (ctx, index) {
                    Final item = _cart[index];
                    Return Card(
                      Margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      Child: Padding(
                        Padding: const EdgeInsets.all(6.0),
                        Child: Column(
                          CrossAxisAlignment: CrossAxisAlignment.start,
                          Children: [
                            Row(
                              Children: [
                                Expanded(
                                  Flex: 3,
                                  Child: Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                                Row(
                                  Children: [
                                    InkWell(
                                      OnTap: () {
                                        SetState(() {
                                          If (item.quantity > 1) {
                                            Item.quantity--;
                                          } else {
                                            _cart.removeAt(index);
                                          }
                                        });
                                      },
                                      Child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                    ),
                                    Padding(
                                      Padding: const EdgeInsets.symmetric(horizontal: 4),
                                      Child: Text(_formatNum(item.quantity)),
                                    ),
                                    InkWell(
                                      OnTap: () => setState(() => item.quantity++),
                                      Child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                    ),
                                  ],
                                ),
                                ConstrainedBox(constraints: const BoxConstraints(width: 8)),
                                Text(_formatNum(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            If (!_isReturnMode)
                              InkWell(
                                OnTap: () => _showPrepNotesDialog(item),
                                Child: Padding(
                                  Padding: const EdgeInsets.only(top: 4.0),
                                  Child: Row(
                                    Children: [
                                      Const Icon(Icons.note_alt_outlined, size: 14, color: Colors.orange),
                                      ConstrainedBox(constraints: const BoxConstraints(width: 4)),
                                      Expanded(
                                        Child: Text(
                                          Item.preparationNotes.isEmpty ? '+ ملاحظات تحضير' : item.preparationNotes,
                                          Style: TextStyle(
                                            FontSize: 11,
                                            Color: item.preparationNotes.isEmpty ? Colors.grey : Colors.deepOrange,
                                            FontStyle: FontStyle.italic,
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
          Padding: const EdgeInsets.all(12),
          Color: Colors.grey.shade200,
          Child: Row(
            MainAxisAlignment: MainAxisAlignment.spaceBetween,
            Children: [
              Text(_isReturnMode ? 'إجمالي المسترجع:' : 'الإجمالي العام:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _formatNum(_totalAmount),
                Style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isReturnMode ? Colors.orange.shade800 : Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    Final btnHeight = _getBottomButtonHeight();
    Final btnFontSize = _getBottomButtonFontSize();

    Return Container(
      Padding: const EdgeInsets.all(8),
      Color: Colors.white,
      Child: Row(
        Children: [
          Expanded(
            Child: SizedBox(
              Height: btnHeight,
              Child: ElevatedButton.icon(
                Style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                Icon: const Icon(Icons.cleaning_services, color: Colors.white, size: 20),
                Label: Text('تعليق', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                OnPressed: _clearInvoice,
              ),
            ),
          ),
          ConstrainedBox(constraints: const BoxConstraints(width: 6)),
          Expanded(
            Child: SizedBox(
              Height: btnHeight,
              Child: ElevatedButton.icon(
                Style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                Icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                Label: Text('إلغاء', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                OnPressed: _clearInvoice,
              ),
            ),
          ),
          ConstrainedBox(constraints: const BoxConstraints(width: 6)),
          Expanded(
            Flex: 2,
            Child: SizedBox(
              Height: btnHeight,
              Child: ElevatedButton.icon(
                Style: ElevatedButton.styleFrom(backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green.shade700),
                Icon: Icon(_isReturnMode ? Icons.assignment_return : Icons.payment, color: Colors.white, size: 22),
                Label: Text(_isReturnMode ? 'إتمام المرتجع' : 'دفع وطباعة', style: TextStyle(color: Colors.white, fontSize: btnFontSize, fontWeight: FontWeight.bold)),
                OnPressed: _cart.isEmpty ? null : _showPaymentDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
