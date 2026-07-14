import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 本地离线缓存：弱网/无网时也能翻阅回忆，联网后由仓库同步。
class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      '${dir.path}/wuliao.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE memories_cache(
            uuid TEXT PRIMARY KEY,
            type TEXT,
            content TEXT,
            media_path TEXT,
            lat REAL,
            lng REAL,
            created_at TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE last_location(
            key TEXT PRIMARY KEY,
            lat REAL,
            lng REAL,
            updated_at TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> cacheMemory(Map<String, dynamic> m) async {
    final db = await instance;
    await db.insert(
      'memories_cache',
      {
        'uuid': m['uuid'],
        'type': m['type'],
        'content': m['content'],
        'media_path': m['media_path'],
        'lat': m['lat'],
        'lng': m['lng'],
        'created_at': m['created_at'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> cachedMemories() async {
    final db = await instance;
    return db.query('memories_cache', orderBy: 'created_at DESC');
  }

  static Future<void> saveLastLocation(double lat, double lng) async {
    final db = await instance;
    await db.insert(
      'last_location',
      {
        'key': 'me',
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
