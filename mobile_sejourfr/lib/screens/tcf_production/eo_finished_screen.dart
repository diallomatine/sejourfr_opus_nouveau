import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';

/// Ecran 03 du mockup : enregistrement terminé. Permet d'ecouter l'audio
/// rendu avant soumission, puis lance l'evaluation au tap "Voir mon evaluation".
class EoFinishedScreen extends ConsumerStatefulWidget {
  const EoFinishedScreen({super.key, required this.taskIndex});

  final int taskIndex;

  @override
  ConsumerState<EoFinishedScreen> createState() => _EoFinishedScreenState();
}

class _EoFinishedScreenState extends ConsumerState<EoFinishedScreen> {
  bool _submitting = false;
  String? _submitError;

  Future<void> _submit(BuildContext context) async {
    final rec = ref.read(recordingControllerProvider);
    final path = rec.filePath;
    if (path == null) {
      setState(() => _submitError = 'Audio introuvable, veuillez recommencer.');
      return;
    }
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];

    // Mode examen blanc complet : on attend la persist + upload R2 (~1-3 s
    // selon la taille audio), pas l'éval IA qui tourne en async côté
    // serveur. Garanti : si l'upload échoue, l'utilisateur voit l'erreur et
    // peut retenter sans perdre son enregistrement local.
    if (fullExamId != null) {
      setState(() {
        _submitting = true;
        _submitError = null;
      });
      try {
        await ref.read(eoSessionProvider.notifier).submitTask(
              taskIndex: widget.taskIndex,
              audioFile: File(path),
              mimeType: rec.fileMime ?? 'audio/mp4',
            );
      } catch (e) {
        if (!context.mounted) return;
        setState(() {
          _submitting = false;
          _submitError = ApiClient.toApiException(e).message;
        });
        return;
      }
      if (!context.mounted) return;
      final session = ref.read(eoSessionProvider).value;
      final hasNext =
          session != null && widget.taskIndex + 1 < session.totalTasks;
      if (hasNext) {
        context.pushReplacement(
          withCurrentQuery(
            context,
            '/tcf/expression-orale/t/${widget.taskIndex + 1}',
          ),
        );
      } else {
        try {
          await ref.read(fullTcfExamRepositoryProvider).markSubDone(
                parentAttemptId: fullExamId,
                epreuveWire: 'TCF_EO',
              );
        } catch (_) {
          /* hook auto backend fallback */
        }
        if (!context.mounted) return;
        ref.read(eoSessionProvider.notifier).reset();
        ref.invalidate(fullTcfExamProvider(fullExamId));
        context.go('/tcf/examen-blanc/$fullExamId');
      }
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final submission = await ref.read(eoSessionProvider.notifier).submitTask(
            taskIndex: widget.taskIndex,
            audioFile: File(path),
            mimeType: rec.fileMime ?? 'audio/mp4',
          );
      if (!context.mounted) return;
      final session = ref.read(eoSessionProvider).value;
      final isExamMode = session != null && session.totalTasks > 1;
      final hasNext =
          session != null && widget.taskIndex + 1 < session.totalTasks;
      if (isExamMode) {
        // Mode session 3-tâches (onglet Examens) : pas d'évaluation visible
        // entre les tâches, comme dans le vrai TCF. On enchaîne directement
        // le briefing suivant ; après T3 on push le bilan détaillé
        // (`HistorySessionScreen` en mode `live=1`) qui pollera les
        // évaluations IA des 3 submissions et permettra de drill-down sur
        // chaque tâche.
        if (hasNext) {
          context.pushReplacement(
            withCurrentQuery(
              context,
              '/tcf/expression-orale/t/${widget.taskIndex + 1}',
            ),
          );
        } else {
          final attemptId = session.attempt!.id;
          context.pushReplacement(
            '/tcf/expression-orale/sessions/$attemptId?live=1',
          );
        }
        return;
      }
      context.pushReplacement(
        withCurrentQuery(
          context,
          '/tcf/expression-orale/resultats/${submission.id}?taskIndex=${widget.taskIndex}',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ApiClient.toApiException(e).message;
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le submit on garde l'écran visible avec un loading inline sur le
    // bouton ; un écran loading plein écran ici donnerait l'illusion d'un
    // double push une fois l'écran de résultats (avec son propre loading de
    // polling) monté.
    final session = ref.watch(eoSessionProvider).value;
    final task = session?.taskAt(widget.taskIndex);
    final rec = ref.watch(recordingControllerProvider);

    if (task == null || rec.filePath == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: const ProductionAppHeader(title: 'Expression orale'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];
    final fallbackRoute =
        fullExamId != null ? '/tcf/examen-blanc/$fullExamId' : '/tcf/eo';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: 'Expression orale',
        fallbackRoute: fallbackRoute,
        rightAction: ProductionAppHeaderQuit(
          onPressed: () {
            ref.read(recordingControllerProvider.notifier).cancel();
            ref.read(eoSessionProvider.notifier).reset();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(fallbackRoute);
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ProductionProgressStrip(
              current: widget.taskIndex + 1,
              total: session!.totalTasks,
              niveau: task.niveauCible,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _FinishedIcon(),
                    const SizedBox(height: 16),
                    Text(
                      'Enregistrement termine',
                      style: AppFonts.ui(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Duree enregistree',
                      style: AppFonts.ui(size: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(rec.elapsed),
                      style: AppFonts.ui(
                        size: 30,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PlaybackBar(filePath: rec.filePath!),
                    if (rec.elapsed.inSeconds < 120) ...[
                      const SizedBox(height: 12),
                      const _ShortRecordingHint(),
                    ],
                    const SizedBox(height: 16),
                    _NextInfoCard(),
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      _InlineError(message: _submitError!),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.line2, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'Voir mon évaluation',
                  icon: LucideIcons.sparkles,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : () => _submit(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortRecordingHint extends StatelessWidget {
  const _ShortRecordingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.lightbulb, size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Astuce : visez 2-3 minutes pour une meilleure note — vous pouvez tout de même envoyer.',
              style: AppFonts.ui(
                size: 13,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedIcon extends StatelessWidget {
  const _FinishedIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(LucideIcons.check, size: 44, color: AppColors.white),
    );
  }
}

class _NextInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Et maintenant ?',
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Votre enregistrement va être analysé par notre IA. Vous recevrez une evaluation détaillée dans quelques secondes.",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.ui(size: 13, color: AppColors.red, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini playback bar : play/pause + barre + duration. Lit le fichier local via
/// just_audio. Pas la peine de gerer le seek pour ce flow (lecture lineaire).
class _PlaybackBar extends StatefulWidget {
  const _PlaybackBar({required this.filePath});

  final String filePath;

  @override
  State<_PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<_PlaybackBar> {
  final _player = AudioPlayer();
  bool _ready = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    });
  }

  Future<void> _load() async {
    try {
      _total = await _player.setFilePath(widget.filePath) ?? Duration.zero;
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _player.pause();
    } else {
      if (_position >= _total && _total > Duration.zero) {
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _ready ? _togglePlay : null,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? LucideIcons.pause : LucideIcons.play,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _total.inMilliseconds == 0
                        ? 0
                        : (_position.inMilliseconds / _total.inMilliseconds)
                            .clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppColors.blueLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.blue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_fmt(_position)} / ${_fmt(_total)}',
                  style: AppFonts.mono(
                    size: 11,
                    color: AppColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
