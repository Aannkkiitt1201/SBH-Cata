import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSummary extends StatelessWidget {
  final int totalCount;
  final double totalValue;
  final int lowStockCount;

  const DashboardSummary({
    super.key,
    required this.totalCount,
    required this.totalValue,
    required this.lowStockCount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Units',
            value: '$totalCount',
            icon: Icons.inventory_2_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Value',
            value: currency.format(totalValue),
            icon: Icons.attach_money_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Low Stock',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
            alert: lowStockCount > 0,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool alert;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: alert ? Colors.orange : colorScheme.primary),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
