// lib/screens/new_project_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';

Future<ProjectModel?> showNewProjectCard(BuildContext context) {
  return showGeneralDialog<ProjectModel>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create Project',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) => const NewProjectCard(),
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

class NewProjectCard extends ConsumerStatefulWidget {
  const NewProjectCard({super.key});

  @override
  ConsumerState<NewProjectCard> createState() => _NewProjectCardState();
}

class _NewProjectCardState extends ConsumerState<NewProjectCard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  bool _isNameFocused = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    final goals = _goalsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a project name'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newProj = ref.read(projectsProvider.notifier).createProject(
          name: name,
          description: goals,
        );

    ref.read(activeProjectProvider.notifier).state = newProj;
    Navigator.of(context).pop(newProj);
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
            color: const Color(0xFF333333), // Exact match to dark dialog in Image 1
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
                    'Create a project',
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

              // Question 1: What are you working on?
              Text(
                'What are you working on?',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Focus(
                onFocusChange: (focused) => setState(() => _isNameFocused = focused),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isNameFocused
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.1),
                      width: _isNameFocused ? 1.5 : 1.0,
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
              ),
              const SizedBox(height: 20),

              // Question 2: What are you trying to achieve?
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

              // Action Buttons: Cancel & Create project
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white.withOpacity(0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                    onPressed: _handleCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Create project',
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
