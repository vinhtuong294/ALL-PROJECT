part of 'seller_main_cubit.dart';

/// State cho Seller Main Screen
class SellerMainState extends Equatable {
  final int currentIndex;

  const SellerMainState({
    required this.currentIndex,
  });

  @override
  List<Object?> get props => [currentIndex];
}

