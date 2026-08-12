import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/evidence_excerpt.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/gradient_hero.dart';

/// Écran de fin de diagnostic. Il rend **ce que le serveur a réellement
/// observé** : les deux niveaux estimés, les compétences observées, la
/// priorité n°1 et le détail des deux productions (`summary`,
/// `taskCompletion`, `communicationStatus`, `weaknesses` — présents dans le
/// contrat depuis le début, jamais affichés jusqu'ici).
///
/// Aucun pourcentage de progression vers un palier : le brief l'interdit et le
/// serveur n'en publie aucun.
class DiagnosticResultView extends StatefulWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    required this.onOpenPlan,
    required this.onOpenRecommended,
    this.objective,
  });

  final DiagnosticResult result;
  final String? objective;
  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  State<DiagnosticResultView> createState() => _DiagnosticResultViewState();
}

class _DiagnosticResultViewState extends State<DiagnosticResultView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final observed = _observedSkills(result);
    final priorities = result.priorities;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const _DoneBadge(),
        const SizedBox(height: 14),
        Text(
          'On sait maintenant quoi travailler.',
          style: AppFonts.display(size: 27, height: 1.08),
        ),
        const SizedBox(height: 8),
        Text(
          'Vos productions écrite et orale ont permis d’identifier les compétences qui vous feront progresser le plus vite.',
          style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft, height: 1.45),
        ),
        const SizedBox(height: 20),
        _LevelsHero(
          written: result.written?.levelEstimate,
          oral: result.oral?.levelEstimate,
          objective: widget.objective,
        ),
        const SizedBox(height: 10),
        const _EstimationNote(),
        if (observed.isNotEmpty || result.strengths.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionHead(
            title: 'Ce que votre diagnostic révèle',
            description:
                'Pas une liste de fautes : seulement les éléments utiles pour avancer.',
          ),
          const SizedBox(height: 10),
          if (result.strengths.isNotEmpty) ...[
            _StrengthsCard(strengths: result.strengths.take(3).toList()),
            const SizedBox(height: 10),
          ],
          if (observed.isNotEmpty) _SkillSnapshotCard(skills: observed),
        ],
        if (priorities.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionHead(
            title: 'Votre priorité n°1',
            description: 'C’est ici que votre plan commence.',
          ),
          const SizedBox(height: 10),
          _MainPriorityCard(
            priority: priorities.first,
            explanation: result.mainPriorityExplanation,
            rank: 1,
            total: priorities.length,
          ),
          if (priorities.length > 1) ...[
            const SizedBox(height: 10),
            _NextPrioritiesCard(priorities: priorities.skip(1).toList()),
          ],
        ],
        if (result.written != null || result.oral != null) ...[
          const SizedBox(height: 22),
          const _SectionHead(
            title: 'Vos deux productions',
            description: 'Ce que chaque production a montré.',
          ),
          const SizedBox(height: 10),
          if (result.written != null)
            _ProductionCard(
              title: 'Expression écrite',
              icon: LucideIcons.penLine,
              accent: AppColors.blue,
              accentSoft: AppColors.blueLight,
              production: result.written!,
            ),
          if (result.written != null && result.oral != null)
            const SizedBox(height: 10),
          if (result.oral != null)
            _ProductionCard(
              title: 'Expression orale',
              icon: LucideIcons.mic,
              accent: AppColors.red,
              accentSoft: AppColors.redLight,
              production: result.oral!,
            ),
        ],
        const SizedBox(height: 22),
        _PlanCallToAction(
          action: result.nextAction,
          onOpenPlan: widget.onOpenPlan,
          onOpenRecommended: widget.onOpenRecommended,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: _expanded
              ? 'Masquer le diagnostic complet'
              : 'Voir le diagnostic complet',
          variant: AppButtonVariant.outline,
          iconRight:
              _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _ProductionDetails(
            title: 'Diagnostic écrit',
            result: result.written,
          ),
          const SizedBox(height: 12),
          _ProductionDetails(
            title: 'Diagnostic oral',
            result: result.oral,
          ),
        ],
      ],
    );
  }
}

