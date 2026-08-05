import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
/// L'écran appelle `finish` (idempotent), puis poll `GET /full-tcf-exams/{id}`
/// avec un intervalle adaptatif (3 s pendant 30 s, puis 8 s) pendant 5 min
/// max. Si l'évaluation n'est toujours pas prête, on bascule sur un état
/// `_pollExhausted` qui remplace le spinner du badge par une icône
/// "Actualiser" — et le pull-to-refresh relance un cycle complet.
class TcfFullExamBilanScreen extends ConsumerStatefulWidget {
  const TcfFullExamBilanScreen({super.key, required this.parentAttemptId});

  final String parentAttemptId;

  @override
  ConsumerState<TcfFullExamBilanScreen> createState() => _TcfFullExamBilanScreenState();
}

class _TcfFullExamBilanScreenState extends ConsumerState<TcfFullExamBilanScreen> {
  Timer? _pollTimer;
  bool _finishCalled = false;
  bool _pollExhausted = false;

  /// Polling stop hard après cette durée. 5 min : largement de quoi laisser
  /// les 6 évals IA (3 EE + 3 EO) finir, même quand Claude est lent ou que
  /// la queue backend est saturée. Au-delà, on bascule sur `_pollExhausted`
  /// qui swap le spinner muet pour un bouton "Actualiser".
  static const Duration _pollMaxDuration = Duration(minutes: 5);

  /// Au-delà de ce délai depuis [FullTcfExamResponse.finishedAt], on considère
  /// l'examen comme "stale" : si une submission n'a pas remonté son évaluation
  /// IA après 2 min, c'est qu'elle est bloquée côté backend (jamais picked
  /// up par l'@Async ou exception silencieuse). Inutile de polluer le réseau
  /// avec du polling — on affiche directement l'état terminal et un bouton
  /// "Actualiser" pour relance manuelle.
  static const Duration _staleThreshold = Duration(minutes: 2);

  /// Intervalle initial — agressif pour décrocher dès que possible quand les
  /// évals finissent en quelques secondes.
  static const Duration _pollIntervalFast = Duration(seconds: 3);

  /// Intervalle après [_pollSlowdownAt] — économise des requêtes quand
  /// l'évaluation s'étire.
  static const Duration _pollIntervalSlow = Duration(seconds: 8);
  static const Duration _pollSlowdownAt = Duration(seconds: 30);

  DateTime? _pollStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Détermine si l'examen est trop vieux pour qu'un polling ait du sens :
  /// le parent a été finalisé il y a plus de [_staleThreshold] et le statut
  /// n'est toujours pas COMPLETED ⇒ une submission est bloquée côté backend,
  /// rien ne va changer en attendant.
  bool _examIsStale(FullTcfExamResponse exam) {
    if (exam.status == FullTcfExamStatus.completed) return false;
    final finishedAt = exam.finishedAt;
    if (finishedAt == null) return false;
    return DateTime.now().difference(finishedAt) > _staleThreshold;
  }

  Future<void> _bootstrap() async {
    if (_finishCalled) return;
    _finishCalled = true;
    try {
      final exam = await ref.read(fullTcfExamRepositoryProvider).finish(widget.parentAttemptId);
      if (exam.status == FullTcfExamStatus.completed) {
        return;
      }
      if (_examIsStale(exam)) {
        // Examen "déjà fait" depuis longtemps mais resté PENDING : pas de
        // Claude qui tourne derrière, polling inutile — on affiche
        // directement l'état terminal avec CTA Actualiser.
        if (mounted) setState(() => _pollExhausted = true);
        return;
      }
      _startPolling();
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
    _pollStartedAt = DateTime.now();
    if (_pollExhausted && mounted) {
      setState(() => _pollExhausted = false);
    }
    _schedulePollTick(_pollIntervalFast);
  }

  void _schedulePollTick(Duration delay) {
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, _pollTick);
  }

