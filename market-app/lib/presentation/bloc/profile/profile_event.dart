import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetUserProfileEvent extends ProfileEvent {}

class UpdateUserProfileEvent extends ProfileEvent {
  final Map<String, dynamic> updateData;

  const UpdateUserProfileEvent(this.updateData);

  @override
  List<Object?> get props => [updateData];
}

class ChangePasswordEvent extends ProfileEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordEvent({required this.oldPassword, required this.newPassword});

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class GetLoginHistoryEvent extends ProfileEvent {}
