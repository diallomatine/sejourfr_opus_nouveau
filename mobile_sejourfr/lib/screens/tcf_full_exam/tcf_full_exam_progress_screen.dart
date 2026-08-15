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
import '../../core/utils/epreuve_duration.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import 'full_tcf_exam_provider.dart';

/// Hub de progression d'un examen blanc TCF complet : 4 étapes (CO → CE →
/// EE → EO), **chrono de l'épreuve en cours**, CTA "Commencer cette épreuve"
/// qui push le runner ou la session production avec l'attemptId du sous-attempt
/// correspondant.
///
/// **Refresh** : invalide `fullTcfExamProvider` à chaque mount (re-fetch
/// frais) et au retour au premier plan, et les écrans appelants (runner +
/// bilans EE/EO) doivent appeler `ref.invalidate(fullTcfExamProvider(parentId))`
/// avant `context.go` vers ce hub pour que les épreuves récemment terminées
/// apparaissent.
///
/// **Il n'y a plus d'enveloppe globale de 90 min.** Le temps d'une épreuve ne se
/// transfère jamais à la suivante et l'abandon-reprise entre épreuves est
/// officiellement supporté : un décompte global n'aurait plus de sens. Chaque
/// épreuve porte sa durée, servie par le DTO
/// (`FullTcfExamSubAttempt.timeLimitSeconds`), et son échéance absolue
/// (`deadlineAt`) — **seule** source du compte à rebours affiché ici. Les 4
/// durées font ~95 min au total, annoncé comme indicatif.
///
/// **Quitter ne suspend rien** : le chrono d'une épreuve lancée continue de
/// courir pendant l'absence, on reprend avec le temps réellement restant, et une
/// épreuve dont l'échéance est passée est **clôturée automatiquement par le
/// serveur** à la lecture suivante, avec ce qui était enregistré. Il n'existe
/// aucun flux « recommencer une épreuve interrompue ».
///
/// **Sortir ≠ abandonner** (parité web). Deux gestes distincts, jamais
/// confondus :
/// - la **flèche retour** de la barre du haut *sort de l'écran*, point final —
///   aucune finalisation, aucun appel serveur, l'examen reste reprenable ;
/// - le bouton **« Abandonner l'examen »**, lui seul, mène à la finalisation.
///
/// La flèche a longtemps porté l'abandon : un candidat qui avait fini CO + CE
/// et quittait l'écran voyait ses EE et EO closes en 54 ms, avec un niveau
/// attribué à des épreuves jamais passées.
///
/// **Abandon** : on affiche un avertissement qui **nomme la reprise**, puis on
/// finalise chaque épreuve non terminée (CO/CE = score sur les réponses
/// données, 0 si aucune ; EE/EO = `sub-done`), on finalise le parent et on
/// route vers le bilan.
class TcfFullExamProgressScreen extends ConsumerStatefulWidget {
  const TcfFullExamProgressScreen({super.key, required this.parentAttemptId});

  final String parentAttemptId;

  @override
  ConsumerState<TcfFullExamProgressScreen> createState() =>
      _TcfFullExamProgressScreenState();
}

