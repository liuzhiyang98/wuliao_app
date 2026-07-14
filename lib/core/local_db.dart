// 条件导出：原生平台用 sqflite 实现，Web 平台用占位实现（浏览器无 sqflite）。
export 'local_db_native.dart' if (dart.library.html) 'local_db_web.dart';
