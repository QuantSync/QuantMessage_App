// lib/screens/widgets/attachment_picker_sheet.dart
// ------------------------------------------------------------
//   Cross-platform attachment picker (mobile + web)
//   Fully integrated with Attachment model and MessageBox
// ------------------------------------------------------------

import 'dart:convert'; // ← ADDED for base64.decode
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../core/attachment_model.dart';

/// Signature for the callback that receives the selected attachment.
typedef AttachmentSelected = void Function(Attachment attachment);

/// Maximum file size: 20 MB (configurable)
const int kMaxAttachmentSizeBytes = 20 * 1024 * 1024;

class AttachmentPickerSheet extends StatefulWidget {
  final AttachmentSelected onSelected;
  final int? maxFileSizeBytes;
  final List<AttachmentType>? allowedTypes;

  const AttachmentPickerSheet({
    super.key,
    required this.onSelected,
    this.maxFileSizeBytes,
    this.allowedTypes,
  });

  static Future<void> show(
      BuildContext context, {
        required AttachmentSelected onSelected,
        int? maxFileSizeBytes,
        List<AttachmentType>? allowedTypes,
      }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AttachmentPickerSheet(
        onSelected: onSelected,
        maxFileSizeBytes: maxFileSizeBytes,
        allowedTypes: allowedTypes,
      ),
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

  bool _busy = false;

  int get _maxFileSize => widget.maxFileSizeBytes ?? kMaxAttachmentSizeBytes;

  static const List<String> _allowedExtensions = [
    'pdf',
    'txt',
    'doc',
    'docx',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'md',
    'csv',
    'json',
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Pickers (cross-platform)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        await _processAndDeliver(bytes, image.name);
      }
    } catch (e) {
      _showError('Could not pick image: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_busy) return;
    if (kIsWeb) {
      _showError('📷 Camera is only available on mobile devices.');
      return;
    }
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        await _processAndDeliver(bytes, image.name, mimeOverride: 'image/jpeg');
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
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile picked = result.files.single;
      Uint8List? bytes = picked.bytes;

      if (bytes == null && picked.path != null) {
        final file = File(picked.path!);
        bytes = await file.readAsBytes();
      }

      if (bytes != null && mounted) {
        await _processAndDeliver(bytes, picked.name);
      }
    } catch (e) {
      _showError('File picker error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Clipboard handling — NULL-SAFE VERSION
  // ═══════════════════════════════════════════════════════════════════════

  /// Paste image from clipboard
  Future<void> _pasteFromClipboard() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = await _readImageFromClipboardWeb();
      } else {
        bytes = await _readImageFromClipboardMobile();
      }

      if (bytes != null && bytes.isNotEmpty) {
        final filename =
            'pasted_${DateTime.now().millisecondsSinceEpoch}.png';
        await _processAndDeliver(bytes, filename, mimeOverride: 'image/png');
      } else {
        _showError('No image found in clipboard. Try copying an image first.');
      }
    } catch (e) {
      _showError('Clipboard error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Web: Read image from clipboard
  Future<Uint8List?> _readImageFromClipboardWeb() async {
    try {
      // Method 1: Try 'image/png' MIME type
      final ClipboardData? pngData = await Clipboard.getData('image/png');
      final String? pngText = pngData?.text;
      if (pngText != null && pngText.isNotEmpty) {
        final Uint8List? decoded = _base64ToBytes(pngText);
        if (decoded != null) return decoded;
      }

      // Method 2: Try 'text/plain' (some browsers put data URL there)
      final ClipboardData? plainData =
      await Clipboard.getData(Clipboard.kTextPlain);
      final String? plainText = plainData?.text;
      if (plainText != null && plainText.isNotEmpty) {
        if (plainText.startsWith('data:image')) {
          final Uint8List? decoded = _base64ToBytes(plainText);
          if (decoded != null) return decoded;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Web clipboard read error: $e');
      return null;
    }
  }

  /// Mobile: Try to read image from clipboard
  Future<Uint8List?> _readImageFromClipboardMobile() async {
    try {
      // Try text/plain MIME type
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

      // ✅ Extract to local variable with nullable type
      final String? text = data?.text;

      // ✅ Single null check covers all subsequent uses
      if (text == null || text.isEmpty) {
        return null;
      }

      // Now `text` is guaranteed non-null in this scope
      if (text.startsWith('data:image')) {
        final Uint8List? decoded = _base64ToBytes(text);
        if (decoded != null) return decoded;
      }

      // Android: try to get image URI
      if (!kIsWeb) {
        try {
          if (text.startsWith('content://') || text.startsWith('file://')) {
            final String path = text.replaceFirst('file://', '');
            final File file = File(path);
            if (await file.exists()) {
              return await file.readAsBytes();
            }
          }
        } catch (_) {
          // Ignore file read errors
        }
      }

      return null;
    } catch (e) {
      debugPrint('Mobile clipboard read error: $e');
      return null;
    }
  }

  /// Convert base64 string to bytes
  Uint8List? _base64ToBytes(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      return base64.decode(cleanBase64);
    } catch (e) {
      debugPrint('Base64 decode error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Processing & delivery
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _processAndDeliver(
      Uint8List bytes,
      String filename, {
        String? mimeOverride,
      }) async {
    if (bytes.length > _maxFileSize) {
      final sizeMB = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      final maxMB = (_maxFileSize / 1024 / 1024).toStringAsFixed(0);
      _showError('File too large ($sizeMB MB). Max allowed: $maxMB MB');
      return;
    }

    final mime = mimeOverride ?? _guessMime(filename);
    final attachment = AttachmentX.fromBytes(bytes, filename, mime);

    if (widget.allowedTypes != null &&
        !widget.allowedTypes!.contains(attachment.type)) {
      _showError('File type "${attachment.type.name}" is not allowed');
      return;
    }

    if (mounted) {
      widget.onSelected(attachment);
      Navigator.of(context).pop();
    }
  }

  String _guessMime(String filename) {
    return lookupMimeType(filename) ?? 'application/octet-stream';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(_slideAnim),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.98),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: Color(0xFFE27457), size: 22),
                      SizedBox(width: 10),
                      Text(
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
                    kIsWeb
                        ? 'Pick from your computer — images, PDFs, docs'
                        : 'Upload an image or document for the AI to analyze',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OptionTile(
                    icon: Icons.image_outlined,
                    title:
                    kIsWeb ? 'Image from Computer' : 'Photo from Gallery',
                    subtitle: 'JPG, PNG, WebP, GIF',
                    onTap: _pickFromGallery,
                    enabled: !_busy,
                  ),
                  _OptionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take a Photo',
                    subtitle: kIsWeb ? '📷 Mobile only' : 'Use your camera',
                    onTap: _takePhoto,
                    enabled: !_busy && !kIsWeb,
                  ),
                  _OptionTile(
                    icon: Icons.content_paste_rounded,
                    title: 'Paste from Clipboard',
                    subtitle: kIsWeb
                        ? 'Copy an image then click here'
                        : 'Copy an image from gallery, then paste here',
                    onTap: _pasteFromClipboard,
                    enabled: !_busy,
                  ),
                  _OptionTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Document (PDF / File)',
                    subtitle: 'PDF, TXT, DOC, DOCX, MD, CSV',
                    onTap: _pickFile,
                    enabled: !_busy,
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white70),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: Colors.white24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Max file size: ${(_maxFileSize / 1024 / 1024).toStringAsFixed(0)} MB',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable tile widget (unchanged)
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
    final Color baseColor =
    widget.enabled ? Colors.white : Colors.white.withOpacity(0.3);

    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _hovered = false);
      },
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown:
        widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
        widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
        widget.enabled ? () => setState(() => _pressed = false) : null,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE27457).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: baseColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            color: baseColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
