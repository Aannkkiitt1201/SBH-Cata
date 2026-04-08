import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/stock_item.dart';

class StockItemCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;

  const StockItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'stock-image-${item.id}-${item.imagePath}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(item.imagePath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Qty: ${item.quantity}'),
                    Text(formatter.format(item.price)),
                    Text(item.category,
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(String path) {
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
