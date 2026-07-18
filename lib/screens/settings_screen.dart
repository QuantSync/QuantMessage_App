import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/config.dart' as app_config;
import '../providers/attachment_provider.dart';
import 'widgets/attachment_picker_sheet.dart' show kMaxAttachmentSizeBytes;
import 'widgets/model_logo.dart';

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

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = false;
  bool _fileUploadsEnabled = true;
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
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  SUPABASE INTEGRATIONS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch the profile from the 'profiles' table we created in the SQL steps
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _userProfile = data;
        _nameController.text = data['full_name'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFullName(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final trimmed = newName.trim();
      if (trimmed.isEmpty) return;

      // Keep auth metadata + profiles in sync so ChatScreen greeting updates
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': trimmed,
          'onboarding_complete': true,
        }),
      );

      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': trimmed,
          'onboarding_complete': true,
          'email': user.email,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        await _supabase
            .from('profiles')
            .update({'full_name': trimmed})
            .eq('id', user.id);
      }

      if (!mounted) return;
      setState(() {
        _userProfile = {
          ...?_userProfile,
          'full_name': trimmed,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Update Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update name: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pop(); // Close settings
      // Note: Use your app's navigation to go back to SignInScreen here
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
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 60, spreadRadius: 10),
                BoxShadow(color: AppTheme.primaryRed.withOpacity(0.04), blurRadius: 80, spreadRadius: -10),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
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

  Widget _buildSidebar(double height) {
    return Container(
      width: 210,
      color: const Color(0xFF141414),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Settings', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
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
                      color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 17, color: isSelected ? AppTheme.primaryRed : Colors.white.withOpacity(0.45)),
                        const SizedBox(width: 10),
                        Text(item.label, style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.white.withOpacity(0.55), fontSize: 13.5, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: SingleChildScrollView(
                key: ValueKey(_selectedNavIndex),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)) : _buildPageContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedNavIndex) {
      case 0: return _buildGeneralPage();
      case 1: return _buildAccountPage();
      case 2: return _buildPrivacyPage();
      case 3: return _buildBillingPage();
      case 4: return _buildCapabilitiesPage();
      case 5: return _buildConnectorsPage();
      case 6: return _buildAdvancedPage();
      default: return _buildGeneralPage();
    }
  }

  Widget _buildGeneralPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Profile'),
        const SizedBox(height: 16),

        // Avatar Row - Now using real avatar_url from Supabase
        _settingsRow(
          label: 'Avatar',
          trailing: GestureDetector(
            onTap: () {
              // This would typically open the ImagePicker and upload to Supabase Storage
            },
            child: Container(
              height: 36, width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_themeColors[_selectedColorIndex], _themeColors[_selectedColorIndex].withOpacity(0.5)]),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipOval(
                child: _userProfile?['avatar_url'] != null
                    ? Image.network(_userProfile!['avatar_url'], fit: BoxFit.cover)
                    : Center(child: Text(_userProfile?['full_name']?[0] ?? 'U', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
        ),
        _divider(),

        // Full name - Editable
        _settingsRow(
          label: 'Full name',
          trailing: SizedBox(
            width: 150,
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, size: 16, color: AppTheme.primaryRed),
                  onPressed: () => _updateFullName(_nameController.text),
                ),
              ),
            ),
          ),
        ),
        _divider(),

        _settingsRow(
          label: 'Display name',
          trailing: _pillValue(_userProfile?['full_name'] ?? 'Not set'),
        ),

        const SizedBox(height: 28),
        _sectionTitle('Preferences'),
        const SizedBox(height: 16),
        _settingsRow(label: 'Appearance', trailing: _buildAppearanceToggle()),
        _divider(),
        _settingsRow(label: 'Chat font', trailing: _buildDropdown(_selectedFont, _fontOptions, (val) => setState(() => _selectedFont = val))),
        _divider(),
        _settingsRow(label: 'Theme accent', trailing: _buildColorDots()),
        _divider(),
        _settingsRow(label: 'Notifications', trailing: _buildMiniSwitch(_notificationsEnabled, (val) => setState(() => _notificationsEnabled = val))),
      ],
    );
  }

  Widget _buildAccountPage() {
    final user = _supabase.auth.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Account'),
        const SizedBox(height: 16),
        _settingsRow(
          label: 'Email',
          trailing: Text(user?.email ?? 'Not available', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ),
        _divider(),
        _settingsRow(label: 'Password', trailing: _actionButton('Change', () {})),
        _divider(),
        _settingsRow(label: 'Two-factor authentication', trailing: _actionButton('Enable', () {})),

        const SizedBox(height: 32),
        _sectionTitle('Danger Zone'),
        const SizedBox(height: 16),
        _settingsRow(
          label: 'Delete account',
          trailing: _actionButton('Delete', () {}, isDestructive: true),
        ),
      ],
    );
  }

  Widget _buildPrivacyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Privacy & Data'),
        const SizedBox(height: 16),
        _settingsRow(label: 'Data collection', trailing: _buildMiniSwitch(false, (val) {})),
        _divider(),
        _settingsRow(label: 'Incognito mode', trailing: _buildMiniSwitch(false, (val) {})),
        const SizedBox(height: 28),
        _sectionTitle('Data Management'),
        const SizedBox(height: 16),
        _settingsRow(label: 'Clear chat history', trailing: _actionButton('Clear', () {}, isDestructive: true)),
      ],
    );
  }

  Widget _buildBillingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Subscription'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primaryRed.withOpacity(0.12), AppTheme.primaryRed.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Plan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Upgrade for unlimited access', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              _actionButton('Upgrade', () {}, isPrimary: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilitiesPage() {
    final models = ref.watch(modelsProvider);
    final selected = ref.watch(selectedModelProvider);
    final maxMb =
        (kMaxAttachmentSizeBytes / (1024 * 1024)).toStringAsFixed(0);
    final configReady = app_config.Config.isReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('AI Capabilities'),
        const SizedBox(height: 16),
        _settingsRow(
          label: 'Web search',
          trailing: _buildMiniSwitch(true, (_) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'Code execution',
          trailing: _buildMiniSwitch(true, (_) {}),
        ),
        _divider(),
        _settingsRow(
          label: 'File uploads (max ${maxMb}MB)',
          trailing: _buildMiniSwitch(_fileUploadsEnabled, (val) {
            setState(() => _fileUploadsEnabled = val);
          }),
        ),
        _divider(),
        _settingsRow(
          label: 'Config status',
          trailing: _pillValue(configReady ? 'Ready' : 'Incomplete'),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Default model'),
        const SizedBox(height: 12),
        Text(
          'Applies across chat & attachments. Vision models accept images.',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        ...models.map((model) {
          final isSelected = model.name == selected.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    ref.read(selectedModelProvider.notifier).select(model),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryRed.withOpacity(0.12)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryRed.withOpacity(0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      ModelLogo(modelId: model.id, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.name,
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? AppTheme.primaryRed
                                    : Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              model.description,
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (model.supportsVision)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: Color(0xFFE27457),
                          ),
                        ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppTheme.primaryRed, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConnectorsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Integrations'),
        const SizedBox(height: 16),
        _buildConnectedAccount(Icons.storage_rounded, 'Google Drive', true, const Color(0xFF4285F4)),
        _divider(),
        _buildConnectedAccount(Icons.cloud_outlined, 'Dropbox', false, const Color(0xFF0061FF)),
      ],
    );
  }

  Widget _buildAdvancedPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Advanced Settings'),
        const SizedBox(height: 16),
        _settingsRow(label: 'Developer mode', trailing: _buildMiniSwitch(false, (val) {})),
        _divider(),
        _settingsRow(label: 'API access', trailing: _actionButton('Generate key', () {})),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: _handleLogout,
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
      ],
    );
  }

  // =======================================================================
  //  UI HELPERS
  // =======================================================================

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700));
  Widget _divider() => Divider(color: Colors.white.withOpacity(0.06), height: 1);

  Widget _settingsRow({required String label, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13.5))),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  Widget _pillValue(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.75), fontSize: 13)),
  );

  Widget _actionButton(String label, VoidCallback onTap, {bool isDestructive = false, bool isPrimary = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryRed.withOpacity(0.15) : isDestructive ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.06),
        foregroundColor: isPrimary ? AppTheme.primaryRed : isDestructive ? Colors.redAccent : Colors.white.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAppearanceToggle() {
    final modes = [{'icon': Icons.laptop_mac_rounded, 'mode': 'system'}, {'icon': Icons.light_mode_rounded, 'mode': 'light'}, {'icon': Icons.dark_mode_rounded, 'mode': 'dark'}];
    final selectedMode = _isDarkMode ? 'dark' : 'light';
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isActive = m['mode'] == selectedMode;
          return GestureDetector(
            onTap: () => setState(() => _isDarkMode = m['mode'] == 'dark' || m['mode'] == 'system'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Icon(m['icon'] as IconData, size: 16, color: isActive ? Colors.white : Colors.white.withOpacity(0.35)),
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
            height: 20, width: 20,
            decoration: BoxDecoration(
              color: _themeColors[i],
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMiniSwitch(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 28,
      child: FittedBox(
        child: Switch(
          value: value,
          activeColor: AppTheme.primaryRed,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF252525),
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) { if (val != null) onChanged(val); },
        ),
      ),
    );
  }

  Widget _buildConnectedAccount(IconData icon, String name, bool connected, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.75), fontSize: 13.5))),
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
  /// When embedded in the Home shell, show inline capabilities instead of
  /// opening a popup and calling Navigator.pop (which would leave Home).
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

    // Inline placeholder while the shell primarily uses the settings popup.
    // Tapping Settings in AppBar opens [showSettingsPopup]; this page keeps
    // IndexedStack slot valid without popping the Home route.
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
              'Open from the navigation bar for the full panel.',
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
