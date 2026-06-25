import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Persists outgoing messages locally when offline and replays them on reconnect.
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'offline_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Adds a message payload to the local queue.
  /// [type] — e.g. 'text', 'image', 'voice'
  /// [payload] — a JSON-encodable map with all fields needed to replay the send
  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    try {
      final db = await _database;
      await db.insert('offline_queue', {
        'type': type,
        'payload': jsonEncode(payload),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('[OfflineQueue] Enqueued $type message');
    } catch (e) {
      debugPrint('[OfflineQueue] Error enqueuing: $e');
    }
  }

  /// Returns all queued items ordered by creation time.
  Future<List<Map<String, dynamic>>> getPending() async {
    final db = await _database;
    final rows = await db.query('offline_queue', orderBy: 'createdAt ASC');
    return rows.map((r) {
      return {
        'id': r['id'],
        'type': r['type'],
        'payload': jsonDecode(r['payload'] as String) as Map<String, dynamic>,
        'createdAt': r['createdAt'],
      };
    }).toList();
  }

  /// Removes a successfully sent item from the queue.
  Future<void> remove(int id) async {
    final db = await _database;
    await db.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Flushes all queued text messages via [sender].
  /// [sender] is a callback that takes a payload and performs the actual send.
  /// Items are removed on success; kept on failure.
  Future<void> flush(
      Future<void> Function(String type, Map<String, dynamic> payload)
          sender) async {
    final pending = await getPending();
    if (pending.isEmpty) return;
    debugPrint('[OfflineQueue] Flushing ${pending.length} queued messages');
    for (final item in pending) {
      try {
        await sender(item['type'] as String,
            item['payload'] as Map<String, dynamic>);
        await remove(item['id'] as int);
      } catch (e) {
        debugPrint('[OfflineQueue] Flush failed for item ${item['id']}: $e');
        // Keep in queue for next retry
      }
    }
  }
}
