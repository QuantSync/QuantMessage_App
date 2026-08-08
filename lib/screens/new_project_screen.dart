// lib/screens/new_project_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/chat_message.dart';
import '../core/project_model.dart';
import '../providers/project_provider.dart';
import '../providers/navigation_provider.dart';
import 'project_detail_dropdown.dart';
import 'project_instructions_card.dart';
import 'add_text_context_card.dart';
import 'message_box_pannel/message_box.dart';
import 'message_box_pannel/chat_answers.dart';
import 'animations/animated_buttons/model_selector_button/model_selector_button.dart';
import 'app_sidebar_screen/left_sidebar.dart';
import 'artifact_screen.dart';
import 'app_bar.dart';
import 'settings_screen.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  final ProjectModel project;
  final VoidCallback? onBackToProjects;

  const NewProjectScreen({
    super.key,
    required this.project,
    this.onBackToProjects,
  });

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ProjectModel get _currentProject {
    final list = ref.watch(projectsProvider);
    return list.firstWhere(
          (p) => p.id == widget.project.id,
      orElse: () => widget.project,
    );
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: const Uuid().v4(),//
      conversationId: widget.project.id,
      senderId: 'user',
      createdAt: DateTime.now(),
      text: text,
      isUser: true,
    );

    setState(() {
      _messages.add(userMsg);
      _isGenerating = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate response incorporating project context & instructions
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final projectInstructions = _currentProject.instructions;
      final aiResponseText = projectInstructions.isNotEmpty
          ? 'Project Context Active (${_currentProject.name}): Answer generated following instructions: "$projectInstructions"\n\nHere is what I found regarding your request...'
          : 'Project (${_currentProject.name}): I\'ve analyzed your prompt with the project\'s reference knowledge.';

      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        conversationId: widget.project.id,
        senderId: 'agent',
        createdAt: DateTime.now(),
        text: aiResponseText,
        isUser: false,
      );

      setState(() {
        _messages.add(aiMsg);
        _isGenerating = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _pickDeviceFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          final fileCtx = ProjectFileContext(
            id: const Uuid().v4(),
            title: f.name,
            content: 'Local file: ${f.name} (${(f.size / 1024).toStringAsFixed(1)} KB)',
            isTextContext: false,
            filePath: f.path,
          );
          ref
              .read(projectsProvider.notifier)
              .addFileContext(_currentProject.id, fileCtx);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${result.files.length} file(s) to project'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;
    final proj = _currentProject;

    final mainContent = SafeArea(
      child: Column(
        children: [
            // Top Bar: <- All projects
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBackToProjects ??
                            () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back,
                              color: Colors.white.withOpacity(0.7), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'All projects',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: isDesktop
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Chat & Query interface
                  Expanded(
                    flex: 6,
                    child: _buildChatPane(proj),
                  ),
                  // Right Pane: Project Knowledge Panel (Instructions & Files)
                  Container(
                    width: 380,
                    margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                    child: _buildKnowledgePanel(proj),
                  ),
                ],
              )
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(
                      height: 520,
                      child: _buildChatPane(proj),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildKnowledgePanel(proj),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

    final screenWidth = MediaQuery.of(context).size.width;
    final showDesktopLayout = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF181818), // Deep dark matching Image 4
      body: showDesktopLayout
          ? Row(
              children: [
                LeftSidebar(
                  userEmail: _userEmail,
                  userInitials: _userInitials,
                  onSignOut: () async {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  onProjects: () {
                    if (widget.onBackToProjects != null) {
                      widget.onBackToProjects!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  onNewChat: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  onArtifacts: () {
                    Navigator.push(
                      context,
                      smoothPageRoute(const ArtifactScreen()),
                    );
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

  Widget _buildChatPane(ProjectModel proj) {
    return Column(
      children: [
        // Project Title Header with 3 dots & star
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Row(
            children: [
              Text(
                proj.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              ProjectDetailDropdown(
                project: proj,
                onDelete: widget.onBackToProjects ??
                        () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  proj.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                  color: proj.isStarred
                      ? const Color(0xFFFFC107)
                      : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: () {
                  ref.read(projectsProvider.notifier).toggleStar(proj.id);
                },
              ),
            ],
          ),
        ),

        // Message List or Empty Placeholder
        Expanded(
          child: _messages.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white.withOpacity(0.4),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quant references the same knowledge every time you talk to it in this project.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ChatAnswerCard(
                  message: msg,
                ),
              );
            },
          ),
        ),

        // Input Panel at Bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: MessageBox(
            controller: _messageController,
            focusNode: _focusNode,
            selectedModelName: 'QuantCore',
            isGenerating: _isGenerating,
            onSend: (text, attachments) => _handleSendMessage(text),
            onModelChanged: (model) {},
            onLogout: () => Navigator.of(context).maybePop(),
            onHoverChanged: (isHovered) {},
          ),
        ),
      ],
    );
  }

  Widget _buildKnowledgePanel(ProjectModel proj) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222), // Matching card bg in Image 4 & 5
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Memory Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Memory',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Colors.white.withOpacity(0.5), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Only you',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Project memory will show here after a few chats.',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.38),
              fontSize: 12,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // 2. Instructions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Instructions',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white70, size: 20),
                onPressed: () {
                  showProjectInstructionsCard(
                    context: context,
                    projectId: proj.id,
                    currentInstructions: proj.instructions,
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            proj.instructions.isNotEmpty
                ? proj.instructions
                : 'Add instructions to tailor Quant\'s responses',
            style: GoogleFonts.outfit(
              color: proj.instructions.isNotEmpty
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.38),
              fontSize: 12,
              fontStyle: proj.instructions.isNotEmpty
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // 3. Files Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Files',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Plus Icon Dropdown with 2 options
              PopupMenuButton<String>(
                icon: const Icon(Icons.add, color: Colors.white70, size: 20),
                color: const Color(0xFF2E2E2E),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                onSelected: (value) {
                  if (value == 'device') {
                    _pickDeviceFiles();
                  } else if (value == 'text') {
                    showAddTextContextCard(
                      context: context,
                      projectId: proj.id,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'device',
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_rounded,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Choose from device',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuDivider(color: Colors.white.withOpacity(0.08)),
                  PopupMenuItem(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.post_add_rounded,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Add text context',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Files list or empty placeholder matching Image 4 & 5
          proj.files.isEmpty
              ? Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.snippet_folder_outlined,
                    color: Colors.white.withOpacity(0.3), size: 28),
                const SizedBox(height: 10),
                Text(
                  'Add PDFs, documents, or other text to reference in this project.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: proj.files.map((file) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Icon(
                      file.isTextContext
                          ? Icons.text_snippet_outlined
                          : Icons.insert_drive_file_outlined,
                      color: const Color(0xFF4A9EFF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            file.isTextContext ? 'Text Context' : 'File',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.38),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),//
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
