import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/journey_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'journey_etape_labels.dart';
import 'learning_plan_provider.dart';

/// **Le détail d'une étape de séries** — l'écran intermédiaire du Plan
/// (demande du propriétaire, 2026-09-20).
///
/// Le cycle du Plan **n'ouvre plus une série** sur une étape d'entraînement de
/// compréhension (CO/CE) ni sur une étape civique : il ouvre **cet écran-ci**,
/// qui dit ce que l'étape demande — la compétence ou l'unité travaillée, son
/// avancement, le seuil à tenir — puis propose ses séries une par une.
///
/// 🛑 **Rien n'est décidé ici.** Le quota, le nombre de questions, le **seuil de
/// réussite**, la durée estimée, l'ordre des séries, leur verrou (`locked`) et
/// leur validation (`validee`) sont **servis**
/// (`GET /api/me/plan/journey/steps/{stepId}`). Les phrases viennent de
/// `journey_etape_labels.dart`, miroir de `lib/journey-etape.ts`.
///
/// 🛑 **`dernierScore` n'est JAMAIS comparé à `seuilReussite`.** L'état d'une
/// série se lit sur `locked` et `validee` ; le score est affiché, pas jugé. Un
/// front qui classerait ce nombre deviendrait une seconde autorité sur « cette
/// série est-elle réussie ? » — exactement ce que le dépôt interdit.
///
/// 🛑 **Une étape verrouillée garde son écran ENTIER** (R16, D-18) : le candidat
/// lit ce qu'il y a à faire, seul le **geste** est fermé et il ouvre l'offre. On
/// floute l'action, jamais le résultat.
///
/// 🛑 **Le corrigé d'une série jouée réutilise le chemin existant** — le rapport
/// de série ([AppRoutes.examReportDepuisPlan]), celui des séries hors Plan, dont
/// « Continuer » redépile ici. Aucun écran de rapport n'est écrit ici.
///
/// 🛑 **Une série JOUÉE se lit d'un coup d'œil** (2026-09-27) : carte compacte
/// à coche verte (réussie) ou croix rouge (ratée), rangée sous « Réussies » ou
/// « À faire ». Son toucher ouvre la feuille des sujets déjà traités
/// (`showAppSheet`) : « Voir mon résultat » puis « Refaire la série ». Seule une
/// série jamais jouée garde le gros bouton « Commencer ».
///
/// 🛑 **Étape franchie = `detail.validee`, SERVI** : « Étape validée » et
/// « Continuer mon plan » (retour au cycle, [AppRoutes.plan]). Jamais
/// `validees >= quota` recompté ici.
///
/// 🛑 **Miroir de `PlanEtapeView` côté web**, brique pour brique.
class PlanEtapeScreen extends ConsumerStatefulWidget {
  const PlanEtapeScreen({super.key, required this.stepId});

  final String stepId;

  @override
  ConsumerState<PlanEtapeScreen> createState() => _PlanEtapeScreenState();
}

