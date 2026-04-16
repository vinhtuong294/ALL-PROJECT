import 'package:equatable/equatable.dart';

class AdminUserState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String managerName;
  final String email;
  final String phone;
  final String marketName;
  final String marketLocation;
  final String? avatarUrl;

  const AdminUserState({
    this.isLoading = false,
    this.errorMessage,
    this.managerName = 'Nguyễn Văn A',
    this.email = 'nguyenvana@example.com',
    this.phone = '0912345678',
    this.marketName = 'Chợ Bắc Mỹ An',
    this.marketLocation = 'Đà Nẵng',
    this.avatarUrl,
  });

  AdminUserState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? managerName,
    String? email,
    String? phone,
    String? marketName,
    String? marketLocation,
    String? avatarUrl,
  }) {
    return AdminUserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      managerName: managerName ?? this.managerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      marketName: marketName ?? this.marketName,
      marketLocation: marketLocation ?? this.marketLocation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        managerName,
        email,
        phone,
        marketName,
        marketLocation,
        avatarUrl,
      ];
}

