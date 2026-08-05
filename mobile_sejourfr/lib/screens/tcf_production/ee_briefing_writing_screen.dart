import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import '../question_runner/widgets/exam_timer.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'draft_service.dart';
import 'ee_session_controller.dart';
import 'widgets/consigne_card.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';
import 'widgets/writing_zone.dart';

/// Durée de l'examen EE complet (30 min), comme côté backend pour le module.
/// Utilisée côté front pour le sous-attempt EE d'un examen TCF complet, qui
/// n'expose pas de `timeLimitSeconds`.
const int _eeExamDurationSeconds = 1800;

/// Briefing + zone d'ecriture combines (un seul long scroll), aligne sur
/// le mockup `EE · 01` de sejourfr_mobile_v3.html.
class EeBriefingWritingScreen extends ConsumerStatefulWidget {
  const EeBriefingWritingScreen({super.key, required this.taskIndex});

  final int taskIndex;

  @override
  ConsumerState<EeBriefingWritingScreen> createState() =>
      _EeBriefingWritingScreenState();
}

class _EeBriefingWritingScreenState
    extends ConsumerState<EeBriefingWritingScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _writingFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveTimer;
  bool _submitting = false;
  String? _submitError;
  bool _draftLoaded = false;
  String? _loadedForTaskId;
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    _writingFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Contexte examen blanc complet : sous-attempt EE déjà créé par le
      // backend, on le reprend au lieu d'en créer un nouveau. Sinon la session
      // (examen module via `startExam`, ou sujet unique via `startSingle`) est
      // déjà démarrée par l'écran appelant — on la respecte, pas de fallback.
      final goState = GoRouterState.of(context);
      final fullExamId = goState.uri.queryParameters['fullExamId'];
      final subAttemptId = goState.uri.queryParameters['subAttemptId'];
      if (fullExamId != null && subAttemptId != null) {
        ref
            .read(eeSessionProvider.notifier)
            .startInFullExam(subAttemptId: subAttemptId);
      }
    });
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final isNowFocused = _writingFocusNode.hasFocus;
    final justBlurredWithText =
        _wasFocused && !isNowFocused && _controller.text.trim().isNotEmpty;
    _wasFocused = isNowFocused;
    // On differe le setState a la frame suivante pour ne pas casser la
    // sequence de focus → keyboard (le reflow synchrone des cards qui
    // disparaissent peut intercepter la requete clavier du TextField).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    if (justBlurredWithText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _writingFocusNode.removeListener(_onFocusChanged);
    _writingFocusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _onTextChanged(String value, ProductionTaskDto task) {
    setState(() {});
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      ref.read(eeDraftServiceProvider).save(task.id, value);
    });
  }

  Future<void> _loadDraftIfNeeded(ProductionTaskDto task) async {
    if (_draftLoaded && _loadedForTaskId == task.id) return;
    _draftLoaded = true;
    _loadedForTaskId = task.id;
    final draft = await ref.read(eeDraftServiceProvider).load(task.id);
    if (!mounted || draft == null || draft.isEmpty) return;
    if (_controller.text.isEmpty) {
      _controller.text = draft;
      setState(() {});
    }
  }

  Future<void> _submit(ProductionTaskDto task) async {
    final text = _controller.text;
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];

    // Mode examen blanc complet : on attend la confirmation de PERSISTANCE
    // backend (response du POST ~500 ms), pas l'évaluation IA Claude qui
    // tourne désormais en arrière-plan côté serveur (cf.
    // ProductionPipelineAsyncRunner). Garanti à 100 % : si le POST renvoie
    // une erreur (texte trop court, quota, etc.), on l'affiche au lieu de
    // la swallow silencieusement.
    if (fullExamId != null) {
      setState(() {
        _submitting = true;
        _submitError = null;
      });
      try {
        await ref.read(eeSessionProvider.notifier).submitTask(
              taskIndex: widget.taskIndex,
              texte: text,
            );
        await ref.read(eeDraftServiceProvider).clear(task.id);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _submitError = ApiClient.toApiException(e).message;
        });
        return;
      }
      if (!mounted) return;
      final session = ref.read(eeSessionProvider).value;
      final hasNext =
          session != null && widget.taskIndex + 1 < session.totalTasks;
      if (hasNext) {
        context.pushReplacement(
          withCurrentQuery(
            context,
            '/tcf/expression-ecrite/t/${widget.taskIndex + 1}',
          ),
        );
      } else {
        // Dernière tâche EE : marquer le sous-attempt EE comme terminé
        // côté backend (les 3 submissions sont persistées, mais leurs
        // évaluations IA tournent encore en async). Le hub débloque EO.
        try {
          await ref.read(fullTcfExamRepositoryProvider).markSubDone(
                parentAttemptId: fullExamId,
                epreuveWire: 'TCF_EE',
              );
        } catch (_) {
          /* fallback : hook auto backend finira par poser finishedAt */
        }
        if (!mounted) return;
        ref.read(eeSessionProvider.notifier).reset();
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
      final submission = await ref.read(eeSessionProvider.notifier).submitTask(
            taskIndex: widget.taskIndex,
            texte: text,
          );
      await ref.read(eeDraftServiceProvider).clear(task.id);
      if (!mounted) return;
      final session = ref.read(eeSessionProvider).value;
      final isExamMode = session != null && session.totalTasks > 1;
      final hasNext =
          session != null && widget.taskIndex + 1 < session.totalTasks;
      if (isExamMode) {
        // Mode session 3-tâches (onglet Examens) : pas d'évaluation visible
        // entre T1/T2/T3, fidèle au vrai TCF. On enchaîne directement le
        // briefing suivant ; après T3 on FINALISE l'attempt (`/finish`) avant
        // de push le bilan détaillé (`HistorySessionScreen` en mode `live=1`)
        // qui pollera les évaluations IA Claude.
        if (hasNext) {
          context.pushReplacement(
            withCurrentQuery(
              context,
              '/tcf/expression-ecrite/t/${widget.taskIndex + 1}',
            ),
          );
        } else {
          final attemptId = session.attempt!.id;
          await ref.read(eeSessionProvider.notifier).finishAttemptIfExam();
          if (!mounted) return;
          context.pushReplacement(
            '/tcf/expression-ecrite/sessions/$attemptId?live=1',
          );
        }
        return;
      }
      context.pushReplacement(
        withCurrentQuery(
          context,
          '/tcf/expression-ecrite/resultats/${submission.id}?taskIndex=${widget.taskIndex}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ApiClient.toApiException(e).message;
      });
    }
  }

  /// Chrono d'examen écoulé (30:00). On auto-soumet le texte courant **s'il est
  /// recevable** (mots dans [motsMin, motsMax]), sinon on ne soumet rien ;
  /// puis on finalise (module → `/finish`, full exam → `markSubDone`) et on
  /// navigue vers le bilan. Idempotent contre un double-déclenchement.
  bool _timedOut = false;
  Future<void> _handleTimeout(ProductionTaskDto task) async {
    if (_timedOut || !mounted) return;
    _timedOut = true;
    final wordCount = _countWords(_controller.text);
    final recevable = isEeWordCountWithinBounds(task, wordCount);

    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];

    if (recevable) {
      try {
        await ref.read(eeSessionProvider.notifier).submitTask(
              taskIndex: widget.taskIndex,
              texte: _controller.text,
            );
        await ref.read(eeDraftServiceProvider).clear(task.id);
      } catch (_) {
        /* soumission best-effort à l'expiration */
      }
    }
    if (!mounted) return;

    if (fullExamId != null) {
      try {
        await ref.read(fullTcfExamRepositoryProvider).markSubDone(
              parentAttemptId: fullExamId,
              epreuveWire: 'TCF_EE',
            );
      } catch (_) {/* hook auto backend fallback */}
      if (!mounted) return;
      final id = ref.read(eeSessionProvider).value?.attempt?.id;
      ref.read(eeSessionProvider.notifier).reset();
      if (id != null) ref.invalidate(fullTcfExamProvider(fullExamId));
      context.go('/tcf/examen-blanc/$fullExamId');
      return;
    }

    final attemptId = ref.read(eeSessionProvider).value?.attempt?.id;
    await ref.read(eeSessionProvider.notifier).finishAttemptIfExam();
    if (!mounted || attemptId == null) return;
    context.pushReplacement(
      '/tcf/expression-ecrite/sessions/$attemptId?live=1',
    );
  }

  /// Abandon confirmé en cours d'examen → finalise (la copie ramassée comptera
  /// les tâches manquantes à 0) puis sort. En entraînement libre, on garde le
  /// flux brouillon (pas de finish).
  Future<bool> _confirmQuitExam() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'examen ?'),
        content: const Text(
          'Votre examen sera terminé. Les tâches non rendues seront comptées comme non faites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Quitter',
              style: AppFonts.ui(weight: FontWeight.w700, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _quitExam(String fallbackRoute) async {
    if (!await _confirmQuitExam()) return;
    if (!mounted) return;
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];
    if (fullExamId != null) {
      try {
        await ref.read(fullTcfExamRepositoryProvider).markSubDone(
              parentAttemptId: fullExamId,
              epreuveWire: 'TCF_EE',
            );
      } catch (_) {/* hook auto backend fallback */}
    } else {
      await ref.read(eeSessionProvider.notifier).finishAttemptIfExam();
    }
    ref.read(eeSessionProvider.notifier).reset();
    if (!mounted) return;
    if (fullExamId != null) {
      ref.invalidate(fullTcfExamProvider(fullExamId));
    }
    context.go(fallbackRoute);
  }

  Future<void> _saveDraftAndQuit(
      BuildContext context, ProductionTaskDto task) async {
    if (_controller.text.trim().isNotEmpty) {
      await ref.read(eeDraftServiceProvider).save(task.id, _controller.text);
    }
    if (!context.mounted) return;
    if (context.canPop()) context.pop();
  }

  void _clearText(ProductionTaskDto task) {
    _controller.clear();
    ref.read(eeDraftServiceProvider).clear(task.id);
    setState(() {});
  }

  Future<void> _showConfidentialitySheet(BuildContext context) {
    FocusScope.of(context).unfocus();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ConfidentialitySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le submit on garde l'écran visible avec un loading inline sur le
    // bouton ; un écran loading plein écran ici donnerait l'illusion d'un
    // double push une fois l'écran de résultats (avec son propre loading de
    // polling) monté.
    final sessionAsync = ref.watch(eeSessionProvider);
    // Fallback back-arrow contextuel : si `canPop` est faux (deep link,
    // pushReplacement chain, etc.), on retombe sur le détail EE sauf en mode
    // examen blanc complet où on retourne au progress de l'examen.
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];
    final fallbackRoute =
        fullExamId != null ? '/tcf/examen-blanc/$fullExamId' : '/tcf/ee';
    final session = sessionAsync.value;
    final isExam = session?.isExam ?? false;
    return PopScope(
      // En examen, on intercepte le retour pour confirmer l'abandon + finaliser
      // (copie ramassée). En entraînement libre, le flux brouillon est conservé
      // (pas de PopScope bloquant).
      canPop: !isExam,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !isExam) return;
        await _quitExam(fallbackRoute);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
        appBar: ProductionAppHeader(
          title: 'Expression écrite',
          fallbackRoute: fallbackRoute,
          onBack: isExam ? () => _quitExam(fallbackRoute) : null,
          rightAction: ProductionAppHeaderInfo(
            onPressed: () => _showConfidentialitySheet(context),
          ),
        ),
        body: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBox(
            message: ApiClient.toApiException(e).message,
            onRetry: () {
              final goState = GoRouterState.of(context);
              final fullExamId = goState.uri.queryParameters['fullExamId'];
              final subAttemptId = goState.uri.queryParameters['subAttemptId'];
              if (fullExamId != null && subAttemptId != null) {
                ref
                    .read(eeSessionProvider.notifier)
                    .startInFullExam(subAttemptId: subAttemptId);
              }
            },
          ),
          data: (session) {
            final task = session.taskAt(widget.taskIndex);
            if (!session.isStarted || task == null) {
              return const Center(child: CircularProgressIndicator());
            }
            _loadDraftIfNeeded(task);
            // Chrono EE 30:00 : module → ancre backend (`attempt.startedAt` +
            // `timeLimitSeconds`) ; examen complet → ancre front
            // (`attempt.startedAt` posé à `startInFullExam`), durée 1800 s.
            final examTimer = session.isExam
                ? ExamTimer(
                    durationSeconds: session.attempt!.timeLimitSeconds ??
                        _eeExamDurationSeconds,
                    startedAt: session.attempt!.startedAt,
                    onElapsed: () => _handleTimeout(task),
                  )
                : null;
            return _Content(
              task: task,
              session: session,
              taskIndex: widget.taskIndex,
              controller: _controller,
              focusNode: _writingFocusNode,
              scrollController: _scrollController,
              wordCount: _countWords(_controller.text),
              onChanged: (v) => _onTextChanged(v, task),
              onSubmit: () => _submit(task),
              onSaveDraftAndQuit: () => _saveDraftAndQuit(context, task),
              onClear: () => _clearText(task),
              submitError: _submitError,
              submitting: _submitting,
              examTimer: examTimer,
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.task,
    required this.session,
    required this.taskIndex,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraftAndQuit,
    required this.onClear,
    required this.wordCount,
    required this.submitting,
    this.submitError,
    this.examTimer,
  });

  final ProductionTaskDto task;
  final EeSessionState session;
  final int taskIndex;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraftAndQuit;
  final VoidCallback onClear;
  final int wordCount;
  final bool submitting;
  final String? submitError;

  /// Chrono décompte d'examen (non-null en session d'examen blanc EE).
  final Widget? examTimer;

  bool get _inRange => isEeWordCountWithinBounds(task, wordCount);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductionProgressStrip(
          current: taskIndex + 1,
          total: session.totalTasks,
          niveau: task.niveauCible,
          // En entraînement libre le bandeau n'affiche que ce sous-titre :
          // le répéter dupliquerait le titre de la ConsigneCard juste en
          // dessous. On garde alors le libellé de mode par défaut.
          subtitle: session.totalTasks <= 1 ? null : task.displayTitle,
          trailing: examTimer,
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              ConsigneCard(
                key: const ValueKey('ee-consigne'),
                consigne: task.consigne,
                subTitleHero: task.displayTitle,
                subtitle:
                    'Longueur attendue : ${task.motsMin ?? 0} à ${task.motsMax ?? 0} mots',
              ),
              WritingZone(
                key: const ValueKey('ee-writing-zone'),
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                wordCount: wordCount,
                minWords: task.motsMin ?? 0,
                maxWords: task.motsMax ?? 0,
                onClear: wordCount > 0 ? onClear : null,
                minLines: 12,
              ),
              if (submitError != null) ...[
                const SizedBox(height: 4),
                _InlineError(message: submitError!),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'Valider ma rédaction',
                icon: LucideIcons.send,
                isLoading: submitting,
                onPressed: (_inRange && !submitting) ? onSubmit : null,
              ),
              // Le brouillon n'existe qu'en entraînement libre : en examen
              // chronométré, pas de "mise de côté".
              if (!session.isExam) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onSaveDraftAndQuit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.blue),
                    foregroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enregistrer le brouillon',
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(top: 8),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de démarrer la session.',
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Réessayer',
            onPressed: onRetry,
            icon: LucideIcons.refreshCw,
          ),
        ],
      ),
    );
  }
}

class _ConfidentialitySheet extends StatelessWidget {
  const _ConfidentialitySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    size: 18,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confidentialité de votre rédaction',
                    style: AppFonts.display(
                      size: 18,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "Votre rédaction est confidentielle et sera analysée par notre IA "
              "pour vous fournir un feedback détaillé. Le contenu n'est pas "
              "partagé avec des tiers, n'est pas utilisé pour entraîner nos "
              "modèles, et reste accessible uniquement depuis votre compte.",
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.muted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'J\'ai compris',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
