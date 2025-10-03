import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';
import 'package:snap_receipt/features/receipts/services/ocr_service.dart';
import 'package:snap_receipt/features/receipts/models/receipt_data.dart';
import 'package:snap_receipt/features/receipts/models/item_data.dart';
import 'package:snap_receipt/features/receipts/services/offline_queue.dart';
import 'package:snap_receipt/shared/utils/image_utils.dart';

class OCRScreen extends StatefulWidget {
  final File imageFile;

  const OCRScreen({super.key, required this.imageFile});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final OcrService _ocr = OcrService();
  String? _rawText;
  String? _error;
  bool _loading = true;
  ReceiptData? _parsed;
  bool _editing = false;
  ReceiptData? _editable;
  final OfflineQueueService _queue = OfflineQueueService();

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  Future<void> _runOcr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _ocr.processImage(XFile(widget.imageFile.path));
      if (!mounted) return;
      setState(() {
        _parsed = result;
        _rawText = result.rawText ?? '';
        _loading = false;
        _editable = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'OCR failed: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Widget _buildField({required String label, required String value, bool readOnly = true, TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    if (readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value),
        ],
      );
    }
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      readOnly: false,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  Widget _buildItemRow(int index, ItemData item) {
    if (!_editing) {
      final parts = <String>[item.name];
      if (item.quantity != null) parts.add('x${item.quantity}');
      if (item.unitPrice != null) parts.add('@${item.unitPrice}');
      if (item.lineTotal != null) parts.add('= ${item.lineTotal}');
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(parts.join('  ')),
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (v) => setState(() {
              final list = [..._editable!.items];
              list[index] = item.copyWith(name: v);
              _editable = ReceiptData(
                storeName: _editable!.storeName,
                purchaseDate: _editable!.purchaseDate,
                currency: _editable!.currency,
                totalAmount: _editable!.totalAmount,
                items: list,
                confidence: _editable!.confidence,
                rawText: _editable!.rawText,
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: item.quantity?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Qty'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {
              final list = [..._editable!.items];
              list[index] = item.copyWith(quantity: double.tryParse(v));
              _editable = ReceiptData(
                storeName: _editable!.storeName,
                purchaseDate: _editable!.purchaseDate,
                currency: _editable!.currency,
                totalAmount: _editable!.totalAmount,
                items: list,
                confidence: _editable!.confidence,
                rawText: _editable!.rawText,
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: item.unitPrice?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Unit'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {
              final list = [..._editable!.items];
              list[index] = item.copyWith(unitPrice: double.tryParse(v));
              _editable = ReceiptData(
                storeName: _editable!.storeName,
                purchaseDate: _editable!.purchaseDate,
                currency: _editable!.currency,
                totalAmount: _editable!.totalAmount,
                items: list,
                confidence: _editable!.confidence,
                rawText: _editable!.rawText,
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: item.lineTotal?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Total'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {
              final list = [..._editable!.items];
              list[index] = item.copyWith(lineTotal: double.tryParse(v));
              _editable = ReceiptData(
                storeName: _editable!.storeName,
                purchaseDate: _editable!.purchaseDate,
                currency: _editable!.currency,
                totalAmount: _editable!.totalAmount,
                items: list,
                confidence: _editable!.confidence,
                rawText: _editable!.rawText,
              );
            }),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() {
            final list = [..._editable!.items]..removeAt(index);
            _editable = ReceiptData(
              storeName: _editable!.storeName,
              purchaseDate: _editable!.purchaseDate,
              currency: _editable!.currency,
              totalAmount: _editable!.totalAmount,
              items: list,
              confidence: _editable!.confidence,
              rawText: _editable!.rawText,
            );
          }),
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    if (_editable == null) return;
    // Compress image (base64) for storage payload demo (no backend)
    final compressed = await ImageUtils.compressToJpegBase64(widget.imageFile);
    final payload = _editable!.toJson();
    payload['image'] = {
      'mimeType': compressed.mimeType,
      'base64': compressed.base64Data,
      'width': compressed.width,
      'height': compressed.height,
    };
    await _queue.init();
    await _queue.enqueue(payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to offline queue')));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppThemeConstants.errorColor)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Image preview
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),

                    // Parsed section (read-only or editable)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppThemeConstants.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Parsed Receipt', style: TextStyle(fontSize: AppThemeConstants.titleFontSize, fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: Icon(_editing ? Icons.visibility : Icons.edit),
                                tooltip: _editing ? 'View' : 'Edit',
                                onPressed: () => setState(() => _editing = !_editing),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          _buildField(
                            label: 'Store Name',
                            readOnly: !_editing,
                            value: _editable!.storeName,
                            onChanged: (v) => setState(() {
                              _editable = ReceiptData(
                                storeName: v,
                                purchaseDate: _editable!.purchaseDate,
                                currency: _editable!.currency,
                                totalAmount: _editable!.totalAmount,
                                items: _editable!.items,
                                confidence: _editable!.confidence,
                                rawText: _editable!.rawText,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          _buildField(
                            label: 'Purchase Date',
                            readOnly: true,
                            value: _editable!.purchaseDate.toIso8601String(),
                          ),
                          const SizedBox(height: 8),
                          _buildField(
                            label: 'Total (${_editable!.currency})',
                            readOnly: !_editing,
                            value: _editable!.totalAmount.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() {
                              final t = double.tryParse(v) ?? _editable!.totalAmount;
                              _editable = ReceiptData(
                                storeName: _editable!.storeName,
                                purchaseDate: _editable!.purchaseDate,
                                currency: _editable!.currency,
                                totalAmount: t,
                                items: _editable!.items,
                                confidence: _editable!.confidence,
                                rawText: _editable!.rawText,
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          const Text('Items'),
                          const SizedBox(height: 6),
                          ..._editable!.items.asMap().entries.map((e) => _buildItemRow(e.key, e.value)).toList(),
                          if (_editing)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _editable = ReceiptData(
                                    storeName: _editable!.storeName,
                                    purchaseDate: _editable!.purchaseDate,
                                    currency: _editable!.currency,
                                    totalAmount: _editable!.totalAmount,
                                    items: [..._editable!.items, const ItemData(name: 'New Item')],
                                    confidence: _editable!.confidence,
                                    rawText: _editable!.rawText,
                                  );
                                }),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Raw text under it
                    Padding(
                      padding: const EdgeInsets.all(AppThemeConstants.pagePadding),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppThemeConstants.cardColor,
                          borderRadius: BorderRadius.circular(AppThemeConstants.cardRadius),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Text((_rawText ?? '').isEmpty ? 'No text detected.' : _rawText!),
                      ),
                    ),

                    // Submit button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppThemeConstants.pagePadding),
                      child: ElevatedButton.icon(
                        onPressed: _onSubmit,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
