import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_production/tcf_production_module.dart' show TcfProductionModule;

/// Briefing avant le démarrage d'un examen complet TCF (3 tâches EE ou EO
/// enchaînées). Bottomsheet modal — miroir du `ModuleExamBriefingSheet` des
/// QCM, palette stricte bleu / blanc / rouge.
///
/// Le caller (TcfProductionDetailScreen) passe un callback `onStart` qui
/// déclenche `EeSessionController.start` / `EoSessionController.start` puis
/// push le briefing T1 mode session.
class ProductionExamBriefingSheet extends StatelessWidget {
  const ProductionExamBriefingSheet({
    super.key,
    required this.module,
    required this.starting,
    required this.onStart,
  });

  final TcfProductionModule module;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isEo = module.epreuve == EpreuveType.tcfEo;
    final durationLabel = '${module.durationLabel} min';
    final tasks = isEo ? _eoTasks : _eeTasks;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'EXAMEN COMPLET ${module.title.toUpperCase()}',
                        style: AppFonts.mono(
                          size: 9.5,
                          color: AppColors.muted,
                          letterSpacing: 1.8,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _DurationBadge(label: durationLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Hero(
                    icon: module.icon,
                    title: isEo ? 'Prêt à parler ?' : 'Prêt à écrire ?',
                    description: isEo
                        ? 'Tu enchaînes 3 tâches orales d\'affilée comme au vrai TCF. Chaque réponse est enregistrée puis notée par l\'IA.'
                        : 'Tu enchaînes 3 tâches écrites d\'affilée comme au vrai TCF. Chaque réponse est corrigée par l\'IA en fin de session.',
                  ),
                  const SizedBox(height: 16),
                  _TasksCard(tasks: tasks),
                  const SizedBox(height: 12),
                  _ConseilCard(
                    text: isEo
                        ? 'Parle clairement, utilise des connecteurs (d\'abord, ensuite, donc) et évite les longs blancs. L\'IA apprécie la fluidité.'
                        : 'Lis bien la consigne, structure ta réponse (introduction, développement, conclusion) et respecte le nombre de mots indiqué.',
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Commencer maintenant',
                    icon: Icons.play_arrow_rounded,
                    variant: AppButtonVariant.danger,
                    isLoading: starting,
                    onPressed: starting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onStart();
                          },
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Annuler',
                    variant: AppButtonVariant.ghost,
                    onPressed: starting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper : ouvre le briefing en bottomsheet modal.
void showProductionExamBriefingSheet(
  BuildContext context, {
  required TcfProductionModule module,
  required bool starting,
  required VoidCallback onStart,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProductionExamBriefingSheet(
      module: module,
      starting: starting,
      onStart: onStart,
    ),
  );
}

class _ExamTask {
  const _ExamTask({
    required this.index,
    required this.label,
    required this.detail,
  });

  final int index;
  final String label;
  final String detail;
}

const _eeTasks = <_ExamTask>[
  _ExamTask(
    index: 1,
    label: 'Message simple',
    detail: 'Email, invitation, annulation · 60-120 mots',
  ),
  _ExamTask(
    index: 2,
    label: 'Récit',
    detail: 'Expérience personnelle · 120-150 mots',
  ),
  _ExamTask(
    index: 3,
    label: 'Opinion',
    detail: 'Argumentation simple · 120-180 mots',
  ),
];

const _eoTasks = <_ExamTask>[
  _ExamTask(
    index: 1,
    label: 'Présentation',
    detail: 'Parler de soi, travail, loisirs',
  ),
  _ExamTask(
    index: 2,
    label: 'Jeu de rôle',
    detail: 'Poser des questions et interagir',
  ),
  _ExamTask(
    index: 3,
    label: 'Opinion',
    detail: 'Donner son avis et argumenter',
  ),
];

class _Hero extends StatelessWidget {
  const _Hero({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.red, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFonts.jakarta(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.tasks});

  final List<_ExamTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DÉROULÉ',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < tasks.length; i++) ...[
            _TaskRow(task: tasks[i]),
            if (i != tasks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final _ExamTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${task.index}',
              style: AppFonts.jakarta(
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tâche ${task.index} · ${task.label}',
                  style: AppFonts.jakarta(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.detail,
                  style: AppFonts.jakarta(
                    size: 12,
                    color: AppColors.muted,
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

class _ConseilCard extends StatelessWidget {
  const _ConseilCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppColors.red,
              ),
              const SizedBox(width: 6),
              Text(
                'CONSEIL',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.red,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
