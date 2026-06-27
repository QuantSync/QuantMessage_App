import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';

import '../core/app_theme.dart';


Future<void> showSettingsPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) => const _SettingsDialog(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12 * anim1.value,
          sigmaY: 12 * anim1.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // --- State for various settings ---
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = false;
  int _selectedColorIndex = 0;
  String _selectedFont = 'Outfit';
  String _selectedMotion = 'Default';

  final List<Color> _themeColors = [
    AppTheme.primaryRed,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
  ];

  // Navigation items matching the image's sidebar
  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.tune_rounded, label: 'General'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Account'),
    _NavItem(icon: Icons.shield_outlined, label: 'Privacy'),
    _NavItem(icon: Icons.payment_rounded, label: 'Billing'),
    _NavItem(icon: Icons.auto_awesome_outlined, label: 'Capabilities'),
    _NavItem(icon: Icons.extension_outlined, label: 'Connectors'),
    _NavItem(icon: Icons.code_rounded, label: 'Advanced'),
  ];

  final List<String> _fontOptions = ['Outfit', 'Orbitron', 'Roboto', 'Inter', 'Mono'];
  final List<String> _motionOptions = ['Default', 'Reduced', 'None'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Dialog takes up ~75% width, ~80% height, capped at reasonable maxes
    final dialogWidth = (size.width * 0.78).clamp(340.0, 820.0);
    final dialogHeight = (size.height * 0.82).clamp(400.0, 620.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          from: 20,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.04),
                  blurRadius: 80,
                  spreadRadius: -10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // ========== LEFT SIDEBAR ==========
                _buildSidebar(dialogHeight),

                // ========== VERTICAL DIVIDER ==========
                Container(width: 1, color: Colors.white.withOpacity(0.06)),

                // ========== RIGHT CONTENT ==========
                Expanded(child: _buildContentPane()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(double height) {
    return Container(
      width: 210,
      color: const Color(0xFF141414),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Settings" label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Settings',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNavIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 17,
                          color: isSelected
                              ? AppTheme.primaryRed
                              : Colors.white.withOpacity(0.45),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.label,
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPane() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Top bar with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: SingleChildScrollView(
                key: ValueKey(_selectedNavIndex),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: _buildPageContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildGeneralPage();
      case 1:
        return _buildAccountPage();
      case 2:
        return _buildPrivacyPage();
      case 3:
        return _buildBillingPage();
      case 4:
        return _buildCapabilitiesPage();
      case 5:
        return _buildConnectorsPage();
      case 6:
        return _buildAdvancedPage();
      default:
        return _buildGeneralPage();
    }
  }

  Widget _buildGeneralPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Profile Section ---
        _sectionTitle('Profile'),
        const SizedBox(height: 16),

        // Avatar row
        _settingsRow(
          label: 'Avatar',
          trailing: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_themeColors[_selectedColorIndex], _themeColors[_selectedColorIndex].withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _themeColors[_selectedColorIndex].withOpacity(0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'JD',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        _divider(),

        // Full name
        _settingsRow(
          label: 'Full name',
          trailing: _pillValue('John Doe'),
        ),

        _divider(),

        // What should we call you?
        _settingsRow(
          label: 'Display name',
          trailing: _pillValue('John Doe'),
        ),

        _divider(),

        // What best describes your work?
        _settingsRow(
          label: 'What best describes your work?',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Developer', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.4), size: 18),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // --- Instructions ---
        _sectionTitle('Instructions'),
        const SizedBox(height: 6),
        Text(
          'Custom instructions are remembered across all chats.',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.35),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: TextField(
            maxLines: 4,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. when learning new concepts, I find analogies particularly helpful.',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              filled: false,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // --- Preferences Section ---
        _sectionTitle('Preferences'),
        const SizedBox(height: 16),

        // Appearance row with system/light/dark icons
        _settingsRow(
          label: 'Appearance',
          trailing: _buildAppearanceToggle(),
        ),

        _divider(),

        // Chat font
        _settingsRow(
          label: 'Chat font',
          trailing: _buildDropdown(_selectedFont, _fontOptions, (val) {
            setState(() => _selectedFont = val);
          }),
        ),

        _divider(),

        // Motion
        _settingsRow(
          label: 'Motion',
          trailing: _buildDropdown(_selectedMotion, _motionOptions, (val) {
            setState(() => _selectedMotion = val);
          }),
        ),

        _divider(),

        // Theme Accent Colors
        _settingsRow(
          label: 'Theme accent',
          trailing: _buildColorDots(),
        ),

        _divider(),

        // Notifications
        _settingsRow(
          label: 'Notifications',
          trailing: _buildMiniSwitch(_notificationsEnabled, (val) {
            setState(() => _notificationsEnabled = val);
          }),
        ),

        _divider(),

        // Sound
        _settingsRow(
          label: 'Sound effects',
          trailing: _buildMiniSwitch(_soundEnabled, (val) {
            setState(() => _soundEnabled = val);
          }),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccountPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Account'),
        const SizedBox(height: 16),

        _settingsRow(
          label: 'Email',
          trailing: Text('john.doe@quantspace.ai',
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ),
        _divider(),
        _settingsRow(
          label: 'Password',
          trailing: _actionButton('Change', () {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Two-factor authentication',
          trailing: _actionButton('Enable', () {}),
        ),

        const SizedBox(height: 32),
        _sectionTitle('Connected Accounts'),
        const SizedBox(height: 16),
        _buildConnectedAccount(Icons.facebook_rounded, 'Facebook', true, const Color(0xFF1877F2)),
        _divider(),
        _buildConnectedAccount(Icons.code_rounded, 'GitHub', false, Colors.white70),
        _divider(),
        _buildConnectedAccount(Icons.camera_alt_rounded, 'Instagram', false, const Color(0xFFE1306C)),

        const SizedBox(height: 32),
        _sectionTitle('Danger Zone'),
        const SizedBox(height: 16),
        _settingsRow(
          label: 'Delete account',
          trailing: _actionButton('Delete', () {}, isDestructive: true),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildPrivacyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Privacy & Data'),
        const SizedBox(height: 16),

        _settingsRow(
          label: 'Data collection',
          trailing: _buildMiniSwitch(false, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Analytics',
          trailing: _buildMiniSwitch(true, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Incognito mode',
          trailing: _buildMiniSwitch(false, (val) {}),
        ),

        const SizedBox(height: 28),
        _sectionTitle('Data Management'),
        const SizedBox(height: 16),
        _settingsRow(
          label: 'Export your data',
          trailing: _actionButton('Export', () {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Clear chat history',
          trailing: _actionButton('Clear', () {}, isDestructive: true),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // =======================================================================
  //  BILLING PAGE
  // =======================================================================
  Widget _buildBillingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Subscription'),
        const SizedBox(height: 16),

        // Current plan card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryRed.withOpacity(0.12),
                AppTheme.primaryRed.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Plan',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Upgrade for unlimited access',
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              _actionButton('Upgrade', () {}, isPrimary: true),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _settingsRow(
          label: 'Payment method',
          trailing: _actionButton('Add card', () {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Billing history',
          trailing: _actionButton('View', () {}),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // =======================================================================
  //  CAPABILITIES PAGE
  // =======================================================================
  Widget _buildCapabilitiesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('AI Capabilities'),
        const SizedBox(height: 16),

        _settingsRow(
          label: 'Web search',
          trailing: _buildMiniSwitch(true, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Code execution',
          trailing: _buildMiniSwitch(true, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Image generation',
          trailing: _buildMiniSwitch(false, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'File uploads',
          trailing: _buildMiniSwitch(true, (val) {}),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // =======================================================================
  //  CONNECTORS PAGE
  // =======================================================================
  Widget _buildConnectorsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Integrations'),
        const SizedBox(height: 16),

        _buildConnectedAccount(Icons.storage_rounded, 'Google Drive', true, const Color(0xFF4285F4)),
        _divider(),
        _buildConnectedAccount(Icons.cloud_outlined, 'Dropbox', false, const Color(0xFF0061FF)),
        _divider(),
        _buildConnectedAccount(Icons.link_rounded, 'Slack', false, const Color(0xFF4A154B)),
        _divider(),
        _buildConnectedAccount(Icons.description_outlined, 'Notion', false, Colors.white70),
        const SizedBox(height: 16),
      ],
    );
  }

  // =======================================================================
  //  ADVANCED PAGE
  // =======================================================================
  Widget _buildAdvancedPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Advanced Settings'),
        const SizedBox(height: 16),

        _settingsRow(
          label: 'Developer mode',
          trailing: _buildMiniSwitch(false, (val) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'API access',
          trailing: _actionButton('Generate key', () {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Debug logging',
          trailing: _buildMiniSwitch(false, (val) {}),
        ),

        const SizedBox(height: 32),

        // Logout
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // =======================================================================
  //  SHARED BUILDING BLOCKS
  // =======================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white.withOpacity(0.06), height: 1);
  }

  /// A single settings row: label on the left, trailing widget on the right.
  Widget _settingsRow({required String label, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  /// Dark pill showing a value (e.g. name/email)
  Widget _pillValue(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.75), fontSize: 13),
      ),
    );
  }

  /// A small action button
  Widget _actionButton(String label, VoidCallback onTap,
      {bool isDestructive = false, bool isPrimary = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isPrimary
            ? AppTheme.primaryRed.withOpacity(0.15)
            : isDestructive
            ? Colors.redAccent.withOpacity(0.1)
            : Colors.white.withOpacity(0.06),
        foregroundColor: isPrimary
            ? AppTheme.primaryRed
            : isDestructive
            ? Colors.redAccent
            : Colors.white.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  /// Appearance toggle (system / light / dark) matching the image
  Widget _buildAppearanceToggle() {
    final modes = [
      {'icon': Icons.laptop_mac_rounded, 'mode': 'system'},
      {'icon': Icons.light_mode_rounded, 'mode': 'light'},
      {'icon': Icons.dark_mode_rounded, 'mode': 'dark'},
    ];
    final selectedMode = _isDarkMode ? 'dark' : 'light';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isActive = m['mode'] == selectedMode;
          return GestureDetector(
            onTap: () {
              setState(() {
                _isDarkMode = m['mode'] == 'dark' || m['mode'] == 'system';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                m['icon'] as IconData,
                size: 16,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_themeColors.length, (i) {
        final isSelected = _selectedColorIndex == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 7),
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: _themeColors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _themeColors[i].withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  /// Mini switch (more compact than the default Material switch)
  Widget _buildMiniSwitch(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 28,
      child: FittedBox(
        child: Switch(
          value: value,
          activeColor: AppTheme.primaryRed,
          activeTrackColor: AppTheme.primaryRed.withOpacity(0.3),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white.withOpacity(0.1),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Styled dropdown menu
  Widget _buildDropdown(String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.4), size: 18),
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
          isDense: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  /// Connected account row
  Widget _buildConnectedAccount(IconData icon, String name, bool connected, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.75), fontSize: 13.5),
            ),
          ),
          _actionButton(connected ? 'Connected' : 'Connect', () {}),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Show popup after frame renders, then pop the route when closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showSettingsPopup(context);
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transparent scaffold while the popup is opening
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}