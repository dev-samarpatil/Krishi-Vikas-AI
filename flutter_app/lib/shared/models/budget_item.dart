class BudgetItem {
  final String item;
  final String quantity;
  final double priceInr;

  const BudgetItem({
    required this.item,
    required this.quantity,
    required this.priceInr,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      item: json['item'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      priceInr: (json['price_inr'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'quantity': quantity,
        'price_inr': priceInr,
      };
}
