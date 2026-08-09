import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import 'diagnostic_common.dart';

class DiagnosticIntro extends StatelessWidget {
  const DiagnosticIntro({
    super.key,
    required this.isStarting,
    required this.onStart,
    this.errorMessage,
  });

  final bool isStarting;
  final VoidCallback onStart;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.hero(AppColors.blueDark, AppColors.blue),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  boxShadow: AppShadows.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(
                        LucideIcons.scanSearch,
                        color: AppColors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Découvrez vos priorités TCF',
                      style: AppFonts.display(
                        size: 28,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un écrit et un oral pour construire votre premier plan personnalisé.',
                      style: AppFonts.ui(
                        size: 14.5,
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '2 exercices · environ 8 à 10 min',
                      style: AppFonts.label(
                        color: AppColors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _IntroItem(
                icon: LucideIcons.penLine,
                title: '1 production écrite',
                text: 'Racontez, décrivez et donnez votre opinion.',
              ),
              const SizedBox(height: 10),
              const _IntroItem(
                icon: LucideIcons.mic,
                title: '1 production orale enregistrée',
                text: 'Parlez naturellement, sans conversation en direct.',
              ),
              const SizedBox(height: 10),
              const _IntroItem(
                icon: LucideIcons.route,
                title: 'Une action claire',
                text: 'SejourFR sélectionne au maximum trois priorités.',
              ),
              const SizedBox(height: 18),
              if (errorMessage != null) ...[
                DiagnosticErrorBanner(message: errorMessage!),
                const SizedBox(height: 18),
              ],
              Text(
                'Estimation d’entraînement, non officielle.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        FixedActionBar(
          child: AppButton(
            label: 'Commencer mon diagnostic gratuit',
            iconRight: LucideIcons.arrowRight,
            isLoading: isStarting,
            onPressed: isStarting ? null : onStart,
          ),
        ),
      ],
    );
  }
}

class _IntroItem extends StatelessWidget {
  const _IntroItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 21, color: AppColors.blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFonts.ui(size: 14.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.35,
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
