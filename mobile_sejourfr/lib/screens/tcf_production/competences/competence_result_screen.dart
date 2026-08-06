import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/audio_player.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../core/widgets/screen_header.dart';
import '../tcf_production_module.dart';
import '../widgets/evaluation_loading_view.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_state_views.dart';
import 'widgets/skill_references_tabs.dart';
import 'widgets/skill_status_badge.dart';

/// Résultat d'une tentative sur un petit sujet.
///
/// Ordre du prototype : accusé de traitement → `Ta production` → analyse IA
/// (repliée derrière un bandeau) → références comparatives → les trois
/// actions. Le retour IA reste **au-dessus** des références (§13.4).
///
/// Aucune note /20 et aucun niveau CECRL : interdits sur un micro-exercice
/// (§9 de la spec). Le sujet ne juge qu'un critère.
class CompetenceResultScreen extends ConsumerStatefulWidget {
  const CompetenceResultScreen({
    super.key,
    required this.module,
    required this.attemptId,
  });

  final TcfProductionModule module;
  final String attemptId;

  @override
  ConsumerState<CompetenceResultScreen> createState() =>
      _CompetenceResultScreenState();
}

class _CompetenceResultScreenState
    extends ConsumerState<CompetenceResultScreen> {
  /// **Valeur partagée avec le web** (`CompetenceResult`) : 3 s d'intervalle,
  /// plafond 120 s. Les deux fronts divergeaient (90 s ici, 40 tirages là-bas) :
  /// une analyse qui aboutissait en 100 s réussissait sur le web et échouait
  /// sur mobile. On retient la plus généreuse — échouer une analyse qui allait
  /// aboutir est le pire des deux défauts. À changer des deux côtés.
  static const Duration _pollMaxDuration = Duration(seconds: 120);

  Timer? _poll;
  DateTime _pollStartedAt = DateTime.now();
  bool _retrying = false;

  /// M7 — l'analyse est repliée par défaut, comme dans le prototype.
  bool _analysisExpanded = false;

  Color get _accent => widget.module.accent;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Même contrat que les résultats de production : 3 s d'intervalle, arrêt
  /// sur statut final ou au bout de [_pollMaxDuration] (protège d'une analyse
  /// bloquée).
  void _startPolling() {
    _poll?.cancel();
    _pollStartedAt = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final value = ref.read(skillAttemptProvider(widget.attemptId)).valueOrNull;
      if (value != null && value.statut.isFinal) {
        timer.cancel();
        return;
      }
      if (DateTime.now().difference(_pollStartedAt) > _pollMaxDuration) {
        timer.cancel();
        return;
      }
      ref.invalidate(skillAttemptProvider(widget.attemptId));
    });
  }

  void _back(String? skillId) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(skillId == null
        ? '/tcf/${widget.module.routeKey}'
        : competenceDetailPath(widget.module, skillId));
  }

  Future<void> _retryAnalysis() async {
    setState(() => _retrying = true);
    try {
      await ref.read(skillRepositoryProvider).retryAnalysis(widget.attemptId);
      if (!mounted) return;
      ref.invalidate(skillAttemptProvider(widget.attemptId));
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(skillAttemptProvider(widget.attemptId));
    final attempt = async.valueOrNull;
    final prompt = attempt == null
        ? null
        : ref.watch(skillPromptProvider(attempt.skillPromptId)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: prompt?.title ?? 'Résultat',
              sub: prompt == null
                  ? widget.module.title
                  : '${prompt.skillTitle} · ${widget.module.title}',
              onBack: () => _back(prompt?.skillId),
            ),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () =>
                    Center(child: CircularProgressIndicator(color: _accent)),
                error: (e, _) => ProductionErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () =>
                      ref.invalidate(skillAttemptProvider(widget.attemptId)),
                ),
                data: (data) => data.statut.isInProgress
                    ? Center(
                        child: EvaluationLoadingView(
                          includeTranscription: widget.module.isEo,
                        ),
                      )
                    : _body(data, prompt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(SkillAttemptDto attempt, SkillPromptDto? prompt) {
    final analysis = attempt.analysis;
    final referencesAsync =
        ref.watch(skillReferencesProvider(attempt.skillPromptId));
    final quota = ref.watch(skillAnalysisQuotaProvider).valueOrNull;
    final canAnalyse = quota?.canAnalyse ?? true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // M8 — le prototype ouvre sur l'accusé de traitement, pas sur la
        // production : c'est lui qui confirme que la progression a bougé.
        const _TreatedHeader(),
        const SizedBox(height: 14),
        _ProductionCard(
          attempt: attempt,
          isEo: widget.module.isEo,
          accent: _accent,
        ),
        if (analysis != null) ...[
          const SizedBox(height: 13),
          _AnalysisBanner(
            actionLabel: _analysisExpanded ? 'Masquer' : 'Voir',
            onAction: () =>
                setState(() => _analysisExpanded = !_analysisExpanded),
          ),
          if (_analysisExpanded) ...[
            const SizedBox(height: 11),
            _VerdictCard(analysis: analysis),
            const SizedBox(height: 9),
            _FeedbackItem(
              // Libellés figés par le contrat, mot pour mot avec le web.
              label: 'Ce qui est réussi',
              text: analysis.successPoint,
              color: AppColors.green,
              soft: AppColors.greenLight,
              icon: LucideIcons.check,
            ),
            const SizedBox(height: 9),
            _FeedbackItem(
              label: 'À travailler en priorité',
              text: analysis.improvementPriority,
              color: AppColors.amberDark,
              soft: AppColors.amberLight,
              icon: LucideIcons.arrowRight,
            ),
            if (analysis.improvedVersion.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _RewriteCard(text: analysis.improvedVersion),
            ],
          ],
        ] else ...[
          if (!canAnalyse) ...[
            const SizedBox(height: 13),
            _AnalysisBanner(
              actionLabel: 'Débloquer',
              onAction: () => showPaywallSheet(context),
            ),
          ],
          const SizedBox(height: 13),
          _NoAnalysisCard(
            attempt: attempt,
            quota: quota,
            retrying: _retrying,
            onRetry: () => unawaited(_retryAnalysis()),
            onUpgrade: () => showPaywallSheet(context),
            onRedo: prompt == null
                ? null
                : () => context.pushReplacement(
                      competencePromptPath(
                          widget.module, prompt.skillId, prompt.id),
                    ),
          ),
        ],
        const SizedBox(height: 17),
        // Le titre part avec son contenu : un sujet sans référence n'affiche
        // pas « Compare avec… » au-dessus du vide (et n'expose plus les onglets
        // à une liste vide, qui les faisait échouer à l'initialisation).
        _ReferencesSection(
          async: referencesAsync,
          onRetry: () =>
              ref.invalidate(skillReferencesProvider(attempt.skillPromptId)),
        ),
        const SizedBox(height: 20),
        _Actions(
          module: widget.module,
          prompt: prompt,
          onBackToList: () => _back(prompt?.skillId),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Blocs
// ---------------------------------------------------------------------------

/// Les trois références comparatives, **titre compris**.
///
/// Le titre appartient au contenu : sans référence, la section entière
/// disparaît au lieu de laisser un intertitre orphelin au-dessus d'un widget
/// vide. Pendant le chargement et sur erreur, le titre reste — il y a bien
/// quelque chose à annoncer.
class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({required this.async, required this.onRetry});

  final AsyncValue<List<SkillReferenceDto>> async;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final refs = async.valueOrNull;
    if (async.hasValue && refs!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare avec les niveaux de référence',
          style: AppFonts.display(size: 15),
        ),
        const SizedBox(height: 8),
        async.when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ProductionErrorView(
            message: ApiClient.toApiException(e).message,
            onRetry: onRetry,
          ),
          data: (list) => SkillReferencesTabs(references: list),
        ),
      ],
    );
  }
}

