import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'widgets/bilan_hero.dart';
import 'widgets/feedback_block.dart';
import 'widgets/production_app_header.dart';
import 'widgets/tache_bilan_row.dart';

/// Charge toutes les tasks actives d'une epreuve (max 9 : 3 niveaux x 3 taches).
/// Utilise pour resoudre `productionTaskId` -> displayTitle dans l'historique.
final _allTasksProvider = FutureProvider.autoDispose
    .family<List<ProductionTaskDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listTasks(epreuve: epreuve);
});

/// Charge l'historique complet pour pouvoir filtrer par attemptId. Reutilise
/// le meme provider que `ProductionHistoryScreen` pour beneficier du cache.
final _historyForBilanProvider = FutureProvider.autoDispose
    .family<List<ProductionSubmissionDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listMine(epreuve: epreuve, limit: 200);
});

/// Bilan d'une session passee (lecture seule). Pas de "Terminer la session"
/// ni de "Continuer" : juste affiche les resultats avec un CTA "Retour".
class HistorySessionScreen extends ConsumerWidget {
  const HistorySessionScreen({
    super.key,
    required this.epreuve,
    required this.attemptId,
  });

  final EpreuveType epreuve;
  final String attemptId;

  String _resultsRoute(String submissionId, int taskIndex) {
    final base = epreuve == EpreuveType.tcfEo
        ? '/tcf/expression-orale'
        : '/tcf/expression-ecrite';
    return '$base/resultats/$submissionId?taskIndex=$taskIndex&history=1';
  }

  String get _moduleTitle =>
      epreuve == EpreuveType.tcfEo ? 'Resultats — Expression orale' : 'Resultats — Expression ecrite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyForBilanProvider(epreuve));
    final allTasks = ref.watch(_allTasksProvider(epreuve));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: _moduleTitle,
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref.invalidate(_historyForBilanProvider(epreuve)),
        ),
        data: (allSubs) {
          final session = allSubs.where((s) => s.attemptId == attemptId).toList();
          if (session.isEmpty) {
            return const _ErrorBox(
              message: 'Cette session est introuvable.',
              onRetry: null,
            );
          }
          // Tri par tacheNumero quand on peut, sinon par submittedAt.
          return allTasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBox(
              message: ApiClient.toApiException(e).message,
              onRetry: () => ref.invalidate(_allTasksProvider(epreuve)),
            ),
            data: (tasks) {
              final tasksById = {for (final t in tasks) t.id: t};
              // Trie les submissions par tacheNumero ASC quand on connait la task.
              session.sort((a, b) {
                final ta = tasksById[a.productionTaskId]?.tacheNumero ?? 99;
                final tb = tasksById[b.productionTaskId]?.tacheNumero ?? 99;
                return ta.compareTo(tb);
              });
              return _Body(
                epreuve: epreuve,
                submissions: session,
                tasksById: tasksById,
                onTapTache: (i) {
                  final s = session[i];
                  context.push(_resultsRoute(s.id, i));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.epreuve,
    required this.submissions,
    required this.tasksById,
    required this.onTapTache,
  });

  final EpreuveType epreuve;
  final List<ProductionSubmissionDto> submissions;
  final Map<String, ProductionTaskDto> tasksById;
  final ValueChanged<int> onTapTache;

  double? get _moyenne {
    final notes = submissions
        .map((s) => s.evaluation?.noteSurVingt)
        .whereType<double>()
        .toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  NiveauCecrl? get _niveauGlobal {
    final counts = <NiveauCecrl, int>{};
    for (final s in submissions) {
      final n = s.evaluation?.niveauCecrl;
      if (n != null) counts[n] = (counts[n] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final max = counts.values.reduce((a, b) => a > b ? a : b);
    final tops = counts.entries.where((e) => e.value == max).toList()
      ..sort((a, b) => a.key.scaleIndex.compareTo(b.key.scaleIndex));
    return tops.last.key;
  }

  String _nextStepsMessage() {
    final niveau = _niveauGlobal;
    if (niveau == null) return 'Continuez a vous entrainer pour qu\'on puisse evaluer votre niveau.';
    final modaliteAdj = epreuve == EpreuveType.tcfEo ? 'orale' : 'ecrite';
    switch (niveau) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
        return "Revenez aux bases de l'expression $modaliteAdj. Visez le A2 prochainement.";
      case NiveauCecrl.a2:
        return 'Niveau A2 atteint, suffisant pour la Carte de sejour.';
      case NiveauCecrl.b1:
        return 'Niveau B1 atteint, suffisant pour la Carte de resident.';
      case NiveauCecrl.b2:
        return 'Excellent : niveau B2 atteint, requis pour la naturalisation.';
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        return 'Niveau ${niveau.displayName} -- votre francais $modaliteAdj est avance.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              BilanHero(
                moyenneSur20: _moyenne,
                niveauGlobal: _niveauGlobal,
              ),
              Text(
                'Detail par tache',
                style: AppFonts.jakarta(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tapez sur une tache pour revoir les details de son evaluation.',
                style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < submissions.length; i++)
                _TacheRowTap(
                  onTap: () => onTapTache(i),
                  child: TacheBilanRow(
                    name: _taskName(i),
                    niveauCible: _taskNiveauCible(i),
                    score: submissions[i].evaluation?.noteSurVingt,
                    niveauObtenu: submissions[i].evaluation?.niveauCecrl,
                  ),
                ),
              const SizedBox(height: 12),
              FeedbackBlock(
                kind: FeedbackKind.suggest,
                title: 'Vos prochaines etapes',
                items: [_nextStepsMessage()],
              ),
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
            child: AppButton(
              label: 'Retour a l\'historique',
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _taskName(int i) {
    final s = submissions[i];
    final t = tasksById[s.productionTaskId];
    if (t == null) return 'Tache ${i + 1}';
    return 'Tache ${t.tacheNumero} — ${t.displayTitle}';
  }

  String _taskNiveauCible(int i) {
    final s = submissions[i];
    return tasksById[s.productionTaskId]?.niveauCible ?? '';
  }
}

/// Wrapper InkWell autour d'une `TacheBilanRow` pour la rendre tappable
/// sans modifier le widget de base (qui sert aussi pour le bilan live, non-tappable).
class _TacheRowTap extends StatelessWidget {
  const _TacheRowTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Reessayer',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
