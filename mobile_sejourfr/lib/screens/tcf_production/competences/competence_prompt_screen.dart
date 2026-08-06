import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/utils/start_failure.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../core/widgets/progress_track.dart';
import '../../../core/widgets/screen_header.dart';
import '../audio_recorder_service.dart';
import '../tcf_production_module.dart';
import '../widgets/writing_zone.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import 'widgets/analysis_toggle.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';
import 'widgets/criterion_highlight.dart';
import 'widgets/self_evaluation_picker.dart';
import 'widgets/skill_recorder_panel.dart';

/// Garde anti-abus **côté serveur** : au-delà, la soumission est refusée. Il
/// est signalé au candidat mais ne **bloque pas** la saisie (règle 15 de la
/// spec : une borne de longueur avertit, elle n'interdit jamais).
const int _kMaxWords = 400;

/// Niveau 5 du parcours : un petit sujet.
///
/// Reprend la carte d'exercice du prototype : badge « Une compétence · un
/// critère » + « Petit sujet i/N », titre d'intention, phrase d'objectif,
/// **critère avant la production** (§13.1), aucune référence ici (§13.2),
/// tipline ambre en pied, et une validation atteignable sans scroll
/// interminable (§13.10, `FixedActionBar`).
class CompetencePromptScreen extends ConsumerWidget {
  const CompetencePromptScreen({
    super.key,
    required this.module,
    required this.skillId,
    required this.promptId,
  });

  final TcfProductionModule module;
  final String skillId;
  final String promptId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(competenceDetailPath(module, skillId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(skillPromptProvider(promptId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => Column(
            children: [
              ScreenHeader(title: 'Sujet', onBack: () => _back(context)),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (e, _) => Column(
            children: [
              ScreenHeader(title: 'Sujet', onBack: () => _back(context)),
              Expanded(
                child: ProductionErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(skillPromptProvider(promptId)),
                ),
              ),
            ],
          ),
          data: (prompt) => _PromptView(
            module: module,
            skillId: skillId,
            prompt: prompt,
            onBack: () => _back(context),
          ),
        ),
      ),
    );
  }
}

class _PromptView extends ConsumerStatefulWidget {
  const _PromptView({
    required this.module,
    required this.skillId,
    required this.prompt,
    required this.onBack,
  });

  final TcfProductionModule module;
  final String skillId;
  final SkillPromptDto prompt;
  final VoidCallback onBack;

  @override
  ConsumerState<_PromptView> createState() => _PromptViewState();
}

class _PromptViewState extends ConsumerState<_PromptView> {
  final TextEditingController _controller = TextEditingController();
  SkillSelfEvaluation? _selfEvaluation;

  /// `null` = pas encore choisi par l'utilisateur → on suit le quota.
  bool? _requestAnalysis;
  bool _loadingLastProduction = false;

  bool get _isEo => widget.prompt.section.isEo;

  Color get _accent => widget.module.accent;

