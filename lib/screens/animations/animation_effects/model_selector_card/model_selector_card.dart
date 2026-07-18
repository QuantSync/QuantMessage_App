// lib/screens/animations/animation_effects/model_selector_card/model_selector_card.dart
//
// ModelSelectorCard — Glassmorphism overlay card with:
// • Full-screen blurred background over chat_screen
// • Horizontal ModelSliderButton (tab: Native/Reasoning/Coding/Roleplay)
// • Vertical list of model buttons per category
// • Close button (top-right)
// • Fully responsive, no overflow on resize/orientation change
// • Safe during live AI generation — no freeze

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
    Key? key,
    required this.selectedModelName,
    required this.onModelSelected,
    required this.onClose,
  }) : super(key: key);

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
      transitionDuration: const Duration(milliseconds: 280),
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
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
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
          // ── Full-screen blur layer ──────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.black.withOpacity(0.55)),
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
                      maxWidth: 600,
                      maxHeight: screenSize.height * 0.82,
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C).withOpacity(0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    Text(
                      "Select Model",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    _CloseButton(onTap: widget.onClose),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Horizontal Category Slider ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSlider(),
              ),

              const SizedBox(height: 16),

              // ── Divider ─────────────────────────────────────────────────
              Divider(
                color: Colors.white.withOpacity(0.1),
                thickness: 1,
                height: 1,
              ),

              const SizedBox(height: 16),

              // ── Model List ──────────────────────────────────────────────
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: _currentModels.isEmpty
                      ? Center(
                          child: Text(
                            "No models available",
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 14,
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
                                isSelected:
                                    model.name == widget.selectedModelName,
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
        // On narrow screens, allow horizontal scroll
        if (constraints.maxWidth < 420) {
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

// ─── Close Button ────────────────────────────────────────────────────────────

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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.4 : 0.15),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            color: _isHovered ? Colors.white : Colors.white70,
            size: 18,
          ),
        ),
      ),
    );
  }
}
