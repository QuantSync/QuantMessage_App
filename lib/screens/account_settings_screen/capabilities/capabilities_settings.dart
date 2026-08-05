// lib/screens/account_settings_screen/capabilities/capabilities_settings.dart
//
// Capabilities section matching QuantMessage settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_toggle_button.dart';
import '../widgets/settings_click_button.dart';

class CapabilitiesSettings extends StatefulWidget {
  const CapabilitiesSettings({super.key});

  @override
  State<CapabilitiesSettings> createState() => _CapabilitiesSettingsState();
}

class _CapabilitiesSettingsState extends State<CapabilitiesSettings> {
  bool _connectorSearch = false;
  bool _switchModels = true;
  bool _artifacts = true;
  bool _aiArtifacts = false;
  bool _inlineViz = true;
  bool _codeExec = true;
  bool _networkEgress = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'General'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Tool access mode',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Load tools when needed',
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
            ],
          ),
        ),
        const SizedBox(height: -4),
        Text(
          'Controls how connector tools are loaded in new conversations.',
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Connector search',
          subtitle: 'Let QuantMessage search the connector directory and surface ones relevant to your conversation.',
          value: _connectorSearch,
          onChanged: (val) => setState(() => _connectorSearch = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Switch models when a message is flagged',
          subtitle: 'When safeguards flag a message, automatically switch to a different model to keep chatting. When off, your chat will pause instead.',
          value: _switchModels,
          onChanged: (val) => setState(() => _switchModels = val),
        ),
        
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Visuals'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Artifacts',
          subtitle: 'Generate code, documents, and designs in a dedicated window alongside your conversation.',
          value: _artifacts,
          onChanged: (val) => setState(() => _artifacts = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'AI-powered artifacts',
          subtitle: 'Build apps and interactive documents that use QuantMessage inside the artifact.',
          value: _aiArtifacts,
          onChanged: (val) => setState(() => _aiArtifacts = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Inline visualizations',
          subtitle: 'Allow QuantMessage to generate interactive visualizations, charts, and diagrams directly in the conversation.',
          value: _inlineViz,
          onChanged: (val) => setState(() => _inlineViz = val),
        ),
        
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Code execution and file creation'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Code execution and file creation',
          subtitle: 'QuantMessage can execute code and create and edit docs, spreadsheets, presentations, PDFs, and data reports. Required for skills.',
          value: _codeExec,
          onChanged: (val) => setState(() => _codeExec = val),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow network egress',
                      style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 12, height: 1.4),
                        children: [
                          const TextSpan(text: 'Allow QuantMessage to access common package managers to install packages and libraries for data analysis, visualizations, and file processing. '),
                          TextSpan(
                            text: 'View package manager domains.',
                            style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.6)),
                          ),
                          const TextSpan(text: ' Monitor chats closely as this comes with '),
                          TextSpan(
                            text: 'security risks.',
                            style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              MiniToggleSwitch(
                value: _networkEgress,
                onChanged: (val) => setState(() => _networkEgress = val),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Skills'),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
            children: [
              const TextSpan(text: 'Skills have moved to '),
              TextSpan(
                text: 'Customize.',
                style: TextStyle(decoration: TextDecoration.underline, color: Colors.blueAccent.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
