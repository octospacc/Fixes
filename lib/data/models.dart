import 'package:uuid/uuid.dart';

class Item {
  final String id;
  String name;
  String category;
  double? defaultPrice;

  Item({
    String? id,
    required this.name,
    this.category = '',
    this.defaultPrice,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'defaultPrice': defaultPrice,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? '',
        defaultPrice: (json['defaultPrice'] as num?)?.toDouble(),
      );
}

class Entry {
  final String id;
  final String itemId;
  double quantity;
  DateTime date;
  bool hasTime;
  double? pricePerUnit;
  String note;

  Entry({
    String? id,
    required this.itemId,
    this.quantity = 1,
    required this.date,
    this.hasTime = true,
    this.pricePerUnit,
    this.note = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'quantity': quantity,
        'date': date.toIso8601String(),
        'hasTime': hasTime,
        'pricePerUnit': pricePerUnit,
        'note': note,
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        date: DateTime.parse(json['date'] as String),
        hasTime: json['hasTime'] as bool? ?? true,
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
        note: (json['note'] as String?) ?? '',
      );
}

class StarterPresets {
  static const List<Map<String, String>> suggestions = [
    {'name': 'Coffee', 'category': 'Drink'},
    {'name': 'Cigarette', 'category': 'Smoke'},
    {'name': 'Tea', 'category': 'Drink'},
    {'name': 'Chips', 'category': 'Snack'},
    {'name': 'Scratch card', 'category': 'Gambling'},
    {'name': 'Lunch out', 'category': 'Food'},
    {'name': 'Gaming session', 'category': 'Leisure'},
  ];
}