import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium code block styled like Claude's code blocks.
/// Features: language label, copy button, horizontal scroll, syntax-tinted text.
class CodeSnippetCard extends StatefulWidget {
  final String code;
  final String? language;

  const CodeSnippetCard({
    super.key,
    required this.code,
    this.language,
  });

  @override
  State<CodeSnippetCard> createState() => _CodeSnippetCardState();
}

class _CodeSnippetCardState extends State<CodeSnippetCard> {
  bool _isCopied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Slightly blueish-dark (like Claude)
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E2E42), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: language label on left, copy button on right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF252535),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2E2E42)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language ?? 'code',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF9BA0B4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: _copyToClipboard,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_isCopied),
                      children: [
                        Icon(
                          _isCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                          size: 13,
                          color: _isCopied
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF9BA0B4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isCopied ? 'Copied!' : 'Copy code',
                          style: GoogleFonts.inter(
                            color: _isCopied
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF9BA0B4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code body — horizontally scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(18),
            child: SelectableText(
              widget.code.trimRight(),
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFCDD6F4), // Catppuccin text color
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
