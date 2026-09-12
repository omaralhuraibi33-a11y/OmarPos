import 'package:flutter/material.dart';
import 'db_helper.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;
  String preparationNotes; // ملاحظات التحضير لكل صنف

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.preparationNotes = '',
  });

  double get total => quantity * unitPrice;
}

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // حالة النظام
  bool _isTouchMode = true; // true = مبيعات لمس, false = مبيعات عادية
  bool _isPrinterConnected = true; // حالة الطابعة
  bool _isInvoiceExpanded = false; // توسيع شاشة الفاتورة
  bool _isProductsFullScreen = false; // جعل الأصناف بكامل الشاشة
  bool _isReturnMode = false; // true = وضع مرتجع مبيعات, false = بيع عادي

  // البيانات
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];

  // قائمة ملاحظات التحضير المقترحة
  final List<String> _prepNotesList = [
    'بدون شطة',
    'زيادة صوص',
    'بدون ثوم',
    'بدون بصل',
    'محمص زيادة',
    'سفري',
    'محلي',
  ];

  // قائمة طرق الدفع المتاحة
  final List<String> _paymentMethods = ['نقدي', 'أجل', 'شبكة (بطاقة)', 'تحويل بنكي'];

  // بيانات الفاتورة الحالية
  List<CartItem> _cart = [];
  String _selectedCustomerId = 'cash'; // 'cash' تعني زبون نقدي
  String _selectedCustomerName = 'زبون نقدي';
  String _selectedCategoryId = 'all';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;

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

    setState(() {
      _categories = cats;
      _allProducts = prods;
      _filteredProducts = prods;
      _customers = custs;
      _isLoading = false;
    });
  }

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
      _selectedCustomerId = 'cash';
      _selectedCustomerName = 'زبون نقدي';
    });
  }

  double get _totalAmount => _cart.fold(0.0, (sum, item) => sum + item.total);

  // اختيار العميل
  void _selectCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختيار العميل'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text('زبون نقدي (افتراضي)', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  setState(() {
                    _selectedCustomerId = 'cash';
                    _selectedCustomerName = 'زبون نقدي';
                  });
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ..._customers.map((c) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(c.name),
                    subtitle: Text('هاتف: ${c.phone} | الدين: ${c.balance}'),
                    onTap: () {
                      setState(() {
                        _selectedCustomerId = c.id;
                        _selectedCustomerName = c.name;
                      });
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // إضافة أو تعديل ملاحظات التحضير لصنف معين
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
                mainAxisSize: minMode,
                children: [
                  Wrap(
                    spacing: 6,
                    children: _prepNotesList.map((note) {
                      final isSelected = item.preparationNotes.contains(note);
                      return FilterChip(
                        label: Text(note),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              item.preparationNotes = item.preparationNotes.isEmpty
                                  ? note
                                  : '${item.preparationNotes} - $note';
                            } else {
                              item.preparationNotes = item.preparationNotes
                                  .replaceAll(note, '')
                                  .replaceAll(' -  - ', ' - ')
                                  .trim();
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
                      labelText: 'إضافة ملاحظة جديدة خاصة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (customNoteCtrl.text.trim().isNotEmpty) {
                    final newNote = customNoteCtrl.text.trim();
                    setState(() {
                      if (!_prepNotesList.contains(newNote)) {
                        _prepNotesList.add(newNote);
                      }
                      item.preparationNotes = item.preparationNotes.isEmpty
                          ? newNote
                          : '${item.preparationNotes} - $newNote';
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ الملاحظات'),
              ),
            ],
          );
        },
      ),
    );
  }

  MainAxisSize get minMode => MainAxisSize.min;

  // نافذة إتمام الدفع أو إرجاع المبلغ
  void _showPaymentDialog() {
    String selectedMethod = 'نقدي';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text(_isReturnMode ? 'إتمام مرتجع المبيعات' : 'إتمام الدفع واختيار طريقة الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي: ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _isReturnMode ? Colors.orange.shade800 : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_isReturnMode ? 'طريقة إعادة المبلغ:' : 'اختر طريقة الدفع:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => selectedMethod = val!),
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

  // معالجة الحفظ والطباعة (دعم البيع والمرتجع)
  void _processCheckout(String paymentMethod) {
    final actionName = _isReturnMode ? 'مرتجع المبيعات' : 'الفاتورة';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ $actionName بنجاح ($paymentMethod)'),
        backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green,
      ),
    );

    if (_isPrinterConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري إرسال $actionName للطابعة الحرارية...'),
          backgroundColor: Colors.blue,
        ),
      );
    }

    _clearInvoice();
    if (_isReturnMode) {
      setState(() => _isReturnMode = false); // العودة التلقائية للبيع
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isReturnMode ? Colors.orange.shade800 : null,
        title: Row(
          children: [
            Text(_isReturnMode
                ? 'مرتجع مبيعات'
                : (_isTouchMode ? 'مبيعات لمس' : 'مبيعات عادية')),
            const SizedBox(width: 8),
            if (!_isReturnMode)
              Switch(
                value: _isTouchMode,
                onChanged: (val) => setState(() => _isTouchMode = val),
                activeColor: Colors.white,
              ),
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
          // زر التبديل بين وضع البيع والمرتجع
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(_isReturnMode ? Icons.shopping_cart : Icons.assignment_return),
            label: Text(_isReturnMode ? 'وضع البيع' : 'مرتجع'),
            onPressed: () {
              setState(() {
                _isReturnMode = !_isReturnMode;
                _clearInvoice();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط العميل والوضع
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
                        'العميل: $_selectedCustomerName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (_isReturnMode) ...[
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'وضع المرتجع مفعل',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

                // محتوى الصفحة الرئيسي
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
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('الكل'),
                                        selected: _selectedCategoryId == 'all',
                                        onSelected: (_) => _filterByCategory('all'),
                                      ),
                                      const SizedBox(width: 5),
                                      ..._categories.map((cat) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4.0),
                                          child: ChoiceChip(
                                            label: Text(cat.name),
                                            selected: _selectedCategoryId == cat.id,
                                            avatar: CircleAvatar(backgroundColor: Color(int.parse(cat.colorHex)), radius: 6),
                                            onSelected: (_) => _filterByCategory(cat.id),
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

                // الشريط السفلي
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildTouchProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isProductsFullScreen ? 5 : 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, index) {
        final prod = _filteredProducts[index];
        return InkWell(
          onTap: () => _addToCart(prod),
          child: Card(
            elevation: 2,
            color: _isReturnMode ? Colors.orange.shade50 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prod.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${prod.sellPrice}',
                    style: TextStyle(
                      color: _isReturnMode ? Colors.orange.shade900 : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
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
          subtitle: Text('السعر: ${prod.sellPrice} | الكمية: ${prod.quantity}'),
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
              Text(_isReturnMode ? 'الصنف المراد إرجاعه' : 'الصنف / الملاحظات',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  child: Text(item.product.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                                      child: Text('${item.quantity.toInt()}'),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => item.quantity++),
                                      child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text('${item.total.toStringAsFixed(1)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                          item.preparationNotes.isEmpty
                                              ? '+ اضغط لإضافة ملاحظات تحضير'
                                              : item.preparationNotes,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: item.preparationNotes.isEmpty
                                                ? Colors.grey
                                                : Colors.deepOrange,
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
              Text(_isReturnMode ? 'إجمالي المسترجع:' : 'الإجمالي العام:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${_totalAmount.toStringAsFixed(2)}',
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
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _clearInvoice,
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: Text(_isReturnMode ? 'تفريغ المرتجع' : 'فاتورة جديدة',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReturnMode ? Colors.orange.shade800 : Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _cart.isEmpty ? null : _showPaymentDialog,
              icon: Icon(_isReturnMode ? Icons.assignment_return : Icons.payment, color: Colors.white),
              label: Text(
                _isReturnMode ? 'إتمام المرتجع' : 'الدفع',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
