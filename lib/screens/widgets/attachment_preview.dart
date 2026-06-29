// lib/screens/widgets/attachment_preview.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/chat_message.dart';
import '../../core/attachment_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  Horizontal scrollable strip of pending attachments above the input.
///
///  Now:
///  • Uses LayoutBuilder so it adapts to any orientation
///  • Clamps chip size to avoid RenderFlex overflow
///  • Caches images at fixed resolution (no rebuild jank)
///  • Wraps overlay in ClipRRect so progress bar respects border radius
/// ═══════════════════════════════════════════════════════════════════════════

class AttachmentPreviewStrip extends StatelessWidget {
  final List<Attachment> attachments;
  final ValueChanged<int> onRemove;

  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  // ← Constant chip dimensions — single source of truth
  static const double _chipSize = 72.0;
  static const double _chipSpacing = 8.0;
  static const double _stripHeight = _chipSize + 8.0; // small padding

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: _stripHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine how many chips can fit on screen (for placeholder sizing)
            final chipsFitting =
            ((constraints.maxWidth - 8) / (_chipSize + _chipSpacing))
                .floor()
                .clamp(1, 20);

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: _chipSpacing),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: _chipSize,
                  height: _chipSize,
                  child: _AttachmentChip(
                    attachment: attachments[index],
                    onRemove: () => onRemove(index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Individual chip — uses ClipRRect + safe positioned overlay
// ═══════════════════════════════════════════════════════════════════════════

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentChip({required this.attachment, required this.onRemove});

  static const double _size = 72.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      // ← KEY: ClipRRect wraps everything so nothing overflows the rounded edge
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Base thumbnail ───────────────────────────────────────
            _buildThumbnail(),

            // ── 2. Uploading/processing overlay ────────────────────────
            if (_isInFlight) _buildUploadingOverlay(),

            // ── 3. Failed overlay ──────────────────────────────────────
            if (attachment.status == UploadStatus.failed) _buildFailedOverlay(),

            // ── 4. Remove button (top-right, safe inside bounds) ───────
            Positioned(
              top: 2,
              right: 2,
              child: _RemoveButton(onTap: onRemove),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isInFlight =>
      attachment.status == UploadStatus.uploading ||
          attachment.status == UploadStatus.processing;

  // ── Thumbnail renderer ────────────────────────────────────────────────────
  Widget _buildThumbnail() {
    if (attachment.isImage) {
      // Local file first
      final local = attachment.localFile;
      if (local != null && local.existsSync()) {
        return Image.file(
          local,
          fit: BoxFit.cover,
          // ← Cache at 2x chip size for retina sharpness, no jank
          cacheWidth: 256,
          errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
        );
      }
      // Remote thumbnail
      final thumb = attachment.thumbnailUrl;
      if (thumb != null && thumb.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: thumb,
          fit: BoxFit.cover,
          memCacheWidth: 256,
          placeholder: (_, __) => _placeholder(Icons.image_outlined),
          errorWidget: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
        );
      }
      return _placeholder(Icons.image_outlined);
    }

    if (attachment.isPdf) {
      return Container(
        color: AttachmentColors.pdfBg,
        child: const Center(
          child: Icon(
            Icons.picture_as_pdf,
            color: AttachmentColors.pdfIcon,
            size: 28,
          ),
        ),
      );
    }

    if (attachment.type == AttachmentType.text) {
      return Container(
        color: const Color(0xFF1F2A3A),
        child: const Center(
          child: Icon(
            Icons.description_outlined,
            color: Color(0xFF7FA8FF),
            size: 28,
          ),
        ),
      );
    }

    return _placeholder(Icons.insert_drive_file_outlined);
  }

  // ── Overlays ─────────────────────────────────────────────────────────────
  Widget _buildUploadingOverlay() {
    final isUploading = attachment.status == UploadStatus.uploading;
    final progress = attachment.progress.clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: isUploading
              ? Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: 1.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
              // Progress arc
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: progress,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              // Percentage text
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
              : const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    return Container(
      color: Colors.red.withOpacity(0.75),
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: AttachmentColors.tileBg,
      child: Center(child: Icon(icon, color: Colors.white54, size: 24)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Remove button — small, tappable, with hit-test padding
// ═══════════════════════════════════════════════════════════════════════════

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      // ← Expands the hit area so it's easy to tap without overflow
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
