// lib/screens/project_detail_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';
import 'edit_project_details.dart';

class ProjectDetailDropdown extends ConsumerWidget {
  final ProjectModel project;
  final VoidCallback? onDelete;

  const ProjectDetailDropdown({
    super.key,
    required this.project,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Colors.white.withOpacity(0.7),
        size: 20,
      ),
      color: const Color(0xFF262626),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          showEditProjectDetailsCard(context: context, project: project);
        } else if (value == 'delete') {
          ref.read(projectsProvider.notifier).deleteProject(project.id);
          onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 12),
              Text(
                'Edit details',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
              ),
            ],
          ),
        ),
        PopupMenuDivider(color: Colors.white.withOpacity(0.08)),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete project',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
