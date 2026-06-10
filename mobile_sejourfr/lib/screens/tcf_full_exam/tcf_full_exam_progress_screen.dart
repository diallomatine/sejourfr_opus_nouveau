import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'full_tcf_exam_provider.dart';

/// Hub de progression d'un examen blanc TCF complet : 4 étapes (CO → CE →
/// EE → EO), chrono global 90 min, CTA "Commencer cette épreuve" qui push
/// le runner ou la session production avec l'attemptId du sous-attempt
/// correspondant.
///
/// **Refresh** : invalide `fullTcfExamProvider` à chaque mount (re-fetch
/// frais), et les écrans appelants (runner + bilans EE/EO) doivent appeler
/// `ref.invalidate(fullTcfExamProvider(parentId))` avant `context.go` vers
/// ce hub pour que les épreuves récemment terminées apparaissent.
///
/// **Timer global** : 90 min décomptés depuis `exam.startedAt`. À 0,
/// finalisation automatique côté backend + redirect vers le bilan.
class TcfFullExamProgressScreen extends ConsumerStatefulWidget {
  const TcfFullExamProgressScreen({super.key, required this.parentAttemptId});

  final String parentAttemptId;

  @override
  ConsumerState<TcfFullExamProgressScreen> createState() =>
      _TcfFullExamProgressScreenState();
}

/// Chrono global : 90 minutes (= `time_limit_seconds` posé sur le parent
/// côté backend, cf. `FullTcfExamService.FULL_EXAM_TOTAL_SECONDS`).
const Duration _fullExamTotal = Duration(minutes: 90);

