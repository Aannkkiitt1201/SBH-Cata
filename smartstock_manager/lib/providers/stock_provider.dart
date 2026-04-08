import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/stock_item.dart';
import '../services/image_service.dart';

class StockProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final ImageService _imageService = ImageService();

  List<StockItem> _items = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<StockItem> get allItems => _items;
  String get selectedCategory => _selectedCategory;

  Future<void> loadStockItems() async {
    _items = await _databaseHelper.getStockItems();
    notifyListeners();
  }

  Future<void> addStockItem(StockItem item) async {
    await _databaseHelper.insertStockItem(item);
    await loadStockItems();
  }

  Future<void> updateStockItem(StockItem item) async {
    await _databaseHelper.updateStockItem(item);
    await loadStockItems();
  }

  Future<void> deleteStockItem(StockItem item) async {
    if (item.id == null) return;
    await _databaseHelper.deleteStockItem(item.id!);
    await _imageService.deleteImageIfExists(item.imagePath);
    await loadStockItems();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<String> get categories {
    final set = _items.map((e) => e.category).toSet().toList()..sort();
    return ['All', ...set];
  }

  List<StockItem> get filteredItems {
    return _items.where((item) {
      final searchMatch = item.name.toLowerCase().contains(_searchQuery);
      final categoryMatch =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return searchMatch && categoryMatch;
    }).toList();
  }

  int get totalItemsCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalStockValue =>
      _items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));

  List<StockItem> lowStockItems({int threshold = 5}) =>
      _items.where((item) => item.quantity < threshold).toList();

  Future<void> cleanUpMissingImages() async {
    for (final item in _items) {
      final imageFile = File(item.imagePath);
      if (!await imageFile.exists()) {
        final updated = item.copyWith(imagePath: '');
        await _databaseHelper.updateStockItem(updated);
      }
    }
    await loadStockItems();
  }
}
