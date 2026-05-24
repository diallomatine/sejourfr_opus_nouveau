import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'tcf_full_exam_briefing_sheet.dart';

/// Liste des examens blancs TCF complets de l'utilisateur. Chaque examen
/// passé est affiché avec son niveau CECRL plancher, sa date et son statut.
/// Tap :
/// - {@code COMPLETED} / {@code PENDING_EVALUATIONS} → push le bilan
/// - {@code IN_PROGRESS} → reprend l'examen sur le hub de progression
/// - Bouton "Lancer un nouvel examen" → briefing modal + POST `/api/full-tcf-exams`
///
/// **Distinction backend** : ces examens sont conceptuellement séparés des
/// examens module (CO seul / CE seul) — `attempts.epreuve = TCF_COMPLET`
/// vs `attempts.module_exam_question_type`. L'historique ne se mélange jamais.
final _fullExamsHistoryProvider =
    FutureProvider.autoDispose<List<FullTcfExamSummary>>((ref) {
  return ref.watch(fullTcfExamRepositoryProvider).listMine(limit: 50);
});

/// 20 slots disponibles, comme un cahier d'examens blancs. Au-delà, on
/// continue à pouvoir lancer mais on n'affiche plus de slot supplémentaire
/// — l'historique reste consultable via les premiers slots (rotation
/// chronologique : slot 1 = examen le plus ancien).
const int _fullExamSlotsCount = 20;

/// Écran plein des examens blancs TCF complets, avec topbar + back. Atteint
/// depuis le hero Progression, l'historique et le bilan (`AppRoutes.tcfFullExams`).
/// Dans le hub TCF, c'est `TcfFullExamsView` (le corps) qui est embarqué sous
/// l'onglet Examens — pas cet écran.
class TcfFullExamsScreen extends StatelessWidget {
  const TcfFullExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: _TopBar(onBack: () => _back(context)),
            ),
            const Expanded(child: TcfFullExamsView()),
          ],
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tcf);
    }
  }
}

