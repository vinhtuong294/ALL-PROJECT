import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/merchant_response_model.dart';
import '../../data/models/stall_fee_model.dart';
import '../../data/models/goods_category_model.dart';
import '../../data/models/merchant_create_response_model.dart';
import '../../data/models/market_dashboard_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/login_history_model.dart';
import '../../data/models/market_map_model.dart';

abstract class MarketRepository {
  Future<DashboardStatsModel> getDashboardStats();

  Future<MerchantResponseModel> getMerchants({
    String? search,
    String? status,
    int? page,
    int? limit,
  });

  Future<MerchantResponseModel> getPendingMerchants({
    int? page,
    int? limit,
  });

  Future<CommonResponse> approveMerchant(String userId);
  Future<StallFeeListResponse> getStallFees({
    String? month,
    String? status,
    String? search,
    int? page,
    int? limit,
  });

  Future<StallFeeDetailResponse> getStallFeeDetail(String feeId);

  Future<CommonResponse> confirmStallFeePayment(
      String feeId, Map<String, dynamic> data);
  Future<GoodsCategoryResponse> getGoodsCategories();
  Future<MerchantCreateResponseModel> createMerchant(Map<String, dynamic> data);
  Future<MarketDashboardModel> getDashboardV2();
  Future<CommonResponse> updateStallStatus(
      String stallId, Map<String, dynamic> data);

  Future<UserProfileModel> getUserProfile();
  Future<UserProfileModel> updateUserProfile(Map<String, dynamic> data);
  Future<CommonResponse> changePassword(Map<String, dynamic> data);
  Future<List<LoginHistoryModel>> getLoginHistory();
  Future<MarketMapResponse> getMapStalls();
}
