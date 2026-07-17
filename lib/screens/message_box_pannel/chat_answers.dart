import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/chat_message.dart';
import '../animations/animation_effects/fast_reveal_text.dart';
import 'code_snippet_card.dart';

/// Builder to intercept Markdown code blocks and render them using [CodeSnippetCard].
class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Check if this is a pre > code block (multiline code block)
    // flutter_markdown sometimes passes inline code as 'code' too.
    // Usually multiline code has textContent containing newlines.
    final String text = element.textContent;
    
    // Attempt to extract language from class (e.g. "language-dart")
    String? language;
    if (element.attributes['class'] != null) {
      final match = RegExp(r'language-(\w+)').firstMatch(element.attributes['class']!);
      if (match != null) {
        language = match.group(1);
      }
    }

    if (text.contains('\n') || language != null) {
      return CodeSnippetCard(
        code: text,
        language: language,
      );
    }
    
    // Fallback to default inline code rendering
    return null; 
  }
}

/// A highly readable, Claude-like center-aligned card for AI messages.
class ChatAnswerCard extends StatelessWidget {
  final ChatMessage message;

  const ChatAnswerCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // 65% of screen width to give it a concise, centered document feel
    final maxWidth = MediaQuery.of(context).size.width * 0.65;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Subtle dark card background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // (Claude just shows text without an avatar or name above every single block)
              
              const SizedBox(height: 4),
              
              // Markdown Content wrapped in FastRevealText
              FastRevealText(
                text: message.text,
                builder: (revealedText) => MarkdownBody(
                  data: revealedText,
                  selectable: true,
                  builders: {
                    'code': _CodeElementBuilder(),
                  },
                  styleSheet: MarkdownStyleSheet(
                    // Base text
                    p: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14, // reduced font size
                      height: 1.5,
                      fontWeight: FontWeight.w400, // increased weight for crispness
                    ),
                    // Bold Headings
                    strong: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  h1: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  h2: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  h3: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  // Italic Instructions
                  em: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  // Links / Sources
                  a: GoogleFonts.outfit(
                    color: const Color(0xFF2ECC71),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                  // Choices/Lists
                  listBullet: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  // Inline code (multiline handled by builder)
                  code: GoogleFonts.jetBrainsMono(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    color: const Color(0xFF2ECC71),
                    fontSize: 13.5,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.transparent, // Handled by our CodeSnippetCard
                  ),
                  // Blockquotes
                  blockquote: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                  blockquoteDecoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Color(0xFF2ECC71),
                        width: 4,
                      ),
                    ),
                  ),
                  // Tables
                  tableBorder: TableBorder.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  tableHead: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  tableBody: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    tableCellsPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
