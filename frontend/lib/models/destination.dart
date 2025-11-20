/// File: destination.dart
/// Description: Defines the data model for a travel destination.
///
/// This class encapsulates all the properties related to a destination, making it
/// easy to manage and pass destination data throughout the application.

class Destination {
  final String id;
  final String name;
  final String province;
  final String imagePath;
  final double rating;
  final List<String> tags;
  final String location;
  final String descriptionVi; // Tiếng Việt
  final String descriptionEn; // English
  final String cityId;

  const Destination({
    required this.id,
    required this.name,
    required this.province,
    required this.imagePath,
    double rating = 0.0,
    required this.tags,
    required this.location,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.cityId,
  }) : rating = rating;

  // Getter để lấy description theo ngôn ngữ hiện tại
  String getDescription(String languageCode) {
    return languageCode == 'vi' ? descriptionVi : descriptionEn;
  }

  // copyWith method to create a new instance with updated properties.
  Destination copyWith({
    String? id,
    String? name,
    String? province,
    String? imagePath,
    double? rating,
    List<String>? tags,
    String? location,
    String? descriptionVi,
    String? descriptionEn,
    String? cityId,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      descriptionVi: descriptionVi ?? this.descriptionVi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      cityId: cityId ?? this.cityId,
    );
  }
}
