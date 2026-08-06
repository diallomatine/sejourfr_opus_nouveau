import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Bascule « Analyser ma réponse avec l'IA », proposée **avant** la validation.
///
/// Aucun sujet n'est verrouillé : produire, s'auto-évaluer et lire les trois
/// références restent gratuits. Seule l'analyse IA est premium, avec des
/// analyses offertes aux comptes gratuits. `remaining == -1` signifie illimité
/// et n'est jamais affiché tel quel.
class AnalysisToggle extends StatelessWidget {
  const AnalysisToggle({
    super.key,
    required this.value,
    required this.quota,
    required this.onChanged,
    required this.onLockedTap,
    this.accent = AppColors.blue,
  });

  /// Accent du module (rouge en EO) : sans lui l'écran mélangeait trois bleus
  /// et deux rouges.
  final Color accent;

  final bool value;

  /// `null` tant que le quota n'est pas connu.
  final SkillAnalysisQuotaDto? quota;

  final ValueChanged<bool> onChanged;
  final VoidCallback onLockedTap;

  bool get _locked => quota != null && !quota!.canAnalyse;

  String get _subtitle {
    final q = quota;
    if (q == null) return 'Vérification de tes analyses disponibles…';
    if (q.isUnlimited) return 'Incluse dans ton accès TCF.';
    if (q.remaining > 0) {
      return 'Il te reste ${q.remaining} analyse${q.remaining > 1 ? 's' : ''} '
          'offerte${q.remaining > 1 ? 's' : ''}.';
    }
    return 'Tes ${q.freeAnalysesTotal} analyses offertes ont été utilisées.';
  }

  @override
  Widget build(BuildContext context) {
    final on = value && !_locked;
    final iconColor = _locked ? AppColors.muted2 : accent;

    return Material(
      color: on ? accent.withValues(alpha: 0.08) : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: _locked ? onLockedTap : () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: on ? accent : AppColors.line,
              width: on ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Icon(
                _locked ? LucideIcons.lock : LucideIcons.sparkles,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyser ma réponse avec l\'IA',
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _locked ? AppColors.inkSoft : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      style: AppFonts.ui(size: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Track(on: on, locked: _locked, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.on,
    required this.locked,
    required this.accent,
  });

  final bool on;
  final bool locked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return const Icon(LucideIcons.chevronRight,
          size: 17, color: AppColors.inkFaint);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? accent : AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
