import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import 'realtime_eo_controller.dart';

/// Écran d'une session EO en temps réel (examinateur vocal IA). Pilote
/// [RealtimeEoController] : affiche la consigne, l'état de l'échange et un
/// minuteur. À la clôture, navigue vers le bilan EXISTANT (qui poll la
/// submission créée par le backend).
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
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _goToResult() {
    if (_navigated) return;
    _navigated = true;
    context.pushReplacement(
      '/tcf/expression-orale/sessions/${widget.args.attemptId}?live=1',
    );
  }

  Future<void> _confirmLeave() async {
    final controller =
        ref.read(realtimeEoControllerProvider(widget.args).notifier);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Terminer la session ?', style: AppFonts.display(size: 18)),
        content: Text(
          'Votre échange sera évalué en l\'état.',
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
      canPop: state.phase == RealtimePhase.done,
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
                title: task.displayTitle,
                sub: 'Examen oral · temps réel',
                onBack: _confirmLeave,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ConsigneCard(consigne: task.consigne, contexte: task.contexte),
                      const SizedBox(height: 28),
                      _StatusOrb(pulse: _pulse, state: state),
                      const SizedBox(height: 24),
                      _StatusText(state: state),
                    ],
                  ),
                ),
              ),
              _BottomBar(state: state, onFinish: () => _confirmLeave()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsigneCard extends StatelessWidget {
  const _ConsigneCard({required this.consigne, this.contexte});

  final String consigne;
  final String? contexte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: const Border(left: BorderSide(color: AppColors.red, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONSIGNE',
              style: AppFonts.label(color: AppColors.redDark, size: 11)),
          const SizedBox(height: 6),
          Text(consigne, style: AppFonts.ui(size: 14, color: AppColors.ink)),
          if (contexte != null && contexte!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(contexte!,
                style: AppFonts.ui(size: 13, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.pulse, required this.state});

  final AnimationController pulse;
  final RealtimeEoState state;

  @override
  Widget build(BuildContext context) {
    final active = state.examinerSpeaking;
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = active ? pulse.value : 0.0;
          final size = 132.0 + t * 20;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red.withValues(alpha: active ? 0.14 : 0.07),
            ),
            child: Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                ),
                child: Icon(
                  active ? LucideIcons.volume2 : LucideIcons.ear,
                  color: AppColors.white,
                  size: 34,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.state});

  final RealtimeEoState state;

  @override
  Widget build(BuildContext context) {
    final (title, sub) = switch (state.phase) {
      RealtimePhase.connecting => ('Connexion à l\'examinateur…', null),
      RealtimePhase.live => (
          state.examinerSpeaking ? 'L\'examinateur parle…' : 'À vous de parler',
          'Parlez naturellement, comme à un vrai examen.'
        ),
      RealtimePhase.finishing => ('Fin de l\'échange…', null),
      RealtimePhase.done => ('Échange terminé', null),
      RealtimePhase.failed => (
          'Connexion impossible',
          state.error ?? 'Réessayez en mode enregistrement.'
        ),
    };
    return Column(
      children: [
        Text(title,
            textAlign: TextAlign.center, style: AppFonts.display(size: 20)),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted)),
        ],
        if (state.phase == RealtimePhase.live ||
            state.phase == RealtimePhase.finishing) ...[
          const SizedBox(height: 18),
          Text(
            _fmt(state.remainingSec),
            style: AppFonts.display(size: 30, color: AppColors.red),
          ),
        ],
      ],
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onFinish});

  final RealtimeEoState state;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final isFailed = state.phase == RealtimePhase.failed;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AppButton(
          label: isFailed ? 'Retour' : 'Terminer',
          variant:
              isFailed ? AppButtonVariant.outline : AppButtonVariant.primary,
          isLoading: state.phase == RealtimePhase.finishing,
          icon: isFailed ? null : LucideIcons.check,
          onPressed: isFailed ? () => Navigator.of(context).maybePop() : onFinish,
        ),
      ),
    );
  }
}
