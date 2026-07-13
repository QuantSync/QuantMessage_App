// lib/screens/message_box_pannel/message_box.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String selectedModelName;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final Function(String) onModelChanged;
  final VoidCallback onLogout;
  final Function(bool isHovered) onHoverChanged; // For global blur effect

  const MessageBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = "Type a message...",
    required this.selectedModelName,
    required this.onSend,
    required this.onAttachment,
    required this.onModelChanged,
    required this.onLogout,
    required this.onHoverChanged,
  });

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    widget.focusNode.addListener(() {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool hovered) {
    setState(() => _isHovered = hovered);
    widget.onHoverChanged(hovered); // Notify parent to blur screen
    if (hovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(maxWidth: 850),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: const Offset(0, 10),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(_isHovered ? 0.15 : 0.1),
                        Colors.white.withOpacity(_isHovered ? 0.05 : 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: _isFocused
                          ? Colors.blueAccent.withOpacity(0.5)
                          : Colors.white.withOpacity(_isHovered ? 0.2 : 0.1),
                      width: _isFocused ? 2.0 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text Area with Auto-adjust and Scroll
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 400, // Limit height to prevent screen overflow
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              maxLines: null, // Self-adjusting height
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _ActionButton(icon: Icons.add, onTap: widget.onAttachment),
                            const SizedBox(width: 12),
                            _ModelDropdown(
                              currentModel: widget.selectedModelName,
                              onChanged: widget.onModelChanged,
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(icon: Icons.mic_none, onTap: () {}),
                            const SizedBox(width: 12),
                            _ActionButton(icon: Icons.graphic_eq, onTap: () {}),
                            const SizedBox(width: 16),
                            // 3D Send Button
                            GestureDetector(
                              onTap: widget.onSend,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isHovered ? Colors.white : Colors.white24,
                                  shape: BoxShape.circle,
                                  boxShadow: _isHovered ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ] : [],
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _isHovered ? Colors.black : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(icon: Icons.logout_rounded, onTap: widget.onLogout),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
    }
}


class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  final String currentModel;
  final Function(String) onChanged;
  const _ModelDropdown({required this.currentModel, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // This should trigger the AnimatedDropdown from chat_screen.dart
          // For a reusable widget, we'll simulate the call or pass the dropdown as a child
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentModel,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
