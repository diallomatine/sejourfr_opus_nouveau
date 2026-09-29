import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_tag.dart';
import 'skill_status_badge.dart';

/// Intitulé du niveau démontré. **Il nomme la production, pas le candidat** :
/// ce palier est celui de la réponse qui vient d'être rendue — quinze à trente
/// mots —, pas le niveau TCF de la personne, qui se mesure sur des épreuves
/// entières et vit sur l'accueil. « TON NIVEAU » laissait exactement cette
/// confusion possible, et c'est la lecture la plus décourageante : un A2 sur
/// une phrase n'est pas un verdict sur soi.
///
/// Miroir mot pour mot de `LEVEL_EYEBROW` côté web
/// (`app/_components/competences/CompetenceLevelCard.tsx`).
const String kSkillLevelCardEyebrow = 'NIVEAU DE TA RÉPONSE';

/// Surtitre du hero : ce que l'écran vient de faire.
const String kSkillLevelCardHeroEyebrow = 'ANALYSE DE TA PRODUCTION';

/// L'autre colonne du hero : le palier que la démarche du candidat exige.
const String kSkillLevelCardTargetEyebrow = 'NIVEAU VISÉ';

/// Ce qu'on écrit quand la production atteint déjà l'objectif.
const String kSkillLevelCardReachedBadge = 'Objectif atteint';

/// Le rappel de pied. Notre palier est une **estimation d'entraînement** :
/// le vrai TCF est corrigé par plusieurs examinateurs humains, et le dépôt
/// interdit de laisser croire qu'on reproduit leur verdict.
///
/// ⚠️ Il dit aussi **« sur cette seule réponse »**, et ce n'est pas un détail :
/// c'est la portée du palier, l'argument même de [kSkillLevelCardEyebrow]. La
/// forme courte (« Estimation d'entraînement, non officielle. ») reste celle du
/// diagnostic, qui porte sur deux productions entières. Miroir mot pour mot de
/// `ESTIMATION_NOTE` côté web
/// (`app/_components/competences/CompetenceLevelCard.tsx`).
const String kSkillLevelCardEstimationNote =
    'Estimation d\'entraînement SejourFR, sur cette seule réponse. '
    'Ce n\'est pas une note officielle.';

