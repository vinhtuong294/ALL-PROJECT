import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/signup_cubit.dart';
import '../../../../core/dependency/injection.dart';
import '../../../../core/services/auth/auth_service.dart';

/// Màn hình đăng ký
/// 
/// Chức năng:
/// - Đăng ký với tên, số điện thoại, email và mật khẩu
/// - Validate input
/// - Chuyển sang màn hình đăng nhập
/// - Hiển thị/ẩn mật khẩu
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const String routeName = '/signup';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(authService: getIt<AuthService>()),
      child: const SignUpView(),
    );
  }
}

/// View của màn hình đăng ký
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SIGNUP] Building SignUpView...');
    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        debugPrint('[SIGNUP] State changed: $state');
        if (state is SignUpSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        } else if (state is SignUpFailure) {
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildLogo(),
                      const SizedBox(height: 30),
                      _buildSignUpForm(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/img/splash_logo.png',
      width: 180,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF9E4).withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF0272BA).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabHeader(),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _nameController,
              hintText: 'Tên*',
              icon: Icons.person_outline,
              validator: (value) => context.read<SignUpCubit>().validateName(value),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(),
            const SizedBox(height: 15),
            _buildConfirmPasswordField(),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _emailController,
              hintText: 'Email*',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => context.read<SignUpCubit>().validateEmail(value),
            ),
            const SizedBox(height: 20),
            _buildRoleSelection(),
            const SizedBox(height: 25),
            _buildSignUpButton(),
            const SizedBox(height: 15),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Đăng nhập',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00B40F).withOpacity(0.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Đăng ký',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00B40F),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0606),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF0272BA).withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpPasswordVisibilityChanged,
      builder: (context, state) {
        final isPasswordVisible = context.read<SignUpCubit>().isPasswordVisible;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF0272BA).withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !isPasswordVisible,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Mật khẩu*',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () => context.read<SignUpCubit>().togglePasswordVisibility(),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            validator: (value) => context.read<SignUpCubit>().validatePassword(value),
          ),
        );
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpPasswordVisibilityChanged,
      builder: (context, state) {
        final isPasswordVisible = context.read<SignUpCubit>().isPasswordVisible;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF0272BA).withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: !isPasswordVisible,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu*',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            validator: (value) => context.read<SignUpCubit>().validateConfirmPassword(
                  _passwordController.text,
                  value,
                ),
          ),
        );
      },
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Vai Trò:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<SignUpCubit, SignUpState>(
          buildWhen: (prev, curr) => curr is SignUpRoleChanged,
          builder: (context, state) {
            final selectedRole = context.read<SignUpCubit>().selectedRole;
            return Row(
              children: [
                _buildRoleOption('nguoi_mua', 'Người Mua', selectedRole == 'nguoi_mua'),
                const SizedBox(width: 20),
                _buildRoleOption('nguoi_ban', 'Người Bán', selectedRole == 'nguoi_ban'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleOption(String role, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<SignUpCubit>().setRole(role),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF00B40F) : Colors.grey,
                width: 2,
              ),
              color: isSelected ? const Color(0xFF00B40F) : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? const Color(0xFF00B40F) : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        final isLoading = state is SignUpLoading;
        return SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      await context.read<SignUpCubit>().signUp(
                            username: _emailController.text.trim(),
                            password: _passwordController.text,
                            confirmPassword: _confirmPasswordController.text,
                            fullName: _nameController.text.trim(),
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B40F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Bạn đã có tài khoản? ',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 16,
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
