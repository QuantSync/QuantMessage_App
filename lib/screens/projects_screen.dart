// lib/screens/projects_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';
import 'new_project_card.dart';
import 'new_project_screen.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const ProjectsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Last updated';
  ProjectModel? _activeProjectInView;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewProjectModal() async {
    final createdProj = await showNewProjectCard(context);
    if (createdProj != null && mounted) {
      setState(() {
        _activeProjectInView = createdProj;
      });
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    // If an active project is currently selected/viewed, render NewProjectScreen
    if (_activeProjectInView != null) {
      return NewProjectScreen(
        project: _activeProjectInView!,
        onBackToProjects: () {
          setState(() {
            _activeProjectInView = null;
          });
        },
      );
    }

    final query = _searchController.text.toLowerCase().trim();
    final filteredProjects = projects.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Dark background matching Image 2
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Projects title + Search + Sort + New project button
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 28, 36, 20),
              child: Row(
                children: [
                  Text(
                    'Projects',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),

                  // Search icon / field
                  Container(
                    height: 36,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: Colors.white.withOpacity(0.4), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search projects',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Sort dropdown button
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Sort by ',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _sortBy,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.5), size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // New project button
                  ElevatedButton(
                    onPressed: _openNewProjectModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'New project',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Projects List / Grid matching Image 2
            Expanded(
              child: filteredProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_outlined,
                              color: Colors.white.withOpacity(0.2), size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No projects found',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "New project" above to create your first project.',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 100,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final proj = filteredProjects[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ref
                                    .read(activeProjectProvider.notifier)
                                    .state = proj;
                                setState(() {
                                  _activeProjectInView = proj;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F), // Match card bg in Image 2
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      proj.name,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatRelativeTime(proj.updatedAt),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withOpacity(0.38),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
