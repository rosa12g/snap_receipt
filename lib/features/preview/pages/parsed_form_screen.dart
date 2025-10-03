import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';
import 'package:snap_receipt/features/receipts/models/receipt_data.dart';
import 'package:snap_receipt/features/receipts/models/item_data.dart';
import 'package:snap_receipt/features/receipts/services/offline_queue.dart';

class ParsedFormScreen extends StatefulWidget {
  final ReceiptData receipt;
  final File? imageFile;

  const ParsedFormScreen({super.key, required this.receipt, this.imageFile});

  @override
  State<ParsedFormScreen> createState() => _ParsedFormScreenState();
}

class _ParsedFormScreenState extends State<ParsedFormScreen> {
  late ReceiptData _editable;
  final OfflineQueueService _queue = OfflineQueueService();

  @override
  void initState() {
    super.initState();
    _editable = widget.receipt;
    _queue.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Submit')),
      body: ListView(
        padding: const EdgeInsets.all(AppThemeConstants.pagePadding),
        children: [
          _ConfidenceHeader(confidence: _editable.confidence),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _editable.storeName,
            decoration: const InputDecoration(labelText: 'Store Name'),
            onChanged: (v) => setState(() {
              _editable = ReceiptData(
                storeName: v,
                purchaseDate: _editable.purchaseDate,
                currency: _editable.currency,
                totalAmount: _editable.totalAmount,
                items: _editable.items,
                confidence: _editable.confidence,
                rawText: _editable.rawText,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text('Date: ${_editable.purchaseDate.toIso8601String()}'),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _editable.totalAmount.toStringAsFixed(2),
            decoration: InputDecoration(
              labelText: 'Total (${_editable.currency})',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {
              final t = double.tryParse(v) ?? _editable.totalAmount;
              _editable = ReceiptData(
                storeName: _editable.storeName,
                purchaseDate: _editable.purchaseDate,
                currency: _editable.currency,
                totalAmount: t,
                items: _editable.items,
                confidence: _editable.confidence,
                rawText: _editable.rawText,
              );
            }),
          ),
          const SizedBox(height: 16),
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._editable.items.asMap().entries.map(
            (e) => _buildItemCard(e.key, e.value),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              final items = [
                ..._editable.items,
                const ItemData(name: 'New Item'),
              ];
              _editable = ReceiptData(
                storeName: _editable.storeName,
                purchaseDate: _editable.purchaseDate,
                currency: _editable.currency,
                totalAmount: _editable.totalAmount,
                items: items,
                confidence: _editable.confidence,
                rawText: _editable.rawText,
              );
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onSubmit,
            icon: const Icon(Icons.send),
            label: const Text('Submit (queue only)'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, ItemData item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              initialValue: item.name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => setState(() {
                final updated = item.copyWith(name: v);
                final list = [..._editable.items];
                list[index] = updated;
                _editable = ReceiptData(
                  storeName: _editable.storeName,
                  purchaseDate: _editable.purchaseDate,
                  currency: _editable.currency,
                  totalAmount: _editable.totalAmount,
                  items: list,
                  confidence: _editable.confidence,
                  rawText: _editable.rawText,
                );
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => setState(() {
                      final updated = item.copyWith(
                        quantity: double.tryParse(v),
                      );
                      final list = [..._editable.items];
                      list[index] = updated;
                      _editable = ReceiptData(
                        storeName: _editable.storeName,
                        purchaseDate: _editable.purchaseDate,
                        currency: _editable.currency,
                        totalAmount: _editable.totalAmount,
                        items: list,
                        confidence: _editable.confidence,
                        rawText: _editable.rawText,
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => setState(() {
                      final updated = item.copyWith(
                        unitPrice: double.tryParse(v),
                      );
                      final list = [..._editable.items];
                      list[index] = updated;
                      _editable = ReceiptData(
                        storeName: _editable.storeName,
                        purchaseDate: _editable.purchaseDate,
                        currency: _editable.currency,
                        totalAmount: _editable.totalAmount,
                        items: list,
                        confidence: _editable.confidence,
                        rawText: _editable.rawText,
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.lineTotal?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Line Total'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => setState(() {
                      final updated = item.copyWith(
                        lineTotal: double.tryParse(v),
                      );
                      final list = [..._editable.items];
                      list[index] = updated;
                      _editable = ReceiptData(
                        storeName: _editable.storeName,
                        purchaseDate: _editable.purchaseDate,
                        currency: _editable.currency,
                        totalAmount: _editable.totalAmount,
                        items: list,
                        confidence: _editable.confidence,
                        rawText: _editable.rawText,
                      );
                    }),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  final list = [..._editable.items]..removeAt(index);
                  _editable = ReceiptData(
                    storeName: _editable.storeName,
                    purchaseDate: _editable.purchaseDate,
                    currency: _editable.currency,
                    totalAmount: _editable.totalAmount,
                    items: list,
                    confidence: _editable.confidence,
                    rawText: _editable.rawText,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!mounted) return;

    try {
      await _queue.enqueue(_editable.toJson());

      // Show success dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppThemeConstants.successColor),
                SizedBox(width: 8),
                Text('Submitted Successfully!'),
              ],
            ),
            content: const Text('Receipt has been saved to the offline queue.'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeConstants.primaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeConstants.cardRadius),
            ),
          );
        },
      );

      if (!mounted) return;

      // Navigate back to camera screen after dialog is dismissed
      context.go('/camera');
    } catch (e) {
      if (!mounted) return;

      // Show error dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: AppThemeConstants.errorColor),
                SizedBox(width: 8),
                Text(
                  'Submission Failed',
                  style: TextStyle(color: AppThemeConstants.errorColor),
                ),
              ],
            ),
            content: Text('Error: $e'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeConstants.primaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeConstants.cardRadius),
            ),
          );
        },
      );
    }
  }
}

class _ConfidenceHeader extends StatelessWidget {
  final Map<String, double> confidence;
  const _ConfidenceHeader({required this.confidence});

  @override
  Widget build(BuildContext context) {
    bool warn = (confidence['validation'] ?? 1.0) < 0.7;
    Color badgeColor(double c) {
      if (c >= 0.85) return AppThemeConstants.successColor;
      if (c <= 0.4) return AppThemeConstants.errorColor;
      return AppThemeConstants.warningColor;
    }

    Widget chip(String label, double? c) {
      final v = c ?? 0.0;
      final color = badgeColor(v);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label ${(v * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: color),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warn)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppThemeConstants.warningColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Validation warning: item totals deviate from total',
              style: TextStyle(color: AppThemeConstants.warningColor),
            ),
          ),
        Wrap(
          children: [
            chip('Store', confidence['storeName']),
            chip('Date', confidence['purchaseDate']),
            chip('Total', confidence['totalAmount']),
            chip('Items', confidence['items']),
          ],
        ),
      ],
    );
  }
}
