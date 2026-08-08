import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import 'app_sidebar_screen/left_sidebar.dart';
import 'app_bar.dart';
import 'settings_screen.dart';

class ArtifactScreen extends ConsumerStatefulWidget {
  const ArtifactScreen({super.key});

  @override
  ConsumerState<ArtifactScreen> createState() => _ArtifactScreenState();
}

class _ArtifactScreenState extends ConsumerState<ArtifactScreen> {
  bool _showCategories = false;

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

  void _onCategorySelected(String category) {
    // Set the query in the provider
    ref.read(chatInitialQueryProvider.notifier).state = 'I want to create an artifact for: $category';
    
    // Go to Chat tab globally
    ref.read(navigationProvider.notifier).goTo(AppTab.chat);
    
    // Pop all routes until the main shell (ChatScreen) is visible
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    final mainContent = SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDesktop) ...[
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7), size: 24),
                        ),
                      ),
                    ],
                    Text(
                      'Artifacts',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.6), size: 20),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showCategories = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'New artifact',
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
          
          // Main Body
          Expanded(
            child: _showCategories ? _buildCategorySelection(isDesktop) : _buildEmptyState(),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: isDesktop
          ? Row(
              children: [
                LeftSidebar(
                  userEmail: _userEmail,
                  userInitials: _userInitials,
                  onSignOut: () async {
                    final nav = Navigator.of(context);
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) nav.popUntil((route) => route.isFirst);
                  },
                  onProjects: () {
                    Navigator.maybePop(context);
                  },
                  onArtifacts: () {}, // Already here
                  onNewChat: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  onCustomise: () {
                    showSettingsPopup(context);
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for the "hand picking shapes" icon in image 2
              Icon(
                Icons.extension_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'What will you build with artifacts?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If you can dream it, you can build it. Take apps,\ngames, templates, and tools from thought to reality.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showCategories = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF262626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'New artifact',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection(bool isDesktop) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Let's get cooking! Pick an artifact category or start building your idea from scratch.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              // Grid of Categories
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCategoryCard('Apps and websites', Icons.public),
                    _buildCategoryCard('Documents and templates', Icons.description_outlined),
                    _buildCategoryCard('Games', Icons.flag_outlined),
                    _buildCategoryCard('Productivity tools', Icons.bolt_outlined),
                    _buildCategoryCard('Creative projects', Icons.palette_outlined),
                    _buildCategoryCard('Quiz or survey', Icons.checklist_rtl_outlined),
                    _buildCategoryCard('Start from scratch', Icons.add_circle_outline),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData iconData) {
    return InkWell(
      onTap: () => _onCategorySelected(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                iconData,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
