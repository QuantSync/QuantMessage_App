import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/theme_provider.dart';

class MotionSelectorButton extends ConsumerWidget {
  final ValueChanged<bool>? onChanged;
  
  const MotionSelectorButton({super.key, this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNormalMotion = ref.watch(motionProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: isNormalMotion ? 0 : 70, // Assuming each segment is ~70 wide
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              height: 28,
              width: 76,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: !isDark
                    ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(context, ref, 'System', true, isNormalMotion),
              _buildSegment(context, ref, 'Reduced', false, isNormalMotion),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, WidgetRef ref, String text, bool value, bool currentValue) {
    final isSelected = currentValue == value;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        ref.read(motionProvider.notifier).state = value;
        if (onChanged != null) onChanged!(value);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        height: 32,
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }
}
