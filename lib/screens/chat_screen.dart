// lib/screens/chat_screen.dart
//
// QuantMessage — Chat Screen (Fully Integrated)
// Synchronized with: MessageBox, InfinityAnimation, Attachment Model,
// UploadService, QuantSpaceApi, ChatMessage, Config, Supabase Auth
// ------------------------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/app_theme.dart';
import '../core/chat_message.dart';
import '../core/attachment_model.dart';
import '../core/config.dart' as app_config;
import '../providers/attachment_provider.dart';
import '../providers/chat_provider.dart';
import '../services/quant_space_api.dart';
import 'app_sidebar_screen/left_sidebar.dart';

// ✅ IMPORT THE INTEGRATED MESSAGE BOX
import 'message_box_pannel/message_box.dart';
import 'message_box_pannel/message_card.dart';
import 'message_box_pannel/chat_answers.dart';
import 'widgets/name_onboarding_card.dart';
import 'widgets/user_greeting.dart';
import 'animations/animated_buttons/upgrade_plan_button.dart';
import 'animations/animated_buttons/mode_slider_button.dart';
import 'animations/animated_buttons/model_selector_button/model_selector_button.dart';
import 'animations/animation_effects/model_selector_card/model_selector_card.dart';
import 'animations/animation_effects/step_status_text.dart';
import 'animations/animation_effects/coming_soon_card.dart';
import 'pricing_screen/pricing_screen.dart';
import 'projects_screen.dart';
import 'artifact_screen.dart';
import 'settings_screen.dart';
import 'app_bar.dart' show smoothPageRoute;

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onComplete;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.onComplete,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN CHAT SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  // ── Services & Controllers ──
  final QuantSpaceApi _api = QuantSpaceApi();
  final SupabaseClient _supabase = Supabase.instance.client;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // ── State ──
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  List<String> _agentSteps = [];        // 4-agent pipeline steps for the UI
  String _currentConversationId = "";
  String? _displayName;
  bool _showNameOnboarding = false;
  bool _onboardingChecked = false;
  AppMode _currentMode = AppMode.drive;
  String _selectedModeName = "Autopilot mode";

  // State for the Global Blur Effect (when MessageBox is hovered)
  bool _isMessageBoxHovered = false;

  // State for Profile Menu & Mobile Sidebar Blur
  bool _isProfileMenuOpen = false;
  bool _isMobileSidebarOpen = false;

  // ── Model Selection synced from shared provider ──
  late String _selectedModelName;
  late String _selectedModelId;

  // ── Animations ──
  late final AnimationController _emptyCtrl;
  late final Animation<double> _emptyOpacity;
  late final Animation<double> _emptyScale;

  @override
  void initState() {
    super.initState();
    final model = ref.read(selectedModelProvider);
    _selectedModelName = model.name;
    _selectedModelId = model.id;
    _generateConversationId();

    _emptyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _emptyOpacity =
        CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOut);
    _emptyScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOutBack),
    );
    _emptyCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNameOnboarding();
    });
    _authSub = _supabase.auth.onAuthStateChange.listen((_) {
      _checkNameOnboarding();
    });
  }

  StreamSubscription<AuthState>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    _inputFocus.dispose();
    _emptyCtrl.dispose();
    super.dispose();
  }

  void _generateConversationId() {
    _currentConversationId = const Uuid().v4();
  }

  String? get _userEmail => _supabase.auth.currentUser?.email;

  String? get _userName {
    final meta = _supabase.auth.currentUser?.userMetadata;
    final fullName = meta?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return _displayName;
  }

  Future<void> _checkNameOnboarding() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _displayName = null;
          _showNameOnboarding = false;
          _onboardingChecked = true;
        });
      }
      return;
    }

    final meta = user.userMetadata ?? {};
    final fullName = meta['full_name'] as String?;
    final onboardingDone = meta['onboarding_complete'] == true;

    if (fullName != null && fullName.trim().isNotEmpty && onboardingDone) {
      if (mounted) {
        setState(() {
          _displayName = fullName.trim();
          _showNameOnboarding = false;
          _onboardingChecked = true;
        });
      }
      return;
    }

    try {
      final res = await _supabase
          .from('profiles')
          .select('full_name, onboarding_complete')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        final profileName = res['full_name'] as String?;
        final profileComplete = res['onboarding_complete'] == true;

        if (profileName != null && profileName.trim().isNotEmpty && profileComplete) {
          if (mounted) {
            setState(() {
              _displayName = profileName.trim();
              _showNameOnboarding = false;
              _onboardingChecked = true;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _displayName = fullName?.trim();
        _showNameOnboarding = true;
        _onboardingChecked = true;
      });
    }
  }

  Future<void> _saveDisplayName(String name) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _displayName = name.trim();
          _showNameOnboarding = false;
        });
      }
      return;
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': name.trim(),
          'onboarding_complete': true,
        }),
      );

      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': name.trim(),
          'onboarding_complete': true,
          'email': user.email,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        await _supabase
            .from('profiles')
            .update({
          'full_name': name.trim(),
          'onboarding_complete': true,
        })
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Save Name Error: $e');
    }

    if (mounted) {
      setState(() {
        _displayName = name.trim();
        _showNameOnboarding = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      setState(() {
        _messages.clear();
        _displayName = null;
        _showNameOnboarding = false;
        _onboardingChecked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
    }
  }

  Future<void> _handleSend(String text, List<Attachment> attachments) async {
    if (text.trim().isEmpty && attachments.isEmpty) return;

    final user = _supabase.auth.currentUser;
    final userId = user?.id ?? "guest";

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversationId,
      text: text,
      isUser: true,
      senderId: userId,
      createdAt: DateTime.now(),
      attachments: List.from(attachments),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _agentSteps = [];
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final promptText = text.trim().isEmpty
          ? "Please analyze the attached files."
          : text.trim();

      String effectiveMode = 'autopilot';
      if (_selectedModeName.toLowerCase().contains('deep')) {
        effectiveMode = 'deep_search';
      } else if (_selectedModeName.toLowerCase().contains('quick')) {
        effectiveMode = 'quick_answer';
      }

      final fullRes = await _api.getAIResponseFull(
        promptText,
        userId,
        modelId: _selectedModelId,
        conversationId: _currentConversationId,
        mode: effectiveMode,
      );

      final responseText = fullRes['response'] as String;
      final steps = fullRes['steps'] as List<String>? ?? [];

      if (!mounted) return;

      setState(() {
        _agentSteps = steps;
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          conversationId: _currentConversationId,
          text: responseText,
          isUser: false,
          senderId: 'system',
          createdAt: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          conversationId: _currentConversationId,
          text: "Sorry, I ran into an error processing your request: $e",
          isUser: false,
          senderId: 'system',
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedModelProvider, (prev, next) {
      if (_selectedModelName == next.name) return;
      setState(() {
        _selectedModelName = next.name;
        _selectedModelId = next.id;
      });
    });

    ref.listen(chatInitialQueryProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        Future.microtask(() {
          _handleSend(next, []);
          ref.read(chatInitialQueryProvider.notifier).state = null;
        });
      }
    });

    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBlurredBackground(),

            // GLOBAL BLUR LAYER
            if (_isMessageBoxHovered || _isProfileMenuOpen || _isMobileSidebarOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_isMobileSidebarOpen) {
                      setState(() => _isMobileSidebarOpen = false);
                    }
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withValues(alpha: 0.45)),
                  ),
                ),
              ),

            Builder(
              builder: (context) {
                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isMobile = screenWidth < 800;

                Widget sidebarWidget = LeftSidebar(
                  onNewChat: () {
                    setState(() {
                      _messages.clear();
                      _generateConversationId();
                      _emptyCtrl.forward(from: 0.0);
                      if (isMobile) {
                        _isMobileSidebarOpen = false;
                      }
                    });
                  },
                  userEmail: _userEmail,
                  userInitials: _userName?.substring(0, 1).toUpperCase() ?? 'U',
                  onSignOut: _handleSignOut,
                  onMenuOpened: () {
                    if (mounted) setState(() => _isProfileMenuOpen = true);
                  },
                  onMenuClosed: () {
                    if (mounted) setState(() => _isProfileMenuOpen = false);
                  },
                  onCustomise: () {
                    showSettingsPopup(context);
                    if (isMobile) {
                      setState(() => _isMobileSidebarOpen = false);
                    }
                  },
                  onProjects: () {
                    if (isMobile) {
                      setState(() => _isMobileSidebarOpen = false);
                    }
                    Navigator.push(
                      context,
                      smoothPageRoute(const ProjectsScreen()),
                    );
                  },
                  onArtifacts: () {
                    if (isMobile) {
                      setState(() => _isMobileSidebarOpen = false);
                    }
                    Navigator.push(
                      context,
                      smoothPageRoute(const ArtifactScreen()),
                    );
                  },
                );

                Widget mainChatView = Stack(
                  children: [
                    const _ParticleBackground(count: 22),

                    // Top bar elements
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = MediaQuery.of(context).size.width;
                          final bool isCompact = width < 600;

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.menu, color: Colors.white70, size: 24),
                                      onPressed: () {
                                        setState(() => _isMobileSidebarOpen = !_isMobileSidebarOpen);
                                      },
                                      tooltip: 'Open Sidebar',
                                    ),
                                    const SizedBox(width: 6),
                                    ModeSliderButton(
                                      currentMode: _currentMode,
                                      onModeChanged: (mode) {
                                        setState(() => _currentMode = mode);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ModelSelectorButton(
                                      onPressed: _openModelSelectorCard,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: UpgradePlanButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        smoothPageRoute(const PricingScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              ModeSliderButton(
                                currentMode: _currentMode,
                                onModeChanged: (mode) {
                                  setState(() => _currentMode = mode);
                                },
                              ),
                              const SizedBox(width: 12),
                              ModelSelectorButton(
                                onPressed: _openModelSelectorCard,
                              ),
                              const Spacer(),
                              UpgradePlanButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    smoothPageRoute(const PricingScreen()),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Chat messages scroll view
                    Positioned.fill(
                      top: 80,
                      bottom: 120,
                      child: _buildChatThread(),
                    ),

                    // Empty state center content
                    if (_messages.isEmpty)
                      Positioned.fill(
                        child: Align(
                          alignment: isMobile ? const Alignment(0.0, -0.65) : const Alignment(0.0, -0.45),
                          child: ScaleTransition(
                            scale: _emptyScale,
                            child: FadeTransition(
                              opacity: _emptyOpacity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    UserGreeting(userName: _displayName),
                                    SizedBox(height: isMobile ? 6 : 12),
                                    Text(
                                      'The night owls get the best ideas — what\'s on your mind?',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Input Panel (Floating MessageBox at bottom)
                    if (_messages.isEmpty)
                      Positioned(
                        left: isMobile ? 12 : 20,
                        right: isMobile ? 12 : 20,
                        bottom: (isMobile ? 10 : 24) + keyboardInset,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSuggestionPills(),
                            SizedBox(height: isMobile ? 8 : 14),
                            _buildAdviceBanner(),
                            SizedBox(height: isMobile ? 4 : 8),
                            _buildMessageBox(),
                          ],
                        ),
                      )
                    else
                      Positioned(
                        left: isMobile ? 12 : 20,
                        right: isMobile ? 12 : 20,
                        bottom: (isMobile ? 8 : 16) + keyboardInset,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAdviceBanner(),
                            SizedBox(height: isMobile ? 4 : 8),
                            _buildMessageBox(),
                          ],
                        ),
                      ),
                  ],
                );

                if (isMobile) {
                  return Stack(
                    children: [
                      Positioned.fill(child: mainChatView),
                      if (_isMobileSidebarOpen) ...[
                        // Backdrop tap listener: clicking anywhere outside closes the sidebar
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _isMobileSidebarOpen = false;
                                });
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ),
                        // Sidebar overlay
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          child: sidebarWidget,
                        ),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    sidebarWidget,
                    Expanded(child: mainChatView),
                  ],
                );
              },
            ),

            // First-time name onboarding (blur + glass card)
            if (_onboardingChecked && _showNameOnboarding)
              Positioned.fill(
                child: NameOnboardingOverlay(
                  initialName: _displayName,
                  onSave: _saveDisplayName,
                ),
              ),

            // Coming soon cards for Fly/Jet modes
            if (_currentMode == AppMode.fly || _currentMode == AppMode.jet)
              ComingSoonCard(
                modeName: _currentMode == AppMode.fly ? 'Fly' : 'Jet',
                onClose: () {
                  setState(() {
                    _currentMode = AppMode.drive;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openModelSelectorCard() {
    ModelSelectorCard.show(
      context,
      selectedModelName: _selectedModelName,
      onModelSelected: (modelName) {
        ref
            .read(selectedModelProvider.notifier)
            .selectByName(modelName);
        final model = app_config.Config
            .getModelByName(modelName);
        if (model == null) return;
        if (mounted) {
          setState(() {
            _selectedModelName = model.name;
            _selectedModelId = model.id;
          });
        }
      },
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF1F1F1F),
            AppTheme.backgroundBlack,
          ],
        ),
      ),
    );
  }

  Widget _buildChatThread() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];

        Widget childWidget = Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.center,
          children: [
            if (msg.isUser)
              MessageCard(
                message: msg,
                selectedModelName: _selectedModelName,
              )
            else
              ChatAnswerCard(
                message: msg,
              ),
            if (_isTyping && msg.isUser && index == _messages.length - 1)
              Align(
                alignment: Alignment.centerLeft,
                child: StepStatusText(steps: _agentSteps),
              ),
          ],
        );

        if (msg.animationCompleted) {
          return childWidget;
        } else {
          return FadeInAnimation(
            duration: const Duration(milliseconds: 400),
            onComplete: () {
              msg.animationCompleted = true;
            },
            child: childWidget,
          );
        }
      },
    );
  }

  Widget _buildAdviceBanner() {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 4.0 : 8.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 14,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF28282A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF60A5FA),
                    size: isMobile ? 12 : 15,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Flexible(
                    child: Text(
                      "Deep Search Feature Consumes more model credits so utilise accordingly",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBox() {
    return MessageBox(
      controller: _controller,
      focusNode: _inputFocus,
      selectedModelName: _selectedModelName,
      selectedMode: _selectedModeName,
      onModeChanged: (mode) {
        if (mounted) {
          setState(() {
            _selectedModeName = mode;
          });
        }
      },
      isGenerating: _isTyping,
      onSend: (text, attachments) => _handleSend(text, attachments),
      onLogout: _handleSignOut,
      onHoverChanged: (isHovered) {
        if (mounted) {
          setState(() {
            _isMessageBoxHovered = isHovered;
          });
        }
      },
      onModelChanged: (modelName) {
        ref.read(selectedModelProvider.notifier).selectByName(modelName);
        final model = app_config.Config.getModelByName(modelName);
        if (model == null) return;
        if (mounted) {
          setState(() {
            _selectedModelName = model.name;
            _selectedModelId = model.id;
          });
        }
      },
    );
  }

  Widget _buildSuggestionPills() {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _SuggestionPill(Icons.edit_outlined, "Write"),
        _SuggestionPill(Icons.school_outlined, "Learn"),
        _SuggestionPill(Icons.code, "Code"),
        _SuggestionPill(Icons.coffee_outlined, "Life stuff"),
        _SuggestionPill(Icons.lightbulb_outline, "Something New"),
      ],
    );
  }
}

class _SuggestionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  const _SuggestionPill(this.icon, this.label);
  @override
  State<_SuggestionPill> createState() => _SuggestionPillState();
}

class _SuggestionPillState extends State<_SuggestionPill> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? Colors.white54 : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon,
                color: _isHovered ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                color: _isHovered ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticleBackground extends StatelessWidget {
  final int count;
  const _ParticleBackground({required this.count});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.3,
      child: CustomPaint(
        painter: _ChatParticlePainter(0.0, count),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _ChatParticlePainter extends CustomPainter {
  final double progress;
  final int count;
  _ChatParticlePainter(this.progress, this.count);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white10;
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(
          math.Random().nextDouble() * size.width,
          math.Random().nextDouble() * size.height,
        ),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
