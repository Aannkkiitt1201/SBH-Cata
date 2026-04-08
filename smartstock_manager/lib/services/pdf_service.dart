import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/stock_item.dart';

class PdfService {
  Future<Uint8List> generateStockPdf(List<StockItem> items) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    final rows = <pw.TableRow>[];

    for (final item in items) {
      pw.Widget imageWidget = pw.Container(
        width: 50,
        height: 50,
        color: PdfColors.grey300,
        alignment: pw.Alignment.center,
        child: pw.Text('No Image', style: const pw.TextStyle(fontSize: 8)),
      );

      final imageFile = File(item.imagePath);
      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();
        imageWidget = pw.Image(
          pw.MemoryImage(bytes),
          width: 50,
          height: 50,
          fit: pw.BoxFit.cover,
        );
      }

      rows.add(
        pw.TableRow(
          children: [
            _cell(item.name),
            _cell(item.quantity.toString()),
            _cell(formatter.format(item.price)),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: imageWidget,
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SmartStock Manager',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _headerCell('Item Name'),
                  _headerCell('Qty'),
                  _headerCell('Price'),
                  _headerCell('Image'),
                ],
              ),
              ...rows,
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<String> savePdfToLocal(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(
      dir.path,
      'stock_export_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> sharePdf(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'stock_export.pdf');
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
