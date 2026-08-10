import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class NameCard extends StatefulWidget {
  final Function(String name, String workspaceName) onSave;

  const NameCard({super.key, required this.onSave});

  @override
  State<NameCard> createState() => _NameCardState();
}

class _NameCardState extends State<NameCard> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _workspaceController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Pre-fill name from GitHub/Google metadata if available
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final existingName = (meta['full_name'] as String?)?.trim() ??
        (meta['name'] as String?)?.trim() ?? '';
    if (existingName.isNotEmpty) {
      _nameController.text = existingName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workspaceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final workspace = _workspaceController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    // Save workspace + chat section name to Supabase profiles table
    await AuthService.saveWorkspaceDetails(
      workspaceName: workspace.isNotEmpty ? workspace : '${name}\'s Workspace',
      chatSectionName: workspace.isNotEmpty ? workspace : 'General',
    );

    widget.onSave(name, workspace.isNotEmpty ? workspace : '${name}\'s Workspace');
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withOpacity(0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.04),
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: Colors.white70, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "How Shall We Greet You?",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                'Set up your workspace to get started.',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 22),

              // Name field
              _buildLabel('Your Name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter your name',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 16),

              // Workspace field
              _buildLabel('Workspace Name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _workspaceController,
                hint: 'e.g. My Projects, Work, Personal',
                icon: Icons.folder_outlined,
                onSubmitted: (_) => _handleSave(),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black54),
                        )
                      : Text(
                          "Let's Go →",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white24, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1),
        ),
      ),
    );
  }
}
