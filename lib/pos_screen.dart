import 'package:flutter/material.dart';
import 'db_helper.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
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
  bool _isInvoiceExpanded = false; // تكشيف/توسيع شاشة الفاتورة

  // البيانات
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];

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
          // زر مؤشر الطابعة
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
                      // قسم الأصناف والمجموعات (يختفي أو يتقلص عند توسيع الفاتورة)
                      if (!_isInvoiceExpanded)
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // حقل البحث
                              Padding(
                                padding: const EdgeInsets.all(6.0),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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

  // لوحة الفاتورة
  Widget _buildInvoicePanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blueGrey.shade100,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.product.name, style: const TextStyle(fontSize: 12)),
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
          // زر الدفع
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('إجمالي الفاتورة: ${_totalAmount.toStringAsFixed(2)} - جاهز لتطبيق طرق الدفع!'),
                        ),
                      );
                    },
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('الدفع', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
