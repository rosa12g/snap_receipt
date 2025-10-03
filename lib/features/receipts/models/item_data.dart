class ItemData {
  final String name;
  final double? quantity;
  final double? unitPrice;
  final double? lineTotal;

  const ItemData({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
  });

  ItemData copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
  }) {
    return ItemData(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (lineTotal != null) 'lineTotal': lineTotal,
      };
}