class _TcfFullExamProgressScreenState
    extends ConsumerState<TcfFullExamProgressScreen> {
  Timer? _ticker;
  bool _timeoutHandled = false;

  @override
  void initState() {
    super.initState();
    // Re-fetch frais à chaque entrée sur le hub : indispensable après le
    // retour d'un sous-attempt (CO/CE/EE/EO), sinon les épreuves terminées
    // restent affichées comme "current".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    });
    // Tick chaque seconde pour mettre à jour le chrono — léger, pas de
    // setState destructif.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(fullTcfExamProvider(widget.parentAttemptId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: examAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(
                fullTcfExamProvider(widget.parentAttemptId)),
          ),
          data: (exam) {
            final remaining = _remaining(exam);
            // Temps épuisé : on lance le finish backend une seule fois et on
            // redirige vers le bilan où le polling prendra le relais.
            if (remaining <= Duration.zero &&
                !_timeoutHandled &&
                exam.finishedAt == null) {
              _timeoutHandled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _handleTimeout(exam.id);
              });
            }
            return _ProgressView(exam: exam, remaining: remaining);
          },
        ),
      ),
    );
  }

  Duration _remaining(FullTcfExamResponse exam) {
    final ends = exam.startedAt.add(_fullExamTotal);
    final diff = ends.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _handleTimeout(String parentId) async {
    try {
      await ref.read(fullTcfExamRepositoryProvider).finish(parentId);
    } catch (_) {
      // Ignore : si un sous-attempt n'est pas fini, le backend rejette.
      // Le bilan se chargera quand même de poller pour récupérer le statut.
    }
    if (!mounted) return;
    context.go(AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', parentId));
  }
}

class _ProgressView extends ConsumerWidget {
  const _ProgressView({required this.exam, required this.remaining});

  final FullTcfExamResponse exam;
  final Duration remaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepIdx = exam.currentStepIndex;
    final allDone = stepIdx >= 4;

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        ref.invalidate(fullTcfExamProvider(exam.id));
        await ref.read(fullTcfExamProvider(exam.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _TopBar(onClose: () => _close(context)),
          const SizedBox(height: 20),
          _Hero(exam: exam, remaining: remaining),
          const SizedBox(height: 18),
          _StepsList(exam: exam),
          const SizedBox(height: 22),
          if (allDone)
            AppButton(
              label: 'Voir mon résultat',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => context.go(
                AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id),
              ),
            )
          else
            AppButton(
              label: _ctaLabel(exam),
              icon: Icons.play_arrow_rounded,
              onPressed: () => _startStep(context, ref, exam, stepIdx),
            ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Quitter pour le moment',
            variant: AppButtonVariant.ghost,
            onPressed: () => _close(context),
          ),
        ],
      ),
    );
  }

  String _ctaLabel(FullTcfExamResponse exam) {
    final stepIdx = exam.currentStepIndex;
    const order = [
      EpreuveType.tcfCo,
      EpreuveType.tcfCe,
      EpreuveType.tcfEe,
      EpreuveType.tcfEo,
    ];
    final ep = order[stepIdx];
    return 'Commencer · ${_StepMeta.of(ep).title}';
  }

  void _startStep(
    BuildContext context,
    WidgetRef ref,
    FullTcfExamResponse exam,
    int stepIdx,
  ) {
    const order = [
      EpreuveType.tcfCo,
      EpreuveType.tcfCe,
      EpreuveType.tcfEe,
      EpreuveType.tcfEo,
    ];
    final ep = order[stepIdx];
    final sub = exam.subFor(ep);
    if (sub == null) return;

    switch (ep) {
      case EpreuveType.tcfCo:
      case EpreuveType.tcfCe:
        context.push(
          '${AppRoutes.runner.replaceFirst(':attemptId', sub.attemptId)}'
          '?from=fullTcf&fullExamId=${exam.id}',
        );
        break;
      case EpreuveType.tcfEe:
      case EpreuveType.tcfEo:
        final base = ep == EpreuveType.tcfEe
            ? AppRoutes.tcfExpressionEcrite
            : AppRoutes.tcfExpressionOrale;
        context.push(
          '$base/t/0?from=fullTcf&fullExamId=${exam.id}&subAttemptId=${sub.attemptId}',
        );
        break;
      default:
        break;
    }
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tcf);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onClose,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'EXAMEN BLANC',
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.red,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.exam, required this.remaining});

  final FullTcfExamResponse exam;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final stepIdx = exam.currentStepIndex;
    final allDone = stepIdx >= 4;
    final timedOut = remaining <= Duration.zero;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  allDone ? 'EXAMEN TERMINÉ' : 'ÉTAPE ${stepIdx + 1} / 4',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.8,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (!allDone) _GlobalTimer(remaining: remaining, timedOut: timedOut),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            allDone ? 'Tout est joué' : 'TCF IRN complet',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Text(
            allDone
                ? 'Toutes les épreuves sont terminées. Découvre ton niveau CECRL final.'
                : timedOut
                    ? 'Temps écoulé. On finalise ton examen…'
                    : 'Enchaîne les 4 épreuves dans l\'ordre. Le chrono court en arrière-plan, '
                        'même quand tu es dans une épreuve.',
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
          if (exam.status == FullTcfExamStatus.pendingEvaluations) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom_rounded,
                      size: 14, color: AppColors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'L\'IA évalue tes productions, encore quelques secondes…',
                      style: AppFonts.jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.white,
                      ),
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

/// Pill chrono affichée dans le hero : 90 min décomptés depuis `startedAt`.
/// Devient rouge foncé/blanc clignotant sous les 5 dernières minutes.
class _GlobalTimer extends StatelessWidget {
  const _GlobalTimer({required this.remaining, required this.timedOut});

