import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/market_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final MarketRepository marketRepository;

  ProfileBloc(this.marketRepository) : super(ProfileInitial()) {
    on<GetUserProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await marketRepository.getUserProfile();
        emit(ProfileSuccess(profile));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });

    on<UpdateUserProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        final updatedProfile = await marketRepository.updateUserProfile(event.updateData);
        emit(ProfileUpdateSuccess('Cập nhật thông tin thành công!', updatedProfile));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });

    on<ChangePasswordEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        await marketRepository.changePassword({
          'mat_khau_cu': event.oldPassword,
          'mat_khau_moi': event.newPassword,
        });
        emit(const PasswordChangeSuccess('Thay đổi mật khẩu thành công!'));
      } catch (e) {
        emit(PasswordChangeError(e.toString()));
      }
    });

    on<GetLoginHistoryEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        final history = await marketRepository.getLoginHistory();
        emit(LoginHistoryLoaded(history));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}
