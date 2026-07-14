/// Web 平台的本地缓存占位实现。
///
/// 浏览器环境没有 sqflite（底层依赖 dart:ffi），回忆数据直接走 Supabase 实时读取，
/// 因此这里只提供与原生实现完全一致的接口，方法体为空操作，保证 Web 编译通过且运行不报错。
class LocalDb {
  static Future<void> cacheMemory(Map<String, dynamic> m) async {}

  static Future<List<Map<String, dynamic>>> cachedMemories() async => [];

  static Future<void> saveLastLocation(double lat, double lng) async {}
}
