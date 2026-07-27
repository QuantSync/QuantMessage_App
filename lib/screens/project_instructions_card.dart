// lib/screens/project_instructions_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/project_provider.dart';

Future<void> showProjectInstructionsCard({
  required BuildContext context,
  required String projectId,
  required String currentInstructions,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Project Instructions',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) => ProjectInstructionsCard(
      projectId: projectId,
      initialInstructions: currentInstructions,
    ),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14 * anim1.value,
          sigmaY: 14 * anim1.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class ProjectInstructionsCard extends ConsumerStatefulWidget {
  final String projectId;
  final String initialInstructions;

  const ProjectInstructionsCard({
    super.key,
    required this.projectId,
    required this.initialInstructions,
  });

  @override
  ConsumerState<ProjectInstructionsCard> createState() =>
      _ProjectInstructionsCardState();
}

class _ProjectInstructionsCardState
    extends ConsumerState<ProjectInstructionsCard> {
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _instructionsController =
        TextEditingController(text: widget.initialInstructions);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final text = _instructionsController.text.trim();
    ref
        .read(projectsProvider.notifier)
        .updateInstructions(widget.projectId, text);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project instructions saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final cardWidth = isMobile ? mediaQuery.size.width * 0.90 : 540.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 36,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Instructions',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Provide custom instructions to tailor Quant\'s responses specifically for this project.',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Instructions Input Box
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _instructionsController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Use TypeScript with strict typing, write concise answers, avoid unnecessary preambles.',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.32),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white.withOpacity(0.85),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save instructions',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
