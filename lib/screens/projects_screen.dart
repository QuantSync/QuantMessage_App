// lib/screens/projects_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';
import '../providers/navigation_provider.dart';
import 'new_project_card.dart';
import 'new_project_screen.dart';
import 'app_sidebar_screen/left_sidebar.dart';
import 'app_bar.dart';

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

  String? get _userEmail => Supabase.instance.client.auth.currentUser?.email;

  String? get _userName {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = meta?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return null;
  }

  String get _userInitials => _userName?.substring(0, 1).toUpperCase() ?? 'U';

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

    final mainContent = SafeArea(
      child: Column(
        children: [
          // Top Bar: Projects title + Search + Sort + New project button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.maybePop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.7), size: 24),
                      ),
                    ),
                    Text(
                      'Projects',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search Box
                    Container(
                      width: 180,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.search,
                                color: Colors.white.withOpacity(0.4), size: 18),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search projects...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sort dropdown (visual only)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
    backgroundColor: const Color(0xFF141414),
    body: isDesktop
    ? Row(
    children: [
    LeftSidebar(
    userEmail: _userEmail,
    userInitials: _userInitials,
    onSignOut: () async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
    },
    onProjects: () {},
    onNewChat: () {
    Navigator.maybePop(context);
    },
    ),
    Expanded(
    child: Stack(
    children: [
    Positioned.fill(
    child: Padding(
    padding: const EdgeInsets.only(right: 80),
    child: mainContent,
    ),
    ),
    Positioned(
    right: 0,
    top: 0,
    bottom: 0,
    child: CustomAppBar(
    onItemSelected: (index) {
    ref.read(navigationProvider.notifier).goToIndex(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
    },
    ),
    ),
    ],
    ),
    ),
    ],
    )
        : Column(
    children: [
    Expanded(
    child: Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: mainContent,
    ),
    ),
    CustomAppBar(
    onItemSelected: (index) {
    ref.read(navigationProvider.notifier).goToIndex(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
    },
    ),
    ],
    ),
    );
    }
}
