// lib/screens/animations/animation_effects/model_selector_card/model_selector_card.dart
//
// ModelSelectorCard — Premium Glassmorphism overlay card:
// • Deep-black text throughout
// • Frosted glass background with strong backdrop blur
// • Solid 1.5px border with subtle inner glow
// • Multi-layer shadows for depth
// • Horizontal ModelSliderButton (tab: Native/Reasoning/Coding/Roleplay)
// • Vertical list of model buttons per category
// • Fully responsive on mobile + web

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config.dart' as cfg;
import '../../animated_buttons/model_selector_button/model_slider_button.dart';
import '../../animated_buttons/llm_model_logo/llm_model_button.dart';

class ModelSelectorCard extends StatefulWidget {
  final String selectedModelName;
  final Function(String modelName) onModelSelected;
  final VoidCallback onClose;

  const ModelSelectorCard({
    super.key,
    required this.selectedModelName,
    required this.onModelSelected,
    required this.onClose,
  });

  /// Shows the card as a full-screen overlay with blurred background.
  static void show(
    BuildContext context, {
    required String selectedModelName,
    required Function(String) onModelSelected,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModelSelectorCard',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return ModelSelectorCard(
          selectedModelName: selectedModelName,
          onModelSelected: (name) {
            onModelSelected(name);
            Navigator.of(ctx).pop();
          },
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ModelSelectorCard> createState() => _ModelSelectorCardState();
}

class _ModelSelectorCardState extends State<ModelSelectorCard> {
  cfg.ModelCategory _selectedCategory = cfg.ModelCategory.native;

  List<cfg.AiModel> get _currentModels =>
      cfg.Config.getModelsByCategory(_selectedCategory);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Full-screen blurred scrim ───────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withOpacity(0.42),
                ),
              ),
            ),
          ),

          // ── Centered Card ───────────────────────────────────────────────
          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: screenSize.height * 0.84,
                    ),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          decoration: BoxDecoration(
            // Rich frosted glass — bright with enough opacity to read deep black text
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              // Primary deep shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 56,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
              // Mid-range lift
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              // Inner top-edge highlight
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon accent
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Model",
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          "Choose your AI engine",
                          style: GoogleFonts.outfit(
                            color: Colors.black.withOpacity(0.45),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _CloseButton(onTap: widget.onClose),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Horizontal Category Slider ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSlider(),
              ),

              const SizedBox(height: 16),

              // ── Divider ────────────────────────────────────────────────
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Model List ────────────────────────────────────────────
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _currentModels.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  color: Colors.black.withOpacity(0.25),
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No models available",
                                  style: GoogleFonts.outfit(
                                    color: Colors.black.withOpacity(0.4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _currentModels.map((model) {
                              return LlmModelButton(
                                model: model,
                                isSelected: model.name == widget.selectedModelName,
                                onTap: () {
                                  widget.onModelSelected(model.name);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slider = ModelSliderButton(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (cfg.ModelCategory cat) {
            setState(() => _selectedCategory = cat);
          },
        );
        if (constraints.maxWidth < 400) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: slider,
          );
        }
        return slider;
      },
    );
  }
}

// ─── Close Button ─────────────────────────────────────────────────────────────

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.black.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(_isHovered ? 0.22 : 0.10),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Icon(
            Icons.close_rounded,
            color: _isHovered ? Colors.black87 : Colors.black54,
            size: 17,
          ),
        ),
      ),
    );
  }
}
