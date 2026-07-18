import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config.dart' as cfg;

class ModelSliderButton extends StatefulWidget {
  final cfg.ModelCategory selectedCategory;
  final ValueChanged<cfg.ModelCategory> onCategoryChanged;

  const ModelSliderButton({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  State<ModelSliderButton> createState() => _ModelSliderButtonState();
}

class _ModelSliderButtonState extends State<ModelSliderButton> {
  // Mapping categories to display strings
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((category) {
                final isSelected = widget.selectedCategory == category;
                return _buildTab(category, isSelected);
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
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Text(
          _getCategoryName(category),
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
