import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/banner/presentation/banner_controller.dart';
// Optional: Uncomment if you want to open URLs
// import 'package:url_launcher/url_launcher.dart';

class BannerWidget extends ConsumerWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(bannerProvider);
    final isVisible = ref.watch(isBannerVisibleProvider);

    if (banner == null || !isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            // Optional: open target URL when tapped
            // final uri = Uri.tryParse(banner.targetUrl);
            // if (uri != null && await canLaunchUrl(uri)) {
            //   await launchUrl(uri, mode: LaunchMode.externalApplication);
            // }
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(banner.imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 18,
          child: GestureDetector(
            onTap: () async {
              // Dismiss and persist
              await ref.read(bannerProvider.notifier).dismissBanner();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
