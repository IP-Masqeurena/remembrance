import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  DBService._privateConstructor();
  static final DBService instance = DBService._privateConstructor();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'remembrance.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        question_indices TEXT NOT NULL, -- JSON array of ints
        created_at TEXT NOT NULL,
        best_score INTEGER DEFAULT -1
      )
    ''');

    await db.execute('''
      CREATE TABLE attempts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        attempted_at TEXT NOT NULL,
        FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  // Create a session and return its id
  Future<int> createSession(String mode, List<int> questionIndices) async {
    final dbClient = await db;
    final createdAt = DateTime.now().toIso8601String();
    final res = await dbClient.insert('sessions', {
      'mode': mode,
      'question_indices': jsonEncode(questionIndices),
      'created_at': createdAt,
      'best_score': -1,
    });
    return res;
  }

Future<Map<String, dynamic>?> getSession(int sessionId) async {
  final dbClient = await db;
  final maps = await dbClient.query(
    'sessions',
    columns: ['id', 'mode', 'question_indices', 'created_at', 'best_score'],
    where: 'id = ?',
    whereArgs: [sessionId],
  );

  if (maps.isNotEmpty) {
    // make a mutable copy so we can modify fields
    final m = Map<String, dynamic>.from(maps.first);
    m['question_indices'] =
        (jsonDecode(m['question_indices'] as String) as List).cast<int>();
    return m;
  }
  return null;
}


  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final dbClient = await db;
    final rows = await dbClient.query('sessions', orderBy: 'created_at DESC');
    return rows.map((r) {
      final copy = Map<String, dynamic>.from(r);
      copy['question_indices'] =
          (jsonDecode(copy['question_indices'] as String) as List).cast<int>();
      return copy;
    }).toList();
  }

  // Record an attempt and update best_score if needed
  Future<void> recordAttempt(int? sessionId, int score, int total) async {
    final dbClient = await db;
    final now = DateTime.now().toIso8601String();
    await dbClient.insert('attempts', {
      'session_id': sessionId,
      'score': score,
      'total': total,
      'attempted_at': now,
    });

    if (sessionId != null) {
      // update best_score if this attempt is higher
      final maps = await dbClient.query('sessions',
          columns: ['best_score'], where: 'id = ?', whereArgs: [sessionId]);
      if (maps.isNotEmpty) {
        final currentBest = maps.first['best_score'] as int;
        if (score > currentBest) {
          await dbClient.update('sessions', {'best_score': score},
              where: 'id = ?', whereArgs: [sessionId]);
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAttemptsForSession(int sessionId) async {
    final dbClient = await db;
    final rows = await dbClient.query('attempts',
        where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'attempted_at DESC');
    return rows;
  }
}
