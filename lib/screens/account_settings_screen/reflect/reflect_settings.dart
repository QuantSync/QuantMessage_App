// lib/screens/account_settings_screen/reflect/reflect_settings.dart
//
// Reflect section matching Claude settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReflectSettings extends StatelessWidget {
  const ReflectSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reflect',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your conversations in Claude chat.',
                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                Text('Past month', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
                const SizedBox(width: 16),
                Icon(Icons.refresh, color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Building QuantSync from every angle at once.',
          style: GoogleFonts.tiroDevanagariSanskrit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Text(
          'You worked on QuantMessage and QuantSync across frontend, backend, deployment, branding, and documentation — sometimes all in the same session. Flutter widgets, Python multi-agent architecture, GitHub Pages troubleshooting, logo design, README animations, Vercel and Railway deployment configs. Through most of it, you used Claude as a researcher and implementer: ask for a full roadmap, get the code, move to the next piece.',
          style: GoogleFonts.tiroDevanagariSanskrit(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildStat('Sunday', 'MOST ACTIVE DAY'),
            const SizedBox(width: 64),
            _buildStat('3 AM', 'PEAK HOUR'),
            const SizedBox(width: 64),
            _buildStat('11', 'TOTAL CONVERSATIONS'),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'YOUR TIME WITH CLAUDE',
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('Conversations', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text('Time spent', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Graph placeholder
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _MockGraphPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.tiroDevanagariSanskrit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _MockGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE27457)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.4, size.height);
    path.lineTo(size.width * 0.45, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.9);
    path.lineTo(size.width * 0.7, size.height * 0.85);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.85, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);

    final dashedPaint = Paint()
      ..color = const Color(0xFFE27457).withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashedPath = Path();
    dashedPath.moveTo(size.width * 0.4, size.height);
    dashedPath.lineTo(size.width * 0.45, size.height * 0.1);
    dashedPath.lineTo(size.width * 0.5, size.height * 0.75);
    dashedPath.lineTo(size.width * 0.6, size.height * 0.8);
    dashedPath.lineTo(size.width * 0.7, size.height * 0.7);
    dashedPath.lineTo(size.width * 0.8, size.height * 0.2);
    dashedPath.lineTo(size.width * 0.85, size.height * 0.7);
    dashedPath.lineTo(size.width * 0.9, size.height * 0.1);
    dashedPath.lineTo(size.width, size.height);

    canvas.drawPath(dashedPath, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
