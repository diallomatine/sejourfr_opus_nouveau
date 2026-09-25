import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/router/route_observer.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/diagnostic_run_tracker.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_run_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import '../module_detail/tcf_module_exam_briefing_screen.dart';
import '../module_detail/tcf_qcm_detail_screen.dart' show TcfQcmModule;
import '../plan/learning_plan_provider.dart' show signalerMesureEcrite;
import '../tcf_production/tcf_production_module.dart';
import 'tcf_diagnostic_current_provider.dart';
import 'tcf_diagnostic_labels.dart';

/// T06 — l'accueil du diagnostic TCF 4 épreuves (`30_` §5.1).
///
/// Son travail : rendre 75 minutes acceptables en montrant qu'elles se
/// découpent, et ne rien promettre d'autre.
///
/// 🛑 **Aucun résultat partiel n'apparaît ici** (`10_` §4.2) : ni score, ni
/// niveau. Le DTO ne les porte même pas — le résultat est le moment de
/// conversion, le diluer le détruit.
///
/// 🛑 **Aucun écran de passation n'est créé** : les sections QCM ouvrent le
/// runner existant, les productions la session EE/EO existante.
class TcfDiagnosticScreen extends ConsumerStatefulWidget {
  const TcfDiagnosticScreen({super.key});

  @override
  ConsumerState<TcfDiagnosticScreen> createState() => _TcfDiagnosticScreenState();
}

