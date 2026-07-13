import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'settings_screen.dart'; // FIXED: Changed from '../screens/settings_screen.dart' to 'settings_screen.dart' since both are in lib/screens

class CustomAppBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomAppBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isDesktop = screenWidth > 600;

    final List<NavItem> navItems = [
      NavItem(icon: Icons.home_filled, label: "Home"),
      NavItem(icon: Icons.chat_bubble_rounded, label: "Chat"),
      NavItem(icon: Icons.visibility_off_rounded, label: "Incognito"),
      NavItem(icon: Icons.forum_rounded, label: "Messages"),
      NavItem(icon: Icons.settings_rounded, label: "Settings"), // index 4 → opens popup
    ];

    void handleTap(int index) {
      if (index == 4) {
        showSettingsPopup(context);
      } else {
        onItemSelected(index);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 20 : 30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: isDesktop ? 65 : double.infinity,
          height: isDesktop ? double.infinity : 60,
          margin: EdgeInsets.only(
            top: isDesktop ? 20 : 0,
            bottom: isDesktop ? 20 : 15,
            right: isDesktop ? 15 : 0,
            left: isDesktop ? 0 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 30),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated selection indicator dot
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: isDesktop
                    ? null
                    : (screenWidth / navItems.length) * selectedIndex +
                    (screenWidth / (navItems.length * 2)) -
                    4,
                top: isDesktop
                    ? (screenHeight / navItems.length) * selectedIndex + 20
                    : null,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation layout
              isDesktop
                  ? _buildVerticalNav(
                  context, navItems, selectedIndex, handleTap, screenHeight)
                  : _buildHorizontalNav(
                  context, navItems, selectedIndex, handleTap, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  // HORIZONTAL NAV (mobile / narrow screens)
  Widget _buildHorizontalNav(
      BuildContext context,
      List<NavItem> items,
      int selectedIndex,
      Function(int) onTap,
      double width,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final bool isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: width / items.length,
            child: Center(
              child: Icon(
                items[index].icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                size: 22,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalNav(
      BuildContext context,
      List<NavItem> items,
      int selectedIndex,
      Function(int) onTap,
      double height,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Changed to center for better balance
      children: [
        // Nav icons
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final bool isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  items[index].icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  size: 22,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Data model
class NavItem {
  final IconData icon;
  final String label;
  NavItem({required this.icon, required this.label});
}