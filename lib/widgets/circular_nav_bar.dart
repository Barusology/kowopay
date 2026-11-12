import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kowopay/theme/app_theme.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

/// Floating bottom navigation built from four circular purple buttons.
///
/// A plain [BottomNavigationBar] cannot express the circular, floating look
/// required by the KowoPay design, so this widget owns the layout and motion.
class CircularNavBar extends StatelessWidget {
  const CircularNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(42),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (index) {
            final NavItem item = items[index];
            final bool selected = index == currentIndex;
            return Expanded(
              child: Semantics(
                label: item.label,
                selected: selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(index);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        width: selected ? 52 : 46,
                        height: selected ? 52 : 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected ? AppColors.buttonGradient : null,
                          color: selected ? null : AppColors.mist,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.purple
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                selected ? item.activeIcon : item.icon,
                                key: ValueKey<bool>(selected),
                                size: 23,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.inkMuted,
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 15,
                                    minHeight: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Text(
                                    item.badgeCount > 9
                                        ? '9+'
                                        : '${item.badgeCount}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.purple
                              : AppColors.inkMuted,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