class _TcfFullExamProgressScreenState
    extends ConsumerState<TcfFullExamProgressScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _expiryHandled = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Re-fetch frais à chaque entrée sur le hub : indispensable après le
    // retour d'un sous-attempt (CO/CE/EE/EO), sinon les épreuves terminées
    // restent affichées comme "current".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    });
    // Tick chaque seconde pour mettre à jour le chrono — léger, pas de
    // setState destructif. Le décompte se lit sur `deadlineAt`, une échéance
    // absolue : il reste juste après un passage en arrière-plan, où le temps a
    // continué de courir.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour au premier plan : le temps a couru pendant l'absence et le serveur
    // a peut-être déjà clôturé l'épreuve. On relit l'état plutôt que de
    // continuer sur une échéance périmée.
    if (state == AppLifecycleState.resumed && mounted) {
      _expiryHandled = false;
      ref.invalidate(fullTcfExamProvider(widget.parentAttemptId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(fullTcfExamProvider(widget.parentAttemptId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: examAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                    fullTcfExamProvider(widget.parentAttemptId)),
              ),
              data: (exam) {
                final current = exam.currentSubAttempt;
                final remaining = current?.remainingAt(DateTime.now());
                // Échéance de l'épreuve en cours dépassée : le serveur la
                // clôture lui-même à la lecture suivante, avec ce qui avait été
                // enregistré. On relit, on ne finalise pas l'examen entier —
                // les épreuves suivantes restent à passer.
                if (remaining == Duration.zero &&
                    !_expiryHandled &&
                    exam.finishedAt == null) {
                  _expiryHandled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref.invalidate(
                        fullTcfExamProvider(widget.parentAttemptId));
                  });
                }
                return _ProgressView(
                  exam: exam,
                  remaining: remaining,
                  finishing: _finishing,
                  onExit: () => _close(context),
                  onQuit: () => _confirmQuit(exam),
                );
              },
            ),
          ),
          if (_finishing) const Positioned.fill(child: _FinishingOverlay()),
        ],
      ),
    );
  }

  /// Avertit avant d'abandonner un examen en cours, puis finalise. Si l'examen
  /// est déjà finalisé (éval IA en cours / terminé) ou que les 4 épreuves sont
  /// jouées, il n'y a rien à abandonner → simple sortie.
  Future<void> _confirmQuit(FullTcfExamResponse exam) async {
    final allDone = exam.currentStepIndex >= 4;
    if (exam.finishedAt != null || allDone) {
      _close(context);
      return;
    }
    final confirmed = await showAppSheet<bool>(
      context,
      icon: LucideIcons.triangleAlert,
      iconBg: AppColors.redLight,
      iconColor: AppColors.red,
      title: 'Abandonner l\'examen ?',
      sub: 'Pour reprendre plus tard, quittez simplement cet écran avec la '
          'flèche : votre progression est gardée (le chrono d\'une épreuve '
          'déjà lancée, lui, continue de courir). Abandonner est définitif : '
          'les épreuves restantes sont comptées 0 et l\'examen est finalisé. '
          'Vous verrez votre résultat.',
      children: [
        AppButton(
          label: 'Abandonner et voir le résultat',
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.pop(context, true),
        ),
        AppButton(
          label: 'Continuer l\'examen',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
    if (confirmed == true) {
      await _finalizeAndGoToBilan(exam);
    }
  }

  /// Finalise l'examen et va au bilan. Toute épreuve non terminée est finalisée
  /// (CO/CE = score sur les réponses données, 0 si aucune ; EE/EO = `markSubDone`
  /// → comptée A1 non atteint côté backend), sinon le `finish` parent échouerait
  /// (le backend exige les 4 terminées). Parité avec le web.
  Future<void> _finalizeAndGoToBilan(FullTcfExamResponse exam) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final repo = ref.read(fullTcfExamRepositoryProvider);
    final attempts = ref.read(attemptsRepositoryProvider);
    for (final sa in exam.subAttempts) {
      if (sa.finishedAt != null) continue;
      try {
        if (sa.epreuve == EpreuveType.tcfCo ||
            sa.epreuve == EpreuveType.tcfCe) {
          await attempts.finish(sa.attemptId);
        } else {
          await repo.markSubDone(
            parentAttemptId: exam.id,
            epreuveWire: sa.epreuve.wire,
          );
        }
      } catch (_) {
        // Best-effort : on tente quand même le finish parent.
      }
    }
    try {
      await repo.finish(exam.id);
    } catch (_) {
      // Idempotent / déjà fini — le bilan lira l'état réel via polling.
    }
    if (!mounted) return;
    context.go(AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id));
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.reviser);
    }
  }
}

class _ProgressView extends ConsumerWidget {
  const _ProgressView({
    required this.exam,
    required this.remaining,
    required this.finishing,
    required this.onExit,
    required this.onQuit,
  });

  final FullTcfExamResponse exam;

  /// Temps restant sur l'**épreuve en cours**. `null` quand elle n'est pas
  /// encore lancée, qu'elle n'a pas de chrono (expression orale) ou que tout est
  /// joué — dans ces cas aucun décompte n'est affiché.
  final Duration? remaining;
  final bool finishing;

  /// Sortie simple de l'écran : **ne finalise rien**, l'examen reste reprenable.
  /// C'est ce que fait la flèche retour.
  final VoidCallback onExit;

