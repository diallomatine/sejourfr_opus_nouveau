import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Hub "Mes historiques" accessible depuis le profil. Regroupe les 3 surfaces
/// d'historique de l'app :
///   - QCM (civique + TCF CO/CE/Structure) -> ecran existant /history
///   - TCF Expression ecrite -> ProductionHistoryScreen (route existante)
///   - TCF Expression orale  -> ProductionHistoryScreen (route existante)
///
/// Aucun nouvel ecran d'historique a coder : on reuse les surfaces deja en
/// place. Ce hub se contente d'orienter l'utilisateur.
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
          style: AppFonts.jakarta(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Consultez vos sessions passées par catégorie.',
              style: AppFonts.jakarta(
                size: 13.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _HistoryCategoryCard(
              icon: Icons.fact_check_outlined,
              accent: AppColors.blue,
              title: 'Mes examens',
              subtitle:
                  'QCM civique + TCF (CO / CE / Structure) — examens blancs et entraînements terminés.',
              onTap: () => context.push(AppRoutes.history),
            ),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: Icons.edit_note_rounded,
              accent: AppColors.blue,
              title: 'TCF Expression écrite',
              subtitle:
                  'Sessions de rédaction notées par IA, par tâche et niveau atteint.',
              onTap: () => context.push('${AppRoutes.tcfExpressionEcrite}/historique'),
            ),
            const SizedBox(height: 10),
            _HistoryCategoryCard(
              icon: Icons.mic_rounded,
              accent: AppColors.blue,
              title: 'TCF Expression orale',
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
                      style: AppFonts.jakarta(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.jakarta(
                        size: 12.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
