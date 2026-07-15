// lib/screens/incognito_screen.dart
// QuantMessage — Ghost Mode (ephemeral, no DB persistence)

import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/chat_message.dart';
import '../core/attachment_model.dart';
import '../core/config.dart' as app_config;
import '../services/quant_space_api.dart';
import '../services/upload_service.dart';
import 'widgets/attachment_thumbnail.dart';
import 'animations/animation_effects/infinity_animation_incogonito.dart';

// Shared floating MessageBox (same as ChatScreen)
import 'message_box_pannel/message_box.dart';

class IncognitoScreen extends StatefulWidget {
  /// When embedded in the Home shell, back/exit switches tabs instead of popping routes.
  final VoidCallback? onExit;

  const IncognitoScreen({super.key, this.onExit});

  @override
  State<IncognitoScreen> createState() => _IncognitoScreenState();
}

class _IncognitoScreenState extends State<IncognitoScreen>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get _currentUser => _supabase.auth.currentUser;
  String? get _userEmail => _currentUser?.email;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final QuantSpaceApi _api = QuantSpaceApi();
  final UploadService _uploadService = UploadService();
  final FocusNode _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isMessageBoxHovered = false;
  String? _ephemeralSessionId;

  String _selectedModelName = app_config.Config.models[0].name;
  String _selectedModelId = app_config.Config.models[0].id;

  late final AnimationController _emptyCtrl;
  late final Animation<double> _emptyOpacity;
  late final Animation<double> _emptyScale;

  @override
  void initState() {
    super.initState();
    _emptyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _emptyOpacity = CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOut);
    _emptyScale = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOutBack));
    _emptyCtrl.forward();
    _generateEphemeralId();
  }

  void _generateEphemeralId() {
    _ephemeralSessionId =
    'ghost_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _emptyCtrl.dispose();
    super.dispose();
  }

  void _exitIncognito() {
    if (widget.onExit != null) {
      widget.onExit!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

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

  Future<void> _handleSend(String text, List<Attachment> attachments) async {
    final trimmedText = text.trim();
    final hasAttachments = attachments.isNotEmpty;

    if ((trimmedText.isEmpty && !hasAttachments) || _isTyping) return;

    _emptyCtrl.reset();

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

    final userMsg = ChatMessage(
      text: trimmedText,
      isUser: true,
      conversationId: _ephemeralSessionId!,
      senderId: 'ghost_user',
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
      String finalPrompt = trimmedText;

      for (final att in preparedAttachments) {
        if (att.localFile != null) {
          try {
            final uploaded = await _uploadService.uploadFile(
              file: att.localFile!,
              conversationId: _ephemeralSessionId!,
            );
            finalPrompt += uploaded.promptFragment;
          } catch (e) {
            debugPrint('Upload error for ${att.filename}: $e');
          }
        }
      }

      final response =
      await _api.getAIResponse(finalPrompt, _ephemeralSessionId!);

      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          conversationId: _ephemeralSessionId!,
          senderId: 'ghost_agent',
          createdAt: DateTime.now(),
          modelName: _selectedModelName,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: "🚨 **Ghost System Error**: ${e.toString()}",
          isUser: false,
          conversationId: _ephemeralSessionId!,
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCirc,
        );
      }
    });
  }

  void _burnSession() {
    setState(() {
      _messages.clear();
      _generateEphemeralId();
    });
    _api.resetSession();
    _emptyCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundBlack,
      // Manual keyboard offset via the floating MessageBox
      resizeToAvoidBottomInset: false,
      appBar: _buildBlurredAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: _ParticleBackground(count: 25),
            ),
            if (_isMessageBoxHovered)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            if (_messages.isEmpty)
              _buildEmptyStateResponsive()
            else
              _buildChatState(),

            // MessageBox — vertical center when empty, bottom dock when chatting
            if (_messages.isEmpty)
              Positioned.fill(
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
    );
  }

  Widget _buildChatState() {
    return _buildChatThread();
  }

  Widget _buildMessageBox() {
    return MessageBox(
      controller: _controller,
      focusNode: _inputFocus,
      selectedModelName: _selectedModelName,
      hintText: "Transmit encrypted message...",
      onSend: _handleSend,
      onLogout: _exitIncognito,
      onHoverChanged: (hovered) {
        if (mounted) setState(() => _isMessageBoxHovered = hovered);
      },
      onModelChanged: (modelName) {
        final model = app_config.Config.getModelByName(modelName);
        if (model == null) return;
        setState(() {
          _selectedModelName = model.name;
          _selectedModelId = model.id;
        });
      },
    );
  }

  Widget _buildEmptyStateResponsive() {
    // Intro content in the upper band; MessageBox centered via Stack overlay
    return FadeTransition(
      opacity: _emptyOpacity,
      child: ScaleTransition(
        scale: _emptyScale,
        child: Align(
          alignment: const Alignment(0, -0.65),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text("Secure Session",
                            style: GoogleFonts.tinos(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      _buildInfinityAnimation(constraints),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.security,
                              color: Color(0xFF6B7280), size: 28),
                          const SizedBox(width: 10),
                          Flexible(
                            child: TypingText(
                              text: "< Gone Incognito >",
                              style: GoogleFonts.tinos(
                                color: const Color(0xFFE8E8E8),
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                              typingSpeed: const Duration(milliseconds: 50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TypingText(
                          text:
                              "Ephemeral mode active. Conversations and uploads are handled via ghost session and will be purged upon exit.",
                          style: GoogleFonts.tinos(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                          typingSpeed: const Duration(milliseconds: 25),
                          delayBeforeStart: const Duration(milliseconds: 900),
                        ),
                      ),
                      if (_userEmail != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Ghost session · $_userEmail",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tinos(
                            color: Colors.white24,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfinityAnimation(BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;
    final double animSize = (screenWidth * 0.6).clamp(80.0, 140.0);
    return SizedBox(
      width: animSize,
      height: animSize / 2,
      child: const InfinityAnimationIncognito(),
    );
  }

  PreferredSizeWidget _buildBlurredAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AppBar(
            backgroundColor: AppTheme.backgroundBlack.withOpacity(0.6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
              onPressed: _exitIncognito,
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_rounded,
                    color: AppTheme.accentGrey, size: 20),
                const SizedBox(width: 8),
                Text("INCOGNITO",
                    style: GoogleFonts.tinos(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryWhite,
                        letterSpacing: 2.0)),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.white38),
                tooltip: "Burn Session",
                onPressed: _burnSession,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatThread() {
    return ListView.builder(
      controller: _scrollController,
      // Extra bottom padding so last messages clear the floating MessageBox
      padding: const EdgeInsets.only(top: 90, bottom: 140),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return FadeInAnimation(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _buildMessageRow(_messages[index]),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          _buildAvatar("👻", AppTheme.accentGrey),
          const SizedBox(width: 16),
          const Text("...",
              style: TextStyle(color: Colors.white38, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage msg) {
    final hasAttachments = msg.hasAttachments;
    final hasText = msg.hasText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: msg.isUser ? Colors.transparent : AppTheme.surfaceDark.withOpacity(0.5),
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(
            msg.isUser ? "🕵️" : "👻",
            msg.isUser ? Colors.white24 : AppTheme.accentGrey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.isUser ? "USER_GHOST" : msg.modelName.toUpperCase(),
                  style: GoogleFonts.tinos(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                if (hasAttachments) AttachmentList(attachments: msg.attachments),
                if (hasText)
                  MarkdownBody(
                    data: msg.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.tinos(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.6,
                          color: AppTheme.textPrimary),
                      h1: GoogleFonts.tinos(
                          color: AppTheme.primaryWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      code: GoogleFonts.tinos(
                        backgroundColor: AppTheme.surfaceMedium,
                        color: AppTheme.accentGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppTheme.surfaceMedium,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      blockquote: GoogleFonts.tinos(
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(color: AppTheme.accentGrey, width: 3)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
    );
  }

  Widget _buildSuggestionPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _SuggestionPill(Icons.history_toggle_off, "Auto-burn"),
        _SuggestionPill(Icons.shield_outlined, "Trace bypass"),
        _SuggestionPill(Icons.fingerprint, "Ghost IP"),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Support Widgets
// ═══════════════════════════════════════════════════════════════════════════

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
    final random = math.Random(42);
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          1.5,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatParticlePainter oldDelegate) => false;
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
          color: _isHovered ? Colors.white.withOpacity(0.1) : const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? Colors.white54 : Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _isHovered ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(widget.label,
                style: GoogleFonts.tinos(
                  color: _isHovered ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}

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
      Future.delayed(widget.delay!, () {
        if (mounted) _controller.forward();
      });
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
    return FadeTransition(
      opacity: _opacityAnimation,
      child: widget.child,
    );
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
    this.typingSpeed = const Duration(milliseconds: 50),
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
              style: widget.style ?? DefaultTextStyle.of(context).style),
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
