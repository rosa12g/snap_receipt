import 'item_data.dart';

class ReceiptData {
  final String storeName;
  final DateTime purchaseDate;
  final String currency;
  final double totalAmount;
  final List<ItemData> items;
  final Map<String, double> confidence;
  final String? rawText;

  const ReceiptData({
    required this.storeName,
    required this.purchaseDate,
    required this.currency,
    required this.totalAmount,
    required this.items,
    required this.confidence,
    this.rawText,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'purchaseDate': purchaseDate.toIso8601String(),
        'currency': currency,
        'totalAmount': totalAmount,
        'items': items.map((e) => e.toJson()).toList(),
        'confidence': confidence,
        if (rawText != null) 'rawText': rawText,
      };
}



