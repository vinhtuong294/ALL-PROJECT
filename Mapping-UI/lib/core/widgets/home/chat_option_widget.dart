import 'package:flutter/material.dart';
import '../../../feature/buyer/home/presentation/cubit/home_state.dart';

/// Widget hiển thị một option trong chat (button xanh)
class ChatOptionWidget extends StatelessWidget {
  final ChatOption option;
  final VoidCallback onTap;

  const ChatOptionWidget({
    super.key,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00B40F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          option.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.21,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
