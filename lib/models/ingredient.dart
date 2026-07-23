class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final String original;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.original,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Bahan';
    final amount = (json['amount'] as num?)?.toDouble() ?? 1.0;
    final unit = json['unit']?.toString() ?? '';
    return Ingredient(
      name: name,
      amount: amount,
      unit: unit,
      original: json['original']?.toString() ?? '$amount $unit $name'.trim(),
    );
  }

  String toDisplayString() {
    final suffix = unit.isEmpty ? '' : ' $unit';
    final amountStr = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
    return '$name ($amountStr$suffix)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'original': original,
    };
  }

  static Ingredient fromDisplayString(String display) {
    // Parse strings like "Nasi (2 cups)" or "Telur (3 )"
    final regex = RegExp(r'^(.+?)\s*\(([\d.]+)\s*(.*?)\)\s*$');
    final match = regex.firstMatch(display);
    if (match != null) {
      return Ingredient(
        name: match.group(1)!.trim(),
        amount: double.tryParse(match.group(2) ?? '1') ?? 1.0,
        unit: match.group(3)?.trim() ?? '',
        original: display,
      );
    }
    return Ingredient(
      name: display,
      amount: 1.0,
      unit: '',
      original: display,
    );
  }
}