/// Corps de l'onglet « Examens » du hub TCF : 20 slots d'examens blancs
/// complets. Embarqué dans `TcfScreen` (le hub fournit l'en-tête) et réutilisé
/// par `TcfFullExamsScreen` (qui ajoute une topbar avec back).
class TcfFullExamsView extends ConsumerWidget {
  const TcfFullExamsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_fullExamsHistoryProvider);

    Future<void> startNew(int slot) async {
      final auth = ref.read(authControllerProvider);
      final isPremium = auth is AuthAuthenticated &&
          auth.user.canAccessModule(AppModule.tcf);
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      if (!isPremium) {
        showPaywallSheet(context);
        return;
      }
      showTcfFullExamBriefingSheet(
        context,
        slot: slot,
        onStart: () async {
          try {
            final exam =
                await ref.read(fullTcfExamRepositoryProvider).start();
            if (!context.mounted) return;
            // Force le re-fetch de l'historique quand on revient ici plus tard.
            ref.invalidate(_fullExamsHistoryProvider);
            context.go(
              AppRoutes.tcfFullExamProgress
                  .replaceFirst(':parentId', exam.id),
            );
          } on ApiException catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message),
                backgroundColor: AppColors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Impossible de démarrer l\'examen. Réessaye dans un instant.'),
                backgroundColor: AppColors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        ref.invalidate(_fullExamsHistoryProvider);
        await ref.read(_fullExamsHistoryProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const _Hero(),
          const SizedBox(height: 16),
          const _Stats(),
          const SizedBox(height: 22),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(
              message: e.toString(),
              onRetry: () => ref.invalidate(_fullExamsHistoryProvider),
            ),
            data: (history) => _SlotsSection(
              history: history,
              onTapDone: (exam) => _openExam(context, exam),
              onTapEmpty: startNew,
            ),
          ),
        ],
      ),
    );
  }

  void _openExam(BuildContext context, FullTcfExamSummary exam) {
    switch (exam.status) {
      case FullTcfExamStatus.inProgress:
        context.go(
          AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
        );
        break;
      case FullTcfExamStatus.pendingEvaluations:
      case FullTcfExamStatus.completed:
        context.go(
          AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id),
        );
        break;
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chevron_left_rounded,
                  size: 22, color: AppColors.ink),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'TCF IRN',
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

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
          Text(
            'EXAMENS BLANCS',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.white.withValues(alpha: 0.85),
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Simule le vrai',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          Text(
            'TCF IRN',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Enchaîne les 4 épreuves (CO + CE + EE + EO) en conditions réelles. Score final en niveau CECRL.',
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCell(value: '4', label: 'Épreuves')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: '90', label: 'Minutes')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: 'CECRL', label: 'Score final')),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.jakarta(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section principale : 20 slots numérotés, comme l'onglet Examens du
/// détail TCF QCM/EE/EO. Les examens passés sont triés ASC (le plus ancien
/// occupe le slot 1) et remplissent les slots de gauche à droite. Les slots
/// restants sont vides (clic = nouvelle session).
class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.history,
    required this.onTapDone,
    required this.onTapEmpty,
  });

  final List<FullTcfExamSummary> history;
  final void Function(FullTcfExamSummary) onTapDone;
  final void Function(int slot) onTapEmpty;

  @override
  Widget build(BuildContext context) {
    // Le backend renvoie l'historique DESC (récent en premier). On inverse
    // pour avoir le plus ancien en slot 1 — même règle que TCF QCM (CO/CE)
    // et EE/EO, pour que la numérotation reste stable dans le temps.
    final ordered = history.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tes examens',
              style: AppFonts.jakarta(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            Text(
              '$_fullExamSlotsCount disponibles',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 1.4,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _fullExamSlotsCount; i++) ...[
          _ExamSlotCard(
            slot: i + 1,
            exam: i < ordered.length ? ordered[i] : null,
            onTapDone: onTapDone,
            onTapEmpty: () => onTapEmpty(i + 1),
          ),
          if (i != _fullExamSlotsCount - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Une card slot. État vide → numéro encre sur gris muet, sous-titre
/// "Disponible · 4 épreuves, 90 min", chevron play. État fait → numéro
/// teinté par le niveau, icône premium + badge CECRL à droite.
class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.exam,
    required this.onTapDone,
    required this.onTapEmpty,
  });

  final int slot;
  final FullTcfExamSummary? exam;
  final void Function(FullTcfExamSummary) onTapDone;
  final VoidCallback onTapEmpty;

  @override
  Widget build(BuildContext context) {
    final done = exam != null;
    final level = exam?.finalCecrlLevel;
    final accent = done ? _statusAccent(exam!.status, level) : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: done ? accent.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? accent.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: done ? () => onTapDone(exam!) : onTapEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? accent : AppColors.line2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$slot',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: done ? AppColors.white : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen blanc $slot',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? _doneSubtitle(exam!)
                              : 'Disponible · 4 épreuves, 90 min',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (done)
                    _DoneTrailing(
                      status: exam!.status,
                      level: level,
                      accent: accent,
                    )
                  else
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.muted2,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _doneSubtitle(FullTcfExamSummary exam) {
    final date = _formatDate(exam.startedAt);
    final statusLabel = switch (exam.status) {
      FullTcfExamStatus.inProgress => 'En cours · Reprendre',
      FullTcfExamStatus.pendingEvaluations => 'Évaluation IA en cours',
      FullTcfExamStatus.completed => 'Terminé',
    };
    return '$date · $statusLabel';
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusAccent(FullTcfExamStatus status, NiveauCecrl? level) {
    if (status == FullTcfExamStatus.inProgress) return AppColors.amber;
    if (status == FullTcfExamStatus.pendingEvaluations) return AppColors.blue;
    if (level == null) return AppColors.muted;
    return switch (level) {
      NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => AppColors.red,
      NiveauCecrl.a2 => AppColors.amber,
      NiveauCecrl.b1 => AppColors.blue,
      NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2 => AppColors.green,
    };
  }
}

/// Rendu du badge à droite d'un slot fait : niveau CECRL coloré pour un
/// examen terminé, mini spinner pour un examen en évaluation IA, icône play
/// ambre pour un examen en cours (reprenable).
class _DoneTrailing extends StatelessWidget {
  const _DoneTrailing({
    required this.status,
    required this.level,
    required this.accent,
  });

  final FullTcfExamStatus status;
  final NiveauCecrl? level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (status == FullTcfExamStatus.inProgress) {
      return const Icon(Icons.play_circle_outline_rounded,
          color: AppColors.amber, size: 24);
    }
    if (status == FullTcfExamStatus.pendingEvaluations) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (level != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _shortLevel(level!),
          style: AppFonts.jakarta(
            size: 12,
            weight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
      );
    }
    return const Icon(Icons.chevron_right_rounded,
        color: AppColors.muted, size: 22);
  }

  String _shortLevel(NiveauCecrl l) => switch (l) {
        NiveauCecrl.a1NonAtteint => '<A1',
        NiveauCecrl.a1 => 'A1',
        NiveauCecrl.a2 => 'A2',
        NiveauCecrl.b1 => 'B1',
        NiveauCecrl.b2 => 'B2',
        NiveauCecrl.c1 => 'C1',
        NiveauCecrl.c2 => 'C2',
      };
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.red, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(color: AppColors.muted, size: 12.5),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Réessayer',
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
