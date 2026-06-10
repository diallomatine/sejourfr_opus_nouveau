import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Hub "Mes historiques" accessible depuis le profil. Liste **4 surfaces**
/// d'historique, toutes scopées aux **examens blancs complets** (pas les
/// lots ni les examens thématiques — ceux-là ont leur propre onglet dans
/// le détail du thème/module concerné, plus contextuel) :
///
///   - **Examens civique** → 40 Q tous thèmes, seuil 32 → `/history`
///   - **Examens TCF**     → parent `TCF_COMPLET` + 4 sous-attempts → `/historiques/tcf`
///   - **Expression écrite (EE)** → sessions IA → `/tcf/expression-ecrite/historique`
///   - **Expression orale (EO)**  → sessions IA → `/tcf/expression-orale/historique`
///
/// Le scope "complets uniquement" est volontaire : les listes ici servent à
/// suivre la performance globale, pas les entraînements par lot (qui sont
/// déjà visibles dans le hub du thème/module avec leur score).
class MesHistoriquesScreen extends StatelessWidget {
  const MesHistoriquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          'Mes historiques',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Consultez vos examens blancs et sessions IA passés.',
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Examens blancs'),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: LucideIcons.landmark,
              accent: AppColors.blue,
              title: 'Examens civique',
              subtitle:
                  '40 questions tous thèmes, seuil 32. Score et progression dans le temps.',
              onTap: () => context.push(AppRoutes.history),
            ),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: LucideIcons.languages,
              accent: AppColors.red,
              title: 'Examens TCF',
              subtitle:
                  'CO + CE + EE + EO en conditions réelles, niveau CECRL plancher.',
              onTap: () => context.push(AppRoutes.tcfExamHistory),
            ),
            const SizedBox(height: 22),
            _SectionLabel('Sessions IA'),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: LucideIcons.penLine,
              accent: AppColors.green,
              title: 'Expression écrite',
              subtitle:
                  'Rédactions notées par IA, niveau CECRL et feedback détaillé.',
              onTap: () => context.push('${AppRoutes.tcfExpressionEcrite}/historique'),
            ),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: LucideIcons.mic,
              accent: AppColors.red,
              title: 'Expression orale',
              subtitle:
                  'Enregistrements transcrits par Whisper et évalués par IA.',
              onTap: () => context.push('${AppRoutes.tcfExpressionOrale}/historique'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        '§ ${text.toUpperCase()}',
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 2.0,
          weight: FontWeight.w600,
        ).copyWith(height: 1.0),
      ),
    );
  }
}

class _HistoryCategoryCard extends StatelessWidget {
  const _HistoryCategoryCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.ui(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
