import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:omar_pos/db_helper.dart';

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
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final savedPrintersJson = await DBHelper.getSetting('printers_list');
    final savedAutoKitchen = await DBHelper.getSetting('auto_kitchen');
    final savedAutoCustomer = await DBHelper.getSetting('auto_customer');

    if (mounted) {
      setState(() {
        if (savedPrintersJson != null && savedPrintersJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(savedPrintersJson);
          _printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (savedAutoKitchen != null) {
          _autoKitchen = savedAutoKitchen == 'true';
        }
        if (savedAutoCustomer != null) {
          _autoCustomer = savedAutoCustomer == 'true';
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final printersJson = jsonEncode(_printers);
    await DBHelper.saveSetting('printers_list', printersJson);
    await DBHelper.saveSetting('auto_kitchen', _autoKitchen.toString());
    await DBHelper.saveSetting('auto_customer', _autoCustomer.toString());
  }

  // دالة تجربة الطباعة المباشرة (معدلة لتتفادي أخطاء الحروف العربية في مقطع الاختبار)
  Future<void> _testPrint(Map<String, dynamic> printer) async {
    setState(() => _isTesting = true);

    try {
      final profile = await CapabilityProfile.load();
      final paperSize = (printer['paperSize'] == '57' || printer['paperSize'] == '58') ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];
      bytes += generator.text('OMAR POS TEST',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      
      // استخدام نص إنجليزي لتجنب مشاكل الترميز والحروف العربية في التجربة
      final modeText = printer['printMode'] == 'صورة' ? 'Mode: Image' : 'Mode: Text';
      bytes += generator.text(modeText, styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.text('SUCCESSFUL PRINT TEST!', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(2);
      bytes += generator.cut();

      if (printer['connection'] == 'واي فاي') {
        final String ip = (printer['ip'] ?? '').trim();
        if (ip.isEmpty) throw 'عنوان الـ IP غير مدخل!';

        final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        await socket.close();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الطباعة عبر الواي فاي بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final String mac = (printer['macAddress'] ?? '').trim();
        if (mac.isEmpty) throw 'عنوان MAC الخاص بالبلوتوث غير مدخل!';

        bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if (connected) {
          await PrintBluetoothThermal.writeBytes(bytes);
          await PrintBluetoothThermal.disconnect;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت الطباعة عبر البلوتوث بنجاح!'), backgroundColor: Colors.green),
            );
          }
        } else {
          throw 'تعذر الاتصال بطابعة البلوتوث!';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال بالطابعة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showPrinterDialog({Map<String, dynamic>? printerToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: printerToEdit?['name'] ?? '');
    final ipCtrl = TextEditingController(text: printerToEdit?['ip'] ?? '');
    final macCtrl = TextEditingController(text: printerToEdit?['macAddress'] ?? '');

    String connection = printerToEdit?['connection'] ?? 'بلوتوث';
    String usage = printerToEdit?['usage'] ?? 'زبون';
    String paperSize = printerToEdit?['paperSize'] ?? '80';
    String printMode = printerToEdit?['printMode'] ?? 'نص'; // خيار نص أو صورة
    String selectedBtDevice = printerToEdit?['btDevice'] ?? '';

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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: printMode,
                    decoration: const InputDecoration(labelText: 'طريقة الطباعة'),
                    items: ['نص', 'صورة'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => printMode = val!),
                  ),
                  const SizedBox(height: 12),
                  if (connection == 'بلوتوث') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('البحث عن أجهزة البلوتوث المقترنة'),
                        onPressed: () async {
                          final List<BluetoothInfo> pairedBtDevices = await PrintBluetoothThermal.pairedBluetooths;
                          if (!context.mounted) return;

                          showModalBottomSheet(
                            context: context,
                            builder: (bContext) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('اختر طابعة بلوتوث:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Divider(),
                                    pairedBtDevices.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text('لا توجد أجهزة بلوتوث مقترنة.'),
                                          )
                                        : Expanded(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: pairedBtDevices.length,
                                              itemBuilder: (context, idx) {
                                                final dev = pairedBtDevices[idx];
                                                return ListTile(
                                                  leading: const Icon(Icons.print, color: Colors.blue),
                                                  title: Text(dev.name),
                                                  subtitle: Text('MAC: ${dev.macAdress}'),
                                                  onTap: () {
                                                    setDlgState(() {
                                                      selectedBtDevice = dev.name;
                                                      macCtrl.text = dev.macAdress;
                                                      if (nameCtrl.text.isEmpty) nameCtrl.text = dev.name;
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
                      decoration: const InputDecoration(labelText: 'عنوان MAC للبلوتوث', border: OutlineInputBorder()),
                    ),
                  ] else ...[
                    TextField(
                      controller: ipCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'عنوان IP للطابعة (مثال: 192.168.1.100)', border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الطابعة'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paperSize,
                    decoration: const InputDecoration(labelText: 'مقاس الورق'),
                    items: ['57', '80'].map((e) => DropdownMenuItem(value: e, child: Text('$e mm'))).toList(),
                    onChanged: (val) => setDlgState(() => paperSize = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final printerData = {
                    'name': nameCtrl.text.trim().isEmpty ? 'طابعة جديدة' : nameCtrl.text.trim(),
                    'connection': connection,
                    'usage': usage,
                    'paperSize': paperSize,
                    'printMode': printMode,
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
                  await _saveSettings();
                  if (context.mounted) Navigator.pop(ctx);
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
                    onChanged: (val) async {
                      setState(() => _autoKitchen = val);
                      await _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('طباعة الزبون تلقائياً'),
                    value: _autoCustomer,
                    onChanged: (val) async {
                      setState(() => _autoCustomer = val);
                      await _saveSettings();
                    },
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
                onPressed: (_selectedPrinterIndex == null || _isTesting)
                    ? null
                    : () {
                        final p = _printers[_selectedPrinterIndex!];
                        _testPrint(p);
                      },
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.print, color: Colors.white),
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
                          'الاتصال: ${p['connection']} | الوضع: ${p['printMode']} | المقاس: ${p['paperSize']}mm',
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
                              onPressed: () async {
                                setState(() {
                                  _printers.removeAt(i);
                                  if (_selectedPrinterIndex == i) _selectedPrinterIndex = null;
                                });
                                await _saveSettings();
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
