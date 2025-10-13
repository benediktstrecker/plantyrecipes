// lib/db/app_db_connection_web.dart
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Öffnet die Web-DB (IndexedDB)
QueryExecutor openConnection() {
  return WebDatabase('planty_db');
}