/// Compétences réellement observées sur les deux productions, les plus
/// actionnables d'abord. Aucune fusion savante : on dédoublonne par `skillId`
/// et on garde ce que le serveur a dit.
List<DiagnosticSkillObservation> _observedSkills(DiagnosticResult result) {
  final seen = <String>{};
  final all = <DiagnosticSkillObservation>[];
  for (final production in [result.written, result.oral]) {
    for (final skill in production?.skills ?? const []) {
      if (!skill.observed) continue;
      if (!seen.add(skill.skillId)) continue;
      all.add(skill);
    }
  }
  all.sort((a, b) => _severity(a.status).compareTo(_severity(b.status)));
  return all.take(6).toList(growable: false);
}

int _severity(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => 0,
      LearningPlanSkillStatus.toReinforce => 1,
      LearningPlanSkillStatus.solid => 2,
      LearningPlanSkillStatus.notObserved => 3,
    };

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Diagnostic terminé',
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LevelsHero extends StatelessWidget {
  const _LevelsHero({
    required this.written,
    required this.oral,
    required this.objective,
  });

  final NiveauCecrl? written;
  final NiveauCecrl? oral;
  final String? objective;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIVEAU ESTIMÉ AUJOURD’HUI',
            style: AppFonts.label(
              color: AppColors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 12),
          // IntrinsicHeight : les deux blocs de niveau doivent avoir la même
          // hauteur, or un `stretch` dans une colonne scrollable n'a pas de
          // contrainte de hauteur.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _LevelBlock(
                    label: 'Expression écrite',
                    level: written,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LevelBlock(
                    label: 'Expression orale',
                    level: oral,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.only(top: 13),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.16),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (objective != null)
                  Row(
                    children: [
                      Icon(
                        LucideIcons.target,
                        size: 15,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Objectif : $objective',
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                if (objective != null) const SizedBox(height: 6),
                Text(
                  'Estimation d’entraînement, non officielle.',
                  style: AppFonts.ui(
                    size: 11.5,
                    color: AppColors.white.withValues(alpha: 0.72),
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

class _LevelBlock extends StatelessWidget {
  const _LevelBlock({required this.label, required this.level});

  final String label;
  final NiveauCecrl? level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level?.shortName ?? '—',
            style: AppFonts.display(size: 34, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _EstimationNote extends StatelessWidget {
  const _EstimationNote();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 14, color: AppColors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cette estimation est pédagogique : elle ne remplace pas un résultat officiel du TCF.',
                style: AppFonts.ui(
                  size: 11.5,
                  height: 1.4,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.display(size: 19)),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: AppFonts.ui(
                  size: 12,
                  height: 1.35,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ],
        ),
      );
}

class _StrengthsCard extends StatelessWidget {
  const _StrengthsCard({required this.strengths});

  final List<String> strengths;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.greenLight,
        border: Border.all(color: AppColors.green.withValues(alpha: 0.18)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce qui fonctionne déjà',
              style: AppFonts.ui(
                size: 12.5,
                weight: FontWeight.w800,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 7),
            for (final strength in strengths)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strength,
                        style: AppFonts.ui(size: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// Les compétences observées, chacune teintée par son statut : vert solide,
/// ambre à renforcer, rouge prioritaire. La teinte vient de
/// `LearningPlanSkillStatus.color`, partagée avec le Plan.
class _SkillSnapshotCard extends StatelessWidget {
  const _SkillSnapshotCard({required this.skills});

  final List<DiagnosticSkillObservation> skills;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < skills.length; index++)
              _SkillSnapshotRow(
                skill: skills[index],
                divider: index != skills.length - 1,
              ),
          ],
        ),
      );
}

/// Une compétence observée, **repliée par défaut**.
///
/// Déplié, le diagnostic alignait une douzaine d'explications de trois à quatre
/// lignes : le candidat y voyait un mur de texte et n'en lisait aucune. Replié,
/// il lit d'abord le **verdict** (titre + statut) et n'ouvre que ce qui
/// l'intéresse. Rien n'est retiré — tout est à un geste.
class _SkillSnapshotRow extends StatefulWidget {
  const _SkillSnapshotRow({required this.skill, required this.divider});

  final DiagnosticSkillObservation skill;
  final bool divider;

  @override
  State<_SkillSnapshotRow> createState() => _SkillSnapshotRowState();
}

class _SkillSnapshotRowState extends State<_SkillSnapshotRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final tone = skill.status.color;
    final detail = skill.explanation;
    final evidence = skill.evidence;
    // Sans détail, l'encart n'a rien à ouvrir : ni chevron, ni zone tactile.
    final expandable = detail != null || evidence != null;

    final header = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(_statusIcon(skill.status), size: 18, color: tone),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            skill.skillTitle,
            style: AppFonts.ui(size: 13.5, weight: FontWeight.w700, height: 1.3),
          ),
        ),
        const SizedBox(width: 8),
        AppTag(
          label: skill.status.label,
          tone: _statusTone(skill.status),
          compact: true,
        ),
        if (expandable) ...[
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: widget.divider
            ? const Border(bottom: BorderSide(color: AppColors.lineSoft))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expandable)
            Semantics(
              button: true,
              expanded: _open,
              label: '${skill.skillTitle} · ${skill.status.label}',
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: header,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: header,
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(left: 49, bottom: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail != null)
                          Text(
                            detail,
                            style: AppFonts.ui(
                              size: 12,
                              height: 1.4,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        if (evidence != null) ...[
                          if (detail != null) const SizedBox(height: 7),
                          Text(
                            '« ${evidenceExcerpt(evidence)} »',
                            style: AppFonts.ui(
                              size: 11.5,
                              height: 1.4,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => LucideIcons.circleAlert,
      LearningPlanSkillStatus.toReinforce => LucideIcons.trendingUp,
      LearningPlanSkillStatus.solid => LucideIcons.circleCheck,
      LearningPlanSkillStatus.notObserved => LucideIcons.circle,
    };

TagTone _statusTone(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => TagTone.red,
      LearningPlanSkillStatus.toReinforce => TagTone.amber,
      LearningPlanSkillStatus.solid => TagTone.success,
      LearningPlanSkillStatus.notObserved => TagTone.neutral,
    };

class _MainPriorityCard extends StatelessWidget {
  const _MainPriorityCard({
    required this.priority,
    required this.explanation,
    required this.rank,
    required this.total,
  });

  final DiagnosticSkillObservation priority;
  final String? explanation;
  final int rank;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = explanation ?? priority.explanation;
    return AppCard(
      color: AppColors.redLight,
      border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppTag(
                label: 'IMPACT ÉLEVÉ',
                tone: TagTone.red,
                icon: LucideIcons.zap,
                compact: true,
              ),
              const Spacer(),
              Text(
                'Priorité $rank/$total',
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            priority.skillTitle,
            style: AppFonts.display(size: 18, height: 1.22),
          ),
          if (text != null) ...[
            const SizedBox(height: 7),
            Text(
              text,
              style: AppFonts.ui(
                size: 13,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ],
          if (priority.evidence != null) ...[
            const SizedBox(height: 12),
            _EvidenceBlock(text: priority.evidence!),
          ],
        ],
      ),
    );
  }
}

class _EvidenceBlock extends StatelessWidget {
  const _EvidenceBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXTRAIT DE VOTRE PRODUCTION',
              style: AppFonts.label(size: 10, color: AppColors.inkFaint),
            ),
            const SizedBox(height: 5),
            Text(
              '« ${evidenceExcerpt(text)} »',
              style: AppFonts.ui(
                size: 12.5,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
}

class _NextPrioritiesCard extends StatelessWidget {
  const _NextPrioritiesCard({required this.priorities});

  final List<DiagnosticSkillObservation> priorities;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            for (var index = 0; index < priorities.length; index++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: index != priorities.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.lineSoft),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 2}',
                        style: AppFonts.display(
                          size: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        priorities[index].skillTitle,
                        style: AppFonts.ui(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppTag(
                      label: priorities[index].section.wire,
                      tone: TagTone.neutral,
                      compact: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// Carte d'une production. Elle met enfin à l'écran ce que le contrat serveur
/// portait sans jamais l'afficher : le résumé, l'accomplissement de la
/// consigne, l'efficacité du message et les points à travailler.
/// Le bilan d'une production, **replié par défaut**.
///
/// Même raison que les compétences observées : résumé de cinq lignes, deux
/// pastilles d'état et deux points à travailler multi-lignes, fois deux
/// productions — le candidat voyait un mur. Replié, il lit l'épreuve et son
/// niveau estimé, et n'ouvre que celle qui l'intéresse.
class _ProductionCard extends StatefulWidget {
  const _ProductionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.production,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final DiagnosticProductionResult production;

  @override
  State<_ProductionCard> createState() => _ProductionCardState();
}

class _ProductionCardState extends State<_ProductionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final production = widget.production;
    final accent = widget.accent;
    final weaknesses = production.weaknesses.take(2).toList(growable: false);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label:
                '${widget.title} · niveau estimé ${production.levelEstimate.shortName}',
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(widget.icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppFonts.ui(size: 14.5, weight: FontWeight.w800),
                      ),
                    ),
                    AppTag(
                      label: production.levelEstimate.shortName,
                      tone: production.levelEstimate.tagTone,
                      compact: true,
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : _ProductionDetail(
                    production: production,
                    accent: accent,
                    weaknesses: weaknesses,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductionDetail extends StatelessWidget {
  const _ProductionDetail({
    required this.production,
    required this.accent,
    required this.weaknesses,
  });

  final DiagnosticProductionResult production;
  final Color accent;
  final List<String> weaknesses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (production.summary != null) ...[
            Text(
              production.summary!,
              style: AppFonts.ui(
                size: 13,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 11),
          ],
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StateChip(
                icon: LucideIcons.listChecks,
                label: production.taskCompletion.label,
                tone: _completionTone(production.taskCompletion),
              ),
              _StateChip(
                icon: LucideIcons.messagesSquare,
                label: production.communicationStatus.label,
                tone: _communicationTone(production.communicationStatus),
              ),
            ],
          ),
          if (weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À TRAVAILLER',
                    style: AppFonts.label(size: 10, color: AppColors.inkFaint),
                  ),
                  const SizedBox(height: 6),
                  for (final weakness in weaknesses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              weakness,
                              style: AppFonts.ui(size: 12.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: tone),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.ui(
                size: 11,
                weight: FontWeight.w700,
                color: tone,
              ),
            ),
          ],
        ),
      );
}

Color _completionTone(DiagnosticTaskCompletion completion) =>
    switch (completion) {
      DiagnosticTaskCompletion.completed => AppColors.green,
      DiagnosticTaskCompletion.partial => AppColors.amberDark,
      DiagnosticTaskCompletion.notCompleted => AppColors.red,
    };

Color _communicationTone(DiagnosticCommunicationStatus status) =>
    switch (status) {
      DiagnosticCommunicationStatus.effective => AppColors.green,
      DiagnosticCommunicationStatus.partial => AppColors.amberDark,
      DiagnosticCommunicationStatus.ineffective => AppColors.red,
    };

class _PlanCallToAction extends StatelessWidget {
  const _PlanCallToAction({
    required this.action,
    required this.onOpenPlan,
    required this.onOpenRecommended,
  });

  final PlanRecommendedExercise? action;
  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  Widget build(BuildContext context) {
    final exercise = action;
    return AppCard(
      color: AppColors.blueSoft,
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.16)),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 21,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Votre plan est prêt',
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Il commence par vos priorités les plus importantes et s’adapte ensuite à vos nouvelles productions.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 12.5,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Découvrir mon plan personnalisé',
            child: AppButton(
              label: 'Découvrir mon plan',
              iconRight: LucideIcons.arrowRight,
              onPressed: onOpenPlan,
            ),
          ),
          if (exercise != null) ...[
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Commencer l’exercice recommandé ${exercise.title}',
              child: AppButton(
                label:
                    'Commencer l’exercice · ${exercise.estimatedMinutes} min',
                variant: AppButtonVariant.soft,
                height: 46,
                onPressed: () => onOpenRecommended(exercise),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.title,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 11.5, color: AppColors.inkFaint),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductionDetails extends StatelessWidget {
  const _ProductionDetails({required this.title, required this.result});

  final String title;
  final DiagnosticProductionResult? result;

  @override
  Widget build(BuildContext context) {
    final observed = result?.skills.where((skill) => skill.observed).toList() ??
        const <DiagnosticSkillObservation>[];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.display(size: 17)),
          if (result?.summary != null) ...[
            const SizedBox(height: 5),
            Text(
              result!.summary!,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
          if (observed.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final skill in observed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: skill.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${skill.skillTitle} · ${skill.status.label}',
                            style: AppFonts.ui(
                              size: 12.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (skill.evidence != null)
                            Text(
                              '« ${evidenceExcerpt(skill.evidence!)} »',
                              style: AppFonts.ui(
                                size: 12,
                                color: AppColors.inkFaint,
                                height: 1.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
