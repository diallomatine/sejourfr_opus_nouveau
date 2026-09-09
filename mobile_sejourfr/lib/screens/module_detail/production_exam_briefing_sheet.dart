import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
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
    // Durée d'épreuve servie par la table partagée : « 30 min » à l'écrit,
    // « Chrono par tâche » à l'oral, qui n'a plus de chrono d'épreuve.
    final durationLabel = module.durationLabel;
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
                        ? 'Tu enchaînes 3 tâches orales comme au vrai TCF. Tu lis chaque consigne sans chrono, puis tu lances la tâche quand tu es prêt : le temps de parole ne part qu\'à cet instant. Chaque réponse est enregistrée puis notée par l\'IA.'
                        : 'Tu enchaînes 3 tâches écrites d\'affilée comme au vrai TCF. Le chrono de $durationLabel couvre les 3 tâches ensemble, à toi de répartir. Chaque réponse est corrigée par l\'IA en fin de session.',
                  ),
                  const SizedBox(height: 16),
                  _TasksCard(tasks: tasks),
                  const SizedBox(height: 12),
                  _ConseilCard(
                    text: isEo
                        ? 'Exprime tes idées clairement et utilise des connecteurs (d\'abord, ensuite, donc). L\'IA corrige les mots transcrits ; elle n\'évalue ni la prononciation ni la fluidité.'
                        : 'Lis bien la consigne, structure ta réponse (introduction, développement, conclusion) et respecte le nombre de mots indiqué.',
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Commencer maintenant',
                    icon: LucideIcons.play,
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
                    onPressed:
                        starting ? null : () => Navigator.of(context).pop(),
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

/// Une ligne du sommaire du briefing.
///
/// 🛑 **Aucun intitulé de tâche ici** : [label] est lu sur
/// [productionTaskTitle], seule autorité du front. Trois copies écrites à la
/// main avaient divergé — ce briefing annonçait « Présentation » et
/// « Opinion » là où le hub d'épreuve ouvrait « Entretien dirigé » et « Point
/// de vue ».
class _ExamTask {
  const _ExamTask({
    required this.index,
    required this.epreuve,
    required this.detail,
  });

  final int index;
  final EpreuveType epreuve;
  final String detail;

  String get label => productionTaskTitle(epreuve, index);
}

const _eeTasks = <_ExamTask>[
  _ExamTask(
    index: 1,
    epreuve: EpreuveType.tcfEe,
    detail: 'Email, invitation, annulation · 30-60 mots',
  ),
  _ExamTask(
    index: 2,
    epreuve: EpreuveType.tcfEe,
    detail: 'Expérience personnelle · 40-90 mots',
  ),
  _ExamTask(
    index: 3,
    epreuve: EpreuveType.tcfEe,
    detail: 'Argumentation simple · 40-90 mots',
  ),
];

const _eoTasks = <_ExamTask>[
  _ExamTask(
    index: 1,
    epreuve: EpreuveType.tcfEo,
    detail: 'Parler de soi, travail, loisirs',
  ),
  _ExamTask(
    index: 2,
    epreuve: EpreuveType.tcfEo,
    detail: 'Poser des questions et interagir',
  ),
  _ExamTask(
    index: 3,
    epreuve: EpreuveType.tcfEo,
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
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
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
            style: AppFonts.ui(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppFonts.ui(
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
          const Icon(LucideIcons.timer, size: 13, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.ui(
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
              style: AppFonts.ui(
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
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.detail,
                  style: AppFonts.ui(
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
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 14,
                color: AppColors.amberDark,
              ),
              const SizedBox(width: 6),
              Text(
                'CONSEIL',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.amberDark,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.ui(
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
