import 'package:equatable/equatable.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/models/login_history_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final UserProfileModel profile;

  const ProfileSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdateSuccess extends ProfileState {
  final String message;
  final UserProfileModel profile;

  const ProfileUpdateSuccess(this.message, this.profile);

  @override
  List<Object?> get props => [message, profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordChangeSuccess extends ProfileState {
  final String message;

  const PasswordChangeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordChangeError extends ProfileState {
  final String message;

  const PasswordChangeError(this.message);

  @override
  List<Object?> get props => [message];
}

class LoginHistoryLoaded extends ProfileState {
  final List<LoginHistoryModel> history;

  const LoginHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}
