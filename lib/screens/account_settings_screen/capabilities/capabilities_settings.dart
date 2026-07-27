// lib/screens/account_settings_screen/capabilities/capabilities_settings.dart
//
// Capabilities section under Customize.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_toggle_button.dart';
import '../widgets/settings_click_button.dart';
import '../../../core/app_theme.dart';
import '../../../core/attachment_model.dart';
import '../../../core/config.dart' as app_config;
import '../../../providers/attachment_provider.dart';
import '../../widgets/model_logo.dart';
import '../../widgets/attachment_picker_sheet.dart' show kMaxAttachmentSizeBytes;

class CapabilitiesSettings extends ConsumerStatefulWidget {
  const CapabilitiesSettings({super.key});

  @override
  ConsumerState<CapabilitiesSettings> createState() => _CapabilitiesSettingsState();
}

class _CapabilitiesSettingsState extends ConsumerState<CapabilitiesSettings> {
  bool _webSearchEnabled = true;
  bool _codeExecutionEnabled = true;
  bool _fileUploadsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(modelsProvider);
    final selected = ref.watch(selectedModelProvider);
    final maxMb = (kMaxAttachmentSizeBytes / (1024 * 1024)).toStringAsFixed(0);
    final configReady = app_config.Config.isReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'AI Capabilities'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Web search',
          value: _webSearchEnabled,
          onChanged: (val) => setState(() => _webSearchEnabled = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Code execution',
          value: _codeExecutionEnabled,
          onChanged: (val) => setState(() => _codeExecutionEnabled = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'File uploads (max ${maxMb}MB)',
          value: _fileUploadsEnabled,
          onChanged: (val) => setState(() => _fileUploadsEnabled = val),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Config status',
          trailing: SettingsPillValue(text: configReady ? 'Ready' : 'Incomplete'),
        ),
        
        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Default model'),
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
                onTap: () => ref.read(selectedModelProvider.notifier).select(model),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                color: isSelected ? AppTheme.primaryRed : Colors.white,
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
}
