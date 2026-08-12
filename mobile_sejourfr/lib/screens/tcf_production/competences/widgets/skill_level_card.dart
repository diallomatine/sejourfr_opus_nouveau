import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_tag.dart';
import 'skill_status_badge.dart';

/// « TON NIVEAU » : le niveau démontré par la micro-production, l'objectif, la
/// phrase de situation, la jauge à trois crans, le verdict du critère et les
/// deux étiquettes.
///
/// **Rien n'est calculé ici** : le niveau, le palier visé, la phrase, l'échelle
/// et la position du curseur sont tous dérivés serveur
/// (`SkillLevelProgressResolver`). L'app ne réordonne pas les crans, ne déduit
/// aucun palier et ne recompose jamais [SkillLevelProgressDto.situationLabel].
///
/// Le verdict du critère unique est rendu ici, en discret — une pastille sur
/// la rangée du haut et une ligne de texte sous les puces — plutôt qu'en gros
/// bloc `_VerdictCard` autonome : c'est le pavé que la refonte a supprimé.
class SkillLevelCard extends StatelessWidget {
  const SkillLevelCard({
    super.key,
    required this.progress,
    this.criterionStatus,
    this.verdict,
    this.strengthTag,
    this.focusTag,
  });

  final SkillLevelProgressDto progress;

  /// Statut du critère unique du sujet. `null` → la pastille disparaît (garde
  /// la carte utilisable même sans analyse v3 complète).
  final SkillCriterionStatus? criterionStatus;

  /// Le verdict IA, en une ligne de texte sous les puces. `null` ou vide →
  /// rien n'est rendu.
  final String? verdict;

  /// Ce qui est réussi, en 3 mots. `null` → la puce disparaît.
  final String? strengthTag;

  /// L'axe de progrès, en 3 mots. `null` → la puce disparaît.
  final String? focusTag;

  @override
  Widget build(BuildContext context) {
    // `CecrlColor` est la seule table qui décide de la teinte d'un niveau : le
    // gros chiffre, la jauge et les crans franchis en dérivent tous.
    final accent = progress.levelReached.color;
    // Aucune teinte d'alerte quand l'objectif n'est pas atteint : « Encore du
    // chemin » décrit une distance, pas un échec.
    final atteint = progress.situation.isObjectifAtteint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TON NIVEAU', style: AppFonts.label(size: 10)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progress.levelReached.shortName,
                style: AppFonts.display(
                  size: 40,
                  weight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  // Wrap plutôt que Row : à 360 px la pastille de critère
                  // passe à la ligne sous la puce « Objectif » au lieu de
                  // déborder.
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      AppTag(
                        label:
                            'Objectif ${progress.targetLevel.asNiveau.shortName}',
                        tone: TagTone.neutral,
                        icon: LucideIcons.target,
                        compact: true,
                      ),
                      if (criterionStatus != null)
                        SkillCriterionBadge(status: criterionStatus!),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                atteint ? LucideIcons.circleCheck : LucideIcons.trendingUp,
                size: 15,
                color: atteint ? AppColors.green : AppColors.blue,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  // Libellé posé par le serveur, rendu tel quel.
                  progress.situationLabel,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: atteint ? AppColors.green : AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          if (progress.scale.length > 1) ...[
            const SizedBox(height: 16),
            _LevelGauge(
              scale: progress.scale,
              cursorIndex: progress.cursorIndex,
              accent: accent,
            ),
          ],
          if (strengthTag != null || focusTag != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (strengthTag != null)
                  AppTag(
                    label: strengthTag!,
                    tone: TagTone.success,
                    icon: LucideIcons.check,
                    compact: true,
                  ),
                if (focusTag != null)
                  AppTag(
                    label: focusTag!,
                    tone: TagTone.blue,
                    icon: LucideIcons.target,
                    compact: true,
                  ),
              ],
            ),
          ],
          if (verdict != null && verdict!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              verdict!,
              style: AppFonts.ui(
                size: 11.5,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La jauge : les crans de l'échelle serveur, étiquetés, le trait rempli
/// jusqu'au curseur, un point marqué dessus, les crans suivants en gris.
///
/// **Aucune position n'est recalculée** : [scale] et [cursorIndex] arrivent tels
/// quels du serveur, l'ordre n'est jamais retouché. Le seul ajustement est un
/// garde-fou de rendu (index borné) : il protège l'affichage d'une échelle
/// dégénérée, il ne déduit aucun niveau.
class _LevelGauge extends StatelessWidget {
  const _LevelGauge({
    required this.scale,
    required this.cursorIndex,
    required this.accent,
  });

  final List<NiveauCecrl> scale;
  final int cursorIndex;
  final Color accent;

  /// Largeur d'un cran. Les deux rangées (points puis étiquettes) partagent la
  /// même géométrie, c'est ce qui les garde alignées sans mesure.
  static const double _slot = 40;

  @override
  Widget build(BuildContext context) {
    final cursor = cursorIndex.clamp(0, scale.length - 1);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < scale.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: i <= cursor ? accent : AppColors.surface3,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              SizedBox(
                width: _slot,
                height: 20,
                child: Center(child: _dot(i, cursor)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < scale.length; i++) ...[
              if (i > 0) const Expanded(child: SizedBox.shrink()),
              SizedBox(
                width: _slot,
                child: Text(
                  scale[i].shortName,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 10.5,
                    weight: i == cursor ? FontWeight.w900 : FontWeight.w600,
                    color: i <= cursor ? AppColors.ink : AppColors.inkFaint,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _dot(int index, int cursorIndex) {
    if (index == cursorIndex) {
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.22),
        ),
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < cursorIndex ? accent : AppColors.surface3,
      ),
    );
  }
}