class _PlanEtapeScreenState extends ConsumerState<PlanEtapeScreen> {
  bool _occupe = false;
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(journeyStepProvider(widget.stepId));
    final detail = async.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              // 🛑 **Jamais un `pop()` nu** : un écran atteint par `go` n'a
              // personne en dessous, et la flèche ne répondrait pas.
              onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
              title: journeyEtapeTitle(detail),
              lead: detail == null
                  ? null
                  : journeyEtapeObjectif(detail.objectif),
            ),
            SfSection(
              flush: true,
              child: SfStack(
                pad: false,
                children: [
                  ...async.when(
                    loading: () => const [
                      SfCard(child: SfTiny(kJourneyEtapeLoading)),
                    ],
                    // 🛑 **Un échec se DIT** : sans ce cas, une panne réseau se
                    // lirait « aucune série », c'est-à-dire un mensonge sur ce
                    // qu'il reste à faire.
                    error: (error, _) => [
                      SfCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SfTiny(ApiClient.toApiException(error).message),
                            const SizedBox(height: 10),
                            SfButton(
                              label: kJourneyEtapeRetry,
                              variant: SfButtonVariant.blue,
                              onPressed: () => ref.invalidate(
                                  journeyStepProvider(widget.stepId)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    data: (data) => _corps(data),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  List<Widget> _corps(JourneyStepDetail detail) {
    final pastille =
        journeyEtapeSectionPill(detail.section, detail.objectif);
    final pied = journeyEtapeFoot(detail.section);
    final erreur = _erreur;
    return [
      if (pastille != null || detail.priorite)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (pastille != null) SfPill(label: pastille, tone: SfBarTone.now),
            // 🛑 **`priorite` est SERVI** : aucune position, aucun rang ne le
            // remplace.
            if (detail.priorite)
              const SfPill(label: kJourneyEtapePriorite, tone: SfBarTone.hot),
          ],
        ),
      SfPanelHead(
        lead: true,
        title: detail.unite.label,
        sub: detail.unite.description,
      ),
      // 🛑 **`validees` est SERVI** : c'est le compteur du moteur, celui qui
      // clôt l'étape. Le recompter depuis `series` aurait fait deux additions
      // de la même chose.
      SfSerieProgress(
        count: journeyEtapeCompteur(detail.validees, detail.quota),
        note: journeyEtapeSeuil(detail.seuilReussite, detail.questionsParSerie),
        noteSub: kJourneyEtapeSeuilSub,
        done: detail.validees,
        total: detail.quota,
      ),
      // 🛑 **« À faire » ne coiffe jamais une série réussie** : le partage se
      // lit sur `validee`, servi, et chaque liste garde l'ordre servi. Une
      // liste vide n'a pas d'intertitre.
      for (final (titre, reussies) in const [
        (kJourneyEtapeListTitle, false),
        (kJourneyEtapeDoneTitle, true),
      ])
        if (detail.series.any((serie) => serie.validee == reussies)) ...[
          const SizedBox(height: 12),
          SfSectionTitle(titre, flush: true, mono: true),
          for (var rang = 0; rang < detail.series.length; rang++)
            if (detail.series[rang].validee == reussies)
              _carte(
                detail,
                detail.series[rang],
                // 🛑 **La série précédente est celle que la LISTE SERVIE
                // porte avant**, jamais `index - 1` — et la liste ENTIÈRE,
                // pas la section.
                rang == 0 ? null : detail.series[rang - 1].index,
              ),
        ],
      const SizedBox(height: 12),
      if (erreur != null) SfTiny(erreur, color: AppColors.red),
      // 🛑 **`validee` de l'ÉTAPE est SERVI** : c'est la fonction qui la clôt
      // qui le rend. Le bouton ramène au cycle du Plan, qui sert l'étape
      // suivante.
      if (detail.validee) ...[
        const SfCard(
          variant: SfCardVariant.ok,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SfCheckRow(label: kJourneyEtapeDoneLead, large: true),
              SfTiny(kJourneyEtapeDoneSub),
            ],
          ),
        ),
        SfButton(
          label: kJourneyEtapeDoneCta,
          variant: SfButtonVariant.blue,
          onPressed: () => context.go(AppRoutes.plan),
        ),
      ],
      SfInfoNote(
        variant: SfInfoNoteVariant.check,
        child: RichText(
          text: TextSpan(
            style: AppFonts.ui(
                size: 11.5, color: AppColors.blueDark, height: 1.45),
            children: [
              TextSpan(
                text: kJourneyEtapeValidationLead,
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: AppColors.blueDark,
                  height: 1.45,
                ),
              ),
              TextSpan(
                text: journeyEtapeValidation(
                  detail.quota,
                  detail.seuilReussite,
                  detail.questionsParSerie,
                ),
              ),
            ],
          ),
        ),
      ),
      // 🛑 **Le verrou se DIT, il ne masque rien** : la liste reste entière
      // au-dessus.
      if (detail.locked) const SfTiny(kJourneyEtapeLockedNote),
      // 🛑 **En compréhension ORALE seulement**, sur le `section` servi —
      // jamais déduit d'une route.
      if (pied != null) SfTiny(pied),
    ];
  }

  /// Une carte de série.
  ///
  /// 🛑 **Deux verrous, deux lectures.** Celui de la SÉRIE est pédagogique
  /// (« la précédente n'est pas réussie ») : le bouton devient gris et porte la
  /// condition. Celui de l'ÉTAPE est commercial : le bouton reste vivant, et il
  /// ouvre l'offre — la même que le 403 que le serveur opposerait.
  Widget _carte(JourneyStepDetail detail, JourneySerie serie, int? precedente) {
    final ferme = serie.locked;
    final attemptId = serie.dernierAttemptId;
    return SfSerieCard(
      mark: journeyEtapeSerieMark(serie.index),
      title: journeyEtapeSerieTitle(serie.index),
      duree: journeyEtapeDuree(detail.dureeEstimeeMin),
      questions: journeyEtapeQuestions(detail.questionsParSerie),
      state: journeyEtapeSerieState(serie),
      score:
          journeyEtapeDernierScore(serie.dernierScore, detail.questionsParSerie),
      locked: ferme,
      // 🛑 **Jouée et jugée ⇒ compacte** : la carte ne porte plus « Refaire »,
      // la feuille s'en charge.
      verdict: journeyEtapeSerieVerdict(serie),
      onOpen: () => _ouvrirFeuille(detail, serie),
      actionLabel: journeyEtapeSerieCta(serie, precedente),
      onAction: ferme || _occupe
          ? null
          : detail.locked
              ? () => unawaited(_ouvrirOffre())
              : () => unawaited(_lancer(serie.index)),
      // 🛑 **Jouée sans score** (session non terminée) : ni verdict ni
      // feuille, le bouton reste sur la carte et le corrigé en lien, par le
      // chemin EXISTANT — le MÊME rapport de série, « Continuer » compris.
      linkLabel: attemptId == null ? null : kJourneyEtapeSerieResult,
      onLink: attemptId == null
          ? null
          : () => context.push(AppRoutes.examReportDepuisPlan(attemptId)),
    );
  }

  /// **La feuille d'une série jouée** — celle des sujets déjà traités
  /// (`showAppSheet`, miroir de l'`ExamDoneSheet` web) : le corrigé par le
  /// chemin EXISTANT, puis refaire par le même lancement que la carte — ou
  /// l'offre, si l'étape est fermée.
  void _ouvrirFeuille(JourneyStepDetail detail, JourneySerie serie) {
    final attemptId = serie.dernierAttemptId;
    showAppSheet<void>(
      context,
      icon: LucideIcons.fileText,
      title: journeyEtapeSerieTitle(serie.index),
      sub: journeyEtapeDernierScore(
          serie.dernierScore, detail.questionsParSerie),
      children: [
        if (attemptId != null)
          AppButton(
            label: kJourneyEtapeSerieResult,
            icon: LucideIcons.fileText,
            variant: AppButtonVariant.ghost,
            height: 46,
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.examReportDepuisPlan(attemptId));
            },
          ),
        AppButton(
          label: kJourneyEtapeSheetRedo,
          icon: LucideIcons.refreshCw,
          height: 46,
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(
                detail.locked ? _ouvrirOffre() : _lancer(serie.index));
          },
        ),
      ],
    );
  }

  /// **Lancer une série.**
  ///
  /// 🛑 **L'index est SERVI**, on le repasse tel quel. Le **403** n'est pas une
  /// panne : c'est le verrou que le serveur oppose, et il ouvre l'offre — jamais
  /// un message technique ([classifyStartFailure] est l'autorité).
  ///
  /// 🛑 **Le runner existant**, comme toute série : [AppRoutes.runnerDepuisPlan]
  /// lui dit de pousser le rapport de série en fin de passation, donc son
  /// « Continuer » redépile **sur cet écran** — pas sur le Plan.
  /// Le verrou **commercial** de l'étape : un CTA du Plan (`LOCKED_PLAN`),
  /// avec le parcours affiché — l'achat qui en part se rattache au tunnel.
  Future<void> _ouvrirOffre() => showPaywallSheet(
        context,
        ctaLocation: AnalyticsCtaLocation.lockedPlan,
        journeyId: planJourneyId(
          ref,
          civique: ref.read(parcoursCiviqueProvider) ?? false,
        ),
      );

  Future<void> _lancer(int index) async {
    if (_occupe) return;
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      final attempt = await ref
          .read(learningPlanRepositoryProvider)
          .startSerie(widget.stepId, index);
      if (!mounted) return;
      context.push(AppRoutes.runnerDepuisPlan(attempt.id));
    } catch (error) {
      if (!mounted) return;
      // 🛑 **Pas de `showPaywallOrError` ici** : sa branche « message » est une
      // SnackBar, qui disparaît — et l'écran porte déjà sa ligne d'erreur, à
      // l'endroit où le geste a échoué. On garde sa CLASSIFICATION, qui est
      // l'autorité, et on pose la phrase soi-même (même choix que la fin de
      // cycle, `plan_cycle_section.dart`).
      if (classifyStartFailure(error) == StartFailure.paywall) {
        unawaited(_ouvrirOffre());
      } else {
        setState(() => _erreur = kJourneyEtapeStartError);
      }
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }
}
