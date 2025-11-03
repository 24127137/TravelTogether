/// Model cho một địa điểm trong Explore Screen
class DestinationExploreItem {
  final String id;
  final String cityId; // Thêm trường cityId
  final String name;
  final String subtitle;
  final String location;
  final String imageUrl;
  final double rating; // Restore rating for explore items
  bool isFavorite; // Added isFavorite field

  DestinationExploreItem({
    required this.id,
    required this.cityId,
    required this.name,
    required this.subtitle,
    required this.location,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = false, // Default value
  });
}