  Future<void> _pollTick() async {
    if (!mounted) return;
    final startedAt = _pollStartedAt;
    if (startedAt == null) return;
    if (DateTime.now().difference(startedAt) > _pollMaxDuration) {
      if (mounted) setState(() => _pollExhausted = true);
      return;
    }
    ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    try {
      final exam = await ref.read(fullTcfExamProvider(widget.parentAttemptId).future);
      if (!mounted) return;
      if (exam.status == FullTcfExamStatus.completed) {
        return; // plus de polling : le widget rebuild affichera le niveau.
      }
      if (_examIsStale(exam)) {
        // Le parent est finalisé depuis longtemps mais une eval reste bloquée :
        // pas la peine de continuer à hammerer le backend, on affiche un CTA
        // Actualiser et on s'arrête.
        setState(() => _pollExhausted = true);
        return;
      }
    } catch (_) {
      // Ignore : on retentera au prochain tick.
    }
    final elapsed = DateTime.now().difference(startedAt);
    final next = elapsed < _pollSlowdownAt ? _pollIntervalFast : _pollIntervalSlow;
    _schedulePollTick(next);
  }

  Future<void> _onPullToRefresh() async {
    ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    try {
      final exam = await ref.read(fullTcfExamProvider(widget.parentAttemptId).future);
      if (!mounted) return;
      if (exam.status == FullTcfExamStatus.completed) {
        if (_pollExhausted) setState(() => _pollExhausted = false);
        return;
      }
      if (_examIsStale(exam)) {
        if (!_pollExhausted) setState(() => _pollExhausted = true);
        return;
      }
      _startPolling();
    } catch (_) {
      if (mounted) _startPolling();
    }
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
                  const Icon(LucideIcons.cloudOff, size: 40, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      textAlign: TextAlign.center, style: AppFonts.ui(color: AppColors.muted)),
                ],
              ),
            ),
          ),
          data: (exam) {
            // `_pollExhausted` (5 min de polling sans succès) OU exam stale
            // (déjà finalisé depuis plus de 2 min ⇒ pipeline IA bloqué côté
            // backend). Dans les deux cas, le bilan affiche un CTA Actualiser
            // au lieu de spinners infinis pour les sous-attempts en attente.
            final effectiveExhausted = _pollExhausted || _examIsStale(exam);
            return RefreshIndicator(
              onRefresh: _onPullToRefresh,
              color: AppColors.red,
              child: _BilanView(
                exam: exam,
                pollExhausted: effectiveExhausted,
                onManualRefresh: _onPullToRefresh,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BilanView extends StatelessWidget {
  const _BilanView({
    required this.exam,
    required this.pollExhausted,
    required this.onManualRefresh,
  });

  final FullTcfExamResponse exam;
  final bool pollExhausted;
  final Future<void> Function() onManualRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _TopBar(onBack: () => _backToExams(context)),
        const SizedBox(height: 20),
        _Hero(exam: exam),
        const SizedBox(height: 18),
        if (pollExhausted && exam.status != FullTcfExamStatus.completed) ...[
          _PollExhaustedBanner(onRefresh: onManualRefresh),
          const SizedBox(height: 14),
        ],
        _DetailSection(
          exam: exam,
          pollExhausted: pollExhausted,
          onManualRefresh: onManualRefresh,
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Retour aux examens',
          icon: LucideIcons.arrowLeft,
          onPressed: () => _backToExams(context),
        ),
      ],
    );
  }

  void _backToExams(BuildContext context) {
    // Revenir à la page précédente quand on a été poussé dessus (consultation
    // d'un examen depuis la liste). Sinon (arrivée via `go` après avoir fini un
    // examen → pile remplacée), repli sur la liste des examens.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tcfFullExams);
    }
  }
}

