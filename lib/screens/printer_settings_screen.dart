import 'dart:convert';
import 'dart:io'; // لاستخدام Socket للواي فاي
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
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final savedPrintersJson = await DBHelper.getSetting('printers_list');

    if (mounted) {
      setState(() {
        if (savedPrintersJson != null && savedPrintersJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(savedPrintersJson);
          _printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final printersJson = jsonEncode(_printers);
    await DBHelper.saveSetting('printers_list', printersJson);
  }

  // تحويل القيمة البرمجية إلى حجم PosTextSize المناسب لمكتبة الطباعة
  PosTextSize _getPosTextSize(String sizeStr) {
    switch (sizeStr) {
      case 'medium':
        return PosTextSize.size1; // متوسط (يمكن دمجه أو جعله بحجم مناسب)
      case 'large':
        return PosTextSize.size2; // كبير (ضعف الحجم)
      case 'huge':
        return PosTextSize.size3; // ضخم (ثلاثة أضعاف)
      case 'normal':
      default:
        return PosTextSize.size1; // عادي
    }
  }

  // دالة تجربة الطباعة مع أخذ مقاس الخط المختار بعين الاعتبار
  Future<void> _testPrint(Map<String, dynamic> printer) async {
    setState(() => _isTesting = true);

    try {
      if (printer['paperSize'] == 'A4') {
        throw 'طابعات الـ A4 تتطلب نظام طباعة مستندات (PDF)، يرجى تجربة الطابعات الحرارية المعتادة.';
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(
        printer['paperSize'] == '57' ? PaperSize.mm58 : PaperSize.mm80,
        profile,
      );

      String fontSizeSetting = printer['fontSize'] ?? 'normal';
      PosTextSize textSize = _getPosTextSize(fontSizeSetting);

      List<int> bytes = [];
      bytes += generator.text('OMAR POS TEST',
          styles: PosStyles(align: PosAlign.center, bold: true, height: textSize, width: textSize));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('SUCCESSFUL PRINT TEST!', 
          styles: PosStyles(align: PosAlign.center, bold: true, height: textSize, width: textSize));
      
      bytes += generator.text('Printer: ${printer['name']}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('IP/MAC: ${printer['connection'] == 'واي فاي' ? printer['ip'] : printer['macAddress']}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Font Size: $fontSizeSetting', styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.feed(2);
      bytes += generator.cut();

      if (printer['connection'] == 'واي فاي') {
        final String ip = (printer['ip'] ?? '').trim();
        if (ip.isEmpty) {
          throw 'عنوان الـ IP غير مدخل!';
        }

        final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        await socket.close();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تمت طباعة التجربة على (${printer['name']}) بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final String mac = (printer['macAddress'] ?? '').trim();
        if (mac.isEmpty) {
          throw 'عنوان MAC الخاص بالبلوتوث غير مدخل!';
        }

        bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if (connected) {
          await PrintBluetoothThermal.writeBytes(bytes);
          await PrintBluetoothThermal.disconnect;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تمت طباعة التجربة على (${printer['name']}) بنجاح!'), backgroundColor: Colors.green),
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
    String fontSize = printerToEdit?['fontSize'] ?? 'normal'; // القيمة البرمجية الافتراضية
    String selectedBtDevice = printerToEdit?['btDevice'] ?? '';
    
    bool printerAutoPrint = printerToEdit?['autoPrint'] ?? true;
    bool isDefaultPrinter = printerToEdit?['isDefault'] ?? false;

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
                    items: ['مطبخ', 'زبون', 'تقرير'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => usage = val!),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text(
                      'تعيين كطابعة افتراضية لهذا النوع',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ستكون الطابعة الرئيسية لعمليات الـ "$usage"'),
                    value: isDefaultPrinter,
                    onChanged: (val) => setDlgState(() => isDefaultPrinter = val),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'طباعة تلقائية لهذه الطابعة ($usage)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    value: printerAutoPrint,
                    onChanged: (val) => setDlgState(() => printerAutoPrint = val),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: connection,
                    decoration: const InputDecoration(labelText: 'نوع الاتصال'),
                    items: ['بلوتوث', 'واي فاي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDlgState(() => connection = val!),
                  ),
                  const SizedBox(height: 12),
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
                                    const Text(
                                      'اختر طابعة من أجهزة البلوتوث المقترنة:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const Divider(),
                                    pairedBtDevices.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text('لم يتم العثور على أجهزة بلوتوث مقترنة بالجوال.'),
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
                                                      if (nameCtrl.text.isEmpty) {
                                                        nameCtrl.text = dev.name;
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'عنوان IP للطابعة (مثال: 192.168.1.100)',
                        border: OutlineInputBorder(),
                      ),
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
                    items: ['57', '78', '80', 'A4']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e == 'A4' ? 'A4' : '$e mm')))
                        .toList(),
                    onChanged: (val) => setDlgState(() => paperSize = val!),
                  ),
                  const SizedBox(height: 8),
                  // الخيارات الأربعة المطلوبة بدقة: عادي، متوسط، كبير، ضخم
                  DropdownButtonFormField<String>(
                    value: fontSize,
                    decoration: const InputDecoration(
                      labelText: 'مقاس الخط عند الطباعة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('عادي')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                      DropdownMenuItem(value: 'large', child: Text('كبير')),
                      DropdownMenuItem(value: 'huge', child: Text('ضخم')),
                    ],
                    onChanged: (val) => setDlgState(() => fontSize = val!),
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
                    'fontSize': fontSize, 
                    'btDevice': selectedBtDevice,
                    'macAddress': macCtrl.text.trim(),
                    'ip': ipCtrl.text.trim(),
                    'autoPrint': printerAutoPrint,
                    'isDefault': isDefaultPrinter,
                  };

                  setState(() {
                    if (isDefaultPrinter) {
                      for (var p in _printers) {
                        if (p['usage'] == usage) {
                          p['isDefault'] = false;
                        }
                      }
                    }

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

  // دالة مطابقة المقاس البرمجي ليعرض بالعربي في البطاقة الرئيسية
  String _getArabicFontSizeName(String sizeKey) {
    switch (sizeKey) {
      case 'medium': return 'متوسط';
      case 'large': return 'كبير';
      case 'huge': return 'ضخم';
      case 'normal':
      default: return 'عادي';
    }
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
          const Text('الطابعات المضافة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          _printers.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طابعات مضافة. اضغط + للإضافة')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _printers.length,
                  itemBuilder: (ctx, i) {
                    final p = _printers[i];
                    bool isAuto = p['autoPrint'] ?? true;
                    bool isDefault = p['isDefault'] ?? false;
                    String fontSizeKey = p['fontSize'] ?? 'normal';
                    String fontSizeArabic = _getArabicFontSizeName(fontSizeKey);

                    return Card(
                      color: isDefault ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          p['connection'] == 'بلوتوث' ? Icons.bluetooth : Icons.wifi,
                          color: isDefault ? Colors.blue.shade800 : Colors.blue,
                        ),
                        title: Row(
                          children: [
                            Text('${p['name']} (${p['usage']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'افتراضية',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ]
                          ],
                        ),
                        subtitle: Text(
                          (p['connection'] == 'بلوتوث'
                              ? 'الاتصال: بلوتوث (${p['macAddress']}) | المقاس: ${p['paperSize']}mm'
                              : 'الاتصال: IP (${p['ip']}) | المقاس: ${p['paperSize']}mm') +
                          '\nمقاس الخط: $fontSizeArabic | الحالة: ${isAuto ? "تلقائي (مفعل)" : "معطل"}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: _isTesting 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.print, color: Colors.orange),
                              tooltip: 'تجربة الطباعة',
                              onPressed: _isTesting ? null : () => _testPrint(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'تعديل',
                              onPressed: () => _showPrinterDialog(printerToEdit: p, editIndex: i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'حذف',
                                onPressed: () async {
                                setState(() {
                                  _printers.removeAt(i);
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
