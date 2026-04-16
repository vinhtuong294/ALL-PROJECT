part of 'edit_profile_cubit.dart';

/// Base state cho Edit Profile
abstract class EditProfileState extends Equatable {
  const EditProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class EditProfileInitial extends EditProfileState {}

/// Loading state
class EditProfileLoading extends EditProfileState {}

/// Loaded state với thông tin user
class EditProfileLoaded extends EditProfileState {
  final String maNguoiDung;
  final String tenDangNhap;
  final String name;
  final String phone;
  final String address;
  final String? gioiTinh;
  final String? soTaiKhoan;
  final String? nganHang;
  final double? canNang;
  final double? chieuCao;
  
  // New fields for maps
  final double? latitude;
  final double? longitude;
  final List<dynamic> addressSuggestions;
  final bool isSearchingAddress;

  const EditProfileLoaded({
    required this.maNguoiDung,
    required this.tenDangNhap,
    required this.name,
    required this.phone,
    required this.address,
    this.gioiTinh,
    this.soTaiKhoan,
    this.nganHang,
    this.canNang,
    this.chieuCao,
    this.latitude,
    this.longitude,
    this.addressSuggestions = const [],
    this.isSearchingAddress = false,
  });

  @override
  List<Object?> get props => [
        maNguoiDung,
        tenDangNhap,
        name,
        phone,
        address,
        gioiTinh,
        soTaiKhoan,
        nganHang,
        canNang,
        chieuCao,
        latitude,
        longitude,
        addressSuggestions,
        isSearchingAddress,
      ];

  EditProfileLoaded copyWith({
    String? maNguoiDung,
    String? tenDangNhap,
    String? name,
    String? phone,
    String? address,
    String? gioiTinh,
    String? soTaiKhoan,
    String? nganHang,
    double? canNang,
    double? chieuCao,
    double? latitude,
    double? longitude,
    List<dynamic>? addressSuggestions,
    bool? isSearchingAddress,
  }) {
    return EditProfileLoaded(
      maNguoiDung: maNguoiDung ?? this.maNguoiDung,
      tenDangNhap: tenDangNhap ?? this.tenDangNhap,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      soTaiKhoan: soTaiKhoan ?? this.soTaiKhoan,
      nganHang: nganHang ?? this.nganHang,
      canNang: canNang ?? this.canNang,
      chieuCao: chieuCao ?? this.chieuCao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressSuggestions: addressSuggestions ?? this.addressSuggestions,
      isSearchingAddress: isSearchingAddress ?? this.isSearchingAddress,
    );
  }
}

/// Saving state
class EditProfileSaving extends EditProfileState {}

/// Save success state
class EditProfileSaveSuccess extends EditProfileState {
  final String message;

  const EditProfileSaveSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Error state
class EditProfileError extends EditProfileState {
  final String message;

  const EditProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
