// lib/screens/add_text_context_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';

Future<void> showAddTextContextCard({
  required BuildContext context,
  required String projectId,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Text Context',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) =>
        AddTextContextCard(projectId: projectId),
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

class AddTextContextCard extends ConsumerStatefulWidget {
  final String projectId;

  const AddTextContextCard({super.key, required this.projectId});

  @override
  ConsumerState<AddTextContextCard> createState() => _AddTextContextCardState();
}

class _AddTextContextCardState extends ConsumerState<AddTextContextCard> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contextController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and context'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final fileCtx = ProjectFileContext(
      id: const Uuid().v4(),
      title: title,
      content: content,
      isTextContext: true,
    );

    ref.read(projectsProvider.notifier).addFileContext(widget.projectId, fileCtx);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text context added to project reference'),
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
                    'Add text context',
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
                'Enter title and text context below. Quant will take this input as reference during conversation.',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Title input
              Text(
                'Title',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. System Requirements, API Docs',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Context input
              Text(
                'Context / Text content',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 120,
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
                  controller: _contextController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Paste or type text context here...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
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
                      'Save context',
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
