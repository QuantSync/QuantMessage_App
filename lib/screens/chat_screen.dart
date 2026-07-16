// lib/screens/chat_screen.dart
//
// QuantMessage — Chat Screen (Fully Integrated)
// Synchronized with: MessageBox, InfinityAnimation, Attachment Model,
// UploadService, QuantSpaceApi, ChatMessage, Config, Supabase Auth
// ------------------------------------------------------------------------------

import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/chat_message.dart';
import '../core/attachment_model.dart';
import '../core/config.dart' as app_config;
import '../providers/attachment_provider.dart';
import '../services/quant_space_api.dart';
import '../services/upload_service.dart';
import 'animations/animation_effects/infinity_animation.dart';
import 'sidebar_panel/left_sidebar.dart';
import 'widgets/attachment_thumbnail.dart';

// ✅ IMPORT THE INTEGRATED MESSAGE BOX
import 'message_box_pannel/message_box.dart';
import 'message_box_pannel/message_card.dart';
import 'widgets/name_onboarding_card.dart';
import 'animations/animated_buttons/upgrade_plan_button.dart';
import 'animations/animation_effects/step_status_text.dart';
import 'pricing_screen/pricing_screen.dart';
import 'app_bar.dart' show smoothPageRoute;

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay,
    this.curve = Curves.easeIn,
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    if (widget.delay != null) {
      Future.delayed(widget.delay!, _controller.forward);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacityAnimation, child: widget.child);
  }
}

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration cursorSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final Duration delayBeforeStart;
  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 20),
    this.cursorSpeed = const Duration(milliseconds: 500),
    this.showCursor = true,
    this.onComplete,
    this.delayBeforeStart = Duration.zero,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayedText = "";
  int _currentIndex = 0;
  bool _cursorVisible = true;
  Timer? _typingTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _startCursorBlink();
  }

  void _startAnimation() {
    Future.delayed(widget.delayBeforeStart, () {
      if (!mounted) return;
      _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
        if (_currentIndex < widget.text.length) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
        } else {
          timer.cancel();
          if (widget.onComplete != null) widget.onComplete!();
        }
      });
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(widget.cursorSpeed, (timer) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: widget.style ?? DefaultTextStyle.of(context).style,
          ),
          if (widget.showCursor)
            WidgetSpan(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _cursorVisible ? 1.0 : 0.0,
                child: Container(
                  width: 2,
                  height: (widget.style?.fontSize ?? 14) * 1.2,
                  color: widget.style?.color ?? Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN CHAT SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  // ── Supabase Auth ──
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get _currentUser => _supabase.auth.currentUser;
  String? get _userEmail => _currentUser?.email;

  /// Prefer onboarding / settings display name, then auth metadata, then email.
  String? get _userName {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    final meta = _currentUser?.userMetadata?['full_name'] as String?;
    if (meta != null && meta.trim().isNotEmpty) return meta.trim();
    return _currentUser?.email?.split('@').first;
  }

  // ── Controllers & Services ──
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final QuantSpaceApi _api = QuantSpaceApi();
  final UploadService _uploadService = UploadService();
  final FocusNode _inputFocus = FocusNode();

  // ── State ──
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _currentConversationId = "";
  String? _displayName;
  bool _showNameOnboarding = false;
  bool _onboardingChecked = false;

  // State for the Global Blur Effect (when MessageBox is hovered)
  bool _isMessageBoxHovered = false;

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

  /// First-time account: show name card until onboarding is complete.
  Future<void> _checkNameOnboarding() async {
    final user = _currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _onboardingChecked = true;
          _showNameOnboarding = false;
          _displayName = null;
        });
      }
      return;
    }

    final meta = user.userMetadata ?? {};
    final metaFlag = meta['onboarding_complete'];
    final existing = (meta['full_name'] as String?)?.trim();

    bool? profileFlag;
    String? profileName = existing;
    try {
      final row = await _supabase
          .from('profiles')
          .select('full_name, onboarding_complete')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        profileFlag = row['onboarding_complete'] as bool?;
        final pn = (row['full_name'] as String?)?.trim();
        if (pn != null && pn.isNotEmpty) profileName = pn;
      }
    } catch (_) {
      // profiles.onboarding_complete may not exist yet — auth metadata is enough
    }

    final explicitComplete =
        metaFlag == true || profileFlag == true;
    final explicitIncomplete =
        metaFlag == false || profileFlag == false;
    final hasName = profileName != null && profileName.isNotEmpty;

    // New signups set onboarding_complete: false → always show the card.
    // Legacy users who already have a name → skip the card.
    final shouldShow = !explicitComplete &&
        (explicitIncomplete || !hasName);

    if (!mounted) return;
    setState(() {
      _displayName = profileName;
      _onboardingChecked = true;
      _showNameOnboarding = shouldShow;
    });
  }

  Future<void> _saveDisplayName(String name) async {
    final user = _currentUser;
    if (user == null) return;

    final trimmed = name.trim();

    await _supabase.auth.updateUser(
      UserAttributes(data: {
        'full_name': trimmed,
        'onboarding_complete': true,
      }),
    );

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': trimmed,
        'onboarding_complete': true,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile upsert warning: $e');
      // Auth metadata already saved — greeting still works
    }

    if (!mounted) return;
    setState(() {
      _displayName = trimmed;
      _showNameOnboarding = false;
    });
  }

  void _generateConversationId() {
    _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _emptyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMP FILE HELPER (used by _handleSend for byte-only attachments)
  // ═══════════════════════════════════════════════════════════════════════

  Future<File?> _writeTempFile(Uint8List bytes, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File(p.join(dir.path, filename));
      await tempFile.writeAsBytes(bytes, flush: true);
      return tempFile;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEND LOGIC — Receives text + attachments FROM the MessageBox
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleSend(String text, List<Attachment> attachments) async {
    final hasAttachments = attachments.isNotEmpty;
    if ((text.isEmpty && !hasAttachments) || _isTyping) return;

    final userId = _currentUser?.id ?? "guest_user";
    _emptyCtrl.reset();

    // Prepare each attachment — ensure localFile exists for uploading
    final List<Attachment> preparedAttachments = [];
    for (final att in attachments) {
      if (att.localFile != null) {
        preparedAttachments.add(att);
      } else if (att.bytes != null) {
        final file = await _writeTempFile(att.bytes!, att.filename);
        preparedAttachments.add(
          file != null ? att.copyWith(localFile: file) : att,
        );
      } else {
        preparedAttachments.add(att);
      }
    }

    // Create user ChatMessage
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      conversationId: _currentConversationId,
      senderId: userId,
      createdAt: DateTime.now(),
      attachments: preparedAttachments,
      modelName: _selectedModelName,
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      String finalPrompt = text;

      // Upload each file to Supabase via UploadService
      for (final att in preparedAttachments) {
        if (att.localFile != null) {
          final uploaded = await _uploadService.uploadFile(
            file: att.localFile!,
            conversationId: _currentConversationId,
          );
          finalPrompt += uploaded.promptFragment;
        }
      }

      // Save user message to Supabase
      await _supabase.from('chat_messages').insert(userMsg.toMap());

      // Get AI response via Flowise
      final response = await _api.getAIResponse(finalPrompt, userId);

      final aiMsg = ChatMessage(
        text: response,
        isUser: false,
        conversationId: _currentConversationId,
        senderId: 'agent',
        createdAt: DateTime.now(),
        modelName: _selectedModelName,
      );

      // Save AI message to Supabase
      await _supabase.from('chat_messages').insert(aiMsg.toMap());

      if (!mounted) return;
      setState(() {
        _messages.add(aiMsg);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(
        text: "🚨 Error: ${e.toString()}",
        isUser: false,
        conversationId: _currentConversationId,
        senderId: 'system',
        createdAt: DateTime.now(),
      )));
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  // Model selection is handled by the floating MessageBox dropdown.

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

    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      // Manual keyboard offset via the floating MessageBox
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBlurredBackground(),

            // GLOBAL BLUR LAYER (when MessageBox is hovered)
            if (_isMessageBoxHovered)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),

            Row(
              children: [
                LeftSidebar(
                  onNewChat: () {
                    setState(() {
                      _messages.clear();
                      _generateConversationId();
                      _emptyCtrl.forward(from: 0.0);
                    });
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      const _ParticleBackground(count: 22),

                      // Top-centre upgrade pill
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: UpgradePlanButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                smoothPageRoute(const PricingScreen()),
                              );
                            },
                          ),
                        ),
                      ),

                      if (_messages.isEmpty)
                        _buildEmptyState()
                      else
                        _buildChatState(),

                      // MessageBox — vertical center when empty, bottom dock when chatting
                      if (_messages.isEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                keyboardInset > 0 ? keyboardInset : 24,
                              ),
                              child: Column(
                                children: [
                                  const Spacer(flex: 3),
                                  _buildMessageBox(),
                                  const SizedBox(height: 12),
                                  _buildSuggestionPills(),
                                  const Spacer(flex: 2),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 16 + keyboardInset,
                          child: _buildMessageBox(),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // First-time name onboarding (blur + glass card)
            if (_onboardingChecked && _showNameOnboarding)
              Positioned.fill(
                child: NameOnboardingOverlay(
                  initialName: _displayName,
                  onSave: _saveDisplayName,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE — Welcome screen with centered content
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    // Greeting sits in the upper band; MessageBox is centered via Stack overlay
    return FadeTransition(
      opacity: _emptyOpacity,
      child: ScaleTransition(
        scale: _emptyScale,
        child: Align(
          alignment: const Alignment(0, -0.55),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildGreeting(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAT STATE — Message thread (MessageBox floats above via Stack)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChatState() {
    return _buildChatThread();
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.5),
          radius: 1.5,
          colors: [Color(0xFF1A0A0A), AppTheme.backgroundBlack],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=1500&q=80',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: AppTheme.backgroundBlack),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTEGRATED MESSAGE BOX (Single source of truth for attachments)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMessageBox() {
    return MessageBox(
      controller: _controller,
      focusNode: _inputFocus,
      selectedModelName: _selectedModelName,
      hintText: "Type a message...",
      onSend: _handleSend,
      onLogout: _handleSignOut,
      onHoverChanged: (hovered) {
        if (mounted) setState(() => _isMessageBoxHovered = hovered);
      },
      onModelChanged: (modelName) {
        ref.read(selectedModelProvider.notifier).selectByName(modelName);
        final model = app_config.Config.getModelByName(modelName);
        if (model == null) return;
        setState(() {
          _selectedModelName = model.name;
          _selectedModelId = model.id;
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GREETING — With InfinityAnimation, responsive, no overflow
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildGreeting() {
    final userName = _userName;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double fontSize =
        (constraints.maxWidth * 0.08).clamp(24.0, 48.0);
        final double animationSize =
        (constraints.maxWidth * 0.15).clamp(60.0, 100.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Infinity animation + greeting row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: animationSize,
                  height: animationSize * 0.5,
                  child: InfinityAnimation(
                    size: animationSize,
                    color: const Color(0xFF22C55E),
                    duration: const Duration(seconds: 5),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '< Hey "${userName ?? 'there'}" >',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFE8E8E8),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "How can I help you today?",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAT THREAD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChatThread() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      // Extra bottom padding so last messages clear the floating MessageBox
      padding: const EdgeInsets.only(top: 20, bottom: 140),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Show dotted loading animation + step status text
          return const StepStatusText();
        }
        final msg = _messages[index];
        return FadeInAnimation(
          duration: const Duration(milliseconds: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MessageCard(
                message: msg,
                selectedModelName: _selectedModelName,
              ),
              // Show step status text right below the last user message while typing
              if (_isTyping && msg.isUser && index == _messages.length - 1)
                const StepStatusText(),
            ],
          ),
        );
      },
    );
  }

  // Typing indicator is now handled by StepStatusText inline in _buildChatThread

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUGGESTION PILLS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSuggestionPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _SuggestionPill(Icons.edit_outlined, "Write"),
        _SuggestionPill(Icons.school_outlined, "Learn"),
        _SuggestionPill(Icons.code, "Code"),
        _SuggestionPill(Icons.coffee_outlined, "Life stuff"),
        _SuggestionPill(Icons.lightbulb_outline, "Something New"),
      ],
    );
  }
}

// _AnimatedMessageRow replaced by MessageCard (from message_box_pannel/message_card.dart)

// ═══════════════════════════════════════════════════════════════════════════
// UI HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

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

// _ThinkingDots replaced by StepStatusText (from animations/animation_effects/step_status_text.dart)

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
