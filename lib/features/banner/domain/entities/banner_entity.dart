class BannerEntity {
  final int id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;

  BannerEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.isActive,
  });
}
