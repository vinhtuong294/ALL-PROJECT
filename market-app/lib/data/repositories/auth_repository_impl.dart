import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/remote/api_service.dart';
import '../../data/models/auth_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.apiService,
    required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, AuthResponseModel>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiService.login({
        'ten_dang_nhap': username,
        'mat_khau': password,
      });

      // Store token and user data
      await sharedPreferences.setString('access_token', response.token);
      await sharedPreferences.setString('user_data', jsonEncode(response.data.toJson()));

      return Right(response);
    } on DioException catch (e) {
      // ignore: avoid_print
      print('Login DioException: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null && e.response!.data is Map) {
        final message = e.response!.data['detail'] ?? 'Sai tài khoản hoặc mật khẩu';
        return Left(AuthFailure(message: message));
      }
      return Left(ServerFailure(message: 'Lỗi kết nối máy chủ: ${e.message}'));
    } catch (e) {
      // ignore: avoid_print
      print('Login Unknown Exception: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await sharedPreferences.remove('access_token');
      await sharedPreferences.remove('user_data');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<AuthUserDataModel?> getStoredUser() async {
    final userDataString = sharedPreferences.getString('user_data');
    if (userDataString != null) {
      try {
        return AuthUserDataModel.fromJson(jsonDecode(userDataString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> getStoredToken() async {
    return sharedPreferences.getString('access_token');
  }
}
