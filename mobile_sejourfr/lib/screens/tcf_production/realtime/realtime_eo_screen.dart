import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/repositories.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/realtime_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/screen_header.dart';
import '../widgets/transcript_dialogue.dart';
import 'realtime_eo_controller.dart';

/// Écran d'une session EO en temps réel (examinateur vocal IA). Volontairement
/// DISTINCT de l'enregistrement solo : marqueur « IA · En direct », minuteur, et
/// un GROS MICRO central avec un libellé d'état (« À vous de parler » /
/// « L'examinateur parle… »). Pas d'affichage du dialogue. Pilote
/// [RealtimeEoController] ; à la clôture, navigue vers le bilan EXISTANT (qui
/// poll la submission créée par le backend).
class RealtimeEoScreen extends ConsumerStatefulWidget {
  const RealtimeEoScreen({super.key, required this.args});

  final RealtimeRunnerArgs args;

  @override
  ConsumerState<RealtimeEoScreen> createState() => _RealtimeEoScreenState();
}

class _RealtimeEoScreenState extends ConsumerState<RealtimeEoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _goToResult() async {
    if (_navigated) return;
    _navigated = true;
    if (widget.args.popOnDone) {
      context.pop(true);
      return;
    }
    // Comme une soumission EE / EO T3 : on va DIRECTEMENT au détail du rapport
    // (spinner d'évaluation puis rapport + transcription), pas au bilan de
    // session multi-tâches. On résout la submission créée par la session.
    final repo = ref.read(productionRepositoryProvider);
    final attemptId = widget.args.attemptId;
    final taskIndex = (widget.args.task.tacheNumero) - 1;
    String? submissionId;
    for (var i = 0; i < 4 && submissionId == null; i++) {
      try {
        final subs = await repo.listMine(epreuve: EpreuveType.tcfEo, limit: 10);
        for (final s in subs) {
          if (s.attemptId == attemptId) {
            submissionId = s.id;
            break;
          }
        }
      } catch (_) {/* retry */}
      if (submissionId == null) {
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }
    if (!mounted) return;
    if (submissionId != null) {
      context.pushReplacement(
        '/tcf/expression-orale/resultats/$submissionId?taskIndex=$taskIndex&single=1',
      );
    } else {
      // Repli : le bilan de session (poll) finira par afficher le résultat.
      context.pushReplacement(
        '/tcf/expression-orale/sessions/$attemptId?live=1',
      );
    }
  }

