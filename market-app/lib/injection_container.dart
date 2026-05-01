import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/remote/api_service.dart';
import 'data/repositories/market_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/market_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/bloc/dashboard/dashboard_bloc.dart';
import 'presentation/bloc/merchant/merchant_bloc.dart';
import 'presentation/bloc/tax/tax_bloc.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Dio
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final prefs = sl<SharedPreferences>();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        if (error.response?.statusCode == 401) {
          sl<SharedPreferences>().remove('access_token');
          sl<SharedPreferences>().remove('user_data');
          sl<AuthBloc>().add(LoggedOut());
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            message: 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
          ));
        }
        return handler.next(error);
      },
    ));
    
    return dio;
  });


  // Data Sources
  sl.registerLazySingleton(() => ApiService(sl()));

  // Repositories
  sl.registerLazySingleton<MarketRepository>(() => MarketRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        apiService: sl(),
        sharedPreferences: sl(),
      ));

  // Blocs
  sl.registerFactory(() => DashboardBloc(sl()));
  sl.registerFactory(() => MerchantBloc(sl()));
  sl.registerFactory(() => TaxBloc(repository: sl()));
  sl.registerFactory(() => ProfileBloc(sl()));
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));
}


