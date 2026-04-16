import 'package:equatable/equatable.dart';

/// Represents the state of the menu detail screen
class MenuDetailState extends Equatable {
  final String productName;
  final String productImage;
  final String description;
  final int servings;
  final String preparationTime;
  final String difficulty;
  final String recipe;
  final String nutrition;
  final int selectedBottomNavIndex;
  final int cartItemCount;
  final bool isLoading;

  const MenuDetailState({
    this.productName = '',
    this.productImage = '',
    this.description = '',
    this.servings = 2,
    this.preparationTime = '30 phút',
    this.difficulty = 'Trung bình',
    this.recipe = 'Món ngon',
    this.nutrition = '500 kcal/người',
    this.selectedBottomNavIndex = 1,
    this.cartItemCount = 2,
    this.isLoading = false,
  });

  MenuDetailState copyWith({
    String? productName,
    String? productImage,
    String? description,
    int? servings,
    String? preparationTime,
    String? difficulty,
    String? recipe,
    String? nutrition,
    int? selectedBottomNavIndex,
    int? cartItemCount,
    bool? isLoading,
  }) {
    return MenuDetailState(
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      preparationTime: preparationTime ?? this.preparationTime,
      difficulty: difficulty ?? this.difficulty,
      recipe: recipe ?? this.recipe,
      nutrition: nutrition ?? this.nutrition,
      selectedBottomNavIndex:
          selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        productName,
        productImage,
        description,
        servings,
        preparationTime,
        difficulty,
        recipe,
        nutrition,
        selectedBottomNavIndex,
        cartItemCount,
        isLoading,
      ];
}
