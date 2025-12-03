/// Model cho một địa điểm trong Explore Screen
class DestinationExploreItem {
  final String id;
  final String cityId;
  final String name;
  final String subtitleVi; // Tiếng Việt
  final String subtitleEn; // English
  final String location;
  final String imageUrl;
  final double rating;
  final String description;
  bool isFavorite;

  DestinationExploreItem({
    required this.id,
    required this.cityId,
    required this.name,
    required this.subtitleVi,
    required this.subtitleEn,
    required this.location,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = false,
    this.description = "Thông tin chi tiết đang được cập nhật...",
  });

  // Getter để lấy subtitle theo ngôn ngữ hiện tại
  String getSubtitle(String languageCode) {
    return languageCode == 'vi' ? subtitleVi : subtitleEn;
  }
}
