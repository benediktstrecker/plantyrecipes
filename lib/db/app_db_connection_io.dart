// lib/db/app_db_connection_io.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Öffnet die native SQLite-DB (Android/iOS/Desktop)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'planty.sqlite'));
    return NativeDatabase(file, logStatements: true);
  });
}
