import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/progress_track.dart';
import '../tcf_production_module.dart';
import 'production_common.dart';

/// Tête commune aux trois modes du parcours EE/EO, telle que la maquette
/// client la décrit : carte héros chiffrée, carte « Prochain entraînement »,
/// barre segmentée des trois modes, puis le sélecteur de tâche.
///
/// Les trois modes la rendent **en tête de leur propre liste** : c'est ce qui
/// garde le défilement de chacun (l'`IndexedStack` du parcours ne démonte pas
/// le mode quitté) tout en donnant à voir la même vue d'ensemble partout.

/// Chiffres du parcours, tous **dérivés du catalogue déjà chargé** — aucun
/// endpoint ajouté, aucun agrégat inventé.
class ProductionParcoursStats {
  const ProductionParcoursStats({
    required this.avgScore,
    required this.examsDone,
    required this.examsTotal,
    required this.subjectsDone,
    required this.subjectsTotal,
  });

  /// Moyenne /20 des examens blancs **entièrement évalués** de l'épreuve.
  /// `null` tant qu'aucun examen n'a rendu ses trois notes — on écrit « — »,
  /// jamais un zéro qui se lirait comme un mauvais résultat.
  ///
  /// ⚠️ C'est une note d'**examen** (3 tâches agrégées), la seule échelle /20
  /// autorisée ici : une tâche isolée ne reçoit qu'un niveau
  /// (cf. `production_result_labels.dart`).
  final double? avgScore;

  final int examsDone;
  final int examsTotal;
  final int subjectsDone;
  final int subjectsTotal;

  /// Progression **du parcours** : la part des sujets publiés déjà produits.
  /// Volontairement nommée « du parcours » et non « de l'épreuve » — la
  /// progression d'épreuve, elle, est dérivée serveur
  /// (`GET /api/me/dashboard`) et ne se recalcule pas côté front.
  double get percent =>
      subjectsTotal == 0 ? 0 : (subjectsDone / subjectsTotal) * 100;
}

/// Carte héros du parcours : anneau de progression, trois colonnes chiffrées
/// séparées par des filets, puis la ligne « Progression du parcours ».
class ProductionParcoursHero extends StatelessWidget {
  const ProductionParcoursHero({
    super.key,
    required this.module,
    required this.stats,
  });

  final TcfProductionModule module;
  final ProductionParcoursStats stats;

