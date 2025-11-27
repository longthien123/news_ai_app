import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';

class AISummaryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AISummaryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
    );
  }
}
