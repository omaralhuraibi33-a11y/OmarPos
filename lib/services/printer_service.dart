import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:omar_pos/db_helper.dart'; // تأكد من مطابقة اسم المشروع مع مشروعك

class PrinterService {
  /// دالة طباعة الفاتورة للزبون أو المطبخ
  static Future<void> printInvoice({
    required dynamic invoice,
    required List<Map<String, dynamic>> items,
    required String usageType, // 'زبون' أو 'مطبخ'
  }) async {
    // 1. التحقق من تفعيل الطباعة التلقائية
    final autoCustomer = await DBHelper.getSetting('auto_customer');
    final autoKitchen = await DBHelper.getSetting('auto_kitchen');

    if (usageType == 'زبون' && autoCustomer != 'true') return;
    if (usageType == 'مطبخ' && autoKitchen != 'true') return;

    // 2. جلب قائمة الطابعات
    final savedPrintersJson = await DBHelper.getSetting('printers_list');
    if (savedPrintersJson == null || savedPrintersJson.isEmpty) return;

    final List<dynamic> decoded = jsonDecode(savedPrintersJson);
    final printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    // فلترة الطابعات المخصصة لهذا الاستخدام (زبون / مطبخ)
    final targetPrinters = printers.where((p) => p['usage'] == usageType).toList();
    if (targetPrinters.isEmpty) return;

    // 3. جلب نص التذييل المكتوب في شاشة إعدادات الفاتورة
    final footerNote = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم!');

    for (var printer in targetPrinters) {
      final bytes = await _generateReceiptBytes(
        invoice: invoice,
        items: items,
        paperSizeStr: printer['paperSize'] ?? '80',
        usageType: usageType,
        footerNote: footerNote ?? '',
      );

      await _sendToPrinter(printer, bytes);
    }
  }

  /// توليد مصفوفة الأوامر (ESC/POS Bytes)
  static Future<List<int>> _generateReceiptBytes({
    required dynamic invoice,
    required List<Map<String, dynamic>> items,
    required String paperSizeStr,
    required String usageType,
    required String footerNote,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperSizeStr == '57' ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);

    List<int> bytes = [];

    // ترويسة الفاتورة
    bytes += generator.text(
      usageType == 'مطبخ' ? 'طلب مطبخ' : 'فاتورة مبيعات',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text('رقم الفاتورة: ${invoice.id}');
    bytes += generator.text('التاريخ: ${invoice.date}');
    if (invoice.customerName != null && invoice.customerName.toString().isNotEmpty) {
      bytes += generator.text('العميل: ${invoice.customerName}');
    }
    bytes += generator.text('نوع الدفع: ${invoice.paymentType == 'cash' ? 'نقدي' : 'آجل'}');
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    // طباعة الأصناف
    for (var item in items) {
      final String name = item['name'] ?? '';
      final double qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
      final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final double total = qty * price;

      if (usageType == 'مطبخ') {
        bytes += generator.text('$name  x$qty', styles: const PosStyles(bold: true));
      } else {
        bytes += generator.text(name, styles: const PosStyles(bold: true));
        bytes += generator.text('  $qty x $price = $total');
      }
    }

    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    // الإجمالي والتذييل للزبون
    if (usageType == 'زبون') {
      bytes += generator.text(
        'الإجمالي: ${invoice.totalAmount}',
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      );
      if (footerNote.isNotEmpty) {
        bytes += generator.feed(1);
        bytes += generator.text(footerNote, styles: const PosStyles(align: PosAlign.center));
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// إرسال البيانات للطابعة (شبكة أو بلوتوث)
  static Future<void> _sendToPrinter(Map<String, dynamic> printer, List<int> bytes) async {
    try {
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
    } catch (_) {
      // إهمال الأخطاء لضمان عدم توقف حفظ الفاتورة في حال وجود مشكلة في الاتصال بالطابعة
    }
  }
}
