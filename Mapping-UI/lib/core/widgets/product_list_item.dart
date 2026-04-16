import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Product List Item Widget - Hiển thị item món ăn trong danh sách
class ProductListItem extends StatelessWidget {
  final String productName;
  final String imagePath;
  final int? servings; // Số khẩu phần (vd: 4)
  final String? difficulty; // Độ khó (vd: 'Dễ', 'Trung bình', 'Khó')
  final int? cookTime; // Thời gian nấu (phút)
  final VoidCallback? onViewDetail;

  const ProductListItem({
    super.key,
    required this.productName,
    required this.imagePath,
    this.servings,
    this.difficulty,
    this.cookTime,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF5E5C5C).withOpacity(0.18),
            width: 0.7,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _buildImage(),
            ),
            const SizedBox(width: 10),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 9),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.47,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Info row: servings, difficulty, cook time
                  Row(
                    children: [
                      // Servings
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD9D9D9),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/img/mm_icon_people.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${servings ?? 4} Người',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Color(0xFF000000),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      
                      // Difficulty
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD9D9D9),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/img/mm_icon_star.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  difficulty ?? 'Dễ',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Color(0xFF000000),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      
                      // Cook time
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD9D9D9),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/img/mm_icon_clock.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${cookTime ?? 40} Phút',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Color(0xFF000000),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // "Xem chi tiết" button
                  GestureDetector(
                    onTap: onViewDetail,
                    child: Container(
                      width: 76,
                      height: 21,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F8000).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          height: 2.2,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image widget - hỗ trợ cả URL và local asset
  Widget _buildImage() {
    // Kiểm tra nếu là URL (bắt đầu bằng http hoặc https)
    final isUrl = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isUrl) {
      // Sử dụng Image.network cho URL
      return Image.network(
        imagePath,
        width: 103,
        height: 103,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 103,
            height: 103,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 103,
            height: 103,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      // Sử dụng Image.asset cho local asset
      return Image.asset(
        imagePath,
        width: 103,
        height: 103,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 103,
            height: 103,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }
}
