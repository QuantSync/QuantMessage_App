import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/theme_provider.dart';

class ThemeSwitcherButton extends ConsumerWidget {
  final ValueChanged<ThemeMode>? onChanged;
  
  const ThemeSwitcherButton({super.key, this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: _getLeftPosition(themeMode),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              height: 32,
              width: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: Theme.of(context).brightness == Brightness.light
                    ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(context, ref, Icons.desktop_windows_outlined, ThemeMode.system, themeMode),
              _buildIcon(context, ref, Icons.wb_sunny_outlined, ThemeMode.light, themeMode),
              _buildIcon(context, ref, Icons.nightlight_round_outlined, ThemeMode.dark, themeMode),
            ],
          ),
        ],
      ),
    );
  }

  double _getLeftPosition(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 0;
      case ThemeMode.light:
        return 40; // 38 width + 2 margin
      case ThemeMode.dark:
        return 80;
    }
  }

  Widget _buildIcon(BuildContext context, WidgetRef ref, IconData icon, ThemeMode mode, ThemeMode currentMode) {
    final isSelected = currentMode == mode;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).state = mode;
        if (onChanged != null) onChanged!(mode);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
        ),
      ),
    );
  }
}
