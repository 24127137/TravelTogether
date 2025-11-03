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
  final double rating; // kept, but constructor will provide default
  final List<String> tags;
  final String location;
  final String description;
  final String cityId; // Add cityId to associate destinations with cities

  const Destination({
    required this.id,
    required this.name,
    required this.province,
    required this.imagePath,
    double rating = 0.0,
    required this.tags,
    required this.location,
    required this.description,
    required this.cityId, // Initialize cityId
  }) : rating = rating;

  // copyWith method to create a new instance with updated properties.
  Destination copyWith({
    String? id,
    String? name,
    String? province,
    String? imagePath,
    double? rating,
    List<String>? tags,
    String? location,
    String? description,
    String? cityId, // Add cityId to copyWith
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      description: description ?? this.description,
      cityId: cityId ?? this.cityId, // Copy cityId
    );
  }
}
