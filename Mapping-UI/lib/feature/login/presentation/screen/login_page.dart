import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/route_name.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth/simple_auth_helper.dart';
import '../cubit/login_cubit.dart';

/// Màn hình đăng nhập
/// 
/// Chức năng:
/// - Đăng nhập bằng email và mật khẩu
/// - Validate input
/// - Chuyển sang màn hình đăng ký
/// - Hiển thị/ẩn mật khẩu
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: const LoginView(),
    );
  }
}

/// View của màn hình đăng nhập
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          
          // TODO: Navigate to Home screen
          // Navigator.of(context).pushReplacementNamed(HomePage.routeName);
        } else if (state is LoginFailure) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/img/splash_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.white.withOpacity(0.3),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo
                    _buildLogo(),
                    
                    const SizedBox(height: 50),
                    
                    // Login Form Container
                    _buildLoginForm(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build logo
  Widget _buildLogo() {
    return Container(
      width: 206,
      height: 91,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/img/splash_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Build login form container
  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF9E4).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0272BA),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab header
            _buildTabHeader(),
            
            const SizedBox(height: 40),
            
            // Email field
            _buildEmailField(),
            
            const SizedBox(height: 30),
            
            // Password field
            _buildPasswordField(),
            
            const SizedBox(height: 40),
            
            // Login button
            _buildLoginButton(),
            
            const SizedBox(height: 24),
            
            // Register link
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  /// Build tab header (Đăng nhập / Đăng ký)
  Widget _buildTabHeader() {
    return Row(
      children: [
        // Đăng nhập tab (active)
        Expanded(
          child: Column(
            children: [
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00B40F),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 2,
                width: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF0606),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 50),
        
        // Đăng ký tab (inactive)
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Navigate to SignUp page
              AppRouter.navigateTo(context, RouteName.register);
            },
            child: Text(
              'Đăng ký',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00B40F).withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build email field
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF0272BA),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              
              // Text field
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Tên đăng nhập hoặc Email',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5E5C5C),
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    return context.read<LoginCubit>().validateEmail(value);
                  },
                ),
              ),
              
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Build password field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            final cubit = context.read<LoginCubit>();
            final isPasswordVisible = cubit.isPasswordVisible;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF0272BA),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  
                  // Text field
                  Expanded(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: const InputDecoration(
                        hintText: 'Mật khẩu',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF5E5C5C),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        return cubit.validatePassword(value);
                      },
                    ),
                  ),
                  
                  // Toggle visibility button
                  IconButton(
                    onPressed: () {
                      cubit.togglePasswordVisibility();
                    },
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build login button
  Widget _buildLoginButton() {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        
        return SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      // Sử dụng simple auth helper - tất cả error handling tự động
                      final success = await logIn(
                        context,
                        _emailController.text.trim(),
                        _passwordController.text,
                      );
                      
                      // Chỉ navigate khi đăng nhập thành công
                      if (success && mounted) {
                        // Lấy vai trò người dùng để navigate đúng trang
                        final vaiTro = await getUserRole();
                        debugPrint('[LOGIN] 👤 User role (normalized): $vaiTro');
                        
                        if (!mounted) return;
                        
                        if (vaiTro == 'quan_ly_cho') {
                          // Quản lý chợ -> Admin Home
                          debugPrint('[LOGIN] ➡️ Navigating to ADMIN home');
                          AppRouter.navigateAndRemoveUntil(
                            context,
                            RouteName.adminHome,
                          );
                        } else if (vaiTro == 'nguoi_ban') {
                          // Người bán -> Seller Home
                          debugPrint('[LOGIN] ➡️ Navigating to SELLER home');
                          AppRouter.navigateAndRemoveUntil(
                            context,
                            RouteName.sellerMain,
                          );
                        } else {
                          // Người mua hoặc vai trò khác -> Buyer Home
                          debugPrint('[LOGIN] ➡️ Navigating to BUYER home');
                          AppRouter.navigateAndRemoveUntil(
                            context,
                            RouteName.main,
                          );
                        }
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B40F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Build register link
  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bạn mới biết đến DNGo? ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to SignUp page
              AppRouter.navigateTo(context, RouteName.register);
            },
            child: const Text(
              'Đăng ký',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00B40F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
