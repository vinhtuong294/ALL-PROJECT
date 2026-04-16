import 'package:flutter/material.dart';

/// Widget hiển thị header của trang Home
class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Text(
                  'Chào buổi sáng $userName, bạn muốn nấu món gì hôm nay? ',
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Color(0xFF517907),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
