import 'package:flutter/material.dart';

class Nav_Bar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Nav_Bar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 15.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.assignment, "Agreement", 1),
          SizedBox(width: 48),
          _buildNavItem(Icons.history, "History", 2),
          _buildNavItem(Icons.person, "Profile", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selectedIndex == index ? Color(0xFF2252A1) : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selectedIndex == index ? Color(0xFF2252A1) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
