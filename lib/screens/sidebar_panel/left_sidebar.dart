import 'package:flutter/material.dart';

class LeftSidebar extends StatefulWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onProjects;
  final VoidCallback? onArtifacts;
  final VoidCallback? onCode;
  final VoidCallback? onCustomise;
  final VoidCallback? onBook;
  final VoidCallback? onDownload;

  const LeftSidebar({
    Key? key,
    this.onNewChat,
    this.onProjects,
    this.onArtifacts,
    this.onCode,
    this.onCustomise,
    this.onBook,
    this.onDownload,
  }) : super(key: key);

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  // Tracks the currently selected icon index
  int _selectedIndex = 1; // Default to "New Chat"

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, // Decreased size for a sleeker look
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // === TOP PORTION ===
          _SidebarIconButton(
            icon: Icons.arrow_forward_ios,
            size: 14,
            index: 0,
            isSelected: _selectedIndex == 0,
            onTap: () => _setSelectedIndex(0),
          ),
          const SizedBox(height: 24),

          _SidebarIconButton(
            icon: Icons.add,
            index: 1,
            isSelected: _selectedIndex == 1,
            onTap: () {
              _setSelectedIndex(1);
              if (widget.onNewChat != null) widget.onNewChat!();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.chat_bubble_outline,
            index: 2,
            isSelected: _selectedIndex == 2,
            onTap: () => _setSelectedIndex(2),
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.layers_outlined,
            index: 3,
            isSelected: _selectedIndex == 3,
            onTap: () {
              _setSelectedIndex(3);
              if (widget.onProjects != null) widget.onProjects!();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.category_outlined,
            index: 4,
            isSelected: _selectedIndex == 4,
            onTap: () {
              _setSelectedIndex(4);
              if (widget.onArtifacts != null) widget.onArtifacts!();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.code,
            index: 5,
            isSelected: _selectedIndex == 5,
            onTap: () {
              _setSelectedIndex(5);
              if (widget.onCode != null) widget.onCode!();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.work_outline,
            index: 6,
            isSelected: _selectedIndex == 6,
            onTap: () {
              _setSelectedIndex(6);
              if (widget.onCustomise != null) widget.onCustomise!();
            },
          ),

          const Spacer(),

          // === MIDDLE PORTION ===
          _SidebarIconButton(
            icon: Icons.menu_book_outlined,
            index: 7,
            isSelected: _selectedIndex == 7,
            onTap: () {
              _setSelectedIndex(7);
              if (widget.onBook != null) widget.onBook!();
            },
          ),

          const Spacer(),

          // === BOTTOM PORTION ===
          _SidebarIconButton(
            icon: Icons.file_download_outlined,
            index: 8,
            isSelected: _selectedIndex == 8,
            showNotificationDot: true,
            onTap: () {
              _setSelectedIndex(8);
              if (widget.onDownload != null) widget.onDownload!();
            },
          ),
          const SizedBox(height: 24),

          // Profile Avatar
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFD3D3D3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AS',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final int index;
  final double size;
  final bool showNotificationDot;

  const _SidebarIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
    required this.isSelected,
    required this.index,
    this.size = 20.0, // Decreased icon size
    this.showNotificationDot = false,
  }) : super(key: key);

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Icon turns white if selected OR hovered
    final Color iconColor = (widget.isSelected || _isHovered)
        ? Colors.white
        : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            // The "Toggle Effect": highlight expands/appears when selected
            color: widget.isSelected
                ? Colors.white.withOpacity(0.15)
                : (_isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                widget.icon,
                color: iconColor,
                size: widget.size,
              ),
              if (widget.showNotificationDot)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
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