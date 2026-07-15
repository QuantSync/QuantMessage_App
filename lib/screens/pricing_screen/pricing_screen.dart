// lib/screens/pricing_screen/pricing_screen.dart
// QuantMessage pricing — Individual & Team plans with responsive layout and animations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../animations/animation_effects/fade_in_animation.dart';
import '../animations/animation_effects/infinity_animation.dart';
import '../animations/animation_effects/button_bulge.dart';
import '../animations/animated_buttons/plan_slider_button.dart';
import '../animations/animated_buttons/solid_plan_button.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  PlanSegment _segment = PlanSegment.individual;

  static const _accentOrange = Color(0xFFFF9800); // SOLID Orange
  static const _accentGreen = Color(0xFF4CAF50);  // SOLID Green

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWide = width > 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Infinity Animation (High Contrast B&W)
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Center(
                child: InfinityAnimation(
                  size: (width * 0.7).clamp(300.0, 700.0),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeInAnimation(
                        duration: const Duration(milliseconds: 600),
                        child: _buildTitle(),
                      ),
                      const SizedBox(height: 28),
                      FadeInAnimation(
                        duration: const Duration(milliseconds: 650),
                        delay: const Duration(milliseconds: 120),
                        child: SizedBox(
                          width: (width * 0.55).clamp(280.0, 420.0),
                          child: PlanSliderButton(
                            selected: _segment,
                            onChanged: (s) => setState(() => _segment = s),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _segment == PlanSegment.individual
                            ? _buildIndividualPlans(isWide)
                            : _buildTeamPlans(isWide),
                      ),
                      const SizedBox(height: 32),
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          '*Usage limits apply. Prices and plans are subject to change at QUANTSYNC\'s discretion.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.lora(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        children: const [
          TextSpan(
            text: '<  ',
            style: TextStyle(
              color: Colors.white30,
              fontWeight: FontWeight.w300,
            ),
          ),
          TextSpan(text: 'Buy The Plan '),
          TextSpan(
            text: 'You',
            style: TextStyle(color: _accentOrange),
          ),
          TextSpan(text: ' '),
          TextSpan(
            text: 'Grow',
            style: TextStyle(color: _accentGreen),
          ),
          TextSpan(text: ' With'),
          TextSpan(
            text: '  >',
            style: TextStyle(
              color: Colors.white30,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualPlans(bool isWide) {
    final cardW = isWide ? null : (MediaQuery.sizeOf(context).width - 48).clamp(260.0, 400.0);

    final cards = [
      _PlanCard(
        width: cardW,
        title: 'Free',
        subtitle: 'Meet QuantCore',
        price: '\$0',
        priceNote: null,
        features: const [
          'Chat on web and mobile',
          'Write and edit content',
          'Analyze text and documents',
          'Generate code and visualize data',
        ],
        button: SolidPlanButton(
          label: 'Use QuantCore for free',
          outlined: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      _PlanCard(
        width: cardW,
        title: 'Pro',
        subtitle: 'Research, code, and organize',
        price: '\$17',
        priceNote: 'USD / month billed annually',
        features: const [
          'Everything in Free and:',
          'More usage than Free',
          'Access more models',
          'Unlimited projects',
          'Deep Research',
          'Memory across conversations',
        ],
        button: SolidPlanButton(
          label: 'Get Pro plan',
          onPressed: () {},
        ),
      ),
      _PlanCard(
        width: cardW,
        title: 'Max',
        subtitle: 'Higher limits, priority access',
        price: 'From \$100',
        priceNote: 'USD / month billed monthly',
        features: const [
          'Everything in Pro, plus:',
          'Choose 5x or 20x more usage',
          'Higher output limits',
          'Early access to advanced models',
          'Priority access at high traffic',
        ],
        button: SolidPlanButton(
          label: 'Get Max plan',
          onPressed: () {},
        ),
        footerNote: 'No commitment · Cancel anytime',
      ),
    ];

    if (isWide) {
      return KeyedSubtree(
        key: const ValueKey('individual_wide'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('individual_narrow'),
      child: Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
      ),
    );
  }

  Widget _buildTeamPlans(bool isWide) {
    final cardW = isWide ? null : (MediaQuery.sizeOf(context).width - 48).clamp(300.0, 420.0);

    final cards = [
      _PlanCard(
        width: cardW,
        title: 'Team',
        subtitle: 'Predictable usage per seat',
        badge: '2–150 users',
        priceBlock: _PriceBlock(
          rows: const [
            _PriceRow(
              label: 'Standard seat',
              price: '\$20',
              period: '/mo',
              note:
                  'All QuantCore features, plus more usage than Pro*. \$25 /mo when billed monthly.',
            ),
            _PriceRow(
              label: 'Premium seat',
              price: '\$100',
              period: '/mo',
              note:
                  '5x more usage than standard seats*. \$125 /mo when billed monthly.',
            ),
          ],
        ),
        features: const [
          'Includes QuantCore Code',
          'Includes QuantCore Design',
          'Includes QuantCore Science',
          'Connect Microsoft 365',
          'Enterprise search with connectors',
          'Central billing and administration',
          'Single sign-on (SSO)',
          'Admin controls for connectors',
        ],
        button: const SolidPlanButton(
          label: 'Team Plan Coming Soon',
        ),
      ),
      _PlanCard(
        width: cardW,
        title: 'Enterprise',
        subtitle: 'Flexible pooled usage',
        badge: '20+ users',
        priceBlock: _PriceBlock(
          rows: const [
            _PriceRow(
              label: 'Seat price + usage at API rates',
              price: '',
              period: '',
              note:
                  '\$20/seat + tax. Usage cost scales with model and task.',
              isTitle: true,
            ),
          ],
        ),
        features: const [
          'All Team features, plus:',
          'Admins set user and org spend limits',
          'Role-based access with fine-grained permissions',
          'SCIM for automated provisioning',
          'Audit logs',
          'Compliance API',
          'IP allowlisting',
          'QuantCore Security (beta)',
        ],
        button: const SolidPlanButton(
          label: 'Enterprise Plan Coming Soon',
        ),
      ),
    ];

    if (isWide) {
      return KeyedSubtree(
        key: const ValueKey('team_wide'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: c))).toList(),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('team_narrow'),
      child: Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 20), child: c)).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Plan card
// ═══════════════════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  final double? width;
  final String title;
  final String subtitle;
  final String? badge;
  final String? price;
  final String? priceNote;
  final _PriceBlock? priceBlock;
  final List<String> features;
  final Widget button;
  final String? footerNote;

  const _PlanCard({
    this.width,
    required this.title,
    required this.subtitle,
    this.badge,
    this.price,
    this.priceNote,
    this.priceBlock,
    required this.features,
    required this.button,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Align(
              alignment: Alignment.topRight,
              child: Text(
                badge!,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          Text(
            title,
            style: GoogleFonts.tinos(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (priceBlock != null)
            priceBlock!
          else ...[
            Text(
              price ?? '',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (priceNote != null) ...[
              const SizedBox(height: 4),
              Text(
                priceNote!,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          button,
          if (footerNote != null) ...[
            const SizedBox(height: 8),
            Text(
              footerNote!,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final card = ButtonBulge(
      style: BulgeStyle.card,
      hoverScale: 1.04,
      onPressed: () {},
      borderRadius: 16,
      child: cardContent,
    );

    return FadeInAnimation(
      duration: const Duration(milliseconds: 500),
      child: width != null
          ? SizedBox(
              width: width,
              child: card,
            )
          : card,
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final List<_PriceRow> rows;

  const _PriceBlock({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616), // surfaceMedium / high contrast black
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String note;
  final bool isTitle;

  const _PriceRow({
    required this.label,
    required this.price,
    required this.period,
    required this.note,
    this.isTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              price,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              period,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          note,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
