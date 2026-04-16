import '../../domain/repositories/market_repository.dart';
import '../datasources/remote/api_service.dart';
import '../models/dashboard_stats_model.dart';
import '../models/merchant_response_model.dart';
import '../models/stall_fee_model.dart';
import '../models/goods_category_model.dart';
import '../models/merchant_create_response_model.dart';
import '../models/market_dashboard_model.dart';
import '../models/user_profile_model.dart';
import '../models/login_history_model.dart';
import '../models/market_map_model.dart';

class MarketRepositoryImpl implements MarketRepository {
  final ApiService apiService;

  MarketRepositoryImpl(this.apiService);

  @override
  Future<DashboardStatsModel> getDashboardStats() {
    return apiService.getDashboardStats();
  }

  @override
  Future<MerchantResponseModel> getMerchants({
    int? page,
    int? limit,
    String? search,
    String? status,
  }) {
    return apiService.getMerchants(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
  }

  @override
  Future<MerchantResponseModel> getPendingMerchants({
    int? page,
    int? limit,
  }) {
    return apiService.getPendingMerchants(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<CommonResponse> approveMerchant(String userId) {
    return apiService.approveMerchant(userId: userId);
  }

  @override
  Future<StallFeeListResponse> getStallFees({
    String? month,
    String? status,
    String? search,
    int? page,
    int? limit,
  }) async {
    return apiService.getStallFees(
      month: month,
      status: status,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<StallFeeDetailResponse> getStallFeeDetail(String feeId) async {
    return apiService.getStallFeeDetail(feeId: feeId);
  }

  @override
  Future<CommonResponse> confirmStallFeePayment(
      String feeId, Map<String, dynamic> data) async {
    return apiService.confirmStallFeePayment(feeId: feeId, data: data);
  }

  @override
  Future<GoodsCategoryResponse> getGoodsCategories() async {
    return apiService.getGoodsCategories();
  }

  @override
  Future<MerchantCreateResponseModel> createMerchant(
      Map<String, dynamic> data) async {
    return apiService.createMerchant(data: data);
  }

  @override
  Future<MarketDashboardModel> getDashboardV2() async {
    return apiService.getDashboardV2();
  }

  @override
  Future<CommonResponse> updateStallStatus(
      String stallId, Map<String, dynamic> data) async {
    return apiService.updateStallStatus(stallId: stallId, data: data);
  }

  @override
  Future<UserProfileModel> getUserProfile() async {
    final response = await apiService.getUserProfile();
    return response.data;
  }

  @override
  Future<UserProfileModel> updateUserProfile(Map<String, dynamic> data) async {
    final response = await apiService.updateUserProfile(data: data);
    return response.data;
  }

  @override
  Future<CommonResponse> changePassword(Map<String, dynamic> data) async {
    return await apiService.changePassword(data: data);
  }

  @override
  Future<List<LoginHistoryModel>> getLoginHistory() async {
    final response = await apiService.getLoginHistory();
    return response.data;
  }

  @override
  Future<MarketMapResponse> getMapStalls() async {
    return apiService.getMapStalls();
  }
}
