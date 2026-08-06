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
import '../../../core/widgets/progress_track.dart';
import '../../../core/widgets/screen_header.dart';
import '../audio_recorder_service.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';
import 'widgets/prompt_guidance.dart';
import 'widgets/skill_answer_card.dart';
import 'widgets/skill_recorder_panel.dart';

/// Garde anti-abus **côté serveur** : au-delà, la soumission est refusée. Il
/// est signalé au candidat mais ne **bloque pas** la saisie (règle 15 de la
/// spec : une borne de longueur avertit, elle n'interdit jamais).
const int _kMaxWords = 400;

/// Niveau 5 du parcours : un petit sujet.
///
/// **Cet écran fait produire, il n'explique pas.** De haut en bas : repère
/// « Sujet i/N » + palier, progression de la compétence, ce qu'il faut faire,
/// la situation, les contraintes, puis la zone de production — qui doit tenir
/// **au-dessus de la ligne de flottaison** sur un téléphone standard. C'est le
/// critère de réussite de la mise en page : tout ce qu'on ajoute avant la carte
/// « Votre réponse » se paie en défilement.
///
/// Ont disparu de l'écran (ils racontaient l'exercice) : le fil d'Ariane sur
/// deux lignes, les badges « Une compétence · un critère » / « Petit sujet i/N »,
/// le titre « Produis ta propre réponse. », le paragraphe d'objectif, l'encart
/// « Compétence évaluée », l'encart « Pourquoi cet exercice ? » et les puces
/// méta « Accessible » / « Un seul critère ».
///
/// **L'analyse IA n'est pas une option** : elle est demandée dès que
/// l'utilisateur y a droit (abonné, ou analyses offertes restantes). Quand il
/// n'y a plus droit, la production part **sans** analyse — c'est l'écran de
/// résultat qui invite à s'abonner. Ne pas y remettre une bascule : le choix
/// n'existe plus, seule l'information de quota reste.
///
/// Cette information et la tipline restent **sous** la zone de production :
/// elles ne doivent jamais la repousser.
///
/// L'oral reçoit **exactement la même structure** : seules la zone de
/// production (panneau d'enregistrement) et la donnée du pied de carte (durée)
/// changent.
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

  /// L'analyse est le comportement naturel : on la demande **toujours**, sauf
  /// quand le compte n'y a plus droit. Dans ce cas la soumission part sans
  /// analyse au lieu d'échouer en 403 — l'écran de résultat prend le relais et
  /// invite à s'abonner.
  ///
  /// Quota inconnu (lecture en vol, erreur réseau) = on demande : le serveur
  /// reste l'arbitre, et un 403 est rattrapé par `showPaywallOrError`.
  bool _analysisRequested(SkillAnalysisQuotaDto? quota) =>
      quota?.canAnalyse ?? true;

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
              _PromptMetaRow(prompt: prompt),
              const SizedBox(height: 12),
              _SkillProgressBar(
                skillId: prompt.skillId,
                total: prompt.skillPromptCount,
                accent: _accent,
              ),
              if (prompt.attemptCount > 0 && prompt.lastAttemptId != null) ...[
                const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              // Ce qu'il faut faire — la check-list remplace le critère
              // abstrait. Sans check-list, elle retombe sur la consigne.
              SkillChecklistCard(
                checklist: skillChecklist(prompt),
                fallback: prompt.instruction,
                accent: _accent,
              ),
              const SizedBox(height: 10),
              if (prompt.context.trim().isNotEmpty) ...[
                SkillSituationCard(
                  context: prompt.context.trim(),
                  accent: _accent,
                ),
                const SizedBox(height: 10),
              ],
              _ConstraintRowSlot(prompt: prompt),
              SkillAnswerCard(
                accent: _accent,
                icon: _isEo ? LucideIcons.mic : LucideIcons.penLine,
                tip: prompt.tip,
                meta: _answerMeta(prompt, recording),
                metaTone: _metaTone(prompt, recording, overCap: overCap),
                child: _isEo
                    ? Column(
                        children: [
                          if (prompt.answerStarter != null &&
                              recording.phase == RecordingPhase.idle) ...[
                            SkillStarterHint(starter: prompt.answerStarter!),
                            const SizedBox(height: 14),
                          ],
                          SkillRecorderPanel(
                            state: recording,
                            accent: _accent,
                            onStart: () => unawaited(_startRecording()),
                            onStop: () => unawaited(
                              ref
                                  .read(recordingControllerProvider.notifier)
                                  .stop(),
                            ),
                            onReset: () => unawaited(
                              ref
                                  .read(recordingControllerProvider.notifier)
                                  .cancel(),
                            ),
                          ),
                        ],
                      )
                    : SkillWritingField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                        starter: prompt.answerStarter,
                        accent: _accent,
                      ),
              ),
              if (overCap) ...[
                const SizedBox(height: 8),
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
              // Spec §15 — le garde-fou central de l'oral : la note se fonde
              // sur la transcription, jamais sur la voix. Rendu SOUS le
              // panneau d'enregistrement pour ne pas repousser le micro.
              if (_isEo) ...[
                const SizedBox(height: 10),
                const SkillTranscriptNotice(),
              ],
              _FreeAnalysesSlot(quota: quota, accent: _accent),
              const SizedBox(height: 11),
              // M5 — sans cette ligne, rien n'explique au candidat pourquoi
              // les références restent masquées (§13.2).
              const ProductionTipline(
                lead: 'Important :',
                body: 'Les exemples de référence et l\'analyse '
                    'apparaissent seulement après ta production.',
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

  /// La donnée du pied de la carte de réponse : compteur de mots à l'écrit,
  /// durée capturée à l'oral. Même place, même rôle — c'est la parité.
  ///
  /// À l'oral on affiche **écoulé / conseillé** (`0:12 / 0:45`, format du web) :
  /// un chrono sans cible ne dit pas au candidat s'il est court ou long.
  String _answerMeta(SkillPromptDto prompt, RecordingState recording) {
    if (_isEo) {
      final elapsed = SkillRecorderPanel.formatDuration(recording.elapsed);
      final target = prompt.recommendedDurationSeconds;
      if (target == null || target <= 0) return elapsed;
      return '$elapsed / ${SkillRecorderPanel.formatSeconds(target)}';
    }
    final max = prompt.recommendedMaxWords;
    // La borne haute est indicative : elle s'affiche, elle ne bloque pas.
    if (max == null) return '$_wordCount ${_wordCount > 1 ? "mots" : "mot"}';
    return '$_wordCount / $max mots';
  }

  /// La teinte du compteur : vert **dans** la cible, ambre au-delà, neutre tant
  /// que rien n'a été produit. Sans le vert, le candidat n'apprend jamais qu'il
  /// est bon — il n'a que « rien » ou « trop ».
  SkillMetaTone _metaTone(
    SkillPromptDto prompt,
    RecordingState recording, {
    required bool overCap,
  }) {
    if (_isEo) {
      if (recording.phase == RecordingPhase.idle ||
          recording.elapsed == Duration.zero) {
        return SkillMetaTone.neutral;
      }
      final target = prompt.recommendedDurationSeconds;
      return target == null || recording.elapsed.inSeconds <= target
          ? SkillMetaTone.inTarget
          : SkillMetaTone.outOfTarget;
    }
    if (_wordCount == 0) return SkillMetaTone.neutral;
    final min = prompt.recommendedMinWords;
    final max = prompt.recommendedMaxWords;
    final inRange = (min == null || _wordCount >= min) &&
        (max == null || _wordCount <= max);
    return inRange && !overCap
        ? SkillMetaTone.inTarget
        : SkillMetaTone.outOfTarget;
  }
}

/// Ce qu'il reste d'analyses offertes à un compte gratuit — **une information,
/// plus une décision**.
///
/// La bascule « Analyser ma réponse avec l'IA » a disparu : l'analyse est le
/// comportement naturel. Mais valider consomme une analyse offerte, et le
/// candidat doit le savoir — sans cette ligne, un quota se viderait à son insu.
///
/// Ne s'affiche donc que dans ce cas précis : ni pour un accès illimité (rien à
/// décompter), ni quand il n'en reste plus (la production part sans analyse, et
/// c'est l'écran de résultat qui le dit), ni tant que le quota est inconnu.
class _FreeAnalysesSlot extends StatelessWidget {
  const _FreeAnalysesSlot({required this.quota, required this.accent});

  final SkillAnalysisQuotaDto? quota;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final q = quota;
    if (q == null || q.isUnlimited || q.remaining <= 0) {
      return const SizedBox.shrink();
    }
    final plural = q.remaining > 1 ? 's' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.sparkles, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ta réponse sera analysée par l\'IA. Il te reste '
              '${q.remaining} analyse$plural offerte$plural.',
              style: AppFonts.ui(
                size: 11.5,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La rangée de contraintes et l'espace qui la suit : sans borne de longueur ni
/// étiquette, ni l'une ni l'autre n'existe (pas de trou de 10 px sous une
/// rangée vide).
class _ConstraintRowSlot extends StatelessWidget {
  const _ConstraintRowSlot({required this.prompt});

  final SkillPromptDto prompt;

  @override
  Widget build(BuildContext context) {
    final row = SkillConstraintRow(
      lengthHint: skillLengthHint(prompt),
      tags: skillConstraintTags(prompt),
      isEo: prompt.section.isEo,
    );
    if (row.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: row,
    );
  }
}

/// M3 — « Progression · X/N », sous le repère de sujet.
///
/// Le libellé s'est réduit à « Progression » : le mot « compétence » se paie en
/// hauteur, et l'écran est déjà celui d'une compétence.
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
                'Progression',
                style: AppFonts.ui(size: 12.5, weight: FontWeight.w800),
              ),
            ),
            Text(
              '$done/$count',
              style: AppFonts.ui(
                size: 12.5,
                weight: FontWeight.w700,
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

/// Ligne compacte de repère : `Sujet i/N` à gauche, **palier** à droite.
///
/// Remplace le fil d'Ariane sur deux lignes : la tâche et la compétence sont
/// déjà dans l'en-tête et dans l'écran d'où l'on vient, les répéter coûtait
/// deux lignes juste avant la zone de production. Le palier, lui, est exigé sur
/// l'écran d'un petit sujet (spec §3 niveau 5) et vient du sujet lui-même —
/// deep link direct compris, aucun appel à la compétence.
class _PromptMetaRow extends StatelessWidget {
  const _PromptMetaRow({required this.prompt});

  final SkillPromptDto prompt;

  @override
  Widget build(BuildContext context) {
    final total = prompt.skillPromptCount;
    final position = total <= 0
        ? 'Sujet ${prompt.displayOrder}'
        : 'Sujet ${prompt.displayOrder}/$total';
    final level = prompt.skillTargetLevel.trim();
    return Row(
      children: [
        Expanded(
          child: Text(
            position,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.inkSoft,
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

/// Le sujet a déjà été traité : on le dit et on propose **une seule** action
/// (reprendre en EE, réécouter en EO).
///
/// Volontairement tenu sur **une ligne** : ce bandeau s'intercale juste
/// au-dessus du guidage, et la version en pavé (pastille + deux lignes de méta
/// + bouton pleine largeur) suffisait à repousser la zone de production sous la
/// ligne de flottaison dès la deuxième visite d'un sujet.
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

    return Material(
      color: accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: busy ? null : onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.history, size: 16, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: actionLabel,
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  $meta',
                        style: AppFonts.ui(
                          size: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
              else
                Icon(actionIcon, size: 15, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
