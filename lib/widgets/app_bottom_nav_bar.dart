import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Ionicons.home_outline,
                selectedIcon: Ionicons.home,
                isSelected: currentIndex == 0,
                index: 0,
              ),
              _buildNavItem(
                icon: Ionicons.compass_outline,
                selectedIcon: Ionicons.compass,
                isSelected: currentIndex == 1,
                index: 1,
              ),
              _buildNavItem(
                icon: Ionicons.bookmark_outline,
                selectedIcon: Ionicons.bookmark,
                isSelected: currentIndex == 2,
                index: 2,
              ),
              _buildNavItem(
                icon: Ionicons.person_outline,
                selectedIcon: Ionicons.person,
                isSelected: currentIndex == 3,
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : Colors.grey[600],
          size: 26,
        ),
      ),
    );
  }
}
