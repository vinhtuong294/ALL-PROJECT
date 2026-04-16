import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/user_profile_service.dart';
import '../../../../../core/services/geocoding_service.dart';
import 'dart:async';

part 'edit_profile_state.dart';

/// Cubit quản lý logic cho Edit Profile
class EditProfileCubit extends Cubit<EditProfileState> {
  final UserProfileService _profileService = UserProfileService();
  final GeocodingService _geocodingService = GeocodingService();
  Timer? _debounce;
  
  EditProfileCubit() : super(EditProfileInitial());

  /// Load thông tin user hiện tại từ API
  Future<void> loadProfile() async {
    emit(EditProfileLoading());

    try {
      final response = await _profileService.getProfile();
      final data = response.data;

      if (isClosed) return;

      emit(EditProfileLoaded(
        maNguoiDung: data.maNguoiDung,
        tenDangNhap: data.tenDangNhap,
        name: data.tenNguoiDung,
        phone: data.sdt ?? '',
        address: data.diaChi ?? '',
        gioiTinh: data.gioiTinh,
        soTaiKhoan: data.soTaiKhoan,
        nganHang: data.nganHang,
        canNang: data.canNang,
        chieuCao: data.chieuCao,
      ));
    } catch (e) {
      if (!isClosed) {
        emit(EditProfileError(message: 'Không thể tải thông tin: $e'));
      }
    }
  }

  /// Cập nhật tên
  void updateName(String name) {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(name: name));
    }
  }

  /// Cập nhật số điện thoại
  void updatePhone(String phone) {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(phone: phone));
    }
  }

  /// Cập nhật địa chỉ và tìm kiếm gợi ý
  void updateAddress(String address) {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(address: address));
      
      // Debounce search
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (address.length >= 3) {
          emit(currentState.copyWith(isSearchingAddress: true, addressSuggestions: []));
          final suggestions = await _geocodingService.searchAddress(address);
          if (isClosed) return;
          
          final newState = state;
          if (newState is EditProfileLoaded) {
            emit(newState.copyWith(
              isSearchingAddress: false, 
              addressSuggestions: suggestions
            ));
          }
        } else {
          emit(currentState.copyWith(addressSuggestions: []));
        }
      });
    }
  }

  /// Chọn một gợi ý từ danh sách
  void selectSuggestion(MapSuggestion suggestion) {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(
        address: suggestion.displayName,
        latitude: suggestion.lat,
        longitude: suggestion.lon,
        addressSuggestions: [],
      ));
    }
  }

  /// Xóa danh sách gợi ý
  void clearSuggestions() {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(addressSuggestions: []));
    }
  }

  /// Cập nhật giới tính
  void updateGioiTinh(String gioiTinh) {
    final currentState = state;
    if (currentState is EditProfileLoaded) {
      emit(currentState.copyWith(gioiTinh: gioiTinh));
    }
  }

  /// Lưu thông tin profile qua API
  Future<void> saveProfile({
    required String name,
    required String phone,
    required String address,
    String? gioiTinh,
    String? soTaiKhoan,
    String? nganHang,
    double? canNang,
    double? chieuCao,
  }) async {
    final currentState = state;
    if (currentState is! EditProfileLoaded) return;

    emit(EditProfileSaving());

    try {
      await _profileService.updateProfile(
        tenNguoiDung: name,
        gioiTinh: gioiTinh ?? currentState.gioiTinh,
        sdt: phone,
        diaChi: address,
        soTaiKhoan: soTaiKhoan ?? currentState.soTaiKhoan,
        nganHang: nganHang ?? currentState.nganHang,
        canNang: canNang ?? currentState.canNang,
        chieuCao: chieuCao ?? currentState.chieuCao,
      );

      if (isClosed) return;

      emit(const EditProfileSaveSuccess(
        message: 'Cập nhật thông tin thành công!',
      ));

      // Reload profile sau khi save
      await loadProfile();
    } catch (e) {
      if (!isClosed) {
        emit(EditProfileError(message: 'Không thể lưu thông tin: $e'));
      }
    }
  }
}
