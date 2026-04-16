import 'package:dngo/core/config/app_config.dart';
/// Model cho search response
class SearchResponse {
  final bool success;
  final SearchData data;

  SearchResponse({
    required this.success,
    required this.data,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? SearchData.fromJson(json['data'] as Map<String, dynamic>)
          : SearchData(stalls: [], dishes: [], ingredients: []),
    );
  }
}

class SearchData {
  final List<SearchStall> stalls;
  final List<SearchDish> dishes;
  final List<SearchIngredient> ingredients;

  SearchData({
    required this.stalls,
    required this.dishes,
    required this.ingredients,
  });

  factory SearchData.fromJson(Map<String, dynamic> json) {
    return SearchData(
      stalls: (json['stalls'] as List?)
              ?.map((item) => SearchStall.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      dishes: (json['dishes'] as List?)
              ?.map((item) => SearchDish.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List?)
              ?.map((item) => SearchIngredient.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isEmpty => stalls.isEmpty && dishes.isEmpty && ingredients.isEmpty;
  int get totalResults => stalls.length + dishes.length + ingredients.length;
}

class SearchStall {
  final String id;
  final String name;
  final String type;
  final String? image;

  SearchStall({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });

  factory SearchStall.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['image'] as String? ?? json['hinh_anh'] as String?;
    String? processedImage = rawImage != null
        ? (rawImage.contains('http') ? rawImage : '${AppConfig.baseUrl}$rawImage')
        : null;
    return SearchStall(
      id: (json['id'] ?? json['ma_gian_hang'] ?? '').toString(),
      name: (json['name'] ?? json['ten_gian_hang'] ?? '').toString(),
      type: (json['type'] ?? 'stall').toString(),
      image: processedImage,
    );
  }
}

class SearchDish {
  final String id;
  final String name;
  final String type;
  final String? image;

  SearchDish({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });

  factory SearchDish.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['image'] as String? ?? json['hinh_anh'] as String?;
    String? processedImage = rawImage != null
        ? (rawImage.contains('http') ? rawImage : '${AppConfig.baseUrl}$rawImage')
        : null;
    return SearchDish(
      id: (json['id'] ?? json['ma_mon_an'] ?? '').toString(),
      name: (json['name'] ?? json['ten_mon_an'] ?? '').toString(),
      type: (json['type'] ?? 'dish').toString(),
      image: processedImage,
    );
  }
}

class SearchIngredient {
  final String id;
  final String name;
  final String type;
  final String? image;

  SearchIngredient({
    required this.id,
    required this.name,
    required this.type,
    this.image,
  });

  factory SearchIngredient.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['image'] as String? ?? json['hinh_anh'] as String?;
    String? processedImage = rawImage != null
        ? (rawImage.contains('http') ? rawImage : '${AppConfig.baseUrl}$rawImage')
        : null;
    return SearchIngredient(
      id: (json['id'] ?? json['ma_nguyen_lieu'] ?? '').toString(),
      name: (json['name'] ?? json['ten_nguyen_lieu'] ?? '').toString(),
      type: (json['type'] ?? 'ingredient').toString(),
      image: processedImage,
    );
  }
}
