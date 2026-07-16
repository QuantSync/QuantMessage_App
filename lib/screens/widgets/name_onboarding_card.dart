// lib/screens/widgets/name_onboarding_card.dart
// First-time welcome name card — blurred backdrop + glass panel (chat_screen)

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';

/// Centered onboarding card asking for the user's display name.
/// Use as a full-screen Stack overlay on [ChatScreen].
class NameOnboardingOverlay extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(String name) onSave;

  const NameOnboardingOverlay({
    super.key,
    this.initialName,
    required this.onSave,
  });

  @override
  State<NameOnboardingOverlay> createState() => _NameOnboardingOverlayState();
}

class _NameOnboardingOverlayState extends State<NameOnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final FocusNode _focusNode;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _focusNode = FocusNode();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width * 0.9).clamp(300.0, 440.0);

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Full-screen blur + dim (only the card stays crisp)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),

            // Centered glass card
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome to QuantMessage',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'What should we call you? This name appears in chat and can be changed anytime in Settings.',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _nameCtrl,
                            focusNode: _focusNode,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSave(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor:
                                  Colors.white.withValues(alpha: 0.06),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryRed
                                      .withValues(alpha: 0.7),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent.shade100,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton(
                                onPressed: _saving ? null : _handleSave,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor:
                                      Colors.white.withValues(alpha: 0.35),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