  /// Abandon explicite (confirmation puis finalisation). Seul le bouton
  /// « Abandonner l'examen » y mène.
  final VoidCallback onQuit;

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
          _TopBar(onClose: finishing ? () {} : onExit),
          const SizedBox(height: 20),
          _Hero(exam: exam, remaining: remaining),
          const SizedBox(height: 18),
          _StepsList(exam: exam),
          const SizedBox(height: 22),
          if (allDone)
            AppButton(
              label: 'Voir mon résultat',
              icon: LucideIcons.crown,
              onPressed: () => context.go(
                AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id),
              ),
            )
          else
            AppButton(
              label: _ctaLabel(exam),
              icon: LucideIcons.play,
              onPressed: () => _startStep(context, ref, exam, stepIdx),
            ),
          const SizedBox(height: 10),
          AppButton(
            label: allDone ? 'Quitter' : 'Abandonner l\'examen',
            variant: AppButtonVariant.ghost,
            onPressed: finishing ? null : (allDone ? onExit : onQuit),
          ),
        ],
      ),
    );
  }

  String _ctaLabel(FullTcfExamResponse exam) {
    final ep = kFullTcfExamOrder[exam.currentStepIndex];
    return 'Commencer · ${_StepMeta.of(ep).title}';
  }

  Future<void> _startStep(
    BuildContext context,
    WidgetRef ref,
    FullTcfExamResponse exam,
    int stepIdx,
  ) async {
    final ep = kFullTcfExamOrder[stepIdx];
    final sub = exam.subFor(ep);
    if (sub == null) return;

    // Démarre le chrono propre de l'épreuve côté backend AVANT d'ouvrir son
    // écran, pour les **4** épreuves : tant que `begin` n'est pas appelé,
    // l'épreuve n'a pas d'échéance (les 4 sous-attempts sont créés d'un bloc au
    // lancement de l'examen). Il est **obligatoire pour l'EE** et sert à l'EO à
    // dater l'ouverture de l'épreuve (statut de continuité). Best-effort — si
    // l'appel réseau échoue on ouvre quand même l'écran, le chrono restant
    // ancré sur la dernière valeur serveur.
    try {
      await ref.read(fullTcfExamRepositoryProvider).beginEpreuve(
            parentAttemptId: exam.id,
            epreuveWire: ep.wire,
          );
    } catch (_) {}
    if (!context.mounted) return;
    ref.invalidate(fullTcfExamProvider(exam.id));

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
}

