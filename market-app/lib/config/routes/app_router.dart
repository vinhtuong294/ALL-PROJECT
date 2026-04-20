import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/product/product_detail_screen.dart';
import '../../presentation/screens/product/product_list_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/order/order_history_screen.dart';
import '../../presentation/screens/order/order_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String productList = '/products';
  static const String productDetail = '/products/:id';
  static const String cart = '/cart';
  static const String orderHistory = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String profile = '/profile';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.productList,
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
