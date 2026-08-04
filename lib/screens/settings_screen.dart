// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import 'account_settings_screen/general/profile/profile_settings.dart';
import 'account_settings_screen/account/account_settings.dart';
import 'account_settings_screen/privacy/privacy_settings.dart';
import 'account_settings_screen/billing/billing_settings.dart';
import 'account_settings_screen/capabilities/capabilities_settings.dart';
import 'account_settings_screen/connectors/connectors_settings.dart';
import 'account_settings_screen/quantcode/quantcode_settings.dart';
import 'account_settings_screen/skills/skills_settings.dart';
import 'account_settings_screen/plugins/plugins_settings.dart';
import 'account_settings_screen/memory/memory_settings.dart';

Future<void> showSettingsPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black.withOpacity(0.75),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) => const _SettingsDialog(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18 * anim1.value,
          sigmaY: 18 * anim1.value,
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

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  int _selectedNavIndex = 0; // Starts with General
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  
  // Theme state
  int _selectedColorIndex = 0;
  final List<Color> _themeColors = [
    AppTheme.primaryRed,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
  ];

  final List<_NavItem> _settingsItems = [
    _NavItem(icon: Icons.settings_outlined, label: 'General', index: 0),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Account', index: 1),
    _NavItem(icon: Icons.shield_outlined, label: 'Privacy', index: 2),
    _NavItem(icon: Icons.payment_rounded, label: 'Billing', index: 3),
    _NavItem(icon: Icons.auto_awesome_outlined, label: 'Capabilities', index: 4),
    _NavItem(icon: Icons.bedtime_outlined, label: 'Time and focus', index: 5),
    _NavItem(icon: Icons.code_rounded, label: 'QuantCode', index: 6),
  ];

  final List<_NavItem> _customizeItems = [
    _NavItem(icon: Icons.extension_outlined, label: 'Skills', index: 7),
    _NavItem(icon: Icons.cable_outlined, label: 'Connectors', index: 8),
    _NavItem(icon: Icons.power_outlined, label: 'Plugins', index: 9),
    _NavItem(icon: Icons.memory_outlined, label: 'Memory', index: 10),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userProfile = data;
          _nameController.text = data['full_name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFullName(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final trimmed = newName.trim();
      if (trimmed.isEmpty) return;

      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': trimmed}),
      );

      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': trimmed,
          'email': user.email,
        });
      } catch (_) {
        await _supabase
            .from('profiles')
            .update({'full_name': trimmed})
            .eq('id', user.id);
      }

      if (mounted) {
        setState(() {
          _userProfile = {
            ...?_userProfile,
            'full_name': trimmed,
          };
        });
      }
    } catch (e) {
      debugPrint('Update Error: $e');
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    
    final dialogWidth = isMobile ? size.width * 0.95 : (size.width * 0.78).clamp(800.0, 1000.0);
    final dialogHeight = isMobile ? size.height * 0.90 : (size.height * 0.82).clamp(500.0, 720.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FadeInUp(
          duration: const Duration(milliseconds: 300),
          from: 20,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF262626), // Match image background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isMobile
                ? Column(
                    children: [
                      _buildMobileHeader(),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildPageContent(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildSidebar(dialogHeight),
                      Container(width: 1, color: Colors.white.withOpacity(0.06)),
                      Expanded(child: _buildContentPane()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMobileHeader() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(double height) {
    return Container(
      width: 220,
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
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
                        hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.25), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildNavSection('Settings', _settingsItems),
                const SizedBox(height: 16),
                _buildNavSection('Customize', _customizeItems),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(String title, List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) {
          final isSelected = _selectedNavIndex == item.index;
          return GestureDetector(
            onTap: () => setState(() => _selectedNavIndex = item.index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContentPane() {
    return Container(
      color: const Color(0xFF262626),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SingleChildScrollView(
                key: ValueKey(_selectedNavIndex),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 40),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _buildPageContent(),
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
        return ProfileSettings(
          userProfile: _userProfile,
          nameController: _nameController,
          onNameSaved: _updateFullName,
          themeColors: _themeColors,
          selectedColorIndex: _selectedColorIndex,
        );
      case 1:
        return AccountSettings(
          userEmail: _supabase.auth.currentUser?.email,
          onDeleteAccount: _handleLogout,
        );
      case 2:
        return const PrivacySettings();
      case 3:
        return const BillingSettings();
      case 4:
        return const CapabilitiesSettings();
      case 5:
        return _buildTimeAndFocusPlaceholder(); // Placeholder for Time and focus
      case 6:
        return const QuantCodeSettings();
      case 7:
        return const SkillsSettings();
      case 8:
        return const ConnectorsSettings();
      case 9:
        return const PluginsSettings();
      case 10:
        return const MemorySettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeAndFocusPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time and focus',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          'Configure focus modes and active hours.',
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem({required this.icon, required this.label, required this.index});
}

class SettingsScreen extends StatefulWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showSettingsPopup(context);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) {
      return const Scaffold(backgroundColor: Colors.transparent);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open from the navigation bar or left sidebar.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => showSettingsPopup(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
              ),
              child: Text('Open settings', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
    );
  }
}
