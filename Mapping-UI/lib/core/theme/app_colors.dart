import 'package:flutter/material.dart';

/// Định nghĩa màu sắc cho ứng dụng
/// Hỗ trợ cả Light Mode và Dark Mode
class AppColors {
  AppColors._();

  // Primary Colors - Light Mode
  static const Color primaryLight = Color(0xFF6366F1); // Indigo
  static const Color primaryVariantLight = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF10B981); // Emerald
  static const Color secondaryVariantLight = Color(0xFF059669);

  // Primary Colors - Dark Mode
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color primaryVariantDark = Color(0xFF6366F1);
  static const Color secondaryDark = Color(0xFF34D399);
  static const Color secondaryVariantDark = Color(0xFF10B981);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Common Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Semantic Colors
  static const Color successBackground = Color(0xFFD1FAE5);
  static const Color warningBackground = Color(0xFFFEF3C7);
  static const Color errorBackground = Color(0xFFFEE2E2);
  static const Color infoBackground = Color(0xFFDBEAFE);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Divider Colors
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1F2937);

  // Shimmer Colors
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);
  static const Color shimmerHighlightLight = Color(0xFFF3F4F6);
  static const Color shimmerBaseDark = Color(0xFF374151);
  static const Color shimmerHighlightDark = Color(0xFF4B5563);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Overlay Colors
  static const Color overlayLight = Color(0x4D000000);
  static const Color overlayDark = Color(0x66000000);

  // E-commerce Specific Colors
  static const Color price = Color(0xFFEF4444);
  static const Color discount = Color(0xFFDC2626);
  static const Color inStock = Color(0xFF10B981);
  static const Color outOfStock = Color(0xFF6B7280);
  static const Color rating = Color(0xFFFBBF24);
  
  // App Specific Colors
  static const Color primaryGreen = Color(0xFF2F8000);
  static const Color lightGreenBackground = Color(0xFFD7FFBD);
  static const Color cardBackground = Color(0xFFD7FFBD); // Same as lightGreenBackground for consistency

  // Social Media Colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color google = Color(0xFFDB4437);
  static const Color apple = Color(0xFF000000);
  static const Color twitter = Color(0xFF1DA1F2);
  
  // Helper methods
  /// Get card background color with alpha
  static Color getCardBackground({double alpha = 0.5}) {
    return cardBackground.withValues(alpha: alpha);
  }
  
  /// Get primary green with alpha
  static Color getPrimaryGreen({double alpha = 1.0}) {
    return primaryGreen.withValues(alpha: alpha);
  }
}
