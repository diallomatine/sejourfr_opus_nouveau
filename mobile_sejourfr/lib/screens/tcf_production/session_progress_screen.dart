import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'session_view.dart';
import 'widgets/production_app_header.dart';
import 'widgets/task_progress_item.dart';

/// Ecran "Votre progression" entre les taches d'une session EO ou EE.
/// Affiche le compteur "X/3" + la liste des taches avec statut (done / current /
/// todo). CTA principal "Continuer" -> tache suivante.
class SessionProgressScreen extends ConsumerWidget {
  const SessionProgressScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  String get _moduleTitle =>
      epreuve == EpreuveType.tcfEo ? 'Expression orale' : 'Expression ecrite';

  String _baseRoute() => epreuve == EpreuveType.tcfEo
      ? AppRoutes.tcfExpressionOrale
      : AppRoutes.tcfExpressionEcrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = readSessionView(ref, epreuve);
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: ProductionAppHeader(title: _moduleTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final nextIndex = _nextTaskIndex(session);
    final hasNext = nextIndex != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: _moduleTitle,
        rightAction: ProductionAppHeaderQuit(
          onPressed: () {
            resetSession(ref, epreuve);
            context.go(AppRoutes.tcf);
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                children: [
                  Text(
                    'Votre progression',
                    style: AppFonts.jakarta(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProgressionSummary(
                    completed: session.completed,
                    total: session.total,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(session.total, (i) {
                    final task = session.taskAt(i)!;
                    final sub = session.submissions[i];
                    TaskProgressStatus status;
                    if (sub != null) {
                      status = TaskProgressStatus.done;
                    } else if (i == nextIndex) {
                      status = TaskProgressStatus.current;
                    } else {
                      status = TaskProgressStatus.todo;
                    }
                    return TaskProgressItem(
                      number: i + 1,
                      name: task.displayTitle,
                      niveauCible: task.niveauCible,
                      status: status,
                      score: sub?.evaluation?.noteSurVingt,
                      niveauObtenu: sub?.evaluation?.niveauCecrl,
                    );
                  }),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    AppButton(
                      label: hasNext
                          ? 'Continuer l\'entrainement'
                          : 'Voir mon bilan',
                      icon: hasNext ? Icons.arrow_forward_rounded : Icons.bar_chart_rounded,
                      onPressed: hasNext
                          ? () => context.pushReplacement(
                              '${_baseRoute()}/t/$nextIndex')
                          : () => context.pushReplacement('${_baseRoute()}/bilan'),
                    ),
                    if (hasNext && session.completed > 0) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.line),
                          foregroundColor: AppColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Revoir mes resultats',
                          style: AppFonts.jakarta(
                            size: 15,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _nextTaskIndex(SessionView session) {
    for (int i = 0; i < session.total; i++) {
      if (!session.submissions.containsKey(i)) return i;
    }
    return null;
  }
}

class _ProgressionSummary extends StatelessWidget {
  const _ProgressionSummary({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Taches completees',
            style: AppFonts.jakarta(size: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$completed',
                  style: AppFonts.fraunces(
                    size: 48,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: '/$total',
                  style: AppFonts.jakarta(
                    size: 24,
                    weight: FontWeight.w500,
                    color: AppColors.muted2,
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
