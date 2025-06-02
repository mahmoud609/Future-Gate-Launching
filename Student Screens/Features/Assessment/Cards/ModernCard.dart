import 'package:flutter/material.dart';
import '../Theme/AppTheme.dart';
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ModernCard({Key? key, required this.child, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