  final Duration remaining;
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    final critical = remaining.inMinutes < 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: critical ? 0.32 : 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.white),
          const SizedBox(width: 5),
          Text(
            timedOut ? '00:00' : _format(remaining),
            style: AppFonts.mono(
              size: 12,
              color: AppColors.white,
              weight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final hh = d.inHours;
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList({required this.exam});

  final FullTcfExamResponse exam;

  @override
  Widget build(BuildContext context) {
    const order = [
      EpreuveType.tcfCo,
      EpreuveType.tcfCe,
      EpreuveType.tcfEe,
      EpreuveType.tcfEo,
    ];
    final currentIdx = exam.currentStepIndex;

    return Column(
      children: [
        for (int i = 0; i < order.length; i++) ...[
          _StepCard(
            index: i,
            epreuve: order[i],
            sub: exam.subFor(order[i]),
            state: i < currentIdx
                ? _StepState.done
                : i == currentIdx
                    ? _StepState.current
                    : _StepState.locked,
          ),
          if (i != order.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

enum _StepState { done, current, locked }

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.epreuve,
    required this.sub,
    required this.state,
  });

  final int index;
  final EpreuveType epreuve;
  final FullTcfExamSubAttempt? sub;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final meta = _StepMeta.of(epreuve);
    // EE/EO verrouillées (compte gratuit ayant déjà utilisé l'EE/EO offerte) :
    // ni « à faire » ni « terminé » — réservées à l'abonnement.
    final lockedProd = sub?.locked == true;
    final isCurrent = state == _StepState.current && !lockedProd;
    final isDone = state == _StepState.done && !lockedProd;
    final accent = isCurrent ? AppColors.red : AppColors.ink;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.red.withValues(alpha: 0.5)
              : AppColors.line,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? AppColors.green : accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: AppColors.white, size: 22)
                : Text(
                    '${index + 1}',
                    style: AppFonts.jakarta(
                      size: 16,
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
                Row(
                  children: [
                    Icon(meta.icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta.title,
                        style: AppFonts.jakarta(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lockedProd
                      ? 'Réservé à l\'abonnement Intégral'
                      : _subtitle(meta, sub, state),
                  style: AppFonts.jakarta(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StepTrailing(state: state, sub: sub),
        ],
      ),
    );
  }

  String _subtitle(_StepMeta meta, FullTcfExamSubAttempt? sub, _StepState st) {
    if (st == _StepState.done && sub != null) {
      if (sub.score != null && sub.maxScore != null) {
        return '${meta.duration} · ${sub.score}/${sub.maxScore}'
            '${sub.cecrlLevel != null ? ' · ${sub.cecrlLevel!.displayName}' : ''}';
      }
      if (sub.submissionsCount != null) {
        return '${meta.duration} · ${sub.submissionsCount}/3 évaluées'
            '${sub.cecrlLevel != null ? ' · ${sub.cecrlLevel!.displayName}' : ''}';
      }
      return '${meta.duration} · Terminé';
    }
    return '${meta.duration} · ${meta.detail}';
  }
}

class _StepTrailing extends StatelessWidget {
  const _StepTrailing({required this.state, required this.sub});

  final _StepState state;
  final FullTcfExamSubAttempt? sub;

  @override
  Widget build(BuildContext context) {
    // EE/EO verrouillées : cadenas premium, jamais le badge niveau / le check.
    if (sub?.locked == true) {
      return const Icon(Icons.lock_outline_rounded,
          color: AppColors.muted2, size: 18);
    }
    if (state == _StepState.done && sub?.cecrlLevel != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          sub!.cecrlLevel!.displayName.replaceAll(' non atteint', ''),
          style: AppFonts.jakarta(
            size: 11,
            weight: FontWeight.w800,
            color: AppColors.green,
          ),
        ),
      );
    }
    if (state == _StepState.locked) {
      return const Icon(Icons.lock_outline_rounded,
          color: AppColors.muted2, size: 18);
    }
    return const Icon(Icons.chevron_right_rounded,
        color: AppColors.muted, size: 22);
  }
}

class _StepMeta {
  const _StepMeta({
    required this.title,
    required this.icon,
    required this.duration,
    required this.detail,
  });

  final String title;
  final IconData icon;
  final String duration;
  final String detail;

  static _StepMeta of(EpreuveType e) {
    switch (e) {
      case EpreuveType.tcfCo:
        return const _StepMeta(
          title: 'Compréhension orale',
          icon: Icons.headphones_rounded,
          duration: '20 min',
          detail: '25 questions audio',
        );
      case EpreuveType.tcfCe:
        return const _StepMeta(
          title: 'Compréhension écrite',
          icon: Icons.menu_book_rounded,
          duration: '30 min',
          detail: '25 questions texte',
        );
      case EpreuveType.tcfEe:
        return const _StepMeta(
          title: 'Expression écrite',
          icon: Icons.edit_note_rounded,
          duration: '30 min',
          detail: '3 tâches IA',
        );
      case EpreuveType.tcfEo:
        return const _StepMeta(
          title: 'Expression orale',
          icon: Icons.mic_rounded,
          duration: '10 min',
          detail: '3 tâches IA',
        );
      default:
        return const _StepMeta(
          title: '—',
          icon: Icons.help_outline_rounded,
          duration: '—',
          detail: '—',
        );
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 40, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
