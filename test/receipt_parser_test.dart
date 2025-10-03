import 'package:flutter_test/flutter_test.dart';
import 'package:snap_receipt/features/receipts/services/receipt_parser.dart';

void main() {
  test('Parses totals, dates, and items from sample OCR text', () {
    const raw = '''
FreshMart Bole
Date: 2025-09-20 11:25
Items
Bread 60.00
Milk 2x 60.00 120.00
Grand Total 1543.90 ETB
''';

    final parser = ReceiptParser();
    final parsed = parser.parse(raw);

    expect(parsed.storeName.contains('FreshMart'), true);
    expect(parsed.purchaseDate.year, 2025);
    expect(parsed.totalAmount, 1543.90);
    expect(parsed.items.isNotEmpty, true);
  });
}




