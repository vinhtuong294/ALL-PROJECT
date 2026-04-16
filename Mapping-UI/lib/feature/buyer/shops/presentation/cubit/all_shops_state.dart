import 'package:equatable/equatable.dart';

/// State cho All Shops Screen
abstract class AllShopsState extends Equatable {
  const AllShopsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AllShopsInitial extends AllShopsState {
  const AllShopsInitial();
}

/// Loading state
class AllShopsLoading extends AllShopsState {
  const AllShopsLoading();
}

/// Loaded state
class AllShopsLoaded extends AllShopsState {
  final List<ShopItem> shops;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const AllShopsLoaded({
    this.shops = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  AllShopsLoaded copyWith({
    List<ShopItem>? shops,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AllShopsLoaded(
      shops: shops ?? this.shops,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [shops, currentPage, hasMore, isLoadingMore];
}

/// Error state
class AllShopsError extends AllShopsState {
  final String message;

  const AllShopsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Model cho shop item
class ShopItem extends Equatable {
  final String maGianHang;
  final String tenGianHang;
  final String? hinhAnh;
  final String viTri;
  final double danhGiaTb;

  const ShopItem({
    required this.maGianHang,
    required this.tenGianHang,
    this.hinhAnh,
    required this.viTri,
    required this.danhGiaTb,
  });

  @override
  List<Object?> get props => [maGianHang, tenGianHang, hinhAnh, viTri, danhGiaTb];
}
