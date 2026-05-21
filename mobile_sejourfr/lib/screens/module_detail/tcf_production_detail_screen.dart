import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'widgets/module_detail_widgets.dart';

/// Module TCF productif (Expression écrite ou orale). Reste séparé de
/// `TcfQcmModule` parce que le flow downstream est différent : ces 2 modules
/// pushent un `ProductionHubScreen` (sélection T1/T2/T3) et non un runner QCM.
enum TcfProductionModule {
  ee(
    routeKey: 'ee',
    epreuve: EpreuveType.tcfEe,
    eyebrow: 'Module TCF',
    title: 'Expression écrite',
    headline: '3 tâches corrigées par IA',
    description:
        'Tu rédiges 3 productions de niveau croissant. Notre IA Claude évalue selon les critères CECRL et te renvoie une note + un feedback détaillé.',
    icon: Icons.edit_note_rounded,
    durationLabel: '≈ 30 min',
    accentColor: AppColors.green,
    accentBg: Color(0xFFE6F4EC), // green-light
    hubRoutePath: AppRoutes.tcfExpressionEcrite,
  ),
  eo(
    routeKey: 'eo',
    epreuve: EpreuveType.tcfEo,
    eyebrow: 'Module TCF',
    title: 'Expression orale',
    headline: '3 tâches enregistrées et notées',
    description:
        'Tu enregistres 3 productions orales. Whisper transcrit ta voix puis l\'IA Claude évalue selon les critères CECRL et te renvoie ton niveau.',
    icon: Icons.mic_rounded,
    durationLabel: '≈ 10 min',
    accentColor: AppColors.red,
    accentBg: AppColors.redLight,
    hubRoutePath: AppRoutes.tcfExpressionOrale,
  );

  const TcfProductionModule({
    required this.routeKey,
    required this.epreuve,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.durationLabel,
    required this.accentColor,
    required this.accentBg,
    required this.hubRoutePath,
  });

  final String routeKey;
  final EpreuveType epreuve;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String durationLabel;
  final Color accentColor;
  final Color accentBg;

  /// Route du `ProductionHubScreen` (sélection des 3 tâches) à laquelle on
  /// renvoie quand l'utilisateur clique sur le CTA.
  final String hubRoutePath;
}

/// Écran détail TCF EE/EO. Pas de score de maîtrise — ces modules renvoient
/// un niveau CECRL par submission, donnée trop fine pour une simple % ici.
/// À la place, une carte "Comment ça marche" en 3 étapes.
class TcfProductionDetailScreen extends ConsumerWidget {
  const TcfProductionDetailScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final target = user?.targetProcedure?.tcfLevel;
    final niveauLabel = target == null ? 'A2-B2' : 'Cible $target';

    void openHub() {
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      final isPremium = user != null && user.canAccessModule(AppModule.tcf);
      if (!isPremium) {
        showPaywallSheet(context);
        return;
      }
      context.push(module.hubRoutePath);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            ModuleDetailTopBar(
              onBack: () => context.pop(),
              icon: module.icon,
              iconColor: module.accentColor,
              iconBg: module.accentBg,
            ),
            const SizedBox(height: 22),
            ModuleDetailTitle(
              eyebrow: module.eyebrow,
              title: module.title,
            ),
            const SizedBox(height: 22),
            ModuleDetailHero(
              icon: module.icon,
              headline: module.headline,
              description: module.description,
              gradient: [module.accentColor, _darken(module.accentColor)],
            ),
            const SizedBox(height: 16),
            ModuleDetailStats(
              items: [
                (value: '3', label: 'Tâches'),
                (value: module.durationLabel, label: 'Durée'),
                (value: niveauLabel, label: 'Niveau'),
              ],
            ),
            const SizedBox(height: 14),
            _HowItWorksCard(accent: module.accentColor, isOrale: module.epreuve == EpreuveType.tcfEo),
            const SizedBox(height: 22),
            AppButton(
              label: 'Voir les tâches',
              icon: Icons.arrow_forward_rounded,
              onPressed: openHub,
            ),
          ],
        ),
      ),
    );
  }

  /// Assombrit une couleur d'environ 15 % pour le 2ᵉ stop du gradient
  /// du hero. On garde la logique inline pour ne pas polluer
  /// `AppColors` avec des helpers ponctuels.
  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.accent, required this.isOrale});

  final Color accent;
  final bool isOrale;

  @override
  Widget build(BuildContext context) {
    final step1 = isOrale
        ? 'Tu enregistres ta production avec le micro de l\'appareil.'
        : 'Tu rédiges ta production directement dans l\'app.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMENT ÇA MARCHE',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _Step(index: 1, accent: accent, label: step1),
          const SizedBox(height: 10),
          _Step(
            index: 2,
            accent: accent,
            label: isOrale
                ? 'Whisper transcrit ta voix puis Claude évalue selon les critères CECRL.'
                : 'Claude évalue ta production selon les critères CECRL en moins de 15 secondes.',
          ),
          const SizedBox(height: 10),
          _Step(
            index: 3,
            accent: accent,
            label: 'Tu reçois un niveau CECRL (A1 à C2), une note sur 20 et un feedback détaillé.',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.accent, required this.label});

  final int index;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.ink2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
