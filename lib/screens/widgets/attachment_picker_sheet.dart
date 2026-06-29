// lib/screens/widgets/attachment_picker_sheet.dart

import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef AttachmentSelected = void Function(File file, String mimeType);

/// ═══════════════════════════════════════════════════════════════════════════
///  Modal bottom sheet for picking an attachment.
///
///  Now:
///  • Uses backdrop blur so the chat screen blurs behind it
///  • Stateful for safe async handling (camera, file picker)
///  • Built-in entry animation that matches chat_screen.dart
///  • Properly synced with chat_screen's design language
/// ═══════════════════════════════════════════════════════════════════════════

class AttachmentPickerSheet extends StatefulWidget {
  final AttachmentSelected onSelected;
  const AttachmentPickerSheet({super.key, required this.onSelected});

  static Future<void> show(
      BuildContext context, {
        required AttachmentSelected onSelected,
      }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // ← we draw our own background
      barrierColor: Colors.black.withOpacity(0.55), // ← semi-transparent
      barrierLabel: 'Dismiss',
      isScrollControlled: true,
      elevation: 0,
      // ← Enable backdrop blur on supported platforms
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AttachmentPickerSheet(onSelected: onSelected),
    );
  }

  @override
  State<AttachmentPickerSheet> createState() => _AttachmentPickerSheetState();
}

class _AttachmentPickerSheetState extends State<AttachmentPickerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  bool _busy = false; // shows loading state during async pick

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        widget.onSelected(
          File(image.path),
          'image/${image.path.split('.').last}',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Gallery error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        widget.onSelected(File(image.path), 'image/jpeg');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Camera error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: false,
      );
      if (result != null &&
          result.files.single.path != null &&
          mounted) {
        final file = File(result.files.single.path!);
        widget.onSelected(file, _mimeFromExt(file.path));
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('File picker error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _mimeFromExt(String path) {
    final ext = path.split('.').last.toLowerCase();
    return {
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    }[ext] ??
        'application/octet-stream';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Slide-up entry animation
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          top: false,
          child: Container(
            // Backdrop blur for premium feel — works on iOS, macOS, Android 12+
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.96),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Drag handle ───────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // ── Title ─────────────────────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFFE27457),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Add to chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload an image or document for the AI to analyze',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Options ───────────────────────────────────────
                    _OptionTile(
                      icon: Icons.image_outlined,
                      title: 'Photo from Gallery',
                      subtitle: 'JPG, PNG, WebP, GIF',
                      onTap: _pickFromGallery,
                      enabled: !_busy,
                    ),
                    _OptionTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Take a Photo',
                      subtitle: 'Use your camera to capture something',
                      onTap: _takePhoto,
                      enabled: !_busy,
                    ),
                    _OptionTile(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Document (PDF)',
                      subtitle: 'Upload a PDF for analysis',
                      onTap: _pickFile,
                      enabled: !_busy,
                    ),

                    const SizedBox(height: 12),

                    // ── Busy indicator ─────────────────────────────────
                    if (_busy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Opening...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 4),
                  ],
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
//  Reusable option tile — clean InkWell + hover-ready
// ═══════════════════════════════════════════════════════════════════════════

class _OptionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? Colors.white
        : Colors.white.withOpacity(0.3);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.10)
                : _hovered
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE27457).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
