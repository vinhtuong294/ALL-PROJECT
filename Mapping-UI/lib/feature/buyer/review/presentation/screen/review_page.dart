import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cubit/review_cubit.dart';

/// Màn hình đánh giá gian hàng
/// 
/// Chức năng:
/// - Hiển thị thống kê đánh giá
/// - Xem danh sách đánh giá
/// - Viết đánh giá mới
/// - Thêm ảnh vào đánh giá
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  static const String routeName = '/review';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReviewCubit()..loadReviews('shop_id_demo'),
      child: const ReviewView(),
    );
  }
}

/// View của màn hình đánh giá
class ReviewView extends StatefulWidget {
  const ReviewView({super.key});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final _reviewController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _reviewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewCubit, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Clear text field
          _reviewController.clear();
        } else if (state is ReviewSubmitFailure) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ReviewValidationError) {
          // Show validation error
          final errorMsg = state.reviewTextError ?? state.ratingError ?? '';
          if (errorMsg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header with background
              _buildHeader(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Shop info
                      _buildShopInfo(),
                      
                      const SizedBox(height: 24),
                      
                      // Review input
                      _buildReviewInput(context),
                      
                      const SizedBox(height: 16),
                      
                      // Add image section
                      _buildAddImageSection(context),
                      
                      const SizedBox(height: 16),
                      
                      // Submit button
                      _buildSubmitButton(context),
                      
                      const SizedBox(height: 24),
                      
                      // Reviews statistics
                      _buildReviewsStatistics(),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              // Bottom navigation
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Header với background
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Background image
        
        
        // Content
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(
                  'assets/img/back.svg',
                  width: 16,
                  height: 16,
                ),
              ),
              
              const Spacer(),
              
              // Title
              const Text(
                'Đánh giá',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.1,
                  color: Color(0xFF000000),
                ),
              ),
              
              const Spacer(),
              
              // Placeholder to balance the back button
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Thông tin gian hàng
  Widget _buildShopInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 49,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8F959E),
            ),
            alignment: Alignment.center,
            child: const Text(
              'L',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 30,
                height: 0.73,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Shop name and tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gian hàng cô Nhi',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.1,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag('Tươi mới'),
                    _buildTag('Thơm ngon'),
                    _buildTag('Sạch sẽ'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tag widget
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 17,
          height: 1.29,
          color: Color(0xFF202020),
        ),
      ),
    );
  }

  /// Input đánh giá
  Widget _buildReviewInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF5E5C5C)),
          borderRadius: BorderRadius.circular(9998),
        ),
        child: TextField(
          controller: _reviewController,
          decoration: const InputDecoration(
            hintText: 'Viết đánh giá cho gian hàng',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1,
              color: Color(0xFF5E5C5C),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  /// Section thêm ảnh
  Widget _buildAddImageSection(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, state) {
        final cubit = context.read<ReviewCubit>();
        final selectedImages = cubit.selectedImages;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 31),
          child: Column(
            children: [
              // Add image button
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBFFDE),
                    border: Border.all(color: const Color(0xFF5E5C5C)),
                    borderRadius: BorderRadius.circular(9998),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/img/camera.svg',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Thêm ảnh và video',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1,
                          color: Color(0xFF5E5C5C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Selected images preview
              if (selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImages[index]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => cubit.removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Show image picker options
  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ReviewCubit>().pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ReviewCubit>().pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Nút đăng đánh giá
  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 133),
      child: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          final isLoading = state is ReviewSubmitting;
          
          return GestureDetector(
            onTap: isLoading
                ? null
                : () {
                    context.read<ReviewCubit>().submitReview(
                          reviewText: _reviewController.text,
                          rating: 5.0, // TODO: Add rating selector
                        );
                  },
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF21A036),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Đăng',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1.5,
                        letterSpacing: -0.21,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  /// Thống kê đánh giá
  Widget _buildReviewsStatistics() {
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, state) {
        if (state is ReviewLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ReviewLoaded) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Đánh giá từ khách hàng',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.21,
                    color: Color(0xFF000000),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Rating summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.averageRating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 25,
                            height: 0.64,
                            color: Color(0xFF008EDB),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStarRating(state.averageRating),
                      ],
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 93,
                      color: const Color(0xFFB3B3B3),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Rating breakdown
                    Expanded(
                      child: Column(
                        children: [
                          _buildRatingBar(5, state.ratingCounts[5] ?? 0, state.totalReviews),
                          const SizedBox(height: 8),
                          _buildRatingBar(4, state.ratingCounts[4] ?? 0, state.totalReviews),
                          const SizedBox(height: 8),
                          _buildRatingBar(3, state.ratingCounts[3] ?? 0, state.totalReviews),
                          const SizedBox(height: 8),
                          _buildRatingBar(2, state.ratingCounts[2] ?? 0, state.totalReviews),
                          const SizedBox(height: 8),
                          _buildRatingBar(1, state.ratingCounts[1] ?? 0, state.totalReviews),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Star rating display
  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: const Color(0xFFFCC866),
          size: 20,
        );
      }),
    );
  }

  /// Rating bar với progress
  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;
    final percentageText = '${(percentage * 100).round()}%';

    return Row(
      children: [
        // Star number
        SizedBox(
          width: 20,
          child: Text(
            '$stars',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.33,
              color: Color(0xFF0C0D0D),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Progress bar
        Expanded(
          child: Stack(
            children: [
              // Background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              
              // Progress
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCC866),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Percentage or count
        SizedBox(
          width: 70,
          child: Text(
            count > 0 ? '$count đánh giá' : percentageText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.33,
              color: Color(0xFF0C0D0D),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom navigation
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      height: 69,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/img/add_home.svg', 'Trang chủ'),
          _buildNavItem('assets/img/mon_an_icon.png', 'Món ăn', isImage: true),
          _buildNavItem('assets/img/user_personas_presentation-26cd3a.png', '', isImage: true, isCenter: true),
          _buildNavItem('assets/img/wifi_notification.svg', 'Thông báo'),
          _buildNavItem('assets/img/account_circle.svg', 'Tài khoản'),
        ],
      ),
    );
  }

  /// Navigation item
  Widget _buildNavItem(String icon, String label, {bool isImage = false, bool isCenter = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isCenter)
          Container(
            width: 58,
            height: 67,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(icon),
                fit: BoxFit.cover,
              ),
            ),
          )
        else ...[
          isImage
              ? Image.asset(
                  icon,
                  width: 30,
                  height: 30,
                )
              : SvgPicture.asset(
                  icon,
                  width: 30,
                  height: 30,
                ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.33,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
