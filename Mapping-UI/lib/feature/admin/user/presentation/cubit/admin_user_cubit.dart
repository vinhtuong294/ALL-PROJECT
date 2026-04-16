import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_user_state.dart';

class AdminUserCubit extends Cubit<AdminUserState> {
  AdminUserCubit() : super(const AdminUserState());

  Future<void> loadUserData() async {
    emit(state.copyWith(isLoading: true));

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(
        isLoading: false,
        managerName: 'Nguyễn Văn A',
        email: 'nguyenvana@example.com',
        phone: '0912345678',
        marketName: 'Chợ Bắc Mỹ An',
        marketLocation: 'Đà Nẵng',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin: ${e.toString()}',
      ));
    }
  }

  Future<void> updateProfile({
    String? managerName,
    String? email,
    String? phone,
  }) async {
    emit(state.copyWith(
      managerName: managerName ?? state.managerName,
      email: email ?? state.email,
      phone: phone ?? state.phone,
    ));
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    // TODO: Implement password change
  }
}

