import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/stock_item.dart';
import '../providers/stock_provider.dart';
import 'add_edit_stock_screen.dart';

class StockDetailScreen extends StatelessWidget {
  final StockItem item;

  const StockDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditStockScreen(item: item),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'stock-image-${item.id}-${item.imagePath}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: item.imagePath.isNotEmpty && File(item.imagePath).existsSync()
                  ? Image.file(
                      File(item.imagePath),
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 260,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 64),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Item Name', item.name),
                  _row('Category', item.category),
                  _row('Quantity', item.quantity.toString()),
                  _row('Price', currency.format(item.price)),
                  _row('Total Value', currency.format(item.totalValue)),
                  _row('Date', DateFormat('yyyy-MM-dd').format(item.date)),
                  _row('Description', item.description ?? '—'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$title:')),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (delete == true && context.mounted) {
      await context.read<StockProvider>().deleteStockItem(item);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
