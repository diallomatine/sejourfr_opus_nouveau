import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/eyebrow.dart';

/// Historique des **examens blancs TCF complets** (4 épreuves CO + CE + EE +
/// EO en conditions réelles). On ne mélange pas avec les examens module (CO
/// ou CE isolés) ni avec les sessions EE/EO single — ces surfaces ont leurs
/// propres écrans (onglet Examens des détails module, historiques EE/EO).
///
/// Source = `GET /api/me/full-tcf-exams`, dédiée à cet usage : un examen =
/// un parent `TCF_COMPLET` agrégeant ses 4 sous-attempts. Le bilan ouvert
/// au tap est `/tcf/examen-blanc/:parentId/bilan`.
final _tcfFullExamHistoryProvider = FutureProvider.autoDispose<List<FullTcfExamSummary>>((ref) {
  return ref.watch(fullTcfExamRepositoryProvider).listMine(limit: 30);
});

class TcfExamHistoryScreen extends ConsumerWidget {
  const TcfExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(_tcfFullExamHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Examens TCF',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(_tcfFullExamHistoryProvider),
          ),
          data: (exams) {
            if (exams.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_tcfFullExamHistoryProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _Header(exams: exams),
                  const SizedBox(height: 18),
                  const Eyebrow('§ Sessions'),
                  const SizedBox(height: 10),
                  for (final e in exams) ...[
                    _ExamItem(
                      exam: e,
                      onTap: () => context.push(
                        AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', e.id),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — meilleur niveau CECRL plancher obtenu, count examens
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.exams});

  final List<FullTcfExamSummary> exams;

  @override
  Widget build(BuildContext context) {
    final completed = exams.where((e) => e.status == FullTcfExamStatus.completed).toList();
    final best = _bestLevel(completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(
          '§ ${exams.length} examen${exams.length > 1 ? "s" : ""} TCF complet${exams.length > 1 ? "s" : ""}',
        ),
        const SizedBox(height: 8),
        if (best != null)
          RichText(
            text: TextSpan(
              style: AppFonts.display(size: 22, weight: FontWeight.w500),
              children: [
                const TextSpan(text: 'Meilleur niveau atteint : '),
                TextSpan(
                  text: best.wire,
                  style: AppFonts.display(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Aucun niveau CECRL plancher disponible pour l\'instant.',
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
        const SizedBox(height: 6),
        Text(
          'Le niveau du TCF IRN est le plancher des 4 épreuves (CO · CE · EE · EO).',
          style: AppFonts.ui(
            size: 12.5,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Meilleur niveau CECRL parmi les examens completés. Le niveau le plus
  /// haut atteint, pas le plancher des planchers. Les bilans **partiels**
  /// (épreuve verrouillée par le freemium ou évaluation en échec) en sont
  /// exclus : ils ne portent pas sur les 4 épreuves.
  NiveauCecrl? _bestLevel(List<FullTcfExamSummary> completed) {
    NiveauCecrl? best;
    for (final e in completed) {
      final lvl = e.finalCecrlLevel;
      if (lvl == null || e.finalLevelPartial) continue;
      if (best == null || lvl.index > best.index) best = lvl;
    }
    return best;
  }
}

// ---------------------------------------------------------------------------
// Item examen — un parent TCF_COMPLET
// ---------------------------------------------------------------------------

class _ExamItem extends StatelessWidget {
  const _ExamItem({required this.exam, required this.onTap});

  final FullTcfExamSummary exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lvl = exam.finalCecrlLevel;
    // Bilan partiel : la pastille porte un niveau qui ne couvre pas les 4
    // épreuves — on le dit, plutôt que de le laisser passer pour un résultat
    // d'examen complet.
    final statusLabel = _statusLabel(exam.status) +
        (exam.finalLevelPartial ? ' · partiel' : '');
    final dateStr = _formatDate(exam.startedAt);
    final isCompleted = exam.status == FullTcfExamStatus.completed;

    final (badgeBg, badgeColor) = _levelTone(lvl, isCompleted);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Pastille niveau CECRL (ou "—" si pas encore évalué)
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              lvl?.shortName ?? '—',
              style: AppFonts.display(
                size: 18,
                weight: FontWeight.w700,
                color: badgeColor,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examen blanc · 4 épreuves',
                  style: AppFonts.ui(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr · $statusLabel',
                  style: AppFonts.ui(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.muted2),
        ],
      ),
    );
  }

  String _statusLabel(FullTcfExamStatus s) => switch (s) {
        FullTcfExamStatus.inProgress => 'en cours',
        FullTcfExamStatus.pendingEvaluations => 'évaluations en cours',
        FullTcfExamStatus.completed => 'terminé',
      };

  /// Couleurs de fond + texte de la pastille selon le niveau. On reste sur
  /// la palette globale (pas de hex en dur) : rouge pour les paliers TCF
  /// (la couleur d'identité TCF), ambre pour A1, gris si pas encore noté.
  (Color, Color) _levelTone(NiveauCecrl? lvl, bool completed) {
    if (lvl == null) {
      return (
        AppColors.blueLight,
        completed ? AppColors.blue : AppColors.muted,
      );
    }
    if (lvl == NiveauCecrl.a1NonAtteint || lvl == NiveauCecrl.a1) {
      return (AppColors.amber.withValues(alpha: 0.12), AppColors.amber);
    }
    return (AppColors.redLight, AppColors.red);
  }

  String _formatDate(DateTime d) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Empty / Error
// ---------------------------------------------------------------------------

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.timer, size: 48, color: AppColors.muted2),
            const SizedBox(height: 14),
            Text(
              'Aucun examen TCF',
              style: AppFonts.display(
                size: 20,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos examens blancs TCF complets (CO + CE + EE + EO) apparaîtront ici.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted2),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => context.push(AppRoutes.tcfFullExams),
              child: Text(
                'Lancer un examen blanc TCF',
                style: AppFonts.ui(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cloudOff, size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
