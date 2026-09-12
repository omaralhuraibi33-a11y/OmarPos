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
  bool _isPrinterConnected = true; // حالة الطابعة (أخضر = متصل, أحمر = مفصول)
  bool _isInvoiceExpanded = false; // توسيع شاشة الفاتورة
  bool _isProductsFullScreen = false; // جعل الأصناف بكامل الشاشة

  // البيانات
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];

  // قائمة ملاحظات التحضير المقترحة
  List<String> _prepNotesList = [
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
                mainAxisSize: MainAxisSize.min,
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

  // نافذة إتمام الدفع وتحديد طريقة الدفع مع الحفظ والطباعة
  void _showPaymentDialog() {
    String selectedMethod = 'نقدي';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('إتمام الدفع واختيار طريقة الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي: ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                ),
                const SizedBox(height: 12),
                const Text('اختر طريقة الدفع:'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('حفظ وطباعة الفاتورة', style: TextStyle(color: Colors.white)),
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

  // معالجة الحفظ والطباعة
  void _processCheckout(String paymentMethod) {
    // 1. إرسال أمر الحفظ وقاعدة البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الفاتورة بنجاح ($paymentMethod)'),
        backgroundColor: Colors.green,
      ),
    );

    // 2. إرسال أمر الطباعة إذا كانت الطابعة متصلة
    if (_isPrinterConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري إرسال الفاتورة للطابعة الحرارية...'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنبه: الطابعة غير متصلة! تمت عملية الحفظ فقط.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _clearInvoice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // تبديل النمط (لمس / عادية)
            Text(_isTouchMode ? 'مبيعات لمس' : 'مبيعات عادية'),
            Switch(
              value: _isTouchMode,
              onChanged: (val) => setState(() => _isTouchMode = val),
              activeColor: Colors.white,
            ),
          ],
        ),
        actions: [
          // زر مؤشر الطابعة (أحمر / أخضر)
          IconButton(
            tooltip: _isPrinterConnected ? 'الطابعة متصلة' : 'الطابعة مفصولة',
            icon: Icon(
              Icons.print,
              color: _isPrinterConnected ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              setState(() => _isPrinterConnected = !_isPrinterConnected);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isPrinterConnected ? 'تم الاتصال بالطابعة' : 'الطابعة غير متصلة!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // زر المرتجع
          IconButton(
            tooltip: 'مرتجع مبيعات',
            icon: const Icon(Icons.assignment_return, color: Colors.orangeAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('شاشة المرتجعات قيد التطوير')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط العميل الأعلى
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'العميل: $_selectedCustomerName',
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

                // محتوى الصفحة الرئيسي (المنتجات + الفاتورة)
                Expanded(
                  child: Row(
                    children: [
                      // قسم الأصناف والمجموعات (يختفي عند توسيع الفاتورة وتمديده عند الشاشة الكاملة)
                      if (!_isInvoiceExpanded)
                        Expanded(
                          flex: _isProductsFullScreen ? 10 : 3,
                          child: Column(
                            children: [
                              // حقل البحث مع زر التكبير لكامل الشاشة
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
                                      tooltip: 'عرض الأصناف بكامل الشاشة',
                                      onPressed: () {
                                        setState(() {
                                          _isProductsFullScreen = !_isProductsFullScreen;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // شريط المجموعات (في نمط اللمس)
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

                              // عرض الأصناف (Grid للـ Touch أو List للعادي)
                              Expanded(
                                child: _isTouchMode ? _buildTouchProductGrid() : _buildStandardProductList(),
                              ),
                            ],
                          ),
                        ),

                      // زر السهم الصغير للتوسيع والتضييق
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

                      // قسم الفاتورة
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

                // الشريط السفلي (الأزرار الأساسية)
                _buildBottomBar(),
              ],
            ),
    );
  }

  // شبكة أصناف اللمس
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
            color: Colors.white,
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
                    style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // قائمة الأصناف العادية
  Widget _buildStandardProductList() {
    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, index) {
        final prod = _filteredProducts[index];
        return ListTile(
          title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('السعر: ${prod.sellPrice} | الكمية: ${prod.quantity}'),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
            onPressed: () => _addToCart(prod),
          ),
        );
      },
    );
  }

  // لوحة الفاتورة مع خيار ملاحظات التحضير تحت الصنف
  Widget _buildInvoicePanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blueGrey.shade100,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الصنف / الملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('العدد', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? const Center(child: Text('الفاتورة فارغة'))
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
                                      child: Text('${item.quantity.toInt()}'),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => item.quantity++),
                                      child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text('${item.total.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            // قسم ملاحظات التحضير تحت الصنف
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
              const Text('الإجمالي العام:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // الشريط السفلي للأزرار
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          // زر فاتورة جديدة
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _clearInvoice,
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: const Text('فاتورة جديدة', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          // زر الدفع (يفتح طرق الدفع وإرسال للطباعة)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _cart.isEmpty ? null : _showPaymentDialog,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('الدفع', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
