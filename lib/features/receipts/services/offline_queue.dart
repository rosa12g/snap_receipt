import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

class OfflineQueueService {
  static const String boxName = 'receipt_queue';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(boxName);
  }

  Future<void> enqueue(Map<String, dynamic> payload) async {
    final box = Hive.box<Map>(boxName);
    await box.add(payload);
  }

  Future<List<Map>> getPending() async {
    final box = Hive.box<Map>(boxName);
    return box.values.toList();
  }

  Future<void> clear() async {
    final box = Hive.box<Map>(boxName);
    await box.clear();
  }
}




