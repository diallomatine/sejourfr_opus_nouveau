import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppGradients.hero(AppColors.blueDark, AppColors.blue),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOTRE DIAGNOSTIC TCF',
                style: AppFonts.label(
                  color: AppColors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _LevelResult(
                      label: 'Expression écrite',
                      level: result.written?.levelEstimate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LevelResult(
                      label: 'Expression orale',
                      level: result.oral?.levelEstimate,
                    ),
                  ),
                ],
              ),
              if (widget.objective != null) ...[
                const SizedBox(height: 13),
                Text(
                  'Objectif : ${widget.objective}',
                  style: AppFonts.ui(
                    size: 13,
                    color: AppColors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
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
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionTitle('Vos points solides'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                for (var index = 0;
                    index < result.strengths.take(3).length;
                    index++)
                  _ResultLine(
                    icon: LucideIcons.circleCheck,
                    color: AppColors.green,
                    text: result.strengths[index],
                    divider: index != result.strengths.take(3).length - 1,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const _SectionTitle('Vos priorités'),
        const SizedBox(height: 10),
        if (result.priorities.isEmpty)
          AppCard(
            child: Text(
              'Aucune priorité exploitable n’a encore été dégagée.',
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
          )
        else
          ...result.priorities.take(3).map(
                (priority) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PriorityCard(priority: priority),
                ),
              ),
        const SizedBox(height: 20),
        _NextActionCard(
          action: result.nextAction,
          explanation: result.mainPriorityExplanation,
          onOpenPlan: widget.onOpenPlan,
          onOpenRecommended: widget.onOpenRecommended,
        ),
        if (result.nextAction != null) ...[
          const SizedBox(height: 8),
          AppButton(
            label: 'Voir mon plan',
            variant: AppButtonVariant.ghost,
            iconRight: LucideIcons.arrowRight,
            onPressed: widget.onOpenPlan,
          ),
        ],
        const SizedBox(height: 8),
        AppButton(
          label: _expanded
              ? 'Masquer le diagnostic complet'
              : 'Voir le diagnostic complet',
          variant: AppButtonVariant.ghost,
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

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({
    required this.action,
    required this.explanation,
    required this.onOpenPlan,
    required this.onOpenRecommended,
  });

  final PlanRecommendedExercise? action;
  final String? explanation;
  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  Widget build(BuildContext context) {
    final exercise = action;
    return AppCard(
      color: AppColors.blueSoft,
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À TRAVAILLER MAINTENANT',
            style: AppFonts.label(color: AppColors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            exercise?.title ?? 'Commencer votre plan personnalisé',
            style: AppFonts.display(size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            exercise == null
                ? 'Retrouvez la prochaine action utile dans votre Plan.'
                : (explanation ??
                    'Un exercice ciblé pour travailler votre priorité principale.'),
            style: AppFonts.ui(
              size: 13,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          if (exercise != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock3,
                  size: 16,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  '${exercise.estimatedMinutes} min · ${exercise.section.wire == 'EO' ? 'oral' : 'écrit'}',
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: exercise == null
                ? 'Commencer mon plan personnalisé'
                : 'Commencer l’exercice recommandé ${exercise.title}',
            child: AppButton(
              label: exercise == null
                  ? 'Commencer mon plan'
                  : 'Commencer l’exercice',
              iconRight: LucideIcons.arrowRight,
              onPressed: exercise == null
                  ? onOpenPlan
                  : () => onOpenRecommended(exercise),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelResult extends StatelessWidget {
  const _LevelResult({required this.label, required this.level});

  final String label;
  final NiveauCecrl? level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
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
              color: AppColors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            level?.shortName ?? '—',
            style: AppFonts.display(size: 24, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppFonts.display(size: 18),
      );
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.icon,
    required this.color,
    required this.text,
    required this.divider,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.lineSoft))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.ui(size: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.priority});

  final DiagnosticSkillObservation priority;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              LucideIcons.target,
              size: 19,
              color: AppColors.amberDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priority.skillTitle,
                  style: AppFonts.ui(size: 14.5, weight: FontWeight.w700),
                ),
                if (priority.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    priority.explanation!,
                    style: AppFonts.ui(
                      size: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                        color: _statusColor(skill.status),
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
                              '« ${skill.evidence} »',
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

  Color _statusColor(LearningPlanSkillStatus status) => switch (status) {
        LearningPlanSkillStatus.priority => AppColors.amberDark,
        LearningPlanSkillStatus.toReinforce => AppColors.amber,
        LearningPlanSkillStatus.solid => AppColors.green,
        LearningPlanSkillStatus.notObserved => AppColors.inkFaint,
      };
}
