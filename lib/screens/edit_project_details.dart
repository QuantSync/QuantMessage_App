// lib/screens/edit_project_details.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';

Future<void> showEditProjectDetailsCard({
  required BuildContext context,
  required ProjectModel project,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit Project Details',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) => EditProjectDetailsCard(project: project),
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

class EditProjectDetailsCard extends ConsumerStatefulWidget {
  final ProjectModel project;

  const EditProjectDetailsCard({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<EditProjectDetailsCard> createState() =>
      _EditProjectDetailsCardState();
}

class _EditProjectDetailsCardState
    extends ConsumerState<EditProjectDetailsCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _goalsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _goalsController = TextEditingController(text: widget.project.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final goals = _goalsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(projectsProvider.notifier).updateProjectDetails(
          id: widget.project.id,
          name: name,
          description: goals,
        );

    // Also update active project if it's the current one
    final active = ref.read(activeProjectProvider);
    if (active?.id == widget.project.id) {
      ref.read(activeProjectProvider.notifier).state = active!.copyWith(
        name: name,
        description: goals,
      );
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project details updated successfully'),
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
                    'Edit project details',
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
              const SizedBox(height: 20),

              // Project Name Field
              Text(
                'What are you working on?',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
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
                  controller: _nameController,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Name your project',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Goals/Achievements Field
              Text(
                'What are you trying to achieve?',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 110,
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
                  controller: _goalsController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe your project, goals, subject, etc...',
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
                      'Save changes',
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
