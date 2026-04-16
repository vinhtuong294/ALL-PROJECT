import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/merchant_response_model.dart';
import '../../models/stall_fee_model.dart';
import '../../models/goods_category_model.dart';
import '../../models/merchant_create_response_model.dart';
import '../../models/market_dashboard_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/login_history_model.dart';
import '../../models/auth_model.dart';
import '../../models/market_map_model.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/api/auth/login')
  Future<AuthResponseModel> login(@Body() Map<String, dynamic> data);

  @GET('/api/quan-ly-cho/dashboard')
  Future<DashboardStatsModel> getDashboardStats();

  @GET('/api/quan-ly-cho/tieu-thuong')
  Future<MerchantResponseModel> getMerchants({
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @GET('/api/quan-ly-cho/pending-sellers')
  Future<MerchantResponseModel> getPendingMerchants({
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @PATCH('/api/quan-ly-cho/approve-seller/{user_id}')
  Future<CommonResponse> approveMerchant({
    @Path('user_id') required String userId,
  });

  @GET('/api/quan-ly-cho/thu-thue')
  Future<StallFeeListResponse> getStallFees({
    @Query('month') String? month,
    @Query('status') String? status,
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @GET('/api/quan-ly-cho/thu-thue/{fee_id}')
  Future<StallFeeDetailResponse> getStallFeeDetail({
    @Path('fee_id') required String feeId,
  });

  @POST('/api/quan-ly-cho/thu-thue/{fee_id}/xac-nhan')
  Future<CommonResponse> confirmStallFeePayment({
    @Path('fee_id') required String feeId,
    @Body() required Map<String, dynamic> data,
  });

  @GET('/api/quan-ly-cho/loai-hang-hoa')
  Future<GoodsCategoryResponse> getGoodsCategories();

  @GET('/api/quan-ly-cho/dashboard-v2')
  Future<MarketDashboardModel> getDashboardV2();

  @GET('/api/quan-ly-cho/stalls/map')
  Future<MarketMapResponse> getMapStalls();

  @POST('/api/quan-ly-cho/stalls/{stall_id}/status')
  Future<CommonResponse> updateStallStatus({
    @Path('stall_id') required String stallId,
    @Body() required Map<String, dynamic> data,
  });

  @POST('/api/quan-ly-cho/tieu-thuong')
  Future<MerchantCreateResponseModel> createMerchant({
    @Body() required Map<String, dynamic> data,
  });

  @GET('/api/auth/me')
  Future<UserProfileResponse> getUserProfile();

  @PUT('/api/auth/profile')
  Future<UserProfileResponse> updateUserProfile({
    @Body() required Map<String, dynamic> data,
  });

  @POST('/api/auth/change-password')
  Future<CommonResponse> changePassword({
    @Body() required Map<String, dynamic> data,
  });

  @GET('/api/auth/login-history')
  Future<LoginHistoryListResponse> getLoginHistory();
}

@JsonSerializable()
class LoginHistoryListResponse {
  final String status;
  final List<LoginHistoryModel> data;

  LoginHistoryListResponse({required this.status, required this.data});

  factory LoginHistoryListResponse.fromJson(Map<String, dynamic> json) => _$LoginHistoryListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginHistoryListResponseToJson(this);
}
