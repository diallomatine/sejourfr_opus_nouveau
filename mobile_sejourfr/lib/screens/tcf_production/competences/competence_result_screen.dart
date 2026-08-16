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
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../core/widgets/screen_header.dart';
import '../tcf_production_module.dart';
import '../widgets/action_plan.dart';
import '../widgets/evaluation_loading_view.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_state_views.dart';
import 'widgets/skill_level_card.dart';
import 'widgets/skill_references_tabs.dart';
import 'widgets/skill_status_badge.dart';

/// Résultat d'une tentative sur un petit sujet.
///
/// L'écran doit se comprendre en trois secondes : **où j'en suis**, **ce qu'il
/// me manque pour le niveau que je vise**, **à quoi ça ressemble quand c'est
/// bien fait**. D'où l'ordre, strict et partagé avec le web : confirmation →
/// carte NIVEAU (verdict du critère compact dedans) → « Pour viser X » →
/// « Une version plus aboutie » → « À retenir » →
/// `Ta production` (repliée) → références comparatives (repliées) → actions.
///
/// Le verdict du critère unique **n'est plus un bloc autonome** en v3 : il vit
/// en pastille (rangée du haut, à côté de la puce « Objectif ») et en une
/// ligne de texte sous les puces `strengthTag`/`focusTag`, tous deux dans
/// `SkillLevelCard`. Ça réintroduisait le pavé que la refonte avait supprimé.
///
/// Le bandeau du haut est **conditionnel** : « Production analysée » /
/// « Progression mise à jour » seulement quand une analyse existe, sinon les
/// libellés historiques « Sujet marqué comme traité » / « La progression de
/// la compétence a été mise à jour. » — annoncer « analysée » une production
/// qui ne l'est pas serait faux.
///
/// **Tout le texte affiché est déjà plafonné en mots côté serveur** : aucune
/// phrase d'accompagnement n'est ajoutée ici.
///
/// **Aucune note /20** : interdite sur un micro-exercice, le tool-schema ne
/// prévoit aucun champ pour en loger une. Le **niveau CECRL**, lui, est rendu
/// depuis le contrat v3 — entièrement dérivé serveur.
///
/// Une analyse d'avant v3 (`levelProgress == null`) retombe **intégralement**
/// sur l'affichage historique (`_VerdictCard` en bloc autonome, point réussi,
/// priorité, proposition améliorée) : aucune régression sur les analyses déjà
/// en base.
///
/// Le bandeau premium ne subsiste que quand il n'y a **rien** à montrer — quota
/// épuisé, production sans analyse, analyse en échec — et son action ouvre
/// alors le paywall.
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

  /// Fin du sursis accordé au second appel (`kActionPlanGrace`), posée au
  /// premier tirage qui voit la tentative finalisée sans son bloc « pour
  /// viser X ». La durée vit dans `widgets/action_plan.dart`, à côté du bloc
  /// qu'elle attend, et vaut la même chose sur le rapport de production.
  DateTime? _niveauViseDeadline;

  /// L'analyse a été observée **en vol** depuis l'ouverture de l'écran. C'est
  /// ce qui interdit d'attendre — et d'afficher un indicateur — sur un résultat
  /// rouvert plus tard : là, plus rien ne tourne côté serveur.
  bool _observedInFlight = false;

  /// Le sursis court : la place du bloc porte [ActionPlanPending].
  bool _niveauVisePending = false;
  bool _retrying = false;

  /// Le bloc du second appel est encore attendu : analyse vue en vol, niveau
  /// connu, objectif non atteint, et rien n'est arrivé. Toute autre combinaison
  /// est un état final — notamment `OBJECTIF_ATTEINT`, où le serveur ne produit
  /// **rien** par construction : l'attendre ferait tourner le polling pour rien.
  bool _awaitsNiveauVise(SkillAttemptDto attempt) {
    final analysis = attempt.analysis;
    final progress = analysis?.levelProgress;
    return _observedInFlight &&
        attempt.statut == SkillAttemptStatut.evaluated &&
        progress != null &&
        !progress.situation.isObjectifAtteint &&
        analysis!.niveauVise == null;
  }

  void _setNiveauVisePending(bool value) {
    if (_niveauVisePending == value || !mounted) return;
    setState(() => _niveauVisePending = value);
  }

  /// `null` = l'utilisateur n'a pas tranché → on suit la règle par défaut :
  /// références repliées quand une analyse est affichée, ouvertes quand elle
  /// est le seul retour de l'écran.
  bool? _referencesExpanded;

  /// La production est repliée d'emblée : l'écran doit se lire en trois
  /// secondes, et le candidat vient de l'écrire ou de la dire.
  bool _productionExpanded = false;

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
    _niveauViseDeadline = null;
    _setNiveauVisePending(false);
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final value = ref.read(skillAttemptProvider(widget.attemptId)).valueOrNull;
      if (value != null && !value.statut.isFinal) {
        // Vu en vol : l'analyse s'achève sous les yeux du candidat, donc le
        // second appel, lui, tourne encore.
        _observedInFlight = true;
      }
      if (value != null && value.statut.isFinal) {
        // Statut final : on ne prolonge que pour le second appel, au rythme
        // courant et sans jamais afficher d'erreur si rien n'arrive.
        if (!_awaitsNiveauVise(value)) {
          _setNiveauVisePending(false);
          timer.cancel();
          return;
        }
        final deadline =
            _niveauViseDeadline ??= DateTime.now().add(kActionPlanGrace);
        if (DateTime.now().isAfter(deadline)) {
          // Fin du sursis sans rien : l'indicateur s'efface en silence.
          _setNiveauVisePending(false);
          timer.cancel();
          return;
        }
        _setNiveauVisePending(true);
      }
      // Le budget global reste la borne dure, sursis compris.
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
      // Une analyse relancée peut changer le statut du sujet (donc les
      // compteurs de la liste, gardée en cache pour la session) et le quota.
      ref.invalidate(skillAnalysisQuotaProvider);
      invalidateSkillsSection(
          ref, widget.module.isEo ? SkillSection.eo : SkillSection.ee);
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
    final progress = analysis?.levelProgress;
    final niveauVise = analysis?.niveauVise;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // L'écran ouvre sur la confirmation, pas sur la production : c'est elle
        // qui dit que la progression a bougé.
        _TreatedHeader(analysed: analysis != null),
        if (analysis != null) ...[
          if (progress != null) ...[
            // Le verdict sur le critère unique reste ce que ce module promet,
            // mais en discret : pastille + ligne de texte dans la carte de
            // niveau, plus de gros bloc `_VerdictCard` autonome.
            const SizedBox(height: 13),
            SkillLevelCard(
              progress: progress,
              criterionStatus: analysis.status,
              verdict: analysis.verdict,
              strengthTag: analysis.strengthTag,
              focusTag: analysis.focusTag,
            ),
            // Le second appel est best-effort : son absence est un cas NORMAL,
            // pas une erreur — aucun message, aucun spinner, aucune excuse.
            if (niveauVise != null) ...[
              if (niveauVise.leviers.isNotEmpty) ...[
                const SizedBox(height: 18),
                // `niveauVise` porte ici le PALIER CIBLE (la marche suivante),
                // pas l'objectif lointain : le titre nomme donc ce que le texte
                // modele demontre vraiment. L'objectif, lui, est dit juste
                // au-dessus par la carte de niveau (`SkillLevelProgress`).
                SectionTitle(title: pourPasserAuTitle(niveauVise.niveauVise)),
                const SizedBox(height: 9),
                ActionPlanLeviers(leviers: niveauVise.leviers),
              ],
              if (niveauVise.exempleCible != null) ...[
                const SizedBox(height: 18),
                const SectionTitle(title: kActionPlanExempleTitle),
                const SizedBox(height: 9),
                ActionPlanExempleCard(exemple: niveauVise.exempleCible!),
              ],
              if (niveauVise.aRetenir != null) ...[
                const SizedBox(height: 14),
                ActionPlanMemoCard(memo: niveauVise.aRetenir!),
              ],
            ],
            // Le second appel tourne encore : une ligne à sa place, le temps du
            // sursis, sans rien bloquer.
            if (niveauVise == null && _niveauVisePending)
              const ActionPlanPending(),
          ] else ...[
            // Analyse d'avant le contrat v3 : pas de carte niveau, donc pas de
            // pastille pour loger le verdict → le gros bloc historique reste
            // seul responsable de l'afficher.
            const SizedBox(height: 13),
            _VerdictCard(analysis: analysis),
            if (analysis.successPoint != null) ...[
              const SizedBox(height: 9),
              _FeedbackItem(
                // Libellés figés par le contrat, mot pour mot avec le web.
                label: 'Ce qui est réussi',
                text: analysis.successPoint!,
                color: AppColors.green,
                soft: AppColors.greenLight,
                icon: LucideIcons.check,
              ),
            ],
            if (analysis.improvementPriority != null) ...[
              const SizedBox(height: 9),
              _FeedbackItem(
                label: 'À travailler en priorité',
                text: analysis.improvementPriority!,
                color: AppColors.amberDark,
                soft: AppColors.amberLight,
                icon: LucideIcons.arrowRight,
              ),
            ],
            if (analysis.improvedVersion != null) ...[
              const SizedBox(height: 12),
              _RewriteCard(text: analysis.improvedVersion!),
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
        // La production quitte la vue principale mais reste à un tap : en EO le
        // candidat doit pouvoir se réécouter depuis l'écran de résultat.
        _SectionToggle(
          title: 'Ta production',
          expanded: _productionExpanded,
          onToggle: () =>
              setState(() => _productionExpanded = !_productionExpanded),
        ),
        if (_productionExpanded) ...[
          const SizedBox(height: 8),
          _ProductionCard(
            attempt: attempt,
            isEo: widget.module.isEo,
          ),
        ],
        const SizedBox(height: 17),
        // Le titre part avec son contenu : un sujet sans référence n'affiche
        // pas « Compare avec… » au-dessus du vide (et n'expose plus les onglets
        // à une liste vide, qui les faisait échouer à l'initialisation).
        _ReferencesSection(
          async: referencesAsync,
          // Repliées quand l'analyse occupe déjà l'écran, ouvertes quand elles
          // sont le seul retour disponible.
          expanded: _referencesExpanded ?? analysis == null,
          onToggle: () => setState(
            () => _referencesExpanded = !(_referencesExpanded ?? analysis == null),
          ),
          onRetry: () =>
              ref.invalidate(skillReferencesProvider(attempt.skillPromptId)),
        ),
        const SizedBox(height: 20),
        _Actions(module: widget.module, prompt: prompt),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Blocs
// ---------------------------------------------------------------------------

/// Les trois références comparatives, **titre compris** — et son titre est
/// aussi son interrupteur.
///
/// Le titre appartient au contenu : sans référence, la section entière
/// disparaît au lieu de laisser un intertitre orphelin au-dessus d'un widget
/// vide. Pendant le chargement et sur erreur, le titre reste — il y a bien
/// quelque chose à annoncer.
///
/// Replier ne coupe **aucun** appel : la liste est chargée par l'écran de toute
/// façon (c'est elle qui décide si la section existe). On ne cache que du
/// texte, jamais de la donnée.
class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({
    required this.async,
    required this.expanded,
    required this.onToggle,
    required this.onRetry,
  });

  final AsyncValue<List<SkillReferenceDto>> async;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final refs = async.valueOrNull;
    if (async.hasValue && refs!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionToggle(
          title: 'Compare avec les niveaux de référence',
          expanded: expanded,
          onToggle: onToggle,
          // Le libellé dit ce qui va se passer, pas l'état courant.
          collapsedLabel: 'Comparer',
        ),
        if (expanded) ...[
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
      ],
    );
  }
}

/// L'intertitre d'une section repliable, tappable sur toute sa largeur : titre
/// à gauche, action explicite à droite avec son chevron.
///
/// Partagé par les deux sections repliées de l'écran (la production et les
/// références) : deux copies auraient divergé au premier ajustement.
class _SectionToggle extends StatelessWidget {
  const _SectionToggle({
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.collapsedLabel = 'Afficher',
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  /// Le libellé de repli est toujours « Masquer » ; seule l'invite à ouvrir
  /// change, parce qu'elle nomme le geste que la section propose.
  final String collapsedLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Le fond de l'écran : l'intertitre reste un intertitre, il ne devient
      // pas une carte parce qu'il est devenu tappable.
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AppFonts.display(size: 15)),
              ),
              const SizedBox(width: 10),
              Text(
                expanded ? 'Masquer' : collapsedLabel,
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: AppColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau de confirmation : pastille verte à coche, ce qui vient de se passer,
/// puis la conséquence sur la progression.
///
/// Libellés gelés en miroir du web, **conditionnés à la présence d'une
/// analyse** : annoncer « analysée » une production `RECORDED`/`FAILED` ou
/// bloquée par le quota serait faux.
class _TreatedHeader extends StatelessWidget {
  const _TreatedHeader({required this.analysed});

  /// `true` quand la tentative porte une analyse IA (v3 ou legacy).
  final bool analysed;

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
                analysed ? 'Production analysée' : 'Sujet marqué comme traité',
                style: AppFonts.display(size: 17),
              ),
              const SizedBox(height: 3),
              Text(
                analysed
                    ? 'Progression mise à jour'
                    : 'La progression de la compétence a été mise à jour.',
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

/// `.answer-box` du prototype. Aucun lecteur audio, même en EO :
/// l'enregistrement n'est pas conservé, ce qui est rendu c'est la transcription.
class _ProductionCard extends StatelessWidget {
  const _ProductionCard({
    required this.attempt,
    required this.isEo,
  });

  final SkillAttemptDto attempt;
  final bool isEo;

  @override
  Widget build(BuildContext context) {
    final text = attempt.productionText;
    final duration = attempt.audioDurationSec;

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
          // Pas de lecteur : l'enregistrement n'est pas conservé (il sert à
          // produire la transcription, puis il disparaît). Ce qu'on rend d'une
          // production orale, c'est son texte — la réécoute existe avant
          // l'envoi, sur l'écran d'enregistrement.
          const SizedBox(height: 7),
          if (text != null)
            Text(text, style: AppFonts.ui(size: 13, height: 1.55))
          else
            Text(
              isEo
                  ? 'La transcription de ta réponse orale n\'a pas pu être '
                      'récupérée.'
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

/// Les deux suites possibles : passer au sujet suivant, ou reprendre celui-ci.
///
/// « Sujet suivant » se désactive quand `nextPromptId` est nul — on ne bloque
/// jamais l'accès au sujet suivant, il n'y en a simplement plus. Le retour en
/// arrière reste la flèche de l'en-tête : il n'a pas sa place en bas d'écran.
class _Actions extends StatelessWidget {
  const _Actions({required this.module, required this.prompt});

  final TcfProductionModule module;
  final SkillPromptDto? prompt;

  @override
  Widget build(BuildContext context) {
    final next = prompt?.nextPromptId;
    return Column(
      children: [
        AppButton(
          label: 'Sujet suivant',
          iconRight: LucideIcons.arrowRight,
          variant: AppButtonVariant.outline,
          height: 46,
          onPressed: (prompt == null || next == null)
              ? null
              : () => context.pushReplacement(
                    competencePromptPath(module, prompt!.skillId, next),
                  ),
        ),
        const SizedBox(height: 8),
        AppButton(
          // Refait le sujet courant : c'est là que se retravaille le point que
          // l'analyse vient de nommer.
          label: 'S\'entraîner sur ce point',
          icon: LucideIcons.rotateCcw,
          variant: module.isEo
              ? AppButtonVariant.accent
              : AppButtonVariant.primary,
          height: 46,
          onPressed: prompt == null
              ? null
              : () => context.pushReplacement(
                    competencePromptPath(module, prompt!.skillId, prompt!.id),
                  ),
        ),
      ],
    );
  }
}
