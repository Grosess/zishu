import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart' show DuotoneThemeExtension;

class ModernNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  
  const ModernNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneExt?.isDuotoneTheme == true;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isDuotone 
                ? duotoneExt?.duotoneColor2 
                : Theme.of(context).colorScheme.primary)!
                .withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDuotone
                  ? duotoneExt!.duotoneColor1!.withValues(alpha: 0.8)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: Border(
                top: BorderSide(
                  color: (isDuotone 
                      ? duotoneExt!.duotoneColor2 
                      : Theme.of(context).colorScheme.primary)!
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_rounded,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.folder_rounded,
                  selectedIcon: Icons.folder_rounded,
                  label: 'Sets',
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Icons.analytics_rounded,
                  selectedIcon: Icons.analytics_rounded,
                  label: 'Progress',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneExt?.isDuotoneTheme == true;
    
    final primaryColor = isDuotone 
        ? duotoneExt!.duotoneColor2! 
        : Theme.of(context).colorScheme.primary;
    
    final unselectedColor = isDuotone
        ? duotoneExt!.duotoneColor2!.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Expanded(
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        splashColor: primaryColor.withValues(alpha: 0.1),
        highlightColor: primaryColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 20 : 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ] : [],
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? primaryColor : unselectedColor,
                  size: isSelected ? 28 : 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : unselectedColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}