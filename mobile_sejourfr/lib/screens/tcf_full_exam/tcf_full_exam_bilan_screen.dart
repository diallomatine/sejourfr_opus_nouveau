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

/// Bilan final d'un examen blanc TCF complet : niveau CECRL plancher (règle
/// officielle TCF IRN) + détail par épreuve + CTAs.
///
/// Quand on arrive ici juste après le dernier sous-attempt, les évaluations
/// IA EE/EO peuvent encore être en cours (`status = PENDING_EVALUATIONS`).
/// Dans ce cas l'écran montre un état "On finalise ton évaluation…" et
/// rafraîchit toutes les 4 s jusqu'à passer à `COMPLETED`.
class TcfFullExamBilanScreen extends ConsumerStatefulWidget {
  const TcfFullExamBilanScreen({super.key, required this.parentAttemptId});

  final String parentAttemptId;

  @override
  ConsumerState<TcfFullExamBilanScreen> createState() =>
      _TcfFullExamBilanScreenState();
}

class _TcfFullExamBilanScreenState
    extends ConsumerState<TcfFullExamBilanScreen> {
  Timer? _pollTimer;
  bool _finishCalled = false;

  /// Polling stop hard après cette durée — protège contre une éval IA bloquée
  /// ou plantée silencieusement. Au-delà, l'utilisateur voit l'état partiel
  /// disponible (niveau plancher des sous-épreuves OK) sans rester coincé.
  static const Duration _pollMaxDuration = Duration(seconds: 90);
  late final DateTime _pollStartedAt;

  @override
  void initState() {
    super.initState();
    _pollStartedAt = DateTime.now();
    // Au premier affichage, on poste le finish (idempotent côté backend) puis
    // on attend que toutes les évaluations IA soient prêtes. Le polling
    // s'arrête dès `status == COMPLETED` OU au bout de _pollMaxDuration.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_finishCalled) return;
    _finishCalled = true;
    try {
      final exam = await ref
          .read(fullTcfExamRepositoryProvider)
          .finish(widget.parentAttemptId);
      if (exam.status != FullTcfExamStatus.completed) {
        _startPolling();
      }
    } catch (_) {
      // Ignore : `finish` peut renvoyer 400 si l'utilisateur arrive ici sans
      // que tous les sous-attempts soient finis (cas rare — l'écran montre
      // alors le statut PENDING_EVALUATIONS ou IN_PROGRESS et l'utilisateur
      // peut revenir au hub progress). On poll quand même pour récupérer
      // l'état au fur et à mesure.
      _startPolling();
    } finally {
      if (mounted) {
        ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Timeout hard : on arrête, l'écran affichera l'état disponible.
      if (DateTime.now().difference(_pollStartedAt) > _pollMaxDuration) {
        timer.cancel();
        return;
      }
      ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
      try {
        final exam = await ref
            .read(fullTcfExamProvider(widget.parentAttemptId).future);
        if (exam.status == FullTcfExamStatus.completed) {
          timer.cancel();
        }
      } catch (_) {
        // Ignore : on retentera au prochain tick.
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 40, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: AppFonts.jakarta(color: AppColors.muted)),
                ],
              ),
            ),
          ),
          data: (exam) => _BilanView(exam: exam),
        ),
      ),
    );
  }
}

class _BilanView extends StatelessWidget {
  const _BilanView({required this.exam});

  final FullTcfExamResponse exam;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _TopBar(onBack: () => _backToHub(context)),
        const SizedBox(height: 20),
        _Hero(exam: exam),
        const SizedBox(height: 18),
        _DetailSection(exam: exam),
        const SizedBox(height: 22),
        AppButton(
          label: 'Retour au TCF',
          icon: Icons.home_outlined,
          onPressed: () => _backToHub(context),
        ),
      ],
    );
  }

  void _backToHub(BuildContext context) {
    context.go(AppRoutes.tcf);
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
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'BILAN',
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
  const _Hero({required this.exam});

  final FullTcfExamResponse exam;

  @override
  Widget build(BuildContext context) {
    final pending = exam.status == FullTcfExamStatus.pendingEvaluations;
    final level = exam.finalCecrlLevel;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
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
            'TON NIVEAU TCF IRN',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.white.withValues(alpha: 0.85),
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (pending || level == null)
            Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'L\'IA évalue tes productions…',
                    style: AppFonts.jakarta(
                      size: 17,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _shortLevel(level),
                  style: AppFonts.jakarta(
                    size: 56,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1,
                  ).copyWith(letterSpacing: -2),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'niveau plancher',
                    style: AppFonts.jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            pending || level == null
                ? 'Encore quelques secondes : nous calculons ton niveau final sur la base des 4 épreuves.'
                : 'Ton niveau IRN correspond au plus bas des 4 épreuves (règle officielle). '
                    'Continue à t\'entraîner sur l\'épreuve la plus faible pour le faire monter.',
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

  String _shortLevel(NiveauCecrl l) {
    return switch (l) {
      NiveauCecrl.a1NonAtteint => '<A1',
      NiveauCecrl.a1 => 'A1',
      NiveauCecrl.a2 => 'A2',
      NiveauCecrl.b1 => 'B1',
      NiveauCecrl.b2 => 'B2',
      NiveauCecrl.c1 => 'C1',
      NiveauCecrl.c2 => 'C2',
    };
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.exam});

  final FullTcfExamResponse exam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail par épreuve',
          style: AppFonts.jakarta(
            size: 16,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ).copyWith(letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        for (final e in const [
          EpreuveType.tcfCo,
          EpreuveType.tcfCe,
          EpreuveType.tcfEe,
          EpreuveType.tcfEo,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DetailCard(
              epreuve: e,
              sub: exam.subFor(e),
              parentAttemptId: exam.id,
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends ConsumerStatefulWidget {
  const _DetailCard({
    required this.epreuve,
    required this.sub,
    required this.parentAttemptId,
  });

  final EpreuveType epreuve;
  final FullTcfExamSubAttempt? sub;
  final String parentAttemptId;

  @override
  ConsumerState<_DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends ConsumerState<_DetailCard> {
  bool _retrying = false;

  Future<void> _retryFailed() async {
    final sub = widget.sub;
    if (sub == null || sub.failedSubmissionIds.isEmpty) return;
    setState(() => _retrying = true);
    final repo = ref.read(productionRepositoryProvider);
    int success = 0;
    int failure = 0;
    for (final id in sub.failedSubmissionIds) {
      try {
        await repo.retrySubmission(id);
        success++;
      } catch (_) {
        failure++;
      }
    }
    if (!mounted) return;
    setState(() => _retrying = false);
    // Re-fetch le bilan pour voir les nouveaux statuts (SUBMITTED puis bientôt EVALUATED).
    ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == 0
              ? '$success évaluation${success > 1 ? "s" : ""} relancée${success > 1 ? "s" : ""}, patiente quelques secondes…'
              : '$success relancée(s) · $failure en erreur — réessaye plus tard.',
        ),
        backgroundColor: failure == 0 ? AppColors.blue : AppColors.amber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _epreuveMeta(widget.epreuve);
    final sub = widget.sub;
    final level = sub?.cecrlLevel;
    final pending = sub != null && level == null && sub.isFinished &&
        (sub.failedSubmissionIds.isEmpty);
    final hasFailures = sub != null && sub.failedSubmissionIds.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: meta.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon, size: 22, color: meta.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        meta.title,
                        style: AppFonts.jakarta(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(sub, pending),
                        style: AppFonts.jakarta(
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _levelColor(level).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _shortLevel(level),
                      style: AppFonts.jakarta(
                        size: 13,
                        weight: FontWeight.w800,
                        color: _levelColor(level),
                      ),
                    ),
                  )
                else if (pending)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasFailures)
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.red, size: 22)
                else
                  Text('—',
                      style: AppFonts.jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.muted2,
                      )),
              ],
            ),
          ),
          if (hasFailures)
            _RetryBanner(
              failedCount: sub.failedSubmissionIds.length,
              retrying: _retrying,
              onRetry: _retryFailed,
            ),
        ],
      ),
    );
  }

  String _subtitle(FullTcfExamSubAttempt? sub, bool pending) {
    if (sub == null) return 'Non passée';
    if (sub.score != null && sub.maxScore != null) {
      return 'Score ${sub.score}/${sub.maxScore}';
    }
    // EE/EO : `submissionsCount` = nb EVALUATED. `failedSubmissionIds.length`
    // = nb FAILED. Le total attendu est 3 par épreuve productive.
    if (sub.submissionsCount != null || sub.failedSubmissionIds.isNotEmpty) {
      final ok = sub.submissionsCount ?? 0;
      final ko = sub.failedSubmissionIds.length;
      final pendingCount = 3 - ok - ko;
      if (pendingCount > 0) {
        return '$ok/3 évaluées · $pendingCount en cours';
      }
      if (ko > 0 && ok == 0) {
        return '$ko évaluation${ko > 1 ? "s" : ""} en échec';
      }
      if (ko > 0) {
        return '$ok/3 réussies · $ko à relancer';
      }
      return '3 productions évaluées';
    }
    if (pending) return 'Évaluation en cours…';
    return 'Terminée';
  }

  Color _levelColor(NiveauCecrl l) {
    return switch (l) {
      NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => AppColors.red,
      NiveauCecrl.a2 => AppColors.amber,
      NiveauCecrl.b1 => AppColors.blue,
      NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2 => AppColors.green,
    };
  }

  String _shortLevel(NiveauCecrl l) {
    return switch (l) {
      NiveauCecrl.a1NonAtteint => '<A1',
      NiveauCecrl.a1 => 'A1',
      NiveauCecrl.a2 => 'A2',
      NiveauCecrl.b1 => 'B1',
      NiveauCecrl.b2 => 'B2',
      NiveauCecrl.c1 => 'C1',
      NiveauCecrl.c2 => 'C2',
    };
  }

  _EpreuveMeta _epreuveMeta(EpreuveType e) {
    switch (e) {
      case EpreuveType.tcfCo:
        return _EpreuveMeta(
          title: 'Compréhension orale',
          icon: Icons.headphones_rounded,
          iconColor: AppColors.blue,
          iconBg: AppColors.blueLight,
        );
      case EpreuveType.tcfCe:
        return _EpreuveMeta(
          title: 'Compréhension écrite',
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.amber,
          iconBg: AppColors.amber.withValues(alpha: 0.12),
        );
      case EpreuveType.tcfEe:
        return _EpreuveMeta(
          title: 'Expression écrite',
          icon: Icons.edit_note_rounded,
          iconColor: AppColors.green,
          iconBg: AppColors.green.withValues(alpha: 0.12),
        );
      case EpreuveType.tcfEo:
        return _EpreuveMeta(
          title: 'Expression orale',
          icon: Icons.mic_rounded,
          iconColor: AppColors.red,
          iconBg: AppColors.redLight,
        );
      default:
        return _EpreuveMeta(
          title: '—',
          icon: Icons.help_outline_rounded,
          iconColor: AppColors.muted,
          iconBg: AppColors.bg,
        );
    }
  }
}

class _EpreuveMeta {
  _EpreuveMeta({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

/// Banner rouge clair sous une card EE/EO quand au moins une submission est
/// FAILED côté backend (Claude a planté, audio invalide, etc.). Le bouton
/// "Réessayer" appelle `POST /api/production-submissions/{id}/retry` pour
/// chaque submission failed — le pipeline async re-tente Whisper + Claude.
class _RetryBanner extends StatelessWidget {
  const _RetryBanner({
    required this.failedCount,
    required this.retrying,
    required this.onRetry,
  });

  final int failedCount;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          const Icon(Icons.refresh_rounded, size: 16, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$failedCount évaluation${failedCount > 1 ? "s" : ""} IA en échec',
              style: AppFonts.jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: retrying ? null : onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: retrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        'Réessayer',
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
