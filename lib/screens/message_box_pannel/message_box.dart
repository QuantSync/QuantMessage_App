// lib/screens/message_box_pannel/message_box.dart
// QuantMessage — Message Box (Fully Integrated)
// Synchronized with: Attachment model, UploadService, ChatScreen, IncognitoScreen,
// AttachmentPickerSheet, Config, ChatMessage

import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ✅ FIXED: Use alias to avoid conflict with google_fonts' internal Config
import '../../core/config.dart' as app_config;
import '../../core/attachment_model.dart';
import '../widgets/attachment_picker_sheet.dart';
import '../widgets/attachment_preview.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MessageBox
// ═══════════════════════════════════════════════════════════════════════════

class MessageBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String selectedModelName;

  /// Whether the LLM is currently generating a response.
  /// When true, the send button becomes non-interactive and visually dimmed.
  final bool isGenerating;

  final Function(String text, List<Attachment> attachments) onSend;
  final Function(String) onModelChanged;
  final VoidCallback onLogout;
  final Function(bool isHovered) onHoverChanged;

  const MessageBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = "Type a message...",
    required this.selectedModelName,
    this.isGenerating = false,
    required this.onSend,
    required this.onModelChanged,
    required this.onLogout,
    required this.onHoverChanged,
  });

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isFocused = false;

  final List<Attachment> _pendingAttachments = [];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    widget.focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Attachment handling
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleAttachmentClick() async {
    // ✅ Use app_config alias
    final bool isVisionModel =
    app_config.Config.modelSupportsVision(widget.selectedModelName);

    await AttachmentPickerSheet.show(
      context,
      onSelected: (Attachment attachment) async {
        if (attachment.bytes != null) {
          final tempFile =
          await _writeTempFile(attachment.bytes!, attachment.filename);
          if (tempFile != null) {
            final ready = attachment.copyWith(localFile: tempFile);
            if (mounted) {
              setState(() => _pendingAttachments.add(ready));
            }
          } else {
            if (mounted) {
              setState(() => _pendingAttachments.add(attachment));
            }
          }
        } else {
          if (mounted) {
            setState(() => _pendingAttachments.add(attachment));
          }
        }
      },
      allowedTypes: isVisionModel
          ? null
          : [
        AttachmentType.text,
        AttachmentType.pdf,
        AttachmentType.unknown,
      ],
    );
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

  void _removeAttachment(int index) {
    if (!mounted) return;
    setState(() => _pendingAttachments.removeAt(index));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Send handling
  // ═══════════════════════════════════════════════════════════════════════

  void _triggerSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    widget.onSend(text, List<Attachment>.from(_pendingAttachments));

    if (mounted) {
      setState(() {
        widget.controller.clear();
        _pendingAttachments.clear();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Hover handling
  // ═══════════════════════════════════════════════════════════════════════

  void _handleHover(bool hovered) {
    if (!mounted) return;
    setState(() => _isHovered = hovered);
    widget.onHoverChanged(hovered);
    if (hovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.4),
                    blurRadius: _isHovered ? 25 : 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF1E1E1E).withOpacity(0.95),
                      border: Border.all(
                        color: _isFocused
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        width: _isFocused ? 1.5 : 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_pendingAttachments.isNotEmpty) ...[
                            AttachmentPreviewStrip(
                              attachments: _pendingAttachments,
                              onRemove: _removeAttachment,
                            ),
                            const SizedBox(height: 10),
                          ],
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 28,
                              maxHeight:
                                  (MediaQuery.sizeOf(context).height * 0.5)
                                      .clamp(180.0, 520.0),
                            ),
                            child: TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              // Capacity: up to 5000 lines (scrolls within viewport)
                              maxLines: 5000,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 2,
                                ),
                              ),
                              onSubmitted: (_) => _triggerSend(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _CircleIconButton(
                                icon: Icons.add,
                                tooltip: "Add attachment",
                                onTap: _handleAttachmentClick,
                                isHovered: _isHovered,
                              ),
                              const Spacer(),
                              _ModelDropdown(
                                currentModel: widget.selectedModelName,
                                onChanged: widget.onModelChanged,
                                isHovered: _isHovered,
                              ),
                              const SizedBox(width: 6),
                              _CircleIconButton(
                                icon: Icons.mic_none,
                                tooltip: "Voice input",
                                onTap: () {},
                                isHovered: _isHovered,
                              ),
                              const SizedBox(width: 6),
                              _CircleIconButton(
                                icon: Icons.graphic_eq,
                                tooltip: "Audio settings",
                                onTap: () {},
                                isHovered: _isHovered,
                              ),
                              const SizedBox(width: 10),
                              _SendButton(
                                onTap: _triggerSend,
                                isHovered: _isHovered,
                                isGenerating: widget.isGenerating,
                              ),
                              const SizedBox(width: 6),
                              _CircleIconButton(
                                icon: Icons.logout_rounded,
                                tooltip: "Logout",
                                onTap: widget.onLogout,
                                isHovered: _isHovered,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Internal Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isHovered;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isHovered,
  });

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _localHover = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.isHovered || _localHover;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _localHover = true),
        onExit: (_) => setState(() => _localHover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: isHighlighted ? Colors.white : Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isHovered;
  final bool isGenerating;

  const _SendButton({
    required this.onTap,
    required this.isHovered,
    this.isGenerating = false,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  // Active green
  static const Color _activeGreen = Color(0xFF2ECC71);
  // Disabled dark desaturated green
  static const Color _disabledGreen = Color(0xFF3A5A40);

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isGenerating;
    final bool isHighlighted = !disabled && (widget.isHovered || _pressed);

    final Color bgColor = disabled
        ? _disabledGreen
        : (isHighlighted ? _activeGreen : _activeGreen.withValues(alpha: 0.7));
    final Color iconColor = disabled
        ? Colors.white38
        : (isHighlighted ? Colors.black : Colors.white);

    return IgnorePointer(
      ignoring: disabled,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isHighlighted
                  ? [
                BoxShadow(
                  color: _activeGreen.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatefulWidget {
  final String currentModel;
  final Function(String) onChanged;
  final bool isHovered;

  const _ModelDropdown({
    required this.currentModel,
    required this.onChanged,
    required this.isHovered,
  });

  @override
  State<_ModelDropdown> createState() => _ModelDropdownState();
}

class _ModelDropdownState extends State<_ModelDropdown> {
  bool _localHover = false;


  void _showModelMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModelDropdown',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) {
        return _ModelDropdownOverlay(
          currentModel: widget.currentModel,
          onChanged: (value) {
            Navigator.of(ctx).pop();
            if (value != null && value != widget.currentModel) {
              widget.onChanged(value);
            }
          },
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isHovered || _localHover;

    final model = app_config.Config.getModelByName(widget.currentModel);
    final supportsVision = model?.supportsVision ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _localHover = true),
      onExit: (_) => setState(() => _localHover = false),
      child: GestureDetector(
        onTap: _showModelMenu,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (supportsVision) ...[
                const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFFE27457),
                  size: 12,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  widget.currentModel,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _localHover ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Model Dropdown Overlay — centered dialog with blur background
// ═══════════════════════════════════════════════════════════════════════════

class _ModelDropdownOverlay extends StatelessWidget {
  final String currentModel;
  final Function(String?) onChanged;
  final VoidCallback onClose;

  const _ModelDropdownOverlay({
    required this.currentModel,
    required this.onChanged,
    required this.onClose,
  });

  // Group models by category label
  Map<String, List<app_config.AiModel>> get _groupedModels {
    final groups = <String, List<app_config.AiModel>>{};
    for (final cat in app_config.ModelCategory.values) {
      final label = _categoryLabel(cat);
      final models = app_config.Config.getModelsByCategory(cat);
      if (models.isNotEmpty) {
        groups[label] = models;
      }
    }
    return groups;
  }

  String _categoryLabel(app_config.ModelCategory cat) {
    switch (cat) {
      case app_config.ModelCategory.native:
        return 'Native';
      case app_config.ModelCategory.reasoning:
        return 'Reasoning';
      case app_config.ModelCategory.coding:
        return 'Coding';
      case app_config.ModelCategory.roleplay:
        return 'Roleplay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur + dismiss background
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),

          // Centered dropdown card
          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C).withOpacity(0.88),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
                                child: Row(
                                  children: [
                                    Text(
                                      'Choose Model',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    _OverlayCloseButton(onTap: onClose),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: Colors.white.withOpacity(0.1),
                                thickness: 1,
                                height: 1,
                              ),
                              // Model list grouped by category
                              Flexible(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: _groupedModels.entries.map((entry) {
                                      return _buildCategory(entry.key, entry.value);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String label, List<app_config.AiModel> models) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...models.map((m) => _buildModelTile(m)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildModelTile(app_config.AiModel model) {
    final isSelected = model.name == currentModel;
    return _ModelTile(
      model: model,
      isSelected: isSelected,
      onTap: () => onChanged(model.name),
    );
  }
}

class _ModelTile extends StatefulWidget {
  final app_config.AiModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelTile({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends State<_ModelTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isSelected || _isHovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(widget.model.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.model.name,
                            style: GoogleFonts.outfit(
                              color: widget.isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: widget.isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.model.supportsVision) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.visibility_outlined,
                            color: Color(0xFFE27457),
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                    if (widget.model.description.isNotEmpty)
                      Text(
                        widget.model.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OverlayCloseButton({required this.onTap});

  @override
  State<_OverlayCloseButton> createState() => _OverlayCloseButtonState();
}

class _OverlayCloseButtonState extends State<_OverlayCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.4 : 0.15),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            color: _isHovered ? Colors.white : Colors.white70,
            size: 16,
          ),
        ),
      ),
    );
  }
}