class _TcfDiagnosticScreenState extends ConsumerState<TcfDiagnosticScreen>
    with RouteAware {
  bool _busy = false;

  /// L'erreur d'une **action** (ouvrir, lancer, clôturer). L'erreur de
  /// *chargement*, elle, est portée par le provider — deux natures, deux
  /// endroits, pour qu'un échec d'action n'efface pas les sections à l'écran.
  String? _actionError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 🛑 **Retour d'une section poussée au-dessus** : elle a pu être commencée,
  /// terminée ou close, et rien de tout cela n'est visible d'ici. On relit.
  /// L'invalidation posée avant les `context.go` de fin de section ne couvre
  /// pas ce chemin-là : un `pop` ne repasse par aucune de ces fonctions.
  @override
  void didPopNext() {
    ref.invalidate(tcfDiagnosticCurrentProvider);
  }

  /// Ouvrir est idempotent côté serveur : un double appui ne coûte rien.
  Future<void> _ouvrir() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref.read(tcfDiagnosticRepositoryProvider).open();
      if (!mounted) return;
      ref.invalidate(tcfDiagnosticCurrentProvider);
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  /// 🛑 **On annonce l'épreuve AVANT de la lancer**, avec le **même briefing
  /// qu'un examen blanc de cette épreuve** (demande du propriétaire,
  /// 2026-09-13) : une section du diagnostic est un examen blanc, elle doit
  /// donc en avoir le sas — format, durée, consignes — et c'est le
  /// « Commencer » de la feuille qui démarre.
  ///
  /// 🛑 **Aucun briefing propre au diagnostic n'est écrit** : on réutilise
  /// `ModuleExamBriefingSheet` (CO/CE) et `ProductionExamBriefingSheet`
  /// (EE/EO), en leur déléguant le démarrage. Un second jeu de feuilles aurait
  /// divergé du premier à la première retouche.
  ///
  /// Une section **déjà commencée** ne repasse pas par le sas : le chrono court
  /// déjà, lui réannoncer le format lui ferait perdre du temps.
  void _annoncerPuisLancer(
      TcfDiagnosticDto diagnostic, TcfDiagnosticSectionDto section) {
    if (_busy || section.attemptId == null) return;
    if (section.etat == TcfDiagnosticSectionState.enCours) {
      _lancerSection(diagnostic, section);
      return;
    }
    // 🛑 La DURÉE vient du DTO servi, jamais de la table de référence : la
    // section est déjà composée, elle sait combien de temps elle dure. Lire la
    // table annoncerait 20 min sur une section qui en dure 12 (diagnostic
    // ouvert sous une configuration antérieure) — `config_version` existe
    // précisément pour que ce cas arrive.
    final duree = section.timeLimitSeconds == null
        ? null
        : '${(section.timeLimitSeconds! / 60).round()} min';
    switch (section.epreuve) {
      case EpreuveType.tcfCo:
        // Sas du diagnostic : `onStart` délégué, aucune offre ne s'y ouvre.
        showModuleExamBriefingSheet(context, TcfQcmModule.co,
            ctaLocation: null,
            onStart: () => _lancerSection(diagnostic, section),
            eyebrow: sasEyebrow(section.epreuve),
            durationLabel: duree);
      case EpreuveType.tcfCe:
        showModuleExamBriefingSheet(context, TcfQcmModule.ce,
            ctaLocation: null,
            onStart: () => _lancerSection(diagnostic, section),
            eyebrow: sasEyebrow(section.epreuve),
            durationLabel: duree);
      case EpreuveType.tcfEe:
      case EpreuveType.tcfEo:
        showProductionExamBriefingSheet(
          context,
          module: section.epreuve == EpreuveType.tcfEe
              ? TcfProductionModule.ee
              : TcfProductionModule.eo,
          starting: false,
          eyebrow: sasEyebrow(section.epreuve),
          // ⚠️ Pas de `pop` ici : cette feuille-là se referme elle-même avant
          // d'appeler `onStart`. En rajouter un dépilerait l'écran du
          // diagnostic derrière elle.
          onStart: () => _lancerSection(diagnostic, section),
        );
      default:
        _lancerSection(diagnostic, section);
    }
  }

  /// Poser l'ancre du chrono **avant** d'ouvrir l'écran de passation : sans cet
  /// appel la section n'a aucune échéance. Idempotent — reprendre ne rend pas
  /// de temps au candidat.
  Future<void> _lancerSection(
      TcfDiagnosticDto d, TcfDiagnosticSectionDto section) async {
    if (_busy || section.attemptId == null) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(tcfDiagnosticRepositoryProvider)
          .startSection(d.sessionId, section.epreuve);
      // Étape 1 du tunnel « Suivi » : la première question d'une section
      // s'affiche juste après. Idempotent par session côté serveur, et rien
      // n'est rappelé tant que l'appareil connaît déjà la run.
      unawaited(ref.read(diagnosticRunTrackerProvider).subjectViewed(
            DiagnosticRunType.fullTcf,
            sessionId: d.sessionId,
          ));
      if (!mounted) return;
      setState(() => _busy = false);
      _ouvrirPassation(d, section);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  /// 🛑 Aucun écran de passation propre au diagnostic : on rejoint les parcours
  /// existants. Un second runner divergerait du premier.
  void _ouvrirPassation(
      TcfDiagnosticDto diagnostic, TcfDiagnosticSectionDto section) {
    final id = section.attemptId!;
    final sessionId = diagnostic.sessionId;
    // Le parametre ne sert qu'au RETOUR : il ramene aux 4 sections au lieu du
    // bilan individuel. Il ne change ni la passation, ni la notation.
    final marqueur = '$kTcfDiagnosticParam=$sessionId';
    switch (section.epreuve) {
      case EpreuveType.tcfCo:
      case EpreuveType.tcfCe:
        context.push('/runner/$id?$marqueur');
      case EpreuveType.tcfEe:
        context.push(
            '/tcf/expression-ecrite/t/0?subAttemptId=$id&$marqueur');
      case EpreuveType.tcfEo:
        context.push(
            '/tcf/expression-orale/t/0?subAttemptId=$id&$marqueur');
      default:
        break;
    }
  }

  /// 🛑 **Le rapport d'une section, c'est CELUI D'UN EXAMEN** — aucun écran
  /// n'est créé pour le diagnostic. Une section est un examen blanc de son
  /// épreuve : la compréhension ouvre le rapport question par question, la
  /// production le bilan de session, exactement comme après un examen blanc.
  ///
  /// 🛑 **`rapportAttemptId`, pas `attemptId`** (2026-09-16) : sur une épreuve
  /// mesurée par un examen blanc, c'est cet examen-là qui porte le rapport — le
  /// sous-attempt du diagnostic est vide. Sur une section jouée ici, les deux
  /// sont le même, rien ne change.
  void _ouvrirRapport(TcfDiagnosticSectionDto section) {
    final id = section.rapportAttemptId;
    if (id == null) return;
    switch (section.epreuve) {
      case EpreuveType.tcfCo:
      case EpreuveType.tcfCe:
        context.push(AppRoutes.examReport.replaceFirst(':attemptId', id));
      case EpreuveType.tcfEe:
        context.push('/tcf/expression-ecrite/sessions/$id');
      case EpreuveType.tcfEo:
        context.push('/tcf/expression-orale/sessions/$id');
      default:
        break;
    }
  }

  Future<void> _voirResultat(TcfDiagnosticDto d) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref.read(tcfDiagnosticRepositoryProvider).result(d.sessionId);
      if (!mounted) return;
      // 🛑 **C'est ici que QUATRE niveaux sont posés d'un coup** : clôturer le
      // diagnostic change le profil TCF, le Plan, la préparation et les
      // progrès. `civicDiagnosticApi.result` émettait déjà ce signal ; son
      // pendant TCF ne le faisait pas, et l'Accueil gardait « À évaluer ».
      signalerMesureEcrite(ref);
      ref.invalidate(tcfDiagnosticCurrentProvider);
      setState(() => _busy = false);
      context.push('/diagnostic-tcf/${d.sessionId}/resultat');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionError = ApiClient.toApiException(e).message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: kTcfDiagnosticTitle,
              sub: kTcfDiagnosticSubtitle,
              onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    // `skipLoadingOnReload` : au retour d'une section, on relit — mais l'écran
    // garde ses cartes au lieu de clignoter en spinner plein écran.
    return ref.watch(tcfDiagnosticCurrentProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErreurView(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(tcfDiagnosticCurrentProvider),
          ),
          data: (etat) {
            final d = etat.diagnostic;
            if (d == null) return _amorce();
            // T11 (`30_` §5.6) — un diagnostic CLOS n'affiche pas quatre
            // sections « Terminée » : il affiche ce qu'il a mesuré, et la porte
            // de réévaluation.
            if (d.status == TcfDiagnosticStatus.completed) {
              return _dejaFait(d, etat.eligibilite);
            }
            return _sections(d);
          },
        );
  }

  /// L'échec d'une **action** se dit sur place, sans effacer l'écran.
  Widget _actionErrorLine() {
    final message = _actionError;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message,
          style: AppFonts.ui(size: 13, color: AppColors.red)),
    );
  }

  /// T11 — « Votre diagnostic initial a déjà été réalisé ».
  ///
  /// 🛑 **Le résultat existant n'est jamais bloqué.** Le paywall porte sur la
  /// nouvelle mesure, jamais sur le constat déjà rendu (`10_` §4.5) : « Voir
  /// mon diagnostic » reste le CTA principal.
  ///
  /// 🛑 **Rien n'est décidé ici.** Sans éligibilité servie (appel en échec), on
  /// n'affiche que le constat — on ne fabrique pas un bouton dont on ignore
  /// s'il sera accepté.
  Widget _dejaFait(TcfDiagnosticDto d, TcfReassessmentEligibilityDto? e) {
    final derniere = e == null ? null : derniereMesureLine(e);
    final parLePlan = e == null ? null : declencheParLePlanLine(e);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _actionErrorLine(),
        Text(kTcfDiagnosticDejaFaitTitle,
            style: AppFonts.display(size: 22, color: AppColors.ink)),
        if (derniere != null) ...[
          const SizedBox(height: 8),
          Text(derniere,
              style: AppFonts.ui(size: 14, color: AppColors.inkSoft)),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: kTcfDiagnosticVoirCta,
          onPressed: () => context.push('/diagnostic-tcf/${d.sessionId}/resultat'),
        ),
        if (e != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kTcfDiagnosticMesurerTitle,
                    style: AppFonts.display(size: 17, color: AppColors.ink)),
                const SizedBox(height: 8),
                if (e.locked) ...[
                  Text(reevaluationPitch(e, null),
                      style: AppFonts.ui(size: 14, color: AppColors.inkSoft)),
                  const SizedBox(height: 12),
                  AppButton(
                    label: kTcfDiagnosticDebloquerCta,
                    onPressed: () => showPaywallSheet(
                      context,
                      ref: ref,
                      ctaLocation: AnalyticsCtaLocation.diagnosticReport,
                    ),
                  ),
                ] else if (e.canStart) ...[
                  if (parLePlan != null) ...[
                    Text(parLePlan,
                        style: AppFonts.ui(size: 14, color: AppColors.inkSoft)),
                    const SizedBox(height: 12),
                  ],
                  AppButton(
                    label: kTcfDiagnosticReevaluerCta,
                    onPressed: _busy ? null : _ouvrir,
                    isLoading: _busy,
                  ),
                ] else if (e.message != null)
                  // Délai non écoulé : ce n'est pas un cadenas, et l'écran ne
                  // doit pas le présenter comme tel — aucun CTA d'achat ici.
                  Text(e.message!,
                      style: AppFonts.ui(size: 14, color: AppColors.blueDark)),
                const SizedBox(height: 10),
                Text(reevaluationRegleLine(e),
                    style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(kTcfDiagnosticEstimationNote,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
      ],
    );
  }

  /// Aucun diagnostic ouvert : on montre ce qui attend, puis on propose.
  Widget _amorce() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _actionErrorLine(),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in const [
                EpreuveType.tcfCo,
                EpreuveType.tcfCe,
                EpreuveType.tcfEe,
                EpreuveType.tcfEo,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(epreuvePresentation(e).icon,
                          size: 18, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Text(
                        epreuvePresentation(e).label,
                        style: AppFonts.ui(
                            size: 15, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(kTcfDiagnosticResultNote,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        AppButton(
          label: kTcfDiagnosticStartCta,
          onPressed: _busy ? null : _ouvrir,
          isLoading: _busy,
        ),
      ],
    );
  }

  Widget _sections(TcfDiagnosticDto d) {
    final jours = joursRestants(d.expiresAt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _actionErrorLine(),
        Text(progressionLabel(d),
            style: AppFonts.label(size: 12, color: AppColors.inkFaint)),
        const SizedBox(height: 12),

        // 🛑 Le délai passé n'est PAS une perte : le message le dit.
        if (d.repriseEcoulee) ...[
          AppCard(
            color: AppColors.blueLight,
            child: Text(kTcfDiagnosticRepriseEcoulee,
                style: AppFonts.ui(size: 14, color: AppColors.blueDark)),
          ),
          const SizedBox(height: 12),
        ],

        for (final s in d.sections) ...[
          _SectionCard(
            section: s,
            busy: _busy,
            onStart: () => _annoncerPuisLancer(d, s),
            onRapport: () => _ouvrirRapport(s),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 4),
        Text(kTcfDiagnosticResultNote,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 16),

        if (resultatDisponible(d) || d.repriseEcoulee)
          AppButton(
            label: kTcfDiagnosticResultCta,
            onPressed: _busy ? null : () => _voirResultat(d),
            isLoading: _busy,
          )
        else if (jours > 0)
          Text(
            'Vous avez $jours jour${jours > 1 ? 's' : ''} pour terminer.',
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
          ),

        const SizedBox(height: 16),
        Text(kTcfDiagnosticEstimationNote,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.busy,
    required this.onStart,
    required this.onRapport,
  });

  final TcfDiagnosticSectionDto section;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onRapport;

  @override
  Widget build(BuildContext context) {
    final p = epreuvePresentation(section.epreuve);
    final terminee = section.etat == TcfDiagnosticSectionState.terminee;
    // Section absente du diagnostic : elle se présente « non évaluée », jamais
    // comme un manque de contenu (`00_` §7.4).
    final indisponible = sectionIndisponible(section);

    return AppCard(
      color: terminee
          ? AppColors.green.withValues(alpha: 0.06)
          : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(p.icon, size: 20, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: AppFonts.ui(
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      _meta(),
                      style: AppFonts.ui(
                            size: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              AppTag(
                label: sectionEtatLabel(section.etat),
                tone: terminee ? TagTone.success : TagTone.neutral,
                compact: true,
              ),
            ],
          ),
          if (indisponible) ...[
            const SizedBox(height: 8),
            Text(kNiveauNonEvalue,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
          ] else if (terminee) ...[
            // ⚠️ LE RESULTAT DE L'EPREUVE, des qu'elle est close (arbitrage du
            // proprietaire, 2026-09-13) : une section du diagnostic est un
            // examen blanc de son epreuve, elle en rend donc le resultat et le
            // rapport. Ce qui reste a l'ecran de resultat, c'est le niveau
            // GLOBAL et les priorites.
            const SizedBox(height: 10),
            _Resultat(section: section),
            // Aucun rapport servi ⇒ aucun bouton : on n'ouvre jamais un
            // rapport vide (une section close sans une seule réponse).
            if (section.rapportAttemptId != null) ...[
              const SizedBox(height: 10),
              AppButton(
                label: kTcfDiagnosticRapportCta,
                onPressed: onRapport,
                variant: AppButtonVariant.outline,
                height: 44,
              ),
            ],
          ] else ...[
            const SizedBox(height: 10),
            Text(
              section.epreuve == EpreuveType.tcfEo
                  ? '$kTcfDiagnosticSectionWarning $kTcfDiagnosticMicWarning'
                  : kTcfDiagnosticSectionWarning,
              style: AppFonts.ui(size: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: sectionCtaLabel(section.etat),
              onPressed: busy ? null : onStart,
              variant: AppButtonVariant.soft,
              height: 44,
            ),
          ],
        ],
      ),
    );
  }

  String _meta() {
    final volume = section.totalQuestions != null
        ? '${section.totalQuestions} questions'
        : '3 tâches';
    // L'oral ne s'annonce pas en minutes d'épreuve : il se chronomètre par
    // tâche, comme dans l'examen complet.
    final duree = section.epreuve == EpreuveType.tcfEo
        ? 'Chronométré par tâche'
        : section.timeLimitSeconds != null
            ? '${(section.timeLimitSeconds! / 60).round()} min'
            : '—';
    return '$volume · $duree';
  }
}

/// **Ce que cette épreuve a mesuré** — son niveau, et son score en
/// compréhension.
///
/// 🛑 **Trois états, jamais deux** : un niveau servi, une correction encore en
/// vol (`analyseEnCours`), ou aucune mesure. Les deux derniers donnent
/// `niveau == null` et ne se disent pas pareil — *null = inconnu, jamais
/// mauvais*.
class _Resultat extends StatelessWidget {
  const _Resultat({required this.section});

  final TcfDiagnosticSectionDto section;

  @override
  Widget build(BuildContext context) {
    final niveau = section.niveau;
    if (niveau == null) {
      return Text(
        section.analyseEnCours
            ? kTcfDiagnosticAnalyseEnCours
            : kNiveauNonEvalue,
        style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
      );
    }
    final score = section.scoreCalibre;
    return Row(
      children: [
        Text(
          sectionNiveauLabel(niveau),
          style: AppFonts.display(
              size: 17, weight: FontWeight.w700, color: niveau.color),
        ),
        if (score != null) ...[
          const SizedBox(width: 10),
          // Le /499 des examens blancs de module — le score de PROGRESSION,
          // pas un score TCF : un candidat lit le meme chiffre ici et sur son
          // bilan d'examen.
          Text('$score / 499',
              style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
        ],
      ],
    );
  }
}

class _ErreurView extends StatelessWidget {
  const _ErreurView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.red, size: 32),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 14, color: AppColors.ink)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Réessayer',
            onPressed: onRetry,
            variant: AppButtonVariant.outline,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
