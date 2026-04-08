import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/stock_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../services/pdf_service.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/stock_item_card.dart';
import 'add_edit_stock_screen.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, provider, _) {
        final items = provider.filteredItems;

        return Scaffold(
          appBar: AppBar(
            title: const Text('SmartStock Manager'),
            actions: [
              IconButton(
                tooltip: 'Export PDF',
                onPressed: provider.allItems.isEmpty
                    ? null
                    : () => _exportPdf(context, provider),
                icon: const Icon(Icons.picture_as_pdf_rounded),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelect(context, provider, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                  PopupMenuItem(value: 'json', child: Text('Backup JSON')),
                ],
              ),
            ],
          ),
          drawer: const _AppDrawer(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DashboardSummary(
                      totalCount: provider.totalItemsCount,
                      totalValue: provider.totalStockValue,
                      lowStockCount: provider.lowStockItems().length,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by item name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: provider.setSearchQuery,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Category:'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: provider.selectedCategory,
                            items: provider.categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.setCategoryFilter(value);
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyStateWidget(
                        title: 'No stock found',
                        subtitle:
                            'Add your first item or update search/filter options.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return StockItemCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StockDetailScreen(item: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStockScreen()),
              );
            },
            label: const Text('Add Stock'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(BuildContext context, StockProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = PdfService();
      final bytes = await service.generateStockPdf(provider.allItems);
      final path = await service.savePdfToLocal(bytes);
      await service.sharePdf(bytes);
      messenger.showSnackBar(SnackBar(content: Text('PDF exported: $path')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  Future<void> _onMenuSelect(
    BuildContext context,
    StockProvider provider,
    String value,
  ) async {
    final exportService = ExportService();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (value == 'csv') {
        final path = await exportService.exportCsv(provider.allItems);
        messenger.showSnackBar(SnackBar(content: Text('CSV exported: $path')));
      } else if (value == 'json') {
        final path = await exportService.exportJson(provider.allItems);
        messenger.showSnackBar(SnackBar(content: Text('JSON backup saved: $path')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.themeMode == ThemeMode.dark;
          return ListView(
            children: [
              const DrawerHeader(
                child: Text('SmartStock Settings', style: TextStyle(fontSize: 22)),
              ),
              SwitchListTile(
                value: isDark,
                onChanged: themeProvider.toggleTheme,
                title: const Text('Dark Mode'),
                subtitle: const Text('Light + blue and dark + gold themes'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Today'),
                subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.now())),
              ),
            ],
          );
        },
      ),
    );
  }
}
