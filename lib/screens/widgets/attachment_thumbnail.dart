// lib/screens/widgets/attachment_thumbnail.dart
//
// Display attachments inside chat bubbles.
// Fully integrated with Attachment model, AttachmentPickerSheet, MessageBox, Config
// ------------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/attachment_model.dart';
import '../../core/config.dart' as app_config;
import '../../core/chat_message.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AttachmentList — public entry point used inside chat bubbles
// ═══════════════════════════════════════════════════════════════════════════

class AttachmentList extends StatelessWidget {
  final List<Attachment> attachments;
  final double? maxWidth;
  final String? selectedModelName; // For vision capability check

  const AttachmentList({
    super.key,
    required this.attachments,
    this.maxWidth,
    this.selectedModelName,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments
            .map((a) => _AttachmentTile(
          attachment: a,
          selectedModelName: selectedModelName,
        ))
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tile router
// ═══════════════════════════════════════════════════════════════════════════

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  final String? selectedModelName;
  const _AttachmentTile({required this.attachment, this.selectedModelName});

  @override
  Widget build(BuildContext context) {
    Widget tile;
    switch (attachment.type) {
      case AttachmentType.image:
        tile = _ImageTile(attachment: attachment);
        break;
      case AttachmentType.pdf:
        tile = _PdfTile(attachment: attachment);
        break;
      case AttachmentType.text:
        tile = _TextTile(attachment: attachment);
        break;
      case AttachmentType.unknown:
        tile = _GenericTile(attachment: attachment);
        break;
    }

    // Vision Capability Check:
    // If the attachment is an image, and a model is selected, and that model
    // does not support vision, display a warning icon on the tile.
    if (attachment.type == AttachmentType.image && selectedModelName != null) {
      final supportsVision = app_config.Config.modelSupportsVision(selectedModelName!);
      if (!supportsVision) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            Positioned(
              top: -4,
              right: -4,
              child: Tooltip(
                message: '$selectedModelName does not support images/vision',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return tile;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Image tile
// ═══════════════════════════════════════════════════════════════════════════

class _ImageTile extends StatelessWidget {
  final Attachment attachment;
  const _ImageTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    // ✅ Declare ALL variables first, before any logic
    final String? url = attachment.url;
    final File? localFile = attachment.localFile;
    final Uint8List? bytes = attachment.bytes;

    final bool hasNetwork = url != null && url.isNotEmpty;
    final bool hasLocal = !kIsWeb && localFile != null && localFile.existsSync();
    final bool hasBytes = bytes != null && bytes.isNotEmpty;

    // ✅ Check if we have any image source
    if (!hasNetwork && !hasLocal && !hasBytes) {
      return const _ErrorTile(
        icon: Icons.broken_image_outlined,
        label: 'Image unavailable',
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreen(context, url, localFile, bytes),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, 260.0)
                : 260.0;

            return Container(
              constraints: BoxConstraints(
                maxWidth: maxW,
                maxHeight: maxW,
              ),
              // ✅ Pass all the variables in the right order
              child: _buildImageContent(hasNetwork, hasLocal, hasBytes, url, localFile, bytes),
            );
          },
        ),
      ),
    );
  }

  /// Build image content with priority: URL > local file > bytes
  Widget _buildImageContent(
      bool hasNetwork,
      bool hasLocal,
      bool hasBytes,
      String? url,
      File? localFile,
      Uint8List? bytes,
      ) {
    if (hasNetwork) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        memCacheWidth: 800,
        placeholder: (_, __) => const _LoadingTile(),
        errorWidget: (_, __, ___) =>
        const _ErrorTile(icon: Icons.broken_image_outlined),
      );
    }

    if (hasLocal) {
      return Image.file(
        localFile!,
        fit: BoxFit.cover,
        cacheWidth: 800,
        errorBuilder: (_, __, ___) =>
        const _ErrorTile(icon: Icons.broken_image_outlined),
      );
    }

    if (hasBytes) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        cacheWidth: 800,
        errorBuilder: (_, __, ___) =>
        const _ErrorTile(icon: Icons.broken_image_outlined),
      );
    }

