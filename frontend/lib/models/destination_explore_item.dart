/// Model cho một địa điểm trong Explore Screen
class DestinationExploreItem {
  final String id;
<<<<<<< HEAD
  final String cityId;
  final String name;
  final String subtitleVi; // Tiếng Việt
  final String subtitleEn; // English
  final String location;
  final String imageUrl;
  final double rating;
  bool isFavorite;
=======
  final String cityId; // Thêm trường cityId
  final String name;
  final String subtitle;
  final String location;
  final String imageUrl;
  final double rating; // Restore rating for explore items
  bool isFavorite; // Added isFavorite field
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

  DestinationExploreItem({
    required this.id,
    required this.cityId,
    required this.name,
<<<<<<< HEAD
    required this.subtitleVi,
    required this.subtitleEn,
    required this.location,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = false,
  });

  // Getter để lấy subtitle theo ngôn ngữ hiện tại
  String getSubtitle(String languageCode) {
    return languageCode == 'vi' ? subtitleVi : subtitleEn;
  }
=======
    required this.subtitle,
    required this.location,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = false, // Default value
  });
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
}
