/// Web 平台的背景定位/地理围栏占位实现。
///
/// 浏览器出于隐私与电量考虑，不允许应用在后台持续获取位置，因此 Web 端无法做
/// 「后台持续定位」与「自动报备」推送。实时位置仍由 [location_service]（geolocator web）
/// 在前台（App 打开时）提供，地图、回忆、纪念日、足迹等功能均正常工作。
class BackgroundLocationService {
  BackgroundLocationService._();
  static final BackgroundLocationService _i = BackgroundLocationService._();
  factory BackgroundLocationService() => _i;

  /// 启动后台定位（Web 端为空操作）。
  Future<void> start() async {}

  /// 停止后台定位（Web 端为空操作）。
  Future<void> stop() async {}

  /// 刷新地理围栏（Web 端为空操作）。
  Future<void> refreshGeofences() async {}
}