/// Le hero du résultat d'un micro-exercice : **niveau démontré** face au
/// **niveau visé**, la phrase de situation, la jauge à trois crans, puis — sur
/// la bande claire du bas — le verdict du critère et ses deux étiquettes.
///
/// **Rien n'est calculé ici** : le niveau, le palier visé, la phrase, l'échelle
/// et la position du curseur sont tous dérivés serveur
/// (`SkillLevelProgressResolver`). L'app ne réordonne pas les crans, ne déduit
/// aucun palier et ne recompose jamais [SkillLevelProgressDto.situationLabel].
///
/// 🛑 **Aucune note /20**, ni ici ni ailleurs sur un micro-exercice : le
/// tool-schema n'a aucun champ où en loger une.
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

  /// Le verdict IA, en une ligne de texte. `null` ou vide → rien n'est rendu.
  final String? verdict;

  /// Ce qui est réussi, en 3 mots. `null` → la puce disparaît.
  final String? strengthTag;

  /// L'axe de progrès, en 3 mots. `null` → la puce disparaît.
  final String? focusTag;

  bool get _hasFooter =>
      criterionStatus != null ||
      strengthTag != null ||
      focusTag != null ||
      (verdict != null && verdict!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    // Aucune teinte d'alerte quand l'objectif n'est pas atteint : « Encore du
    // chemin » décrit une distance, pas un échec.
    final atteint = progress.situation.isObjectifAtteint;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(progress: progress, atteint: atteint),
          if (_hasFooter)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (criterionStatus != null)
                        SkillCriterionBadge(status: criterionStatus!),
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
                  if (verdict != null && verdict!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      verdict!,
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.45,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Container(
            width: double.infinity,
            color: AppColors.surface2,
            padding: const EdgeInsets.fromLTRB(15, 9, 15, 10),
            child: Text(
              kSkillLevelCardEstimationNote,
              style: AppFonts.ui(size: 11, color: AppColors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}

/// La partie foncée : deux paliers en vis-à-vis, la situation, la jauge.
class _Hero extends StatelessWidget {
  const _Hero({required this.progress, required this.atteint});

  final SkillLevelProgressDto progress;
  final bool atteint;

  @override
  Widget build(BuildContext context) {
    final onHero = AppColors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(AppColors.blueDark, AppColors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 13,
                color: onHero.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kSkillLevelCardHeroEyebrow,
                  style: AppFonts.label(
                    size: 10,
                    color: onHero.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (atteint)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: onHero.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    kSkillLevelCardReachedBadge,
                    style: AppFonts.ui(
                      size: 10.5,
                      weight: FontWeight.w800,
                      color: onHero,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LevelColumn(
                  eyebrow: kSkillLevelCardEyebrow,
                  value: progress.levelReached.shortName,
                  opacity: 1,
                ),
              ),
              Container(
                width: 1,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: onHero.withValues(alpha: 0.28),
              ),
              Expanded(
                child: _LevelColumn(
                  eyebrow: kSkillLevelCardTargetEyebrow,
                  value: progress.targetLevel.asNiveau.shortName,
                  opacity: 0.72,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            // Libellé posé par le serveur, rendu tel quel.
            progress.situationLabel,
            style: AppFonts.ui(
              size: 13.5,
              weight: FontWeight.w600,
              height: 1.45,
              color: onHero.withValues(alpha: 0.94),
            ),
          ),
          if (progress.scale.length > 1) ...[
            const SizedBox(height: 16),
            _LevelGauge(
              scale: progress.scale,
              cursorIndex: progress.cursorIndex,
            ),
          ],
        ],
      ),
    );
  }
}

/// Une colonne du vis-à-vis : le petit label, puis le palier en grand.
class _LevelColumn extends StatelessWidget {
  const _LevelColumn({
    required this.eyebrow,
    required this.value,
    required this.opacity,
  });

  final String eyebrow;
  final String value;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          maxLines: 2,
          style: AppFonts.label(
            size: 9.5,
            color: AppColors.white.withValues(alpha: 0.72 * opacity + 0.08),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppFonts.display(
              size: 38,
              weight: FontWeight.w800,
              color: AppColors.white.withValues(alpha: opacity),
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

/// La jauge, **sur le fond foncé du hero** : les crans de l'échelle serveur,
/// étiquetés, le trait rempli jusqu'au curseur, un point marqué dessus.
///
/// **Aucune position n'est recalculée** : [scale] et [cursorIndex] arrivent tels
/// quels du serveur, l'ordre n'est jamais retouché. Le seul ajustement est un
/// garde-fou de rendu (index borné) : il protège l'affichage d'une échelle
/// dégénérée, il ne déduit aucun niveau.
///
/// ⚠️ La teinte de `CecrlColor` ne se voit pas sur ce dégradé — même raison que
/// la barre des cinq paliers du rapport de production : les crans franchis
/// passent en **blanc plein**, les autres en blanc très atténué.
class _LevelGauge extends StatelessWidget {
  const _LevelGauge({required this.scale, required this.cursorIndex});

  final List<NiveauCecrl> scale;
  final int cursorIndex;

  /// Largeur d'un cran. Les deux rangées (points puis étiquettes) partagent la
  /// même géométrie, c'est ce qui les garde alignées sans mesure.
  static const double _slot = 40;

  @override
  Widget build(BuildContext context) {
    final cursor = cursorIndex.clamp(0, scale.length - 1);
    final on = AppColors.white.withValues(alpha: 0.95);
    final off = AppColors.white.withValues(alpha: 0.26);
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
                      color: i <= cursor ? on : off,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              SizedBox(
                width: _slot,
                height: 20,
                child: Center(child: _dot(i, cursor, on, off)),
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
                    color: i <= cursor
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _dot(int index, int cursor, Color on, Color off) {
    if (index == cursor) {
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.22),
        ),
        child: Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
          ),
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < cursor ? on : off,
      ),
    );
  }
}
