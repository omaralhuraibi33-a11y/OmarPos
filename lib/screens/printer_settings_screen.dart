import 'package:flutter/material.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<Map<String, dynamic>> _printers = [];
  int? _selectedPrinterIndex;

  bool _autoKitchen = false;
  bool _autoCustomer = false;

  void _showPrinterDialog({Map<String, dynamic>? printerToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: printerToEdit?['name'] ?? '');
    final ipCtrl = TextEditingController(text: printerToEdit?['ip'] ?? '');
    final macCtrl = TextEditingController(text: printerToEdit?['macAddress'] ?? '');
    
    String connection = printerToEdit?['connection'] ?? 'بلوتوث';
    String usage = printerToEdit?['usage'] ?? 'زبون';
    String paperSize = printerToEdit?['paperSize'] ?? '80';
    String selectedBtDevice = printerToEdit?['btDevice'] ?? '';

    // قائمة الأجهزة المقترنة مع عناوين MAC الخاصة بها
    List<Map<String, String>> pairedBtDevices = [
      {'name': 'BT-Printer-01', 'mac': '00:11:22:33:44:55'},
      {'name': 'POS-Thermal-58', 'mac': 'AA:BB:CC:DD:EE:FF'},
      {'name': 'RP-80-Printer', 'mac': '99:88:77:66:55:44'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text(editIndex == null ? 'إضافة طابعة جديدة' : 'تعديل الطابعة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: usage,
                    decoration: const InputDecoration(labelText: 'نوع الطابعة (الاستخدام)'),
                    items: ['مطبخ', 'زبون'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => usage = val!),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: connection,
                    decoration: const InputDecoration(labelText: 'نوع الاتصال'),
                    items: ['بلوتوث', 'واي فاي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => connection = val!),
                  ),
                  const SizedBox(height: 12),
                  
                  // الإضافات الخاصة بالبلوتوث
                  if (connection == 'بلوتوث') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('البحث عن الأجهزة المقترنة (Bluetooth)'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (bContext) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'اختر طابعة من أجهزة البلوتوث المقترنة:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: pairedBtDevices.length,
                                        itemBuilder: (context, idx) {
                                          final dev = pairedBtDevices[idx];
                                          return ListTile(
                                            leading: const Icon(Icons.print, color: Colors.blue),
                                            title: Text(dev['name']!),
                                            subtitle: Text('MAC: ${dev['mac']}'),
                                            onTap: () {
                                              setDlgState(() {
                                                selectedBtDevice = dev['name']!;
                                                macCtrl.text = dev['mac']!;
                                                if (nameCtrl.text.isEmpty) {
                                                  nameCtrl.text = dev['name']!;
                                                }
                                              });
                                              Navigator.pop(bContext);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: macCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'عنوان MAC للبلوتوث (ينضاف تلقائياً)',
                        prefixIcon: Icon(Icons.pin, color: Colors.indigo),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: ipCtrl,
                      decoration: const InputDecoration(labelText: 'عنوان IP للطابعة (مثال: 192.168.1.100)'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الطابعة (تلقائي/تعديل)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paperSize,
                    decoration: const InputDecoration(labelText: 'مقاس الورق'),
                    items: ['57', '78', '80'].map((e) => DropdownMenuItem(value: e, child: Text('$e mm'))).toList(),
                    onChanged: (val) => setDlgState(() => paperSize = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final printerData = {
                    'name': nameCtrl.text.trim().isEmpty ? 'طابعة جديدة' : nameCtrl.text.trim(),
                    'connection': connection,
                    'usage': usage,
                    'paperSize': paperSize,
                    'btDevice': selectedBtDevice,
                    'macAddress': macCtrl.text.trim(),
                    'ip': ipCtrl.text.trim(),
                  };
                  setState(() {
                    if (editIndex == null) {
                      _printers.add(printerData);
                    } else {
                      _printers[editIndex] = printerData;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ الطابعة'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الطابعات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrinterDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الطباعة التلقائية حسب النوع', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('طباعة المطبخ تلقائياً'),
                    value: _autoKitchen,
                    onChanged: (val) => setState(() => _autoKitchen = val),
                  ),
                  SwitchListTile(
                    title: const Text('طباعة الزبون تلقائياً'),
                    value: _autoCustomer,
                    onChanged: (val) => setState(() => _autoCustomer = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الطابعات المضافة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPrinterIndex != null ? Colors.orange : Colors.grey,
                ),
                onPressed: _selectedPrinterIndex == null
                    ? null
                    : () {
                        final p = _printers[_selectedPrinterIndex!];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم إرسال صفحة تجريبية إلى الطابعة: ${p['name']}')),
                        );
                      },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('تجربة الطابعة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(),
          _printers.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طابعات مضافة. اضغط + للإضافة')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _printers.length,
                  itemBuilder: (ctx, i) {
                    final p = _printers[i];
                    final isSelected = _selectedPrinterIndex == i;
                    return Card(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : null,
                      child: ListTile(
                        onTap: () => setState(() => _selectedPrinterIndex = i),
                        leading: Icon(
                          p['connection'] == 'بلوتوث' ? Icons.bluetooth : Icons.wifi,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text('${p['name']} (${p['usage']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          p['connection'] == 'بلوتوث'
                              ? 'الاتصال: بلوتوث (${p['macAddress']}) | المقاس: ${p['paperSize']}mm'
                              : 'الاتصال: IP (${p['ip']}) | المقاس: ${p['paperSize']}mm',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showPrinterDialog(printerToEdit: p, editIndex: i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _printers.removeAt(i);
                                  if (_selectedPrinterIndex == i) _selectedPrinterIndex = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
