import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String username;
  final String password;

  const LoggedIn({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class LoggedOut extends AuthEvent {}
