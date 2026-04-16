import 'package:equatable/equatable.dart';
import 'product_state.dart';

abstract class CategoryProductState extends Equatable {
  const CategoryProductState();

  @override
  List<Object?> get props => [];
}

class CategoryProductInitial extends CategoryProductState {}

class CategoryProductLoading extends CategoryProductState {}

class CategoryProductLoaded extends CategoryProductState {
  final List<MonAnWithImage> monAnList;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalItems; // Tổng số món ăn trong danh mục

  const CategoryProductLoaded({
    this.monAnList = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.totalItems = 0,
  });

  CategoryProductLoaded copyWith({
    List<MonAnWithImage>? monAnList,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalItems,
  }) {
    return CategoryProductLoaded(
      monAnList: monAnList ?? this.monAnList,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  List<Object?> get props => [monAnList, currentPage, hasMore, isLoadingMore, totalItems];
}

class CategoryProductError extends CategoryProductState {
  final String message;
  final bool requiresLogin;

  const CategoryProductError(this.message, {this.requiresLogin = false});

  @override
  List<Object?> get props => [message, requiresLogin];
}