    return const _ErrorTile(icon: Icons.broken_image_outlined);
  }

  void _openFullScreen(
      BuildContext context,
      String? url,
      File? localFile,
      Uint8List? bytes,
      ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => FullImageViewer(
          url: url,
          localFile: localFile,
          bytes: bytes,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PDF tile
// ═══════════════════════════════════════════════════════════════════════════

class _PdfTile extends StatelessWidget {
  final Attachment attachment;
  const _PdfTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final String? url = attachment.url;
    final File? localFile = attachment.localFile;
    final Uint8List? bytes = attachment.bytes;

    final bool hasUrl = url != null && url.isNotEmpty;
    final bool hasLocal = !kIsWeb && localFile != null && localFile.existsSync();
    final bool hasBytes = bytes != null && bytes.isNotEmpty;

    if (!hasUrl && !hasLocal && !hasBytes) {
      return const _ErrorTile(
        icon: Icons.picture_as_pdf_outlined,
        label: 'PDF unavailable',
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PdfViewerScreen(
              url: url,
              localFile: localFile,
              bytes: bytes,
              filename: attachment.filename,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AttachmentColors.tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AttachmentColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AttachmentColors.pdfBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: AttachmentColors.pdfIcon,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // ✅ Use sizeFormatted from the Attachment model
                  Text(
                    attachment.sizeFormatted,
                    // ✅ NOT const - uses withOpacity()
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.visibility_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Text/document tile
// ═══════════════════════════════════════════════════════════════════════════

class _TextTile extends StatelessWidget {
  final Attachment attachment;
  const _TextTile({required this.attachment});

  String _getFileExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filename.length - 1) {
      return 'FILE';
    }
    return filename.substring(dotIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AttachmentColors.tileBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AttachmentColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AttachmentColors.textBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AttachmentColors.textIcon,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // ✅ NOT const - uses withOpacity() in BoxDecoration
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AttachmentColors.textIcon.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        // ✅ Not const - uses instance method
                        _getFileExtension(attachment.filename).toUpperCase(),
                        style: const TextStyle(
                          color: AttachmentColors.textIcon,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      attachment.sizeFormatted,
                      // ✅ NOT const - uses withOpacity()
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generic file tile
// ═══════════════════════════════════════════════════════════════════════════

class _GenericTile extends StatelessWidget {
  final Attachment attachment;
  const _GenericTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AttachmentColors.tileBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          // ✅ NOT const - uses withOpacity()
          Text(
            attachment.sizeFormatted,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared mini widgets
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AttachmentColors.tileBg,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final IconData icon;
  final String? label;
  const _ErrorTile({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AttachmentColors.tileBg,
      width: 120,
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 24),
            if (label != null) ...[
              const SizedBox(height: 4),
              // ✅ NOT const - uses nullable variable
              Text(
                label!,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full-screen image viewer
// ═══════════════════════════════════════════════════════════════════════════

class FullImageViewer extends StatefulWidget {
  final String? url;
  final File? localFile;
  final Uint8List? bytes;

  const FullImageViewer({
    super.key,
    this.url,
    this.localFile,
    this.bytes,
  }) : assert(
  url != null || localFile != null || bytes != null,
  'Provide either url, localFile, or bytes',
  );

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late final TransformationController _transformCtrl;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(child: _buildImage()),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if (widget.url != null && widget.url!.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Long-press image for more options'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.url != null && widget.url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.url!,
        fit: BoxFit.contain,
        memCacheWidth: 2048,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    }

    if (widget.localFile != null) {
      return Image.file(
        widget.localFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    }

    if (widget.bytes != null) {
      return Image.memory(
        widget.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    }

    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 64,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full-screen PDF viewer
// ═══════════════════════════════════════════════════════════════════════════

class PdfViewerScreen extends StatefulWidget {
  final String? url;
  final File? localFile;
  final Uint8List? bytes;
  final String filename;

  const PdfViewerScreen({
    super.key,
    this.url,
    this.localFile,
    this.bytes,
    required this.filename,
  }) : assert(url != null || localFile != null || bytes != null, 'Provide either url, localFile, or bytes');

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          widget.filename,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _error != null
          ? _buildErrorState()
          : Stack(
        children: [
          _buildPdfViewer(),
          if (_loading) _buildLoadingState(),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (widget.url != null) {
      return SfPdfViewer.network(
        widget.url!,
        key: _pdfKey,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        onDocumentLoaded: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onDocumentLoadFailed: (details) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = details.error;
            });
          }
        },
      );
    } else if (widget.localFile != null) {
      return SfPdfViewer.file(
        widget.localFile!,
        key: _pdfKey,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        onDocumentLoaded: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onDocumentLoadFailed: (details) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = details.error;
            });
          }
        },
      );
    } else {
      return SfPdfViewer.memory(
        widget.bytes!,
        key: _pdfKey,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        onDocumentLoaded: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onDocumentLoadFailed: (details) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = details.error;
            });
          }
        },
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text('Loading document...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // ✅ NOT const - uses nullable variable
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE27457),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ChatMessageListItem — Helper to render chat messages with attachments
// ═══════════════════════════════════════════════════════════════════════════

/// Renders a chat message with its attachments.
class ChatMessageListItem extends StatelessWidget {
  final ChatMessage message;
  final String Function(String) getModelIcon;
  final String? selectedModelName;

  const ChatMessageListItem({
    super.key,
    required this.message,
    required this.getModelIcon,
    this.selectedModelName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: message.isUser
            ? Colors.transparent
            : Colors.white.withOpacity(0.012),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(
                message.isUser
                    ? '👤'
                    : getModelIcon(message.modelName),
                message.isUser ? Colors.blueGrey : const Color(0xFFE27457),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.isUser ? 'YOU' : message.modelName.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.white38,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ✅ Render attachments if present
                    if (message.hasAttachments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: AttachmentList(
                          attachments: message.attachments,
                          selectedModelName: selectedModelName,
                        ),
                      ),

                    // ✅ Render text
                    if (message.hasText)
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white,
                          ),
                          h1: const TextStyle(
                            color: Color(0xFFE27457),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          code: const TextStyle(
                            backgroundColor: Color(0xFF1E1E1E),
                            color: Colors.orangeAccent,
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
    );
  }
}