class _PollExhaustedBanner extends StatelessWidget {
  const _PollExhaustedBanner({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.clock, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "L'évaluation IA prend plus longtemps que prévu. Reviens dans une minute ou actualise.",
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onRefresh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text(
                  'Actualiser',
                  style: AppFonts.ui(
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
              child: const Icon(LucideIcons.chevronLeft, size: 22, color: AppColors.ink),
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
            style: AppFonts.ui(
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
                    style: AppFonts.ui(
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
                  level.shortName,
                  style: AppFonts.ui(
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
                    style: AppFonts.ui(
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
                ? _pendingSentence(exam)
                : _basisSentence(exam),
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

  /// Le décompte n'est cité que si le backend l'a donné : une épreuve
  /// verrouillée par le freemium ou dont l'évaluation a échoué est écartée du
  /// plancher, donc « les 4 épreuves » n'est pas une constante. Backend
  /// antérieur au champ ⇒ formulation sans chiffre, jamais un chiffre supposé.
  String _pendingSentence(FullTcfExamResponse exam) {
    const base = 'Encore quelques secondes : nous calculons ton niveau final ';
    final counted = exam.epreuvesCountedInFinalLevel;
    if (counted == null || counted <= 0) {
      return '${base}sur la base des épreuves prises en compte.';
    }
    return counted == 1
        ? '${base}sur la base de la seule épreuve prise en compte.'
        : '${base}sur la base de tes $counted épreuves.';
  }

  String _basisSentence(FullTcfExamResponse exam) {
    const rule = ' Il n\'y a ni moyenne ni compensation (règle officielle) : '
        'continue à t\'entraîner sur l\'épreuve la plus faible pour faire '
        'monter ton niveau.';
    final counted = exam.epreuvesCountedInFinalLevel;
    final expected = exam.epreuvesExpected;

    if (counted == null || counted <= 0) {
      return 'Ton niveau IRN correspond au plus bas des épreuves prises en '
          'compte.$rule';
    }
    if (!exam.finalLevelPartial) {
      return 'Ton niveau IRN correspond au plus bas de tes $counted '
          'épreuves.$rule';
    }
    // Bilan partiel : ne jamais le présenter comme un examen complet.
    final scope = expected == null ? '$counted' : '$counted sur $expected';
    final portee = counted == 1
        ? 'porte sur une seule épreuve ($scope)'
        : 'porte sur $scope épreuves';
    return 'Bilan partiel : ton niveau $portee — les épreuves verrouillées ou '
        'non évaluées n\'entrent pas dans le calcul.$rule';
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.exam,
    required this.pollExhausted,
    required this.onManualRefresh,
  });

  final FullTcfExamResponse exam;
  final bool pollExhausted;
  final Future<void> Function() onManualRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail par épreuve',
          style: AppFonts.ui(
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
              pollExhausted: pollExhausted,
              onManualRefresh: onManualRefresh,
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
    required this.pollExhausted,
    required this.onManualRefresh,
  });

  final EpreuveType epreuve;
  final FullTcfExamSubAttempt? sub;
  final String parentAttemptId;
  final bool pollExhausted;
  final Future<void> Function() onManualRefresh;

  @override
  ConsumerState<_DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends ConsumerState<_DetailCard> {
  bool _retrying = false;

  /// Route vers les détails d'évaluation du sous-attempt, selon l'épreuve :
  /// - CO/CE → `/exam-report/{subAttemptId}` (questions + correction)
  /// - EE/EO → `/tcf/expression-{ecrite,orale}/sessions/{subAttemptId}`
  ///   (bilan lecture seule des 3 productions évaluées par l'IA)
  String? _detailsRouteFor(FullTcfExamSubAttempt sub) {
    switch (widget.epreuve) {
      case EpreuveType.tcfCo:
      case EpreuveType.tcfCe:
        return '/exam-report/${sub.attemptId}';
      case EpreuveType.tcfEe:
        return '/tcf/expression-ecrite/sessions/${sub.attemptId}';
      case EpreuveType.tcfEo:
        return '/tcf/expression-orale/sessions/${sub.attemptId}';
      default:
        return null;
    }
  }

  void _openDetails() {
    final sub = widget.sub;
    if (sub == null || !sub.isFinished) return;
    final route = _detailsRouteFor(sub);
    if (route == null) return;
    context.push(route);
  }

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
    // EE/EO verrouillées (compte gratuit ayant déjà utilisé l'EE/EO offerte) :
    // épreuve non passée, réservée à l'abonnement — pas de niveau, pas de lien.
    final lockedProd = sub?.locked == true;
    final level = lockedProd ? null : sub?.cecrlLevel;
    final pending = !lockedProd &&
        sub != null &&
        level == null &&
        sub.isFinished &&
        (sub.failedSubmissionIds.isEmpty);
    final hasFailures =
        !lockedProd && sub != null && sub.failedSubmissionIds.isNotEmpty;

    // Card tappable quand le sous-attempt est fini ET qu'on a une route de
    // détails à ouvrir (toutes les épreuves CO/CE/EE/EO en ont une). Sinon
    // (sub == null, pas encore fini, ou EE/EO verrouillée), on reste passif —
    // pas d'illusion clickable sur quelque chose qui n'existe pas.
    final tappable =
        !lockedProd && sub != null && sub.isFinished && _detailsRouteFor(sub) != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: tappable ? _openDetails : null,
              child: Padding(
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
                            style: AppFonts.ui(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lockedProd
                                ? 'Réservé à l\'abonnement Intégral'
                                : _subtitle(sub, pending),
                            style: AppFonts.ui(
                              size: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (lockedProd)
                      const Icon(LucideIcons.lock,
                          color: AppColors.muted2, size: 20)
                    else if (level != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _levelColor(level).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          level.shortName,
                          style: AppFonts.ui(
                            size: 13,
                            weight: FontWeight.w800,
                            color: _levelColor(level),
                          ),
                        ),
                      )
                    else if (pending && widget.pollExhausted)
                      _RefreshLevelButton(onTap: widget.onManualRefresh)
                    else if (pending)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (hasFailures)
                      const Icon(LucideIcons.circleAlert, color: AppColors.red, size: 22)
                    else
                      Text('—',
                          style: AppFonts.ui(
                            size: 16,
                            weight: FontWeight.w700,
                            color: AppColors.muted2,
                          )),
                    if (tappable) ...[
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.muted2),
                    ],
                  ],
                ),
              ),
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

  Color _levelColor(NiveauCecrl l) => l.color;

  _EpreuveMeta _epreuveMeta(EpreuveType e) {
    switch (e) {
      case EpreuveType.tcfCo:
        return _EpreuveMeta(
          title: 'Compréhension orale',
          icon: LucideIcons.headphones,
          iconColor: AppColors.blue,
          iconBg: AppColors.blueLight,
        );
      case EpreuveType.tcfCe:
        return _EpreuveMeta(
          title: 'Compréhension écrite',
          icon: LucideIcons.bookOpen,
          iconColor: AppColors.amber,
          iconBg: AppColors.amber.withValues(alpha: 0.12),
        );
      case EpreuveType.tcfEe:
        return _EpreuveMeta(
          title: 'Expression écrite',
          icon: LucideIcons.penLine,
          iconColor: AppColors.green,
          iconBg: AppColors.green.withValues(alpha: 0.12),
        );
      case EpreuveType.tcfEo:
        return _EpreuveMeta(
          title: 'Expression orale',
          icon: LucideIcons.mic,
          iconColor: AppColors.red,
          iconBg: AppColors.redLight,
        );
      default:
        return _EpreuveMeta(
          title: '—',
          icon: LucideIcons.circleHelp,
          iconColor: AppColors.muted,
          iconBg: AppColors.bg,
        );
    }
  }
}

class _RefreshLevelButton extends StatelessWidget {
  const _RefreshLevelButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.blue),
              const SizedBox(width: 6),
              Text(
                'Actualiser',
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$failedCount évaluation${failedCount > 1 ? "s" : ""} IA en échec',
              style: AppFonts.ui(
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
                        style: AppFonts.ui(
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
