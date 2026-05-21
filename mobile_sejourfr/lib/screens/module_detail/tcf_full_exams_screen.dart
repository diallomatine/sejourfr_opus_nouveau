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

class TcfFullExamsScreen extends ConsumerWidget {
  const TcfFullExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_fullExamsHistoryProvider);

    Future<void> startNew() async {
      final auth = ref.read(authControllerProvider);
      final isPremium = auth is AuthAuthenticated &&
          auth.user.canAccessModule(AppModule.tcf);
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      if (!isPremium) {
        showPaywallSheet(context);
        return;
      }
      final nextNumber = (historyAsync.valueOrNull?.length ?? 0) + 1;
      showTcfFullExamBriefingSheet(
        context,
        slot: nextNumber,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.red,
          onRefresh: () async {
            ref.invalidate(_fullExamsHistoryProvider);
            await ref.read(_fullExamsHistoryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _TopBar(onBack: () => _back(context)),
              const SizedBox(height: 22),
              const _Hero(),
              const SizedBox(height: 16),
              const _Stats(),
              const SizedBox(height: 22),
              AppButton(
                label: 'Lancer un nouvel examen',
                icon: Icons.play_arrow_rounded,
                onPressed: startNew,
              ),
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
                data: (history) => _HistorySection(
                  history: history,
                  onTap: (exam) => _openExam(context, exam),
                ),
              ),
            ],
          ),
        ),
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

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tcf);
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

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history, required this.onTap});

  final List<FullTcfExamSummary> history;
  final void Function(FullTcfExamSummary) onTap;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyHistory();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mes examens',
              style: AppFonts.jakarta(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            Text(
              '${history.length}',
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
        for (int i = 0; i < history.length; i++) ...[
          _ExamCard(
            // Numérotation chronologique (le plus ancien = #1).
            number: history.length - i,
            exam: history[i],
            onTap: () => onTap(history[i]),
          ),
          if (i != history.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.red, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun examen blanc encore',
            style: AppFonts.jakarta(
              size: 14.5,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lance ton premier pour obtenir ton niveau CECRL TCF IRN.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 12.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.number,
    required this.exam,
    required this.onTap,
  });

  final int number;
  final FullTcfExamSummary exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = exam.status == FullTcfExamStatus.completed ||
        exam.status == FullTcfExamStatus.pendingEvaluations;
    final level = exam.finalCecrlLevel;
    final accent = _statusAccent(exam.status, level);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDone ? accent.withValues(alpha: 0.12) : AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isDone
                        ? Icon(Icons.workspace_premium_rounded,
                            color: accent, size: 22)
                        : Text(
                            '$number',
                            style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w800,
                              color: AppColors.white,
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
                          'Examen blanc $number',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(exam),
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Trailing(status: exam.status, level: level, accent: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(FullTcfExamSummary exam) {
    final date = _formatDate(exam.startedAt);
    final statusLabel = switch (exam.status) {
      FullTcfExamStatus.inProgress => 'En cours · Reprendre',
      FullTcfExamStatus.pendingEvaluations => 'En évaluation IA',
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

class _Trailing extends StatelessWidget {
  const _Trailing({
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
    // COMPLETED : badge niveau CECRL
    if (level != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _shortLevel(level!),
          style: AppFonts.jakarta(
            size: 13,
            weight: FontWeight.w800,
            color: accent,
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
