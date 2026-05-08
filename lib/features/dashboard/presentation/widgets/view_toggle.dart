import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ViewType {
  list,
  map,
}

class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.listIcon = Icons.list,
    this.mapIcon = Icons.map,
    this.listLabel = 'List View',
    this.mapLabel = 'Map View',
    this.activeColor = const Color(0xFF141E7A),
    this.backgroundColor = Colors.grey,
    this.borderRadius = 10,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final ViewType currentView;
  final ValueChanged<ViewType> onViewChanged;
  final IconData listIcon;
  final IconData mapIcon;
  final String listLabel;
  final String mapLabel;
  final Color activeColor;
  final Color backgroundColor;
  final double borderRadius;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final isListView = currentView == ViewType.list;

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmoothToggleButton(
            label: listLabel,
            isSelected: isListView,
            icon: listIcon,
            onTap: () => onViewChanged(ViewType.list),
          ),
          const SizedBox(width: 4),
          _buildSmoothToggleButton(
            label: mapLabel,
            isSelected: !isListView,
            icon: mapIcon,
            onTap: () => onViewChanged(ViewType.map),
          ),
        ],
      ),
    );
  }

  Widget _buildSmoothToggleButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : Colors.grey.shade600,
          ),
          child: Row(
            children: [
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 200),
                tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                curve: Curves.easeOutBack,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: 0.8 + (scale * 0.2),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? activeColor : backgroundColor,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  label,
                  key: ValueKey(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}