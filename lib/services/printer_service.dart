import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:omar_pos/db_helper.dart';

class PrinterService {
  
  // دالة توليد محتوى الفاتورة وإرسالها للطابعات المطابقة للاستخدام (زبون أو مطبخ)
  static Future<void> printInvoice({
    required dynamic invoice, 
    required List<Map<String, dynamic>> items,
    required String usageType, // 'زبون' أو 'مطبخ'
  }) async {
    try {
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) {
        debugPrint('لا توجد طابعات مضافة في الإعدادات.');
        return;
      }

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      final List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // تصفية الطابعات حسب الاستخدام ('مطبخ' أو 'زبون')
      final targetPrinters = printers.where((p) => p['usage'] == usageType).toList();

      if (targetPrinters.isEmpty) {
        debugPrint('لا توجد طابعة مُعرّفة لنوع الاستخدام: $usageType');
        return;
      }

      for (var printer in targetPrinters) {
        await _sendToPrinter(printer, invoice, items, usageType);
      }
    } catch (e) {
      debugPrint('خطأ عام في PrinterService: $e');
    }
  }

  static Future<void> _sendToPrinter(
    Map<String, dynamic> printer,
    dynamic invoice,
    List<Map<String, dynamic>> items,
    String usageType,
  ) async {
    try {
      final paperSizeStr = printer['paperSize'] ?? '80';
      final paperSize = (paperSizeStr == '57' || paperSizeStr == '58') ? PaperSize.mm58 : PaperSize.mm80;

      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];

      bytes += generator.reset();

      // استخراج بيانات الفاتورة بمرونة عالية
      String invoiceId = '';
      String invoiceDate = '';
      String customerName = '';
      double totalAmount = 0.0;
      String paymentType = '';

      if (invoice is Map) {
        invoiceId = invoice['id']?.toString() ?? '';
        invoiceDate = invoice['date']?.toString() ?? '';
        customerName = invoice['customerName']?.toString() ?? 'عميل نقدي';
        totalAmount = double.tryParse(invoice['totalAmount']?.toString() ?? '0') ?? 0.0;
        paymentType = invoice['paymentType']?.toString() ?? 'cash';
      } else {
        invoiceId = invoice.id?.toString() ?? '';
        invoiceDate = invoice.date?.toString() ?? '';
        customerName = invoice.customerName?.toString() ?? 'عميل نقدي';
        totalAmount = double.tryParse(invoice.totalAmount?.toString() ?? '0') ?? 0.0;
        paymentType = invoice.paymentType?.toString() ?? 'cash';
      }

      // جلب تذييل الفاتورة مع ضمان عدم إرجاع قيمة null لمنع أخطاء الترجمة
      final String footerText = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.') ?? 'شكراً لزيارتكم!';

      // --- تصميم الوصل ---
      bytes += generator.text(
        usageType == 'مطبخ' ? '*** طلب مطبخ تحضير ***' : 'OMAR POS',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('رقم الفاتورة: $invoiceId', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('التاريخ: $invoiceDate', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('العميل: $customerName', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // رأس جدول الأصناف
      bytes += generator.row([
        PosColumn(text: 'الإجمالي', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
        PosColumn(text: 'الكمية/السعر', width: 4, styles: const PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(text: 'الصنف', width: 5, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // تفاصيل الأصناف
      if (items.isNotEmpty) {
        for (var item in items) {
          final name = item['name']?.toString() ?? '';
          final qty = item['qty']?.toString() ?? '1';
          final price = item['price']?.toString() ?? '0';
          final notes = item['notes']?.toString() ?? '';
          
          final double q = double.tryParse(qty) ?? 1.0;
          final double p = double.tryParse(price) ?? 0.0;
          final total = (q * p).toStringAsFixed(2);

          bytes += generator.row([
            PosColumn(text: total, width: 3, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: '$qty x $price', width: 4, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: name, width: 5, styles: const PosStyles(align: PosAlign.right)),
          ]);

          if (notes.isNotEmpty) {
            bytes += generator.text('  (ملاحظة: $notes)', styles: const PosStyles(align: PosAlign.right));
          }
        }
      } else {
        bytes += generator.text('تفاصيل الأصناف غير متوفرة لهذه الفاتورة', styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      if (usageType == 'زبون') {
        bytes += generator.text(
          'المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1),
        );
        bytes += generator.text('طريقة الدفع: $paymentType', styles: const PosStyles(align: PosAlign.right));
        bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text(footerText, styles: const PosStyles(align: PosAlign.center, bold: true));
      } else {
        bytes += generator.text('يرجى التجهيز بسرعة!', styles: const PosStyles(align: PosAlign.center, bold: true));
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      // --- التوجيه التلقائي المحدث والآمن (يعتمد على الـ IP مباشرة إن وجد) ---
      final ip = (printer['ip'] ?? '').trim();
      final mac = (printer['macAddress'] ?? '').trim();

      if (ip.isNotEmpty && ip != '0.0.0.0' && ip != 'null') {
        try {
          debugPrint('جاري الطباعة عبر الشبكة (IP) للطابعة ${printer['name']} على العنوان: $ip...');
          final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 10));
          socket.add(bytes);
          await socket.flush();
          await Future.delayed(const Duration(milliseconds: 800));
          await socket.close();
          debugPrint('تمت الطباعة عبر الشبكة بنجاح.');
        } catch (socketErr) {
          debugPrint('فشل الاتصال بالـ IP الخاص بالطابعة: $socketErr');
        }
      } else if (mac.isNotEmpty) {
        try {
          await PrintBluetoothThermal.disconnect;
        } catch (_) {}

        debugPrint('جاري الاتصال بالطابعة عبر البلوتوث MAC: $mac...');
        bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if (connected) {
          await Future.delayed(const Duration(milliseconds: 300));
          await PrintBluetoothThermal.writeBytes(bytes);
          await Future.delayed(const Duration(milliseconds: 500));
          await PrintBluetoothThermal.disconnect;
          debugPrint('تمت الطباعة عبر البلوتوث بنجاح.');
        }
      } else {
        debugPrint('خطأ: لم يتم العثور على عنوان IP أو MAC صالح للطابعة ${printer['name']}.');
      }
    } catch (e) {
      debugPrint('خطأ أثناء إرسال الطباعة للطابعة ${printer['name']}: $e');
    }
  }
}