  @override
  Widget build(BuildContext context) {
    final percent = stats.percent;
    final onDark = AppColors.white.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(module.accentDark, module.accent),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProgressRing(
                value: percent,
                size: 64,
                stroke: 7,
                color: AppColors.white,
                trackColor: AppColors.white.withValues(alpha: 0.18),
                textColor: AppColors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HeroStat(
                        value: stats.avgScore == null
                            ? '—'
                            : formatScore(stats.avgScore!),
                        label: 'Score moyen',
                        unit: '/20',
                      ),
                    ),
                    _HeroDivider(color: onDark),
                    Expanded(
                      child: _HeroStat(
                        value: '${stats.examsDone}',
                        label: 'Examens blancs',
                        unit: '/${stats.examsTotal}',
                      ),
                    ),
                    _HeroDivider(color: onDark),
                    Expanded(
                      child: _HeroStat(
                        value: '${stats.subjectsDone}',
                        label: 'Sujets traités',
                        unit: '/${stats.subjectsTotal}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progression du parcours',
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                '${percent.round()} %',
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ProgressTrack(
            value: percent,
            height: 7,
            color: AppColors.white,
            trackColor: AppColors.white.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.unit,
  });

  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.display(size: 21, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 10,
            height: 1.25,
            color: AppColors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          unit,
          style: AppFonts.ui(
            size: 10,
            weight: FontWeight.w700,
            color: AppColors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color.withValues(alpha: 0.18),
    );
  }
}

/// Carte « Prochain entraînement » : pictogramme de l'épreuve, la prochaine
/// chose à faire, et le bouton qui y mène.
///
/// Le pictogramme est **le repère écrit/oral** depuis que les deux épreuves
/// partagent le bleu : stylo à l'écrit, micro à l'oral.
class ProductionNextCard extends StatelessWidget {
  const ProductionNextCard({
    super.key,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final TcfProductionModule module;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: module.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(module.icon, size: 20, color: module.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(
                    size: 12,
                    height: 1.35,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: module.accent,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Text(
                  actionLabel,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de tâche : trois cartes « 1 Message · 30-60 mots », l'active
/// encadrée de l'accent. Remplace les anciennes pastilles T1/T2/T3 — elles ne
/// disaient que « Tâche 2 », alors que la carte annonce l'intention et la
/// contrainte, ce qui est précisément ce qui distingue les trois tâches.
class ProductionTaskCards extends StatelessWidget {
  const ProductionTaskCards({
    super.key,
    required this.module,
    required this.active,
    required this.accent,
    required this.onChanged,
    required this.constraintOf,
  });

  final TcfProductionModule module;

  /// Numéro de tâche actif (1-based).
  final int active;
  final Color accent;
  final ValueChanged<int> onChanged;

  /// Contrainte réelle de la tâche (« 30-60 mots », « 3 min »), lue sur les
  /// sujets publiés. `null` quand l'API ne la porte pas — on n'invente pas de
  /// consigne, la carte se contente alors de son titre.
  final String? Function(int tache) constraintOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var n = 1; n <= 3; n++) ...[
          if (n > 1) const SizedBox(width: 8),
          Expanded(
            child: _TaskCard(
              number: n,
              title: productionTaskShortTitle(module, n),
              constraint: constraintOf(n),
              on: n == active,
              accent: accent,
              onTap: () => onChanged(n),
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.number,
    required this.title,
    required this.constraint,
    required this.on,
    required this.accent,
    required this.onTap,
  });

  final int number;
  final String title;
  final String? constraint;
  final bool on;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? accent : AppColors.line,
              width: on ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? accent : AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '$number',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w900,
                    color: on ? AppColors.white : AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: on ? AppColors.ink : AppColors.ink2,
                ),
              ),
              if (constraint != null) ...[
                const SizedBox(height: 2),
                Text(
                  constraint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(size: 10.5, color: AppColors.inkFaint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de palier de l'en-tête : « NIVEAU VISÉ » + le palier.
///
/// C'est le **palier visé** par la démarche du candidat, pas un niveau obtenu.
/// L'eyebrow le dit en toutes lettres : le repo interdit d'afficher un niveau
/// estimé sans le qualifier.
class ProductionLevelBadge extends StatelessWidget {
  const ProductionLevelBadge({super.key, required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NIVEAU VISÉ',
            style: AppFonts.ui(
              size: 8,
              weight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            level,
            style: AppFonts.display(size: 16, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

/// Lien discret vers une ressource d'appoint (les modèles corrigés), posé
/// au-dessus d'une liste. Il ne doit jamais concurrencer l'action principale de
/// l'écran — produire.
class ProductionSideLink extends StatelessWidget {
  const ProductionSideLink({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre segmentée « Parcours examens blancs · n/N » : un segment par examen,
/// rempli quand l'examen a été passé.
class ProductionExamTrail extends StatelessWidget {
  const ProductionExamTrail({
    super.key,
    required this.done,
    required this.total,
    required this.accent,
    this.note,
  });

  final int done;
  final int total;
  final Color accent;

  /// Mention libre alignée sous le titre (« Niveau estimé · B1 »). Absente
  /// tant que le backend n'a pas rendu de bilan : on n'écrit pas un niveau
  /// qu'on ne connaît pas.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcours examens blancs',
                      style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        style:
                            AppFonts.ui(size: 11, color: AppColors.inkFaint),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$done/$total',
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= done ? accent : AppColors.surface3,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
