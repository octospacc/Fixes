import 'package:uuid/uuid.dart';
import '../l10n/generated/app_localizations.dart';

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
  static List<Map<String, String>> forLocale(AppLocalizations l) => [
        {'name': l.presetCoffeeName, 'category': l.presetCoffeeCategory},
        {'name': l.presetCigaretteName, 'category': l.presetCigaretteCategory},
        {'name': l.presetTeaName, 'category': l.presetTeaCategory},
        {'name': l.presetChipsName, 'category': l.presetChipsCategory},
        {'name': l.presetScratchName, 'category': l.presetScratchCategory},
        {'name': l.presetLunchName, 'category': l.presetLunchCategory},
        {'name': l.presetGamingName, 'category': l.presetGamingCategory},
      ];
}