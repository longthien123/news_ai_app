import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;

  const ProfileMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                trailing ?? const Icon(Ionicons.chevron_forward, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.grey[200],
            thickness: 1,
            height: 1,
          ),
      ],
    );
  }
}
