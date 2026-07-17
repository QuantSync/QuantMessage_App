// lib/screens/widgets/share_chat_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareChatCard extends StatefulWidget {
  final String conversationId;

  const ShareChatCard({super.key, required this.conversationId});

  static Future<void> show(BuildContext context, String conversationId) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Share Chat',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: ShareChatCard(conversationId: conversationId),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ShareChatCard> createState() => _ShareChatCardState();
}

class _ShareChatCardState extends State<ShareChatCard> {
  bool _isPublic = false;
  bool _isCopied = false;

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String shareLink = 'https://quantsync.ai/share/${widget.conversationId}';

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C).withValues(alpha: 0.85), // Dark frosted background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Share chat",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Only messages up to this point will be shared.",
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Options Group
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildOption(
                    title: "Keep private",
                    subtitle: "Only you have access",
                    icon: Icons.lock_outline,
                    isSelected: !_isPublic,
                    onTap: () => setState(() => _isPublic = false),
                    isTop: true,
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  _buildOption(
                    title: "Create public link",
                    subtitle: "Anyone with the link can view",
                    icon: Icons.public,
                    isSelected: _isPublic,
                    onTap: () => setState(() => _isPublic = true),
                    isTop: false,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              "Don't share personal information or third-party content without permission, and see our Usage Policy.",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            
            // Link Box or Create Button
            if (_isPublic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shareLink,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _copyToClipboard(shareLink),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isCopied ? "Copied" : "Copy link",
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _isPublic = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Create share link",
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isTop,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: isTop
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
