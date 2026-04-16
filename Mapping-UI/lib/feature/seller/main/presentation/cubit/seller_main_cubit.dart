import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'seller_main_state.dart';

/// Cubit quản lý tab navigation cho Seller Main Screen
class SellerMainCubit extends Cubit<SellerMainState> {
  SellerMainCubit({int initialIndex = 2}) 
      : super(SellerMainState(currentIndex: initialIndex));

  /// Chuyển tab
  void changeTab(int index) {
    if (index != state.currentIndex) {
      emit(SellerMainState(currentIndex: index));
    }
  }
}

