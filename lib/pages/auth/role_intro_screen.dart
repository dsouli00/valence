import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/ui/ui.dart';

/// One value point on a [RoleIntroScreen]: a tinted glyph + title + a short body.
typedef RoleIntroFeature = (
  IconData icon,
  Color tint,
  String title,
  String body,
);

/// The lean, personalize-first intro shown right after role selection
/// (replaces the old 3-slide product tour). One scannable screen — a warm
/// greeting and three "here's how Valence works for you" points — that leads
/// straight into the intake, which does the real connection-building.
///
/// Theme-responsive throughout (`context.tokens`), RTL-safe, Reduce-Motion
/// aware. Both the coach and client onboarding entry points delegate here.
class RoleIntroScreen extends StatelessWidget {
  const RoleIntroScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.ctaLabel,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final List<RoleIntroFeature> features;
  final String ctaLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: VSkyGlow(alpha: 0.10)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
                  child: VHeader(
                    title: title,
                    subtitle: subtitle,
                    serif: true,
                    onBack: () => Navigator.pop(context),
                    backSemanticLabel: context.l10n.back,
                  ),
                ),
                Expanded(
                  // Centred. This is a single screen with three feature rows —
                  // there is no next step for a heading to jump relative to, so
                  // unlike the intake's option lists it is safe to centre, and
                  // on a tall phone the alternative was three rows at the top
                  // and half a screen of nothing above the CTA.
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: c.maxHeight - 44,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < features.length; i++) ...[
                              if (i > 0) const SizedBox(height: 24),
                              _FeatureRow(feature: features[i]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  child: VPillButton.primary(
                    label: ctaLabel,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onContinue();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final RoleIntroFeature feature;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (icon, tint, title, body) = feature;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.tintFill(tint),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: t.legibleTint(tint)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: VType.headline.copyWith(color: t.ink)),
              const SizedBox(height: 3),
              Text(body, style: VType.subhead.copyWith(color: t.inkSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
