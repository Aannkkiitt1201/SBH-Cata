class StockItem {
  final int? id;
  final String name;
  final String category;
  final int quantity;
  final double price;
  final String? description;
  final DateTime date;
  final String imagePath;

  const StockItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    required this.description,
    required this.date,
    required this.imagePath,
  });

  double get totalValue => quantity * price;

  StockItem copyWith({
    int? id,
    String? name,
    String? category,
    int? quantity,
    double? price,
    String? description,
    DateTime? date,
    String? imagePath,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      description: description ?? this.description,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'price': price,
      'description': description,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      imagePath: map['imagePath'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem.fromMap(json);
}