  @override
  void initState() {
    super.initState();
    if (_isEo) {
      // On repart d'un enregistreur au repos : un `finished` résiduel d'un
      // autre sujet ferait croire à une réponse déjà capturée.
      unawaited(ref.read(recordingControllerProvider.notifier).cancel());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _wordCount {
    final words = _controller.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return words.length;
  }

  bool _analysisRequested(SkillAnalysisQuotaDto? quota) {
    if (quota != null && !quota.canAnalyse) return false;
    return _requestAnalysis ?? (quota?.canAnalyse ?? true);
  }

  // ---------------------------------------------------------------------------
  // Reprise d'une production précédente (§13.5)
  // ---------------------------------------------------------------------------

  Future<void> _resumeLastProduction(String attemptId) async {
    setState(() => _loadingLastProduction = true);
    try {
      final attempt = await ref.read(skillAttemptProvider(attemptId).future);
      if (!mounted) return;
      final text = attempt.writtenProduction;
      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune réponse écrite à reprendre.')),
        );
        return;
      }
      _controller.text = text;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingLastProduction = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Capture orale
  // ---------------------------------------------------------------------------

  Future<void> _startRecording() async {
    final notifier = ref.read(recordingControllerProvider.notifier);
    final status = await notifier.requestPermission();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Le micro est nécessaire pour t\'enregistrer. Autorise-le dans les réglages.',
          ),
          backgroundColor: AppColors.red,
          action: SnackBarAction(
            label: 'Réglages',
            textColor: AppColors.white,
            onPressed: () => unawaited(notifier.openSystemSettings()),
          ),
        ),
      );
      return;
    }
    // Plafond aligné sur la borne serveur (180 s) : la durée conseillée du
    // sujet reste une indication, elle ne coupe pas la parole du candidat.
    await notifier.start(maxDuration: const Duration(seconds: 180));
  }

  /// « Effacer » du prototype : on repart d'une production vide, texte ou
  /// capture selon l'épreuve.
  void _clear() {
    if (_isEo) {
      unawaited(ref.read(recordingControllerProvider.notifier).cancel());
    } else {
      _controller.clear();
    }
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Soumission
  // ---------------------------------------------------------------------------

  Future<void> _submit(SkillAnalysisQuotaDto? quota) async {
    final prompt = widget.prompt;
    final notifier = ref.read(skillSubmissionProvider(prompt.id).notifier);
    final analyse = _analysisRequested(quota);

    SkillAttemptDto? attempt;
    if (_isEo) {
      final recording = ref.read(recordingControllerProvider);
      final path = recording.filePath;
      if (path == null) return;
      attempt = await notifier.submitAudio(
        audioFile: File(path),
        durationSec: recording.elapsed.inSeconds.clamp(1, 180),
        requestAnalysis: analyse,
        selfEvaluation: _selfEvaluation,
        mimeType: recording.fileMime,
      );
    } else {
      attempt = await notifier.submitText(
        texte: _controller.text.trim(),
        requestAnalysis: analyse,
        selfEvaluation: _selfEvaluation,
      );
    }

    if (!mounted) return;
    if (attempt == null) {
      final error = ref.read(skillSubmissionProvider(prompt.id)).error;
      if (error != null) showPaywallOrError(context, error);
      return;
    }

    // Le statut du sujet et le quota viennent de changer : on invalide avant
    // de naviguer pour que la liste sous-jacente soit juste au retour (§13.3).
    ref.invalidate(skillAnalysisQuotaProvider);
    ref.invalidate(skillPromptProvider(prompt.id));
    ref.invalidate(skillDetailProvider(prompt.skillId));
    if (_isEo) {
      unawaited(ref.read(recordingControllerProvider.notifier).cancel());
    }
    context.pushReplacement(
      competenceResultPath(widget.module, attempt.id),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final quota = ref.watch(skillAnalysisQuotaProvider).valueOrNull;
    final recording = ref.watch(recordingControllerProvider);
    final submission = ref.watch(skillSubmissionProvider(prompt.id));

    final hasProduction = _isEo
        ? recording.isFinished
        : _controller.text.trim().isNotEmpty;
    // Avertissement, pas verrou : le plafond de 400 mots est un garde-fou
    // serveur, il n'a pas à empêcher la validation côté client.
    final overCap = !_isEo && _wordCount > _kMaxWords;

    return Column(
      children: [
        ScreenHeader(
          title: prompt.title,
          sub: prompt.taskTitle,
          onBack: widget.onBack,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _Breadcrumb(prompt: prompt, accent: _accent),
              const SizedBox(height: 12),
              _SkillProgressBar(
                skillId: prompt.skillId,
                total: prompt.skillPromptCount,
                accent: _accent,
              ),
              if (prompt.attemptCount > 0 && prompt.lastAttemptId != null) ...[
                const SizedBox(height: 14),
                _AlreadyTreatedBanner(
                  prompt: prompt,
                  accent: _accent,
                  busy: _loadingLastProduction,
                  // Libellés fixés par le contrat, identiques au web : en EO on
                  // ouvre la dernière réponse pour la réécouter, en EE on la
                  // recharge dans la zone d'écriture.
                  actionLabel: _isEo
                      ? 'Écouter ma dernière réponse'
                      : 'Reprendre ma réponse',
                  actionIcon:
                      _isEo ? LucideIcons.headphones : LucideIcons.rotateCcw,
                  onAction: () {
                    final id = prompt.lastAttemptId!;
                    if (_isEo) {
                      context.push(
                        competenceResultPath(widget.module, id),
                      );
                    } else {
                      unawaited(_resumeLastProduction(id));
                    }
                  },
                ),
              ],
              const SizedBox(height: 14),
              _ExerciseCard(
                children: [
                  _ExerciseHead(prompt: prompt, accent: _accent),
                  const SizedBox(height: 15),
                  Text(
                    _isEo
                        ? 'Enregistre ta propre réponse.'
                        : 'Produis ta propre réponse.',
                    style: AppFonts.display(size: 20, height: 1.26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    "L'objectif n'est pas d'écrire une réponse parfaite, mais "
                    'de montrer clairement la compétence travaillée.',
                    style: AppFonts.ui(
                      size: 12,
                      height: 1.48,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Y8 — le critère AVANT la production (§13.1). Il précède le
                  // contexte, la consigne et la zone de saisie.
                  CriterionHighlight(
                    criterion: prompt.uniqueCriterion,
                    accent: _accent,
                  ),
                  const SizedBox(height: 15),
                  _ContextBox(
                    label: 'Petit sujet',
                    text: prompt.context,
                  ),
                  const SizedBox(height: 11),
                  _ContextBox(
                    label: 'Consigne',
                    text: prompt.instruction,
                  ),
                  const SizedBox(height: 11),
                  ConstraintChips(labels: _constraintLabels(prompt)),
                  if (prompt.skillDescription.trim().isNotEmpty) ...[
                    const SizedBox(height: 11),
                    WhyThisExercise(
                      text: prompt.skillDescription,
                      accent: _accent,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _EditorHead(
                    title: 'Ta production',
                    hint: _isEo
                        ? 'Parle sans consulter les exemples'
                        : 'Écris sans consulter les exemples',
                  ),
                  const SizedBox(height: 8),
                  if (_isEo)
                    SkillRecorderPanel(
                      state: recording,
                      accent: _accent,
                      recommendedSeconds: prompt.recommendedDurationSeconds,
                      onStart: () => unawaited(_startRecording()),
                      onStop: () => unawaited(
                        ref.read(recordingControllerProvider.notifier).stop(),
                      ),
                      onReset: () => unawaited(
                        ref.read(recordingControllerProvider.notifier).cancel(),
                      ),
                    )
                  else
                    WritingZone(
                      controller: _controller,
                      onChanged: (_) => setState(() {}),
                      wordCount: _wordCount,
                      minWords: prompt.recommendedMinWords ?? 30,
                      maxWords: prompt.recommendedMaxWords ?? 60,
                      title: 'Ta réponse',
                      hint: 'Écris ta réponse ici…',
                      minLines: 8,
                      accent: _accent,
                      onClear: _clear,
                    ),
                  if (overCap) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Au-delà de $_kMaxWords mots, la correction peut être '
                      'refusée. Ce sujet se traite en quelques phrases.',
                      style: AppFonts.ui(
                        size: 11.5,
                        height: 1.4,
                        color: AppColors.amberDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SelfEvaluationPicker(
                    value: _selfEvaluation,
                    accent: _accent,
                    onChanged: (v) => setState(() => _selfEvaluation = v),
                  ),
                  const SizedBox(height: 12),
                  AnalysisToggle(
                    value: _analysisRequested(quota),
                    quota: quota,
                    accent: _accent,
                    onChanged: (v) => setState(() => _requestAnalysis = v),
                    onLockedTap: () => showPaywallSheet(context),
                  ),
                  const SizedBox(height: 11),
                  // M5 — sans cette ligne, rien n'explique au candidat
                  // pourquoi les références restent masquées (§13.2).
                  const ProductionTipline(
                    lead: 'Important :',
                    body: 'Les exemples de référence et l\'analyse '
                        'apparaissent seulement après ta production.',
                  ),
                ],
              ),
            ],
          ),
        ),
        FixedActionBar(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Valider et comparer',
                  icon: LucideIcons.check,
                  variant: widget.module.isEo
                      ? AppButtonVariant.accent
                      : AppButtonVariant.primary,
                  isLoading: submission.isLoading,
                  onPressed: hasProduction && !submission.isLoading
                      ? () => unawaited(_submit(quota))
                      : null,
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 108,
                child: AppButton(
                  label: 'Effacer',
                  variant: AppButtonVariant.outline,
                  onPressed: hasProduction ? _clear : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _constraintLabels(SkillPromptDto prompt) {
    final labels = <String>[];
    if (_isEo) {
      final seconds = prompt.recommendedDurationSeconds;
      if (seconds != null) labels.add('≃ $seconds secondes');
    } else {
      final min = prompt.recommendedMinWords;
      final max = prompt.recommendedMaxWords;
      if (min != null && max != null) labels.add('≃ $min à $max mots');
    }
    labels.add(prompt.difficultyLevel.label);
    labels.add('Un seul critère');
    return labels;
  }
}

/// Carte d'exercice du prototype (`.exercise`) : blanche, `radius 28`,
/// `padding 18`, ombre marquée. Tout l'exercice y vit.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// `.exercise-top` : « Une compétence · un critère » + « Petit sujet i/N ».
class _ExerciseHead extends StatelessWidget {
  const _ExerciseHead({required this.prompt, required this.accent});

  final SkillPromptDto prompt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = prompt.skillPromptCount;
    final step = total <= 0
        ? 'Petit sujet ${prompt.displayOrder}'
        : 'Petit sujet ${prompt.displayOrder}/$total';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.target, size: 12, color: accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Une compétence · un critère',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(
                      size: 10,
                      weight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            step,
            style: AppFonts.ui(
              size: 10,
              weight: FontWeight.w900,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

/// `.context` du prototype : encadré neutre, label en petites capitales.
class _ContextBox extends StatelessWidget {
  const _ContextBox({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.label(size: 10, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(text, style: AppFonts.ui(size: 13, height: 1.5)),
        ],
      ),
    );
  }
}

/// `.editor-head` : intitulé de la zone de production + rappel de la règle du
/// jeu (produire avant de comparer).
class _EditorHead extends StatelessWidget {
  const _EditorHead({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppFonts.ui(size: 13, weight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hint,
            textAlign: TextAlign.right,
            style: AppFonts.ui(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.inkFaint,
            ),
          ),
        ),
      ],
    );
  }
}

/// M3 — « Progression de la compétence · X/N », entre le fil d'Ariane et le
/// bandeau « déjà traité ».
///
/// L'agrégat est **calculé côté client** depuis le détail de la compétence
/// (déjà en cache : cet écran est poussé depuis lui). Aucun endpoint nouveau,
/// et si le détail n'est pas là — deep link direct — la barre disparaît au
/// lieu d'afficher un chiffre faux.
class _SkillProgressBar extends ConsumerWidget {
  const _SkillProgressBar({
    required this.skillId,
    required this.total,
    required this.accent,
  });

  final String skillId;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(skillDetailProvider(skillId)).valueOrNull;
    if (detail == null || detail.prompts.isEmpty) {
      return const SizedBox.shrink();
    }
    final done = detail.prompts.where((p) => p.status.isTreated).length;
    final count = detail.prompts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Progression de la compétence',
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            Text(
              '$done/$count',
              style: AppFonts.ui(
                size: 11,
                weight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressTrack(
          value: count == 0 ? 0 : done / count * 100,
          color: accent,
          height: 7,
        ),
      ],
    );
  }
}

/// Fil d'Ariane `Tâche › Compétence › Sujet i/N` + palier de la compétence
/// (spec §3 niveau 5). Tout vient du sujet lui-même (`skillPromptCount`,
/// `skillTargetLevel`) : aucun appel à la compétence pour l'afficher, deep link
/// direct compris.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.prompt, required this.accent});

  final SkillPromptDto prompt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = prompt.skillPromptCount;
    final position = total <= 0
        ? 'Sujet ${prompt.displayOrder}'
        : 'Sujet ${prompt.displayOrder}/$total';
    final level = prompt.skillTargetLevel.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: prompt.taskTitle,
                  style: AppFonts.ui(
                    size: 10,
                    height: 1.5,
                    weight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                TextSpan(
                  text: ' › ${prompt.skillTitle} › $position',
                  style: AppFonts.ui(
                    size: 10,
                    height: 1.5,
                    weight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (level.isNotEmpty) ...[
          const SizedBox(width: 10),
          AppTag(label: level, tone: TagTone.amber, compact: true),
        ],
      ],
    );
  }
}

/// `.previous-attempt` du prototype : le sujet a déjà été traité, on le dit et
/// on propose **une seule** action (reprendre en EE, réécouter en EO).
class _AlreadyTreatedBanner extends StatelessWidget {
  const _AlreadyTreatedBanner({
    required this.prompt,
    required this.accent,
    required this.busy,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final SkillPromptDto prompt;
  final Color accent;
  final bool busy;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final date = prompt.lastAttemptAt;
    final attempts = prompt.attemptCount;
    final meta = <String>[
      '$attempts tentative${attempts > 1 ? 's' : ''}',
      if (date != null) formatShortDate(date),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(LucideIcons.history, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sujet déjà traité',
                      style: AppFonts.ui(size: 12, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: AppFonts.ui(
                        size: 10,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            label: actionLabel,
            icon: actionIcon,
            variant: AppButtonVariant.outline,
            height: 42,
            isLoading: busy,
            onPressed: busy ? null : onAction,
          ),
        ],
      ),
    );
  }
}
