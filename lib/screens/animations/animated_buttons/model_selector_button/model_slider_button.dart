// lib/screens/animations/animated_buttons/model_selector_button/model_slider_button.dart
//
// ModelSliderButton — Category tab pill with deep-black text + glassmorphism.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config.dart' as cfg;

class ModelSliderButton extends StatefulWidget {
  final cfg.ModelCategory selectedCategory;
  final ValueChanged<cfg.ModelCategory> onCategoryChanged;

  const ModelSliderButton({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<ModelSliderButton> createState() => _ModelSliderButtonState();
}

class _ModelSliderButtonState extends State<ModelSliderButton> {
  final List<cfg.ModelCategory> _categories = [
    cfg.ModelCategory.native,
    cfg.ModelCategory.reasoning,
    cfg.ModelCategory.coding,
    cfg.ModelCategory.roleplay,
  ];

  String _getCategoryName(cfg.ModelCategory category) {
    switch (category) {
      case cfg.ModelCategory.native:
        return "Native";
      case cfg.ModelCategory.reasoning:
        return "Reasoning";
      case cfg.ModelCategory.coding:
        return "Coding";
      case cfg.ModelCategory.roleplay:
        return "Roleplay";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            // Frosted glass pill — translucent white so black text is crisp
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.black.withOpacity(0.14),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((category) {
                return _buildTab(category, widget.selectedCategory == category);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(cfg.ModelCategory category, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onCategoryChanged(category),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Selected tab: deep black fill
          color: isSelected ? Colors.black.withOpacity(0.88) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: isSelected
              ? Border.all(color: Colors.black, width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          _getCategoryName(category),
          style: GoogleFonts.outfit(
            // Selected: pure white on deep-black. Unselected: deep black on glass.
            color: isSelected ? Colors.white : Colors.black.withOpacity(0.65),
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: isSelected ? 0.2 : 0.0,
          ),
        ),
      ),
    );
  }
}
