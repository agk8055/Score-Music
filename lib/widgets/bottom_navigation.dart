import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final bool isLibraryScreen;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isLibraryScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 60;
    const double bottomPadding = 16;
    return SizedBox(
      height: barHeight + bottomPadding,
      child: Stack(
        children: [
          // Black overlay covering both the bar and the area below
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barHeight + bottomPadding,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          // Navigation bar with padding
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            child: SizedBox(
              height: barHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: 'Search',
                    index: 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.library_music_outlined,
                    selectedIcon: Icons.library_music,
                    label: 'Library',
                    index: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required IconData selectedIcon, required String label, required int index}) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (isLibraryScreen && index == 2) {
          Navigator.pop(context);
        } else {
          onDestinationSelected(index);
        }
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? const Color(0xFFF5D505) : Colors.white,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF5D505) : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 