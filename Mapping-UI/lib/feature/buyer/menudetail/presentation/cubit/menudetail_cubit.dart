import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../feature/buyer/menudetail/presentation/cubit/menudetail_state.dart';

/// Cubit for managing menu detail screen state
class MenuDetailCubit extends Cubit<MenuDetailState> {
  MenuDetailCubit() : super(const MenuDetailState());

  /// Initialize menu details
  void loadMenuDetails({
    required String productName,
    required String productImage,
    required String description,
  }) {
    emit(state.copyWith(
      productName: productName,
      productImage: productImage,
      description: description,
      isLoading: false,
    ));
  }

  /// Update servings quantity
  void updateServings(int servings) {
    if (servings > 0) {
      emit(state.copyWith(servings: servings));
    }
  }

  /// Increment servings
  void incrementServings() {
    emit(state.copyWith(servings: state.servings + 1));
  }

  /// Decrement servings
  void decrementServings() {
    if (state.servings > 1) {
      emit(state.copyWith(servings: state.servings - 1));
    }
  }

  /// Handle bottom navigation tap
  void onBottomNavTap(int index) {
    emit(state.copyWith(selectedBottomNavIndex: index));
  }

  /// Add to cart
  void addToCart() {
    emit(state.copyWith(cartItemCount: state.cartItemCount + 1));
  }

  /// Update cart item count
  void updateCartItemCount(int count) {
    emit(state.copyWith(cartItemCount: count));
  }
}