/// Scrim plein écran pendant la finalisation d'un abandon : bloque les taps et
/// indique que l'examen se finalise avant la redirection vers le bilan.
class _FinishingOverlay extends StatelessWidget {
  const _FinishingOverlay();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        color: AppColors.scrim,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.white),
            const SizedBox(height: 14),
            Text(
              'Finalisation de l\'examen…',
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre du haut. Sa flèche **sort de l'écran et rien d'autre** : elle n'a
/// jamais à finaliser l'examen ni à appeler le serveur — l'abandon vit sur son
/// propre bouton, nommé.
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
                LucideIcons.chevronLeft,
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
  const _Hero({required this.exam, required this.remaining});

  final FullTcfExamResponse exam;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final stepIdx = exam.currentStepIndex;
    final allDone = stepIdx >= 4;
    final current = exam.currentSubAttempt;
    final timedOut = remaining == Duration.zero;

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
              if (!allDone && remaining != null)
                _EpreuveTimer(remaining: remaining!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            allDone ? 'Tout est joué' : 'TCF IRN complet',
            style: AppFonts.ui(
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
                    ? 'Temps écoulé sur cette épreuve. On enregistre ce que tu as '
                        'fait, puis tu passes à la suivante.'
                    : _heroSentence(current),
            style: AppFonts.ui(
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
                  const Icon(LucideIcons.hourglass,
                      size: 14, color: AppColors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'L\'IA évalue tes productions, encore quelques secondes…',
                      style: AppFonts.ui(
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

  /// Phrase du hero selon l'épreuve en cours. Aucune durée en dur : elle vient
  /// de `timeLimitSeconds`, et l'oral n'en a pas — il se chronomètre par tâche.
  String _heroSentence(FullTcfExamSubAttempt? current) {
    if (current == null) {
      return 'Enchaîne les 4 épreuves dans l\'ordre. Chaque épreuve a son propre '
          'temps : rien ne se reporte de l\'une à l\'autre.';
    }
    final meta = _StepMeta.of(current.epreuve);
    final duree = epreuveDurationLabel(current.timeLimitSeconds);
    if (duree == null) {
      return '${meta.title} : le temps se compte par tâche. Tu lances chaque '
          'tâche quand tu es prêt.';
    }
    if (current.deadlineAt == null) {
      return '${meta.title} : $duree. Le chrono part quand tu lances '
          'l\'épreuve, et il ne s\'arrête plus si tu quittes.';
    }
    return '${meta.title} : $duree. Le chrono court même quand tu quittes — '
        'le temps restant ne se reporte pas sur l\'épreuve suivante.';
  }
}

/// Pill chrono affichée dans le hero : temps restant sur **l'épreuve en cours**,
/// décompté depuis son `deadlineAt` (échéance absolue servie par le backend).
/// Devient plus contrastée sous les 5 dernières minutes.
class _EpreuveTimer extends StatelessWidget {
  const _EpreuveTimer({required this.remaining});

  final Duration remaining;

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
          const Icon(LucideIcons.timer, size: 13, color: AppColors.white),
          const SizedBox(width: 5),
          Text(
            _format(remaining),
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
    final currentIdx = exam.currentStepIndex;

    return Column(
      children: [
        for (int i = 0; i < kFullTcfExamOrder.length; i++) ...[
          _StepCard(
            index: i,
            epreuve: kFullTcfExamOrder[i],
            sub: exam.subFor(kFullTcfExamOrder[i]),
            state: i < currentIdx
                ? _StepState.done
                : i == currentIdx
                    ? _StepState.current
                    : _StepState.locked,
          ),
          if (i != kFullTcfExamOrder.length - 1) const SizedBox(height: 10),
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
              // Pastille d'ÉTAT (fait / en cours / à faire) : neutre. Le vert
              // est réservé aux niveaux hauts ([CecrlColor]) — l'employer pour
              // « terminé » ferait passer une épreuve ratée pour une réussite.
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isDone
                ? const Icon(LucideIcons.check,
                    color: AppColors.white, size: 22)
                : Text(
                    '${index + 1}',
                    style: AppFonts.ui(
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
                        style: AppFonts.ui(
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
                  style: AppFonts.ui(
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

  /// La durée affichée vient **du DTO** (`timeLimitSeconds`), jamais d'une
  /// constante d'écran : c'est exactement là que la CE annonçait 30 min ici et
  /// 35 min sur la grille standalone. L'expression orale n'en a pas — elle se
  /// chronomètre par tâche, et on le dit.
  String _subtitle(_StepMeta meta, FullTcfExamSubAttempt? sub, _StepState st) {
    final duree = epreuveDurationLabel(sub?.timeLimitSeconds) ??
        (sub?.epreuve == EpreuveType.tcfEo
            ? kChronoParTacheLabel
            : epreuveDurationLabelFor(epreuve));
    if (st == _StepState.done && sub != null) {
      // Score sur l'échelle du relevé TCF (100-499) : le pondéré interne
      // (« 23/50 ») ne veut rien dire pour un candidat. Repli sur le pondéré
      // seulement quand le serveur n'a pas calibré.
      final scoreLabel = sub.qcmScoreLabel;
      if (scoreLabel != null) {
        return '$duree · $scoreLabel'
            '${sub.cecrlLevel != null ? ' · ${sub.cecrlLevel!.displayName}' : ''}';
      }
      if (sub.submissionsCount != null) {
        return '$duree · ${sub.submissionsCount}/3 évaluées'
            '${sub.cecrlLevel != null ? ' · ${sub.cecrlLevel!.displayName}' : ''}';
      }
      return '$duree · Terminé';
    }
    return '$duree · ${meta.detail}';
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
      return const Icon(LucideIcons.lock,
          color: AppColors.muted2, size: 18);
    }
    final level = sub?.cecrlLevel;
    if (state == _StepState.done && level != null) {
      // Le badge porte un NIVEAU, pas un état : sa teinte vient de
      // [CecrlColor] (le vert dit « B2 », pas « terminé ») et son libellé du
      // helper canonique — « <A1 » pour A1 non atteint, comme le bilan.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: level.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          level.shortName,
          style: AppFonts.ui(
            size: 11,
            weight: FontWeight.w800,
            color: level.color,
          ),
        ),
      );
    }
    if (state == _StepState.locked) {
      return const Icon(LucideIcons.lock,
          color: AppColors.muted2, size: 18);
    }
    return const Icon(LucideIcons.chevronRight,
        color: AppColors.muted, size: 22);
  }
}

/// Libellés d'une étape. **Aucune durée ici** : elle est servie par le DTO
/// (`FullTcfExamSubAttempt.timeLimitSeconds`), une seule source pour les 3
/// fronts.
class _StepMeta {
  const _StepMeta({
    required this.title,
    required this.icon,
    required this.detail,
  });

  final String title;
  final IconData icon;
  final String detail;

  static _StepMeta of(EpreuveType e) {
    switch (e) {
      case EpreuveType.tcfCo:
        return const _StepMeta(
          title: 'Compréhension orale',
          icon: LucideIcons.headphones,
          detail: '25 questions audio',
        );
      case EpreuveType.tcfCe:
        return const _StepMeta(
          title: 'Compréhension écrite',
          icon: LucideIcons.bookOpen,
          detail: '25 questions texte',
        );
      case EpreuveType.tcfEe:
        return const _StepMeta(
          title: 'Expression écrite',
          icon: LucideIcons.penLine,
          detail: '3 tâches IA',
        );
      case EpreuveType.tcfEo:
        return const _StepMeta(
          title: 'Expression orale',
          icon: LucideIcons.mic,
          detail: '3 tâches IA',
        );
      default:
        return const _StepMeta(
          title: '—',
          icon: LucideIcons.circleHelp,
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
            const Icon(LucideIcons.cloudOff,
                size: 40, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(color: AppColors.muted),
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
