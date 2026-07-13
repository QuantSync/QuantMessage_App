// lib/screens/chat_screen.dart
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
import 'animations/animation_effects/infinity_animation.dart';
import 'sidebar_panel/left_sidebar.dart';
import 'widgets/attachment_preview.dart';
import 'widgets/attachment_thumbnail.dart';
import 'widgets/attachment_picker_sheet.dart';

// IMPORT THE NEW MESSAGE BOX
import 'message_box_pannel/message_box.dart';

// --- Animation Helper Widgets ---
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  const FadeInAnimation({Key? key, required this.child, this.duration = const Duration(milliseconds: 500), this.delay, this.curve = Curves.easeIn}) : super(key: key);
  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    if (widget.delay != null) { Future.delayed(widget.delay!, _controller.forward); } else { _controller.forward(); }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacityAnimation, child: widget.child);
}

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration cursorSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final Duration delayBeforeStart;
  const TypingText({super.key, required this.text, this.style, this.typingSpeed = const Duration(milliseconds: 20), this.cursorSpeed = const Duration(milliseconds: 500), this.showCursor = true, this.onComplete, this.delayBeforeStart = Duration.zero});
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
          setState(() { _displayedText += widget.text[_currentIndex]; _currentIndex++; });
        } else { timer.cancel(); if (widget.onComplete != null) widget.onComplete!(); }
      });
    });
  }
  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(widget.cursorSpeed, (timer) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }
  @override
  void dispose() { _typingTimer?.cancel(); _cursorTimer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: _displayedText, style: widget.style ?? DefaultTextStyle.of(context).style),
          if (widget.showCursor)
            WidgetSpan(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _cursorVisible ? 1.0 : 0.0,
                child: Container(width: 2, height: (widget.style?.fontSize ?? 14) * 1.2, color: widget.style?.color ?? Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// MAIN CHAT SCREEN
// ──────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get _currentUser => _supabase.auth.currentUser;
  String? get _userEmail => _currentUser?.email;
  String? get _userName => _currentUser?.userMetadata?['full_name'] as String? ?? _currentUser?.email?.split('@').first;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final QuantSpaceApi _api = QuantSpaceApi();
  final UploadService _uploadService = UploadService();
  final FocusNode _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final List<Attachment> _pendingAttachments = [];
  String _currentConversationId = "";

  // State for the Global Blur Effect
  bool _isMessageBoxHovered = false;

  String _selectedModelName = app_config.Config.models[0].name;
  String _selectedModelId = app_config.Config.models[0].id;

  late final AnimationController _emptyCtrl;
  late final Animation<double> _emptyOpacity;
  late final Animation<double> _emptyScale;

  @override
  void initState() {
    super.initState();
    _generateConversationId();

    _emptyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _emptyOpacity = CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOut);
    _emptyScale = Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _emptyCtrl, curve: Curves.easeOutBack));
    _emptyCtrl.forward();
  }

  void _generateConversationId() {
    _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
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

  void _addAttachment(Uint8List bytes, String filename, String mimeType) {
    final attachment = AttachmentX.fromBytes(bytes, filename, mimeType);
    setState(() => _pendingAttachments.add(attachment));
    _writeTempFile(bytes, filename).then((file) {
      if (!mounted || file == null) return;
      setState(() {
        final idx = _pendingAttachments.indexWhere((a) => a.filename == filename);
        if (idx != -1) _pendingAttachments[idx] = _pendingAttachments[idx].copyWith(localFile: file);
      });
    });
  }

  Future<File?> _writeTempFile(Uint8List bytes, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File(p.join(dir.path, filename));
      await tempFile.writeAsBytes(bytes, flush: true);
      return tempFile;
    } catch (_) { return null; }
  }

  Future<void> _onAttachmentButtonPressed() async {
    await AttachmentPickerSheet.show(context, onSelected: _addAttachment);
  }

  void _removePendingAttachment(int index) {
    setState(() => _pendingAttachments.removeAt(index));
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final hasAttachments = _pendingAttachments.isNotEmpty;
    if ((text.isEmpty && !hasAttachments) || _isTyping) return;

    final userId = _currentUser?.id ?? "guest_user";
    _emptyCtrl.reset();
    final pendingSnapshot = List<Attachment>.from(_pendingAttachments);

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      conversationId: _currentConversationId,
      senderId: userId,
      createdAt: DateTime.now(),
      attachments: pendingSnapshot,
      modelName: _selectedModelName,
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _pendingAttachments.clear();
    });
    _controller.clear();
    _scrollToBottom();

    try {
      String finalPrompt = text;
      for (final att in pendingSnapshot) {
        if (att.localFile != null) {
          final uploaded = await _uploadService.uploadFile(
            file: att.localFile!,
            conversationId: _currentConversationId,
          );
          finalPrompt += uploaded.promptFragment;
        }
      }
      await _supabase.from('chat_messages').insert(userMsg.toMap());
      final response = await _api.getAIResponse(finalPrompt, userId);

      final aiMsg = ChatMessage(
        text: response,
        isUser: false,
        conversationId: _currentConversationId,
        senderId: 'agent',
        createdAt: DateTime.now(),
        modelName: _selectedModelName,
      );

      await _supabase.from('chat_messages').insert(aiMsg.toMap());
      if (!mounted) return;
      setState(() { _messages.add(aiMsg); });
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          _buildBlurredBackground(),

          // INTEGRATED: GLOBAL BLUR LAYER
          // This blurs the whole screen except the MessageBox when hovered
          if (_isMessageBoxHovered)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

          Row(
            children: [
              LeftSidebar(
                onNewChat: () {
                  setState(() {
                    _messages.clear();
                    _pendingAttachments.clear();
                    _generateConversationId();
                    _emptyCtrl.forward(from: 0.0);
                  });
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    const _ParticleBackground(count: 22),
                    if (_messages.isEmpty)
                      Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          child: FadeTransition(
                            opacity: _emptyOpacity,
                            child: ScaleTransition(
                              scale: _emptyScale,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGreeting(),
                                  const SizedBox(height: 40),
                                  // Use MessageBox here
                                  _buildMessageBox(),
                                  const SizedBox(height: 16),
                                  _buildSuggestionPills(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Expanded(child: _buildChatThread()),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildMessageBox(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Syncing depth with Signup/Signin screens
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
                errorBuilder: (c, e, s) => Container(color: AppTheme.backgroundBlack),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  // INTEGRATED: New MessageBox Component
  Widget _buildMessageBox() {
    return MessageBox(
      controller: _controller,
      focusNode: _inputFocus,
      selectedModelName: _selectedModelName,
      hintText: _pendingAttachments.isNotEmpty ? "Describe files..." : "Type a message...",
      onSend: _handleSend,
      onAttachment: _onAttachmentButtonPressed,
      onLogout: _handleSignOut,
      onHoverChanged: (hovered) {
        setState(() => _isMessageBoxHovered = hovered);
      },
      onModelChanged: (model) {
        setState(() {
          _selectedModelName = model;
          // Find the ID based on the name
          final modelData = app_config.Config.models.firstWhere((m) => m.name == model);
          _selectedModelId = modelData.id;
        });
      },
    );
  }

  Widget _buildGreeting() {
    final userName = _userName ?? 'there';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 50,
              child: InfinityAnimation(
                size: 100,
                color: const Color(0xFF22C55E),
                duration: const Duration(seconds: 5),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                "< Welcome $userName >",
                style: GoogleFonts.outfit(
                    color: const Color(0xFFE8E8E8),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
            "< How May You be Helped >",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.w300)
        ),
        if (_userEmail != null) ...[
          const SizedBox(height: 8),
          Text("Signed in as $_userEmail", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildChatThread() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _AnimatedMessageRow(message: _messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildAvatar("⚡", AppTheme.primaryWhite),
          const SizedBox(width: 15),
          _ThinkingDots(),
        ],
      ),
    );
  }

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 32, width: 32,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
    );
  }

  Widget _buildSuggestionPills() {
    return Wrap(
      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
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

// ──────────────────────────────────────────────────────────────────────────
// MESSAGE ROW & AI CONTENT
// ──────────────────────────────────────────────────────────────────────────
class _AnimatedMessageRow extends StatefulWidget {
  final ChatMessage message;
  const _AnimatedMessageRow({required this.message});

  @override
  State<_AnimatedMessageRow> createState() => _AnimatedMessageRowState();
}

class _AnimatedMessageRowState extends State<_AnimatedMessageRow> {
  bool _isTypingComplete = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return FadeInAnimation(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.transparent : AppTheme.surfaceDark.withOpacity(0.3),
          border: const Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: msg.isUser ? Colors.white10 : Colors.blueAccent,
              child: Text(msg.isUser ? "👤" : "🤖", style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.isUser ? "USER" : msg.modelName.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white38)),
                  const SizedBox(height: 5),
                  if (msg.hasAttachments) AttachmentList(attachments: msg.attachments),
                  if (msg.hasText)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      child: msg.isUser
                          ? MarkdownBody(data: msg.text, styleSheet: MarkdownStyleSheet(p: GoogleFonts.outfit(color: Colors.white, fontSize: 15)))
                          : _buildAIContent(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIContent() {
    return _isTypingComplete
        ? MarkdownBody(data: widget.message.text, styleSheet: MarkdownStyleSheet(p: GoogleFonts.outfit(color: Colors.white, fontSize: 15)))
        : TypingText(
      text: widget.message.text,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      onComplete: () => setState(() => _isTypingComplete = true),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SuggestionPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

class _ThinkingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Row(children: [Text("...", style: TextStyle(color: Colors.white38, fontSize: 20))]);
}

class _ParticleBackground extends StatelessWidget {
  final int count;
  const _ParticleBackground({required this.count});
  @override
  Widget build(BuildContext context) => Opacity(opacity: 0.3, child: CustomPaint(painter: _ChatParticlePainter(0.0, count), size: MediaQuery.of(context).size));
}

class _ChatParticlePainter extends CustomPainter {
  final double progress;
  final int count;
  _ChatParticlePainter(this.progress, this.count);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white10;
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(Offset(math.Random().nextDouble() * size.width, math.Random().nextDouble() * size.height), 1.5, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _ChatParticlePainter oldDelegate) => false;
}
