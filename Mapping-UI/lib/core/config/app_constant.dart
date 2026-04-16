/// Lưu trữ các hằng số toàn cục của ứng dụng DNGO
class AppConstant {
  AppConstant._();

  // --- API Endpoints (Khớp với cấu trúc Route của DNGO) ---
  
  // Authentication (Sẽ dùng kết hợp với AppConfig.authBaseUrl)
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String refreshTokenEndpoint = '/refresh';
  static const String profileEndpoint = '/me';

  // Buyer - Đi chợ (Sẽ dùng kết hợp với AppConfig.buyerBaseUrl)
  static const String buyerOrders = '/orders';
  static const String buyerCart = '/cart';
  static const String ingredients = '/nguyen-lieu';
  static const String categories = '/categories';
  static const String stores = '/gian-hang';
  static const String products = '/products';

  // Seller - Người bán (Sẽ dùng kết hợp với AppConfig.sellerBaseUrl)
  static const String sellerOrders = '/orders';
  static const String sellerProducts = '/products';
  static const String sellerRevenue = '/revenue'; // Doanh thu
  static const String sellerKhuVuc = '/khu-vuc';

  // Market Manager - Quản lý chợ (Sẽ dùng kết hợp với AppConfig.adminBaseUrl)
  static const String managerDashboard = '/dashboard';
  static const String managerReports = '/reports';

  // --- Storage Keys (Giữ nguyên) ---
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String firstLaunchKey = 'first_launch';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // --- Validation ---
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // --- Patterns ---
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[0-9]{10,11}$';
  static const String urlPattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // --- Date Formats ---
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';

  // --- Error Messages ---
  static const String networkErrorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại.';
  static const String serverErrorMessage = 'Lỗi máy chủ (DNGO Server). Vui lòng thử lại sau.';
  static const String unknownErrorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
  static const String timeoutErrorMessage = 'Yêu cầu hết thời gian chờ.';
  static const String unauthorizedErrorMessage = 'Phiên đăng nhập đã hết hạn.';

  // --- Defaults ---
  static const String defaultLanguage = 'vi';
  static const String defaultCurrency = 'VND';
  static const String defaultCountryCode = 'VN';

  // --- Limits ---
  static const int maxCartItems = 99;
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50 MB
}