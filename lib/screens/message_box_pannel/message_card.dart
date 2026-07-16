// lib/screens/message_box_pannel/message_card.dart
// QuantMessage — Message Card
// A styled card that displays a user's message (including long chunks)
// inside the chat thread. Supports text + attachment thumbnails.
// Integrated with: MessageBox, ChatScreen, IncognitoScreen, HistoryScreen,
//                  AttachmentThumbnail, AttachmentPreview, ChatMessage,
//                  AttachmentModel, AttachmentPickerSheet
// ------------------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/attachment_model.dart';
import '../../core/chat_message.dart';
import '../widgets/attachment_thumbnail.dart';

/// A premium glass-morphism card that renders a user or AI message.
///
/// Features:
/// - Handles very long text gracefully (auto-wraps, scrollable if needed).
/// - Shows attachment thumbnails when the message has files.
/// - Subtle rounded container with blur backdrop for the dark theme.
class MessageCard extends StatelessWidget {
  /// The [ChatMessage] to display.
  final ChatMessage message;

  /// Currently selected model name — forwarded to [AttachmentList] for vision check.
  final String? selectedModelName;

  /// If true, text is rendered with Markdown support.
  final bool useMarkdown;

  const MessageCard({
    super.key,
    required this.message,
    this.selectedModelName,
    this.useMarkdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF2A2A2A).withOpacity(0.85),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Attachment thumbnails (if any)
                    if (message.hasAttachments) ...[
                      AttachmentList(
                        attachments: message.attachments,
                        selectedModelName: selectedModelName,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Message text
                    if (message.hasText)
                      useMarkdown
                          ? MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 14.5,
                                  height: 1.55,
                                ),
                                h1: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                h2: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                code: GoogleFonts.jetBrainsMono(
                                  backgroundColor: const Color(0xFF161616),
                                  color: const Color(0xFF2ECC71),
                                  fontSize: 13,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: const Color(0xFF161616),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                blockquote: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontStyle: FontStyle.italic,
                                ),
                                blockquoteDecoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Color(0xFF2ECC71),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : SelectableText(
                              message.text,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),
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
