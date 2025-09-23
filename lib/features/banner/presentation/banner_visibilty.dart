import 'package:shared_preferences/shared_preferences.dart';

class BannerVisibilityService {
  static const String _dismissedBannerIdKey = 'dismissed_banner_id';

  Future<void> saveDismissedBannerId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedBannerIdKey, id);
  }

  Future<int?> getDismissedBannerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dismissedBannerIdKey);
  }
}
