import '../config/app_constant.dart';

/// Helper class để validate input
class ValidatorHelper {
  ValidatorHelper._();

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    
    final emailRegex = RegExp(AppConstant.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    
    if (value.length < AppConstant.minPasswordLength) {
      return 'Mật khẩu phải có ít nhất ${AppConstant.minPasswordLength} ký tự';
    }
    
    if (value.length > AppConstant.maxPasswordLength) {
      return 'Mật khẩu không được quá ${AppConstant.maxPasswordLength} ký tự';
    }
    
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Xác nhận mật khẩu không được để trống';
    }
    
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    
    final phoneRegex = RegExp(AppConstant.phonePattern);
    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  /// Validate min length
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    
    if (value.length < minLength) {
      return '${fieldName ?? 'Trường này'} phải có ít nhất $minLength ký tự';
    }
    
    return null;
  }

  /// Validate max length
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Trường này'} không được quá $maxLength ký tự';
    }
    
    return null;
  }

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên người dùng không được để trống';
    }
    
    if (value.length < AppConstant.minUsernameLength) {
      return 'Tên người dùng phải có ít nhất ${AppConstant.minUsernameLength} ký tự';
    }
    
    if (value.length > AppConstant.maxUsernameLength) {
      return 'Tên người dùng không được quá ${AppConstant.maxUsernameLength} ký tự';
    }
    
    // Username chỉ chứa chữ cái, số và dấu gạch dưới
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Tên người dùng chỉ chứa chữ cái, số và dấu gạch dưới';
    }
    
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL không được để trống';
    }
    
    final urlRegex = RegExp(AppConstant.urlPattern);
    if (!urlRegex.hasMatch(value)) {
      return 'URL không hợp lệ';
    }
    
    return null;
  }

  /// Validate number
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Trường này'} phải là số';
    }
    
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, {String? fieldName}) {
    final numberError = validateNumber(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '${fieldName ?? 'Trường này'} phải lớn hơn 0';
    }
    
    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    
    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Trường này'} phải là số nguyên';
    }
    
    return null;
  }

  /// Validate range
  static String? validateRange(String? value, num min, num max, {String? fieldName}) {
    final numberError = validateNumber(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    final number = double.parse(value!);
    if (number < min || number > max) {
      return '${fieldName ?? 'Trường này'} phải trong khoảng $min - $max';
    }
    
    return null;
  }

  /// Validate Vietnamese ID card (CMND/CCCD)
  static String? validateIdCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số CMND/CCCD không được để trống';
    }
    
    // CMND: 9 hoặc 12 số, CCCD: 12 số
    if (value.length != 9 && value.length != 12) {
      return 'Số CMND/CCCD không hợp lệ';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Số CMND/CCCD chỉ chứa số';
    }
    
    return null;
  }

  /// Check if string is valid email
  static bool isEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(AppConstant.emailPattern).hasMatch(value);
  }

  /// Check if string is valid phone number
  static bool isPhoneNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(AppConstant.phonePattern).hasMatch(value);
  }

  /// Check if string is valid URL
  static bool isUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(AppConstant.urlPattern).hasMatch(value);
  }
}
