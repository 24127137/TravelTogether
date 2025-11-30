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
<<<<<<< HEAD
  final double rating;
  final List<String> tags;
  final String location;
  final String descriptionVi; // Tiếng Việt
  final String descriptionEn; // English
  final String cityId;
=======
  final double rating; // kept, but constructor will provide default
  final List<String> tags;
  final String location;
  final String description;
  final String cityId; // Add cityId to associate destinations with cities
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

  const Destination({
    required this.id,
    required this.name,
    required this.province,
    required this.imagePath,
    double rating = 0.0,
    required this.tags,
    required this.location,
<<<<<<< HEAD
    required this.descriptionVi,
    required this.descriptionEn,
    required this.cityId,
  }) : rating = rating;

  // Getter để lấy description theo ngôn ngữ hiện tại
  String getDescription(String languageCode) {
    return languageCode == 'vi' ? descriptionVi : descriptionEn;
  }

=======
    required this.description,
    required this.cityId, // Initialize cityId
  }) : rating = rating;

>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
  // copyWith method to create a new instance with updated properties.
  Destination copyWith({
    String? id,
    String? name,
    String? province,
    String? imagePath,
    double? rating,
    List<String>? tags,
    String? location,
<<<<<<< HEAD
    String? descriptionVi,
    String? descriptionEn,
    String? cityId,
=======
    String? description,
    String? cityId, // Add cityId to copyWith
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      location: location ?? this.location,
<<<<<<< HEAD
      descriptionVi: descriptionVi ?? this.descriptionVi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      cityId: cityId ?? this.cityId,
=======
      description: description ?? this.description,
      cityId: cityId ?? this.cityId, // Copy cityId
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
    );
  }
}
