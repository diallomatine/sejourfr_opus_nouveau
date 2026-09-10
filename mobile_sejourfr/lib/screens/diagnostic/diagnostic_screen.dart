import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/analytics/analytics.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/premium_lock.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/audio_recorder_service.dart';
import 'diagnostic_controller.dart';
import 'diagnostic_variant.dart';
import 'widgets/diagnostic_account_gate.dart';
import 'widgets/diagnostic_analysis.dart';
import 'widgets/diagnostic_common.dart';
import 'widgets/diagnostic_intro.dart';
import 'widgets/diagnostic_oral.dart';
import 'widgets/diagnostic_report_labels.dart';
import 'widgets/diagnostic_result.dart';
import 'widgets/diagnostic_sync.dart';
import 'widgets/diagnostic_written.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  /// Fenêtre d'écriture avant sauvegarde locale : assez courte pour qu'un kill
  /// de l'app ne coûte qu'une phrase, assez longue pour ne pas écrire à chaque
  /// frappe.
  static const _autosaveDelay = Duration(seconds: 2);

  final _writingController = TextEditingController();
  late final RecordingController _recordingController;
  Timer? _autosave;
  int _wordCount = 0;
  bool _resultViewedTracked = false;
  bool _eeStartedTracked = false;
  bool _eoStartedTracked = false;
  bool _accountRequiredTracked = false;
  bool _writingHydrated = false;

  /// Accès TCF du compte, lu **au moment du rendu** : un achat conclu pendant
  /// que l'écran est ouvert doit lever les cadenas sans le remonter. Un visiteur
  /// n'a pas d'accès — et n'atteint de toute façon jamais l'écran de résultat.
  bool get _hasTcfAccess {
    final auth = ref.watch(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.hasTcf;
  }

  @override
  void initState() {
    super.initState();
    _recordingController = ref.read(recordingControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(diagnosticControllerProvider.notifier).loadCurrent(),
      );
      unawaited(_recordingController.cancel());
    });
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _writingController.dispose();
    unawaited(_recordingController.cancel());
    super.dispose();
  }

  /// La variante choisie, telle qu'elle est **au moment de l'événement**.
  /// Elle n'est jamais persistée : c'est une intention de front, et la seule
  /// chose honnête à en dire est ce que le candidat avait sélectionné ici.
  AnalyticsDiagnosticType get _diagnosticType =>
      ref.read(diagnosticVariantProvider).isComplet
          ? AnalyticsDiagnosticType.complete
          : AnalyticsDiagnosticType.rapid;

  /// Émission best-effort — jamais attendue, jamais bloquante.
  void _track(AnalyticsEvent event) {
    ref.read(analyticsServiceProvider).track(
          event,
          path: AnalyticsPath.diagnostic,
          diagnosticType: _diagnosticType,
        );
  }

  DiagnosticController get _controller =>
      ref.read(diagnosticControllerProvider.notifier);

  // ---------------------------------------------------------------------------
  // Écrit
  // ---------------------------------------------------------------------------

  /// Réinjecte la production locale dans la zone de saisie : c'est ce qui fait
  /// qu'un visiteur revenu après un kill de l'app retrouve son texte.
  void _hydrateWriting(DiagnosticFlowState state) {
    if (_writingHydrated) return;
    final text = state.draft?.writtenText;
    if (text == null || text.isEmpty || _writingController.text.isNotEmpty) {
      return;
    }
    _writingHydrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _writingController.text = text;
      setState(() => _wordCount = _countWords(text));
    });
  }

  void _onWritingChanged(String text, {required bool isGuest}) {
    setState(() => _wordCount = _countWords(text));
    if (!isGuest) return;
    _autosave?.cancel();
    _autosave = Timer(_autosaveDelay, () {
      unawaited(_controller.autosaveGuestWritten(text));
    });
  }

  Future<void> _submitWritten({required bool isGuest}) async {
    FocusScope.of(context).unfocus();
    _autosave?.cancel();
    final text = _writingController.text.trim();
    final submitted = isGuest
        ? await _controller.submitGuestWritten(text)
        : await _controller.submitWritten(text);
    if (submitted) _track(AnalyticsEvent.diagnosticEeCompleted);
  }

  // ---------------------------------------------------------------------------
  // Oral
  // ---------------------------------------------------------------------------

  int _maxOralSeconds(DiagnosticFlowState state) =>
      (state.isGuest
          ? state.subjects?.oral?.durationMaxSeconds
          : state.journey?.oral?.durationMaxSeconds) ??
      180;

  Future<void> _startRecording() async {
    final status = await _recordingController.requestPermission();
    if (!mounted || status != PermissionStatus.granted) return;
    await _recordingController.start(
      maxDuration: Duration(
        seconds: _maxOralSeconds(ref.read(diagnosticControllerProvider)),
      ),
    );
  }

  Future<void> _submitOral({required bool isGuest}) async {
    final recording = ref.read(recordingControllerProvider);
    final path = recording.filePath;
    if (path == null) return;
    final submitted = isGuest
        ? await _controller.submitGuestOral(
            audioFile: File(path),
            mimeType: recording.fileMime,
          )
        : await _controller.submitOral(
            audioFile: File(path),
            mimeType: recording.fileMime,
          );
    if (!submitted) return;
    _track(AnalyticsEvent.diagnosticEoCompleted);
    // En invité, l'enregistrement a déjà été recopié dans le dossier de
    // l'application : effacer le fichier temporaire ne coûte rien.
    await _recordingController.cancel();
  }

  // ---------------------------------------------------------------------------
  // Compte
  // ---------------------------------------------------------------------------

  void _openRegister() {
    context.push(authFlowLocation(AppRoutes.register, AppRoutes.diagnostic));
  }

  void _openLogin() {
    context.push(loginLocationFor(AppRoutes.diagnostic));
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer vos réponses locales ?'),
        content: const Text(
          'Votre texte et votre enregistrement seront effacés de ce '
          'téléphone. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Conserver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Supprimer',
              style: AppFonts.ui(
                weight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.discardLocalProductions();
  }

  Future<void> _confirmBack() async {
    if (ref.read(diagnosticControllerProvider).isSubmitting) return;
    final recording = ref.read(recordingControllerProvider);
    if (recording.canStop) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Quitter l’enregistrement ?'),
          content: const Text('L’enregistrement en cours sera perdu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continuer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Quitter',
                style: AppFonts.ui(
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    await _recordingController.cancel();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticControllerProvider);
    final recording = ref.watch(recordingControllerProvider);
    final objective = ref.watch(userTargetLevelProvider)?.wire;
    // Une intention de front, jamais persistée : elle ne change pas le parcours
    // joué, seulement ce que le bilan enchaîne (cf. `diagnostic_variant.dart`).
    final variant = ref.watch(diagnosticVariantProvider);

    _hydrateWriting(state);
    // 🛑 « Diagnostic terminé » n'est PAS un événement : il se lit sur
    // `diagnostic_sessions.status`. On ne crée jamais une seconde vérité.
    //
    // Lu ici plutôt que dans le `ref.listen` ci-dessous : celui-ci ne se
    // déclenche que sur un CHANGEMENT, donc une session reprise qui s'ouvre
    // directement sur l'écrit ne l'aurait jamais franchi.
    _trackStepReached(state);

    ref.listen<DiagnosticFlowState>(diagnosticControllerProvider,
        (previous, next) {
      _hydrateWriting(next);
      _trackStepReached(next);
      if (!_resultViewedTracked &&
          next.journey?.nextStep == DiagnosticStep.result &&
          next.journey?.result != null) {
        _resultViewedTracked = true;
        _track(AnalyticsEvent.diagnosticReportViewed);
      }
    });

    final recordingActive = recording.canStop;
    return PopScope(
      canPop: !recordingActive && !state.isSubmitting && !state.isSyncing,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                // Une fois le rapport rendu, l'en-tête EST le titre de la
                // maquette (« Votre rapport ») : l'écran a cessé d'être un
                // parcours, il est devenu un document. C'est ce qui permet au
                // corps de commencer directement par la carte de niveau, sans
                // badge ni titre-phrase.
                title: _showsReport(state)
                    ? kDiagnosticReportTitle
                    : 'Diagnostic TCF',
                sub: _headerSub(state, variant),
                onBack:
                    state.isSubmitting || state.isSyncing ? null : _confirmBack,
              ),
              Expanded(
                child: _content(
                  state: state,
                  recording: recording,
                  objective: objective,
                  variant: variant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content({
    required DiagnosticFlowState state,
    required RecordingState recording,
    required String? objective,
    required DiagnosticVariant variant,
  }) {
    if (state.isGuest) {
      return _guestContent(
        state: state,
        recording: recording,
        variant: variant,
      );
    }

    if (state.isSyncing) return DiagnosticSendingView(stage: state.syncStage);
    if (state.canRetrySync) {
      return DiagnosticSyncFailedView(
        isBusy: state.isSyncing,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.syncLocalProductions()),
      );
    }
    if (state.noticeMessage != null) {
      return DiagnosticAlreadyDoneView(
        message: state.noticeMessage!,
        onContinue: _controller.dismissNotice,
        onDiscard: () => unawaited(_confirmDiscard()),
      );
    }

    final journey = state.journey;
    if (journey == null) {
      return _InitialState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.loadCurrent()),
      );
    }

    if (journey.status == DiagnosticJourneyStatus.failed ||
        journey.nextStep == DiagnosticStep.analysis) {
      return DiagnosticAnalysisView(
        journey: journey,
        isBusy: state.isSubmitting || state.isLoading,
        errorMessage: state.errorMessage,
        onRefresh: () => unawaited(_controller.refreshDetail()),
        onRetry: () => unawaited(_controller.retryAnalysis()),
        onOpenPlan: () => context.go(AppRoutes.plan),
      );
    }
    return switch (journey.nextStep) {
      DiagnosticStep.presentation => DiagnosticIntro(
          isStarting: state.isSubmitting,
          errorMessage: state.errorMessage,
          // Sans session, le serveur n'attache aucun sujet au parcours : les
          // mesures viennent alors du catalogue public, chargé en repli.
          written: journey.written ?? state.subjects?.written,
          oral: journey.oral ?? state.subjects?.oral,
          variant: variant,
          onVariantChanged: _onVariantChanged,
          onStart: () => unawaited(_startAuthenticated()),
        ),
      DiagnosticStep.written when journey.written != null =>
        DiagnosticWrittenStep(
          exercise: journey.written!,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onChanged: (text) => _onWritingChanged(text, isGuest: false),
          onSubmit: () => unawaited(_submitWritten(isGuest: false)),
        ),
      DiagnosticStep.oral when journey.oral != null => DiagnosticOralStep(
          exercise: journey.oral!,
          recording: recording,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onStart: () => unawaited(_startRecording()),
          onStop: () => unawaited(_recordingController.stop()),
          onReset: () => unawaited(_recordingController.cancel()),
          onOpenSettings: () =>
              unawaited(_recordingController.openSystemSettings()),
          onSubmit: () => unawaited(_submitOral(isGuest: false)),
        ),
      DiagnosticStep.result when journey.result != null => DiagnosticResultView(
          result: journey.result!,
          objective: objective,
          // Le serveur reste l'arbitre du verrou : on ne lit ici que l'accès
          // déjà résolu sur le compte, jamais une règle « étape 1 ouverte »
          // réécrite côté app.
          hasTcfAccess: _hasTcfAccess,
          variant: variant,
          onOpenPlan: () => context.go(AppRoutes.plan),
          // Même feuille que le Plan et les Compétences : un seul parcours
          // d'achat, jamais un second.
          onSubscribe: () {
            ref.read(analyticsServiceProvider).track(
                  AnalyticsEvent.premiumCtaClicked,
                  path: AnalyticsPath.diagnostic,
                  ctaLocation: AnalyticsCtaLocation.diagnosticReport,
                );
            unawaited(showTcfLockPaywall(context));
          },
        ),
      _ => _InitialState(
          isLoading: state.isLoading,
          errorMessage:
              state.errorMessage ?? 'Cette étape n’est pas encore disponible.',
          onRetry: () => unawaited(_controller.refreshDetail()),
        ),
    };
  }

  /// Parcours invité : les deux productions se font avant tout compte, et
  /// vivent sur le disque de l'appareil jusqu'à l'inscription.
  Widget _guestContent({
    required DiagnosticFlowState state,
    required RecordingState recording,
    required DiagnosticVariant variant,
  }) {
    final subjects = state.subjects;
    if (subjects == null) {
      return _InitialState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.loadCurrent()),
      );
    }
    return switch (state.guestStep) {
      DiagnosticGuestStep.presentation => DiagnosticIntro(
          isStarting: false,
          errorMessage: state.errorMessage,
          written: subjects.written,
          oral: subjects.oral,
          isGuest: true,
          variant: variant,
          onVariantChanged: _onVariantChanged,
          onStart: _startGuest,
        ),
      DiagnosticGuestStep.written => DiagnosticWrittenStep(
          exercise: subjects.written,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage ?? state.noticeMessage,
          onChanged: (text) => _onWritingChanged(text, isGuest: true),
          onSubmit: () => unawaited(_submitWritten(isGuest: true)),
        ),
      // 🛑 L'étape orale ne se rend que si ce diagnostic en porte une (L3).
      // Sans sujet, le contrôleur a déjà envoyé le visiteur au compte : ce cas
      // n'est donc pas atteignable, et le repli le dit sans planter.
      DiagnosticGuestStep.oral when subjects.oral != null =>
        DiagnosticOralStep(
          exercise: subjects.oral!,
          recording: recording,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          // Rien ne part vers le serveur ici : l'enregistrement rejoint la
          // production locale, l'analyse ne démarre qu'après le compte.
          submitLabel: 'Analyser mes réponses',
          onStart: () => unawaited(_startRecording()),
          onStop: () => unawaited(_recordingController.stop()),
          onReset: () => unawaited(_recordingController.cancel()),
          onOpenSettings: () =>
              unawaited(_recordingController.openSystemSettings()),
          onSubmit: () => unawaited(_submitOral(isGuest: true)),
        ),
      // Le compte est aussi le repli de `oral` sans sujet oral : c'est là que
      // le contrôleur envoie le visiteur, et l'écran doit dire la même chose.
      DiagnosticGuestStep.accountRequired ||
      DiagnosticGuestStep.oral =>
        DiagnosticAccountGate(
          errorMessage: state.errorMessage,
          noticeMessage: state.noticeMessage,
          variantNote: diagnosticVariantAccountNote(variant),
          onRegister: _openRegister,
          onLogin: _openLogin,
        ),
    };
  }

  /// Une production **commencée**, c'est son écran atteint — invité comme
  /// connecté, les deux parcours jouent les deux mêmes exercices. Une seule
  /// émission par lancement : l'écran se reconstruit à chaque frappe.
  void _trackStepReached(DiagnosticFlowState state) {
    final onWritten = state.isGuest
        ? state.guestStep == DiagnosticGuestStep.written
        : state.journey?.nextStep == DiagnosticStep.written;
    final onOral = state.isGuest
        ? state.guestStep == DiagnosticGuestStep.oral
        : state.journey?.nextStep == DiagnosticStep.oral;
    if (onWritten && !_eeStartedTracked) {
      _eeStartedTracked = true;
      _track(AnalyticsEvent.diagnosticEeStarted);
    }
    if (onOral && !_eoStartedTracked) {
      _eoStartedTracked = true;
      _track(AnalyticsEvent.diagnosticEoStarted);
    }
    // L'écran qui demande un compte, les deux productions déjà faites —
    // **la** mesure de conversion du parcours invité. N'existe que pour un
    // visiteur : un compte déjà créé n'a plus de `guestStep` à atteindre.
    if (state.isGuest &&
        state.guestStep == DiagnosticGuestStep.accountRequired &&
        !_accountRequiredTracked) {
      _accountRequiredTracked = true;
      _track(AnalyticsEvent.diagnosticAccountRequired);
    }
  }

  Future<void> _startAuthenticated() async {
    final started = await _controller.startOrResume();
    if (started) _track(AnalyticsEvent.diagnosticStarted);
  }

  void _startGuest() {
    _controller.startGuest();
    _track(AnalyticsEvent.diagnosticStarted);
  }

  /// Le choix du candidat, gardé **en mémoire de processus** : aucune ligne en
  /// base, aucun champ envoyé au serveur, et donc rien à nettoyer si l'app se
  /// ferme — on retombe alors sur le diagnostic rapide.
  void _onVariantChanged(DiagnosticVariant variant) =>
      ref.read(diagnosticVariantProvider.notifier).state = variant;

  /// Le rapport est-il à l'écran ? Il ne l'est qu'une fois le parcours
  /// authentifié arrivé à son terme — jamais en invité, jamais en cours
  /// d'analyse.
  bool _showsReport(DiagnosticFlowState state) =>
      !state.isGuest &&
      !state.isSyncing &&
      state.noticeMessage == null &&
      state.journey?.nextStep == DiagnosticStep.result &&
      state.journey?.result != null;

  String _headerSub(DiagnosticFlowState state, DiagnosticVariant variant) {
    if (state.isSyncing) return 'Envoi de vos réponses';
    if (_showsReport(state)) {
      return _hasTcfAccess
          ? kDiagnosticReportSubPremium
          : kDiagnosticReportSubFree;
    }
    // Le sous-titre de la présentation suit la variante, comme la pilule de
    // budget de l'écran : deux chiffres différents pour le même écran se
    // liraient comme une contradiction.
    if (state.isGuest) {
      return switch (state.guestStep) {
        DiagnosticGuestStep.presentation => diagnosticVariantHeaderSub(
            variant,
            state.subjects?.written,
            state.subjects?.oral,
          ),
        DiagnosticGuestStep.written => 'Étape 1 sur 2 · Écrit',
        DiagnosticGuestStep.oral => 'Étape 2 sur 2 · Oral',
        DiagnosticGuestStep.accountRequired => 'Analyser mes réponses',
      };
    }
    final journey = state.journey;
    if (journey == null || journey.nextStep == DiagnosticStep.presentation) {
      return diagnosticVariantHeaderSub(
        variant,
        journey?.written ?? state.subjects?.written,
        journey?.oral ?? state.subjects?.oral,
      );
    }
    return _stepLabel(journey.nextStep);
  }

  static int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  static String _stepLabel(DiagnosticStep step) => switch (step) {
        DiagnosticStep.written => 'Étape 1 sur 2 · Écrit',
        DiagnosticStep.oral => 'Étape 2 sur 2 · Oral',
        DiagnosticStep.analysis => 'Analyse personnalisée',
        // Le rapport passe par `_headerSub`, qui distingue l'estimation
        // gratuite du rapport complet ; cette entrée ne sert plus que de repli.
        DiagnosticStep.result => kDiagnosticReportSubFree,
        DiagnosticStep.presentation => 'Présentation',
      };
}

class _InitialState extends StatelessWidget {
  const _InitialState({
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && errorMessage == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              if (errorMessage != null)
                DiagnosticErrorBanner(message: errorMessage!),
              const SizedBox(height: 14),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.soft,
                isLoading: isLoading,
                onPressed: isLoading ? null : onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
