import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'draft_service.dart';
import 'ee_session_controller.dart';
import 'widgets/confidential_note.dart';
import 'widgets/consigne_card.dart';
import 'widgets/criteres_card.dart';
import 'widgets/evaluation_loading_view.dart';
import 'widgets/mots_card.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';
import 'widgets/tips_card.dart';
import 'widgets/writing_zone.dart';

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
  Timer? _autoSaveTimer;
  bool _submitting = false;
  String? _submitError;
  bool _draftLoaded = false;
  String? _loadedForTaskId;

  /// Conseils generiques EE par numero de tache (texte calque sur le mockup).
  static const _tipsByTache = <int, List<String>>{
    1: [
      'Adresse-toi directement au destinataire',
      'Sois clair sur les 2-3 informations a transmettre',
      'Utilise un ton adapte (amical, formel)',
      'Relis ton message avant de valider',
    ],
    2: [
      'Raconte une experience reelle et interessante',
      "Organise ton recit (debut, evenements, fin)",
      'Utilise des connecteurs temporels',
      'Exprime tes sentiments et tes reactions',
      'Relis ton texte avant de valider',
    ],
    3: [
      'Donne une opinion claire des le debut',
      'Appuie ta position avec 2 arguments concrets',
      'Illustre par un exemple personnel ou observe',
      'Conclus en reformulant ton avis',
    ],
  };

  static const _criteresEE = [
    'Pertinence et developpement du contenu',
    'Organisation et coherence du texte',
    'Richesse et precision du vocabulaire',
    'Correction grammaticale',
    'Orthographe et ponctuation',
  ];

  String _niveauForUser() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      final tp = auth.user.targetProcedure;
      if (tp != null) return tp.tcfLevel;
    }
    return 'B1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eeSessionProvider.notifier).start(niveau: _niveauForUser());
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
      context.pushReplacement(
        '/tcf/expression-ecrite/resultats/${submission.id}?taskIndex=${widget.taskIndex}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ApiClient.toApiException(e).message;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_submitting) {
      return const Scaffold(
        body: EvaluationLoadingView(includeTranscription: false),
      );
    }

    final sessionAsync = ref.watch(eeSessionProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: 'Expression ecrite',
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref
              .read(eeSessionProvider.notifier)
              .start(niveau: _niveauForUser()),
        ),
        data: (session) {
          final task = session.taskAt(widget.taskIndex);
          if (!session.isStarted || task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _loadDraftIfNeeded(task);
          return _Content(
            task: task,
            session: session,
            taskIndex: widget.taskIndex,
            controller: _controller,
            wordCount: _countWords(_controller.text),
            onChanged: (v) => _onTextChanged(v, task),
            onSubmit: () => _submit(task),
            onSaveDraftAndQuit: () => _saveDraftAndQuit(context, task),
            onClear: () => _clearText(task),
            submitError: _submitError,
            tips: _tipsByTache[task.tacheNumero] ?? const <String>[],
            criteres: _criteresEE,
          );
        },
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
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraftAndQuit,
    required this.onClear,
    required this.wordCount,
    required this.tips,
    required this.criteres,
    this.submitError,
  });

  final ProductionTaskDto task;
  final EeSessionState session;
  final int taskIndex;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraftAndQuit;
  final VoidCallback onClear;
  final int wordCount;
  final List<String> tips;
  final List<String> criteres;
  final String? submitError;

  bool get _inRange =>
      task.motsMin != null &&
      task.motsMax != null &&
      wordCount >= task.motsMin! &&
      wordCount <= task.motsMax!;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductionProgressStrip(
          current: taskIndex + 1,
          total: session.totalTasks,
          niveau: task.niveauCible,
          subtitle: task.displayTitle,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            children: [
              ConsigneCard(
                consigne: task.consigne,
                subTitleHero: task.displayTitle,
                subtitle:
                    'Longueur attendue : ${task.motsMin ?? 0} a ${task.motsMax ?? 0} mots',
              ),
              if (tips.isNotEmpty) TipsCard(tips: tips, title: 'Conseils pour reussir'),
              MotsCard(
                current: wordCount,
                min: task.motsMin ?? 0,
                max: task.motsMax ?? 0,
              ),
              WritingZone(
                controller: controller,
                onChanged: onChanged,
                wordCount: wordCount,
                minWords: task.motsMin ?? 0,
                maxWords: task.motsMax ?? 0,
                onClear: wordCount > 0 ? onClear : null,
              ),
              CriteresCard(criteres: criteres),
              if (submitError != null) ...[
                const SizedBox(height: 4),
                _InlineError(message: submitError!),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.line2, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                AppButton(
                  label: 'Valider ma redaction',
                  icon: Icons.send_rounded,
                  onPressed: _inRange ? onSubmit : null,
                ),
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
                    style: AppFonts.jakarta(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const ConfidentialNote(
                  text:
                      "Votre redaction est confidentielle et sera analysee par notre IA pour vous fournir un feedback detaille.",
                ),
              ],
            ),
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
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.jakarta(size: 13, color: AppColors.red, height: 1.4),
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
          const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de demarrer la session.',
            style: AppFonts.jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Reessayer',
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }
}