  void _exitFailed() {
    if (widget.args.popOnDone) {
      context.pop(false);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _confirmLeave() async {
    final controller =
        ref.read(realtimeEoControllerProvider(widget.args).notifier);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Terminer la session ?', style: AppFonts.display(size: 18)),
        content: Text(
          'Votre échange avec l\'examinateur sera évalué en l\'état.',
          style: AppFonts.ui(size: 14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Terminer', style: AppFonts.label(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (leave == true) controller.finish();
  }

  void _openTranscript() {
    showAppSheet<void>(
      context,
      icon: LucideIcons.messageSquare,
      title: 'Transcription',
      sub: 'Votre échange avec l\'examinateur',
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _TranscriptBody(args: widget.args),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    ref.listen<RealtimeEoState>(realtimeEoControllerProvider(args),
        (prev, next) {
      if (next.phase == RealtimePhase.done) _goToResult();
    });
    final state = ref.watch(realtimeEoControllerProvider(args));
    final task = args.task;

    return PopScope(
      canPop: state.phase == RealtimePhase.done ||
          state.phase == RealtimePhase.failed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: 'Oral avec un examinateur',
                sub: task.displayTitle,
                onBack: _confirmLeave,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _LiveStrip(state: state),
              ),
              Expanded(child: _MicStage(pulse: _pulse, state: state)),
              _BottomBar(
                state: state,
                onFinish: _confirmLeave,
                onExit: _exitFailed,
                onShowTranscript: _openTranscript,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau persistant : identité « Examinateur IA » + badge « ● En direct » +
/// minuteur. C'est ce qui distingue l'écran du recorder solo (qui n'a aucun de
/// ces marqueurs).
class _LiveStrip extends StatelessWidget {
  const _LiveStrip({required this.state});

  final RealtimeEoState state;

  @override
  Widget build(BuildContext context) {
    final live = state.phase == RealtimePhase.welcoming ||
        state.phase == RealtimePhase.live ||
        state.phase == RealtimePhase.finishing;
    // Le décompte ne s'affiche qu'une fois qu'il court réellement (à la 1re
    // parole de l'examinateur) : pendant l'accueil il resterait figé sur la cible.
    final counting = state.phase == RealtimePhase.live ||
        state.phase == RealtimePhase.finishing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text('Examinateur IA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(size: 15)),
                ),
                const SizedBox(width: 6),
                const _IaBadge(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (live) ...[
            const _LiveDot(),
            if (counting) ...[
              const SizedBox(width: 12),
              Text(_fmt(state.remainingSec),
                  style: AppFonts.display(size: 18, color: AppColors.red)),
            ],
          ],
        ],
      ),
    );
  }

  static String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _IaBadge extends StatelessWidget {
  const _IaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child:
          Text('IA', style: AppFonts.label(color: AppColors.redDark, size: 10)),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.red),
        ),
        const SizedBox(width: 5),
        Text('EN DIRECT', style: AppFonts.label(color: AppColors.red, size: 10)),
      ],
    );
  }
}

/// Le gros micro central + le libellé d'état. Le halo pulse quand c'est au
/// candidat de parler ; bascule en bleu (haut-parleur) quand l'examinateur parle.
class _MicStage extends StatelessWidget {
  const _MicStage({required this.pulse, required this.state});

  final AnimationController pulse;
  final RealtimeEoState state;

  @override
  Widget build(BuildContext context) {
    if (state.phase == RealtimePhase.failed) {
      return _Centered(
        icon: LucideIcons.wifiOff,
        title: 'Connexion impossible',
        sub: state.error ?? 'Réessayez en mode enregistrement.',
      );
    }

    final examiner = state.examinerSpeaking;
    final yourTurn = state.phase == RealtimePhase.live && !examiner;
    // Accueil + connexion : on attend (micro coupé), on montre un état neutre.
    final waiting = state.phase == RealtimePhase.connecting ||
        state.phase == RealtimePhase.welcoming;

    final (String label, String hint) = switch (state.phase) {
      RealtimePhase.connecting => (
          'Connexion à l\'examinateur…',
          'Préparez-vous à parler.'
        ),
      RealtimePhase.welcoming => (
          'L\'examinateur vous accueille…',
          'Un instant — votre micro s\'activera après son accueil.'
        ),
      RealtimePhase.live => examiner
          ? ('L\'examinateur parle…', 'Écoutez sa question.')
          : ('À vous de parler', 'Parlez naturellement, comme à un vrai oral.'),
      RealtimePhase.finishing => examiner
          ? ('Temps écoulé — l\'examinateur conclut.', '')
          : ('Préparation de votre évaluation…', ''),
      RealtimePhase.done => ('Échange terminé', ''),
      RealtimePhase.failed => ('', ''),
    };

    final accent = examiner ? AppColors.blue : AppColors.red;
    final accentSoft =
        examiner ? AppColors.blue.withValues(alpha: 0.12) : AppColors.redLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = yourTurn ? pulse.value : 0.0;
              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150 + t * 40,
                      height: 150 + t * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentSoft.withValues(
                            alpha: examiner ? 0.18 : (0.5 - t * 0.25)),
                      ),
                    ),
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.30),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: waiting
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: AppColors.white),
                              ),
                            )
                          : Icon(
                              examiner ? LucideIcons.volume2 : LucideIcons.mic,
                              size: 48,
                              color: AppColors.white,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(label,
              textAlign: TextAlign.center, style: AppFonts.display(size: 22)),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(hint,
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13.5, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.title, required this.sub});

  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppColors.muted2),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center, style: AppFonts.display(size: 18)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onFinish,
    required this.onExit,
    required this.onShowTranscript,
  });

  final RealtimeEoState state;
  final VoidCallback onFinish;
  final VoidCallback onExit;
  final VoidCallback onShowTranscript;

  @override
  Widget build(BuildContext context) {
    final isFailed = state.phase == RealtimePhase.failed;
    final canShow = state.transcript.isNotEmpty && !isFailed;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canShow) ...[
              AppButton(
                label: 'Voir ma transcription',
                variant: AppButtonVariant.soft,
                icon: LucideIcons.messageSquare,
                onPressed: onShowTranscript,
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
              label: isFailed ? 'Retour' : 'Terminer l\'oral',
              variant:
                  isFailed ? AppButtonVariant.outline : AppButtonVariant.primary,
              isLoading: state.phase == RealtimePhase.finishing,
              icon: isFailed ? null : LucideIcons.check,
              onPressed: isFailed ? onExit : onFinish,
            ),
          ],
        ),
      ),
    );
  }
}

/// Corps du bottom sheet « Voir ma transcription » : dialogue en bulles
/// (candidat à droite/rouge, examinateur à gauche/bleu), live via Riverpod +
/// auto-scroll en bas à chaque nouveau tour.
class _TranscriptBody extends ConsumerStatefulWidget {
  const _TranscriptBody({required this.args});

  final RealtimeRunnerArgs args;

  @override
  ConsumerState<_TranscriptBody> createState() => _TranscriptBodyState();
}

class _TranscriptBodyState extends ConsumerState<_TranscriptBody> {
  final ScrollController _sc = ScrollController();

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _stickToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) _sc.jumpTo(_sc.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(
      realtimeEoControllerProvider(widget.args).select((s) => s.transcript),
    );
    if (lines.isEmpty) {
      return Center(
        child: Text(
          'Le dialogue s\'affichera ici au fil de l\'échange.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 13, color: AppColors.muted),
        ),
      );
    }
    _stickToBottom();
    return ListView.separated(
      controller: _sc,
      padding: const EdgeInsets.only(top: 4),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => TranscriptBubble(
        candidate: lines[i].speaker == RealtimeSpeaker.candidate,
        text: lines[i].text,
      ),
    );
  }
}
