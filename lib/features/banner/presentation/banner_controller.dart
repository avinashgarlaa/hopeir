import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/banner/data/repositories/banner_repo_impl.dart';
import 'package:hop_eir/features/banner/domain/entities/banner_entity.dart';
import 'package:hop_eir/features/banner/domain/usecases/fetch_active_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StateProvider to control banner visibility
final isBannerVisibleProvider = StateProvider<bool>((ref) => true);

/// Provides the BannerController (StateNotifier) with dependencies
final bannerProvider = StateNotifierProvider<BannerController, BannerEntity?>(
  (ref) {
    final fetchBanner = ref.watch(fetchBannerUseCaseProvider);
    return BannerController(
      fetchBanner: fetchBanner,
      visibilityNotifier: ref.read(isBannerVisibleProvider.notifier),
    );
  },
);

/// Use case provider
final fetchBannerUseCaseProvider = Provider<FetchActiveBanner>((ref) {
  return FetchActiveBanner(
    ref.watch(bannerRepositoryProvider),
  );
});

/// Repository provider
final bannerRepositoryProvider = Provider((ref) {
  return BannerRepositoryImpl(
    apiUrl: 'https://hopeir.onrender.com/poster/active/get/',
  );
});

/// Key used in SharedPreferences
const _dismissedBannerIdKey = 'dismissed_banner_id';

/// The BannerController with visibility persistence logic
class BannerController extends StateNotifier<BannerEntity?> {
  final FetchActiveBanner fetchBanner;
  final StateController<bool> visibilityNotifier;

  BannerController({
    required this.fetchBanner,
    required this.visibilityNotifier,
  }) : super(null) {
    loadBanner();
  }

  /// Load banner from API and check if it's already dismissed
  Future<void> loadBanner() async {
    final banner = await fetchBanner();
    final prefs = await SharedPreferences.getInstance();
    final dismissedId = prefs.getInt(_dismissedBannerIdKey);

    if (banner == null) {
      visibilityNotifier.state = false;
      return;
    }

    // Save the fetched banner ID if it's new (first time loaded)
    if (dismissedId == null) {
      await prefs.setInt(_dismissedBannerIdKey, banner.id);
      state = banner;
      visibilityNotifier.state = true;
      return;
    }

    // If already saved and it's the same ID, hide it
    if (banner.id == dismissedId) {
      visibilityNotifier.state = false;
      return;
    }

    // If it's a new banner ID, show it and update stored ID
    await prefs.setInt(_dismissedBannerIdKey, banner.id);
    state = banner;
    visibilityNotifier.state = true;
  }

  /// Dismiss the current banner and persist its ID
  Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    if (state != null) {
      await prefs.setInt(_dismissedBannerIdKey, state!.id);
      visibilityNotifier.state = false;
    }
  }
}