/// `.result-title` du prototype : pastille verte 38×38 à coche, « Sujet marqué
/// comme traité », puis la conséquence sur la progression.
class _TreatedHeader extends StatelessWidget {
  const _TreatedHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(LucideIcons.check, size: 20, color: AppColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sujet marqué comme traité',
                style: AppFonts.display(size: 17),
              ),
              const SizedBox(height: 3),
              Text(
                'La progression de la compétence a été mise à jour.',
                style: AppFonts.ui(size: 11, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.premium` du prototype : bandeau en dégradé sombre + bouton clair.
///
/// L'analyse IA **est** la partie premium du module : le bandeau déplie quand
/// l'utilisateur y a droit, et ouvre le paywall sinon.
class _AnalysisBanner extends StatelessWidget {
  const _AnalysisBanner({required this.actionLabel, required this.onAction});

  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.premium,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 18,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse IA du critère',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Verdict simple, point réussi, priorité et reformulation '
                  'courte.',
                  style: AppFonts.ui(
                    size: 10,
                    height: 1.35,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Text(
                  actionLabel,
                  style: AppFonts.ui(size: 10, weight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.answer-box` du prototype, augmenté du lecteur audio en EO.
class _ProductionCard extends StatelessWidget {
  const _ProductionCard({
    required this.attempt,
    required this.isEo,
    required this.accent,
  });

  final SkillAttemptDto attempt;
  final bool isEo;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = attempt.productionText;
    final duration = attempt.audioDurationSec;
    final audioUrl = attempt.audioUrl;
    final hasAudio = isEo && audioUrl != null && audioUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TA PRODUCTION',
                style: AppFonts.label(size: 10, color: AppColors.inkSoft),
              ),
              const Spacer(),
              if (isEo && duration != null)
                AppTag(
                  label: '$duration s',
                  tone: TagTone.neutral,
                  icon: LucideIcons.mic,
                  compact: true,
                ),
              if (!isEo && attempt.wordsCount != null)
                AppTag(
                  label: '${attempt.wordsCount} mots',
                  tone: TagTone.neutral,
                  icon: LucideIcons.type,
                  compact: true,
                ),
            ],
          ),
          // Se réécouter en lisant l'analyse fait la moitié de la valeur
          // pédagogique de l'oral (spec §15 : « l'oral conserve l'audio »).
          if (hasAudio) ...[
            const SizedBox(height: 12),
            SejourAudioPlayer(
              url: audioUrl,
              label: 'TON ENREGISTREMENT',
              icon: LucideIcons.mic,
              accent: accent,
              background: accent.withValues(alpha: 0.06),
            ),
          ],
          const SizedBox(height: 7),
          if (text != null)
            Text(text, style: AppFonts.ui(size: 13, height: 1.55))
          else
            Text(
              isEo
                  ? 'Ta réponse orale est enregistrée. La transcription n\'est '
                      'produite que lorsqu\'une analyse IA est demandée.'
                  : 'Aucune réponse enregistrée.',
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          if (attempt.selfEvaluation != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.userCheck,
                    size: 13, color: AppColors.inkFaint),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Ton ressenti : ${attempt.selfEvaluation!.label.toLowerCase()}',
                    style: AppFonts.ui(size: 11, color: AppColors.inkFaint),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.evaluation-card` du prototype : carte **franchement teintée** de la
/// couleur du verdict, bordure assortie, pastille de statut à fond blanc.
/// Une teinte à 6-8 % rendait la carte blanc cassé — le verdict ne se lisait
/// plus au premier coup d'œil.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.analysis});

  final SkillAnalysisDto analysis;

  @override
  Widget build(BuildContext context) {
    final color = skillCriterionColor(analysis.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Critère unique',
                  style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      skillCriterionIcon(analysis.status),
                      size: 12,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      analysis.status.label,
                      style: AppFonts.ui(
                        size: 10,
                        weight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            analysis.verdict,
            style: AppFonts.ui(size: 11.5, height: 1.48),
          ),
        ],
      ),
    );
  }
}

/// `.feedback-item` : carte blanche, pastille 31×31 teintée, intitulé court.
class _FeedbackItem extends StatelessWidget {
  const _FeedbackItem({
    required this.label,
    required this.text,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String label;
  final String text;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.ui(size: 11, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: AppFonts.ui(
                    size: 11,
                    height: 1.45,
                    color: AppColors.inkSoft,
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

/// `.rewrite` : carte **dédiée** à la proposition améliorée — elle ne se
/// confond plus avec les deux encarts de retour qui la précèdent.
class _RewriteCard extends StatelessWidget {
  const _RewriteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proposition améliorée',
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 7),
          Text(text, style: AppFonts.ui(size: 13, height: 1.52)),
          const SizedBox(height: 7),
          Text(
            'Exemple de reformulation : ce n\'est pas la seule bonne réponse, '
            'et ton idée doit être conservée.',
            style: AppFonts.ui(
              size: 10,
              height: 1.35,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tentative sans analyse (`RECORDED`) ou analyse en échec (`FAILED`) : on ne
/// fabrique pas de verdict, on va droit aux références et on propose une suite
/// sobre.
class _NoAnalysisCard extends StatelessWidget {
  const _NoAnalysisCard({
    required this.attempt,
    required this.quota,
    required this.retrying,
    required this.onRetry,
    required this.onUpgrade,
    required this.onRedo,
  });

  final SkillAttemptDto attempt;
  final SkillAnalysisQuotaDto? quota;
  final bool retrying;
  final VoidCallback onRetry;
  final VoidCallback onUpgrade;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    final failed = attempt.statut == SkillAttemptStatut.failed;
    final canAnalyse = quota?.canAnalyse ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed ? LucideIcons.circleAlert : LucideIcons.sparkles,
                size: 16,
                color: failed ? AppColors.red : AppColors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  failed
                      ? 'L\'analyse n\'a pas abouti'
                      : 'Réponse enregistrée, sans analyse IA',
                  style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            failed
                ? (attempt.errorMessage ??
                    'Tu peux relancer l\'analyse : cela ne consomme pas '
                        'd\'analyse supplémentaire.')
                : 'Compare ta réponse aux trois références ci-dessous. Une '
                    'analyse IA peut aussi pointer précisément ce qui manque '
                    'sur le critère.',
            style: AppFonts.ui(
              size: 11.5,
              color: AppColors.inkSoft,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (failed)
            AppButton(
              label: 'Relancer l\'analyse',
              icon: LucideIcons.refreshCw,
              variant: AppButtonVariant.outline,
              height: 44,
              isLoading: retrying,
              onPressed: retrying ? null : onRetry,
            )
          else
            AppButton(
              label: canAnalyse
                  ? 'Refaire avec l\'analyse IA'
                  : 'Débloquer les analyses IA',
              icon: canAnalyse ? LucideIcons.rotateCcw : LucideIcons.lock,
              variant: AppButtonVariant.outline,
              height: 44,
              onPressed: canAnalyse ? onRedo : onUpgrade,
            ),
        ],
      ),
    );
  }
}

/// `.triple-actions` : deux actions secondaires côte à côte, l'action
/// principale sur toute la largeur.
///
/// « Sujet suivant à travailler » se désactive quand `nextPromptId` est nul —
/// on ne bloque jamais l'accès au sujet suivant, il n'y en a simplement plus
/// (§13.7).
class _Actions extends StatelessWidget {
  const _Actions({
    required this.module,
    required this.prompt,
    required this.onBackToList,
  });

  final TcfProductionModule module;
  final SkillPromptDto? prompt;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    final next = prompt?.nextPromptId;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                // « Retour aux sujets » se confondait avec le mode « Sujets »
                // TCF, qui est un tout autre écran (spec §4).
                label: 'Retour aux petits sujets',
                variant: AppButtonVariant.outline,
                height: 46,
                onPressed: onBackToList,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Refaire ce sujet',
                variant: AppButtonVariant.outline,
                height: 46,
                onPressed: prompt == null
                    ? null
                    : () => context.pushReplacement(
                          competencePromptPath(
                              module, prompt!.skillId, prompt!.id),
                        ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Sujet suivant à travailler',
          icon: LucideIcons.arrowRight,
          variant: module.isEo
              ? AppButtonVariant.accent
              : AppButtonVariant.primary,
          height: 46,
          onPressed: (prompt == null || next == null)
              ? null
              : () => context.pushReplacement(
                    competencePromptPath(module, prompt!.skillId, next),
                  ),
        ),
      ],
    );
  }
}
