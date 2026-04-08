import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/stock_item.dart';

class ExportService {
  Future<String> exportCsv(List<StockItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Quantity,Price,Date,Description,ImagePath');
    for (final item in items) {
      buffer.writeln(
        '"${item.name}","${item.category}",${item.quantity},${item.price},'
        '${DateFormat('yyyy-MM-dd').format(item.date)},'
        '"${(item.description ?? '').replaceAll('"', '""')}",'
        '"${item.imagePath}"',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'stock_backup_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), flush: true);
    return filePath;
  }

  Future<String> exportJson(List<StockItem> items) async {
    final jsonList = items.map((e) => e.toJson()).toList();
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'stock_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final file = File(filePath);
    await file.writeAsString(jsonEncode(jsonList), flush: true);
    return filePath;
  }
}
