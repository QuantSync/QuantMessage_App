// lib/screens/widgets/attachment_preview.dart
// ------------------------------------------------------------
//   Attachment preview strip shown inside the MessageBox input area.
// ------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/attachment_model.dart';

class AttachmentPreviewStrip extends StatelessWidget {
  final List<Attachment> attachments;
  final Function(int) onRemove;

  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final att = attachments[index];
          return _AttachmentPreviewTile(
            attachment: att,
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}

class _AttachmentPreviewTile extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentPreviewTile({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AttachmentColors.tileBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AttachmentColors.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildPreview(),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          if (attachment.status == UploadStatus.uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: attachment.progress > 0 ? attachment.progress : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFE27457)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (attachment.type == AttachmentType.image) {
      if (attachment.url != null && attachment.url!.isNotEmpty) {
        return Image.network(attachment.url!, fit: BoxFit.cover);
      }
      if (!kIsWeb && attachment.localFile != null && attachment.localFile!.existsSync()) {
        return Image.file(attachment.localFile!, fit: BoxFit.cover);
      }
      if (attachment.bytes != null && attachment.bytes!.isNotEmpty) {
        return Image.memory(attachment.bytes!, fit: BoxFit.cover);
      }
      return const Icon(Icons.image, color: Colors.white38, size: 20);
    }

    if (attachment.type == AttachmentType.pdf) {
      return Container(
        color: AttachmentColors.pdfBg,
        child: const Icon(Icons.picture_as_pdf, color: AttachmentColors.pdfIcon, size: 24),
      );
    }

    if (attachment.type == AttachmentType.text) {
      return Container(
        color: AttachmentColors.textBg,
        child: const Icon(Icons.description, color: AttachmentColors.textIcon, size: 24),
      );
    }

    return const Icon(Icons.insert_drive_file, color: Colors.white54, size: 20);
  }
}
