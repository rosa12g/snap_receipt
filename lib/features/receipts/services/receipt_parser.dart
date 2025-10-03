import 'dart:math';

import '../models/item_data.dart';

class ParsedReceipt {
  final String storeName;
  final DateTime purchaseDate;
  final String currency;
  final double totalAmount;
  final List<ItemData> items;
  final Map<String, double> confidence;

  ParsedReceipt({
    required this.storeName,
    required this.purchaseDate,
    required this.currency,
    required this.totalAmount,
    required this.items,
    required this.confidence,
  });
}

class ReceiptParser {
  ParsedReceipt parse(String rawText) {
    final normalized = _convertEasternArabicDigits(rawText);
    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final storeName = _parseStoreName(lines);
    final date = _parseDate(normalized) ?? DateTime.now();
    final currency = _detectCurrency(normalized);
    final total = _parseTotal(lines) ?? 0.0;
    final items = _parseItems(lines);

    final sumLines = items.map((e) => e.lineTotal ?? 0.0).fold(0.0, (a, b) => a + b);
    final deviation = (sumLines - total).abs();

    final confidence = <String, double>{
      'storeName': storeName == 'Unknown Store' ? 0.4 : 0.8,
      'purchaseDate': _dateConfidence,
      'totalAmount': total > 0 ? 0.9 : 0.3,
      'items': items.isNotEmpty ? 0.7 : 0.3,
      'validation': deviation <= 2.5 ? 0.9 : max(0.3, 1 - deviation / max(1, total)),
    };

    return ParsedReceipt(
      storeName: storeName,
      purchaseDate: date.toUtc(),
      currency: currency,
      totalAmount: _round2(total),
      items: items
          .map((e) => ItemData(
                name: e.name,
                quantity: e.quantity != null ? _round2(e.quantity!) : null,
                unitPrice: e.unitPrice != null ? _round2(e.unitPrice!) : null,
                lineTotal: e.lineTotal != null ? _round2(e.lineTotal!) : null,
              ))
          .toList(),
      confidence: confidence,
    );
  }

  String _parseStoreName(List<String> lines) {
    for (final l in lines.take(5)) {
      final clean = l.replaceAll(RegExp(r'[^A-Za-z\s&.,-]'), '').trim();
      if (clean.isNotEmpty && clean.length >= 3) {
        return clean;
      }
    }
    return 'Unknown Store';
  }

  double? _parseTotal(List<String> lines) {
    final regex = RegExp(r'(grand\s*total|total|etb|ብር)', caseSensitive: false);
    for (final l in lines.reversed) {
      if (regex.hasMatch(l) && !RegExp(r'(sub\s*total|vat|tax|discount)', caseSensitive: false).hasMatch(l)) {
        final m = RegExp(r'(\d+[\d,]*\.?\d{0,2})').allMatches(l).lastOrNull;
        if (m != null) {
          return double.tryParse(m.group(1)!.replaceAll(',', ''));
        }
      }
    }
    return null;
  }

  DateTime? _parseDate(String text) {
    _dateConfidence = 0.4;
    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}:\d{2}(?::\d{2})?)Z?)?');
    final dmy = RegExp(r'\b(\d{2})/(\d{2})/(\d{4})\b');
    final dMonY = RegExp(r'\b(\d{2})[-\s]?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[-\s]?((?:20)?\d{2})\b', caseSensitive: false);
    final mIso = iso.firstMatch(text);
    if (mIso != null) {
      _dateConfidence = 0.9;
      return DateTime.parse(mIso.group(0)!);
    }
    final mDmy = dmy.firstMatch(text);
    if (mDmy != null) {
      _dateConfidence = 0.75;
      final d = int.parse(mDmy.group(1)!);
      final m = int.parse(mDmy.group(2)!);
      final y = int.parse(mDmy.group(3)!);
      return DateTime(y, m, d);
    }
    final mDMY = dMonY.firstMatch(text);
    if (mDMY != null) {
      _dateConfidence = 0.7;
      final d = int.parse(mDMY.group(1)!);
      final monthStr = mDMY.group(2)!.substring(0, 3).toLowerCase();
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final y = int.parse(mDMY.group(3)!.length == 2 ? '20${mDMY.group(3)!}' : mDMY.group(3)!);
      return DateTime(y, months[monthStr]!, d);
    }
    return null;
  }

  List<ItemData> _parseItems(List<String> lines) {
    final List<ItemData> items = [];
    final pattern1 = RegExp(r'^([A-Za-z].*?)\s+(\d+)\s*[x\*]\s*(\d+[\d,]*\.?\d{0,2})\s+(\d+[\d,]*\.?\d{0,2})$');
    final pattern2 = RegExp(r'^([A-Za-z].*?)\s+(\d+[\d,]*\.?\d{0,2})$');
    for (final l in lines) {
      final m1 = pattern1.firstMatch(l);
      if (m1 != null) {
        final name = m1.group(1)!.trim();
        final qty = double.tryParse(m1.group(2)!);
        final unit = double.tryParse(m1.group(3)!.replaceAll(',', ''));
        final line = double.tryParse(m1.group(4)!.replaceAll(',', ''));
        items.add(ItemData(name: name, quantity: qty, unitPrice: unit, lineTotal: line));
        continue;
      }
      final m2 = pattern2.firstMatch(l);
      if (m2 != null) {
        final name = m2.group(1)!.trim();
        final amount = double.tryParse(m2.group(2)!.replaceAll(',', ''));
        items.add(ItemData(name: name, lineTotal: amount));
      }
    }
    return items;
  }

  String _detectCurrency(String text) {
    return text.contains(RegExp(r'(ETB|ብር)', caseSensitive: false)) ? 'ETB' : 'ETB';
  }

  String _convertEasternArabicDigits(String input) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const western = '0123456789';
    final map = {
      for (int i = 0; i < eastern.length; i++) eastern[i]: western[i],
    };
    return input.split('').map((c) => map[c] ?? c).join();
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}

extension _MatchesExt on Iterable<RegExpMatch> {
  RegExpMatch? get lastOrNull => isEmpty ? null : last;
}

double _dateConfidence = 0.4;




