import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cecrl_track.dart';
import 'learning_plan_provider.dart';
import '../../core/widgets/paywall_context.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic_civique/civic_diagnostic_blocks.dart';
import '../diagnostic_civique/civic_diagnostic_labels.dart';
import '../diagnostic_tcf/tcf_diagnostic_labels.dart';
import 'plan_unlock_labels.dart';

/// **L'écran de transition « Débloquer mon plan »** — entre le Plan et l'écran
/// de choix du pass (maquettes du propriétaire, 2026-09-20).
///
/// 🛑 **UN SEUL écran pour les deux modules.** Les deux maquettes partagent
/// l'anatomie et ne diffèrent que par leur matière : deux écrans divergeraient
/// au premier correctif (D-50 / A86). Miroir web : `PlanUnlockScreen`.
///
/// 🛑 **Tout vient du DIAGNOSTIC** (demande du propriétaire : « et ces
/// priorités viennent du diagnostic »). Le héros, la liste et les pastilles se
/// lisent sur le **résultat du diagnostic** du module — jamais sur le Plan,
/// jamais sur le parcours : l'écran dit ce que les réponses ont montré, pas où
/// en est le plan aujourd'hui. Deux sources sur le même écran finiraient par se
/// contredire.
///
/// 🛑 **Aucun état n'est dérivé d'un nombre.** Côté civique la pastille est
/// l'`etat` SERVI du thème ([CivicThemeState]) ; côté TCF c'est
/// [prioritePastille], l'autorité que le rapport de diagnostic emploie déjà
/// pour la même liste.
///
/// 🛑 **Aucun prix écrit.** Le montant est le **minimum servi** des pass du
/// module ([passFromPrice]), lu sur le catalogue backend — la même autorité et
/// le même chiffre que le web. Catalogue injoignable ⇒ pas de ligne de prix,
/// jamais un montant de repli.
///
/// 🛑 **Sans diagnostic terminé, cet écran ne s'affiche pas** : il ouvre
/// directement l'offre et se retire. Un écran de transition qui n'a rien à
/// raconter n'a pas à retarder un achat — et il n'invente aucune liste.

/// Le catalogue backend, **lu ici** : l'écran a besoin du prix d'entrée, pas
/// des produits du store (qui ne se chargent que sur l'écran d'achat).
final _plansProvider =
    FutureProvider.autoDispose<List<PlanPublicResponse>>((ref) {
  return ref.read(billingRepositoryProvider).listPlans();
});

/// Ce que l'écran a besoin de savoir, quel que soit le module.
typedef _Matiere = ({
  String heroValue,
  String? heroPill,
  double? heroRatio,
  String? heroMeta,
  List<SfMiniRow> lignes,
  ({String titre, String? note})? encart,
  List<String> checks,
});

/// La matière TCF, lue **sur le résultat du diagnostic 4 épreuves**.
///
/// 🛑 Le rail est celui du kit ([cecrlTrack]) : la seule échelle affichée de
/// l'app, et en inventer une seconde ici ferait deux positions différentes pour
/// le même palier.
_Matiere _matiereTcf(TcfDiagnosticResultDto r) {
  final track = cecrlTrack(r.niveauGlobal, r.cible);
  return (
    heroValue: r.niveauGlobal?.shortName ?? kPlanUnlockLevelUnknown,
    heroPill: planUnlockGoalPill(r.cible?.shortName),
    heroRatio: track == null || track.levels.length < 2
        ? null
        : track.currentIndex / (track.levels.length - 1),
    heroMeta: track?.levels.join(' · '),
    lignes: [
      for (final p in r.priorites)
        SfMiniRow(
          // « Expression orale — Tâche 3 » : la TÂCHE officielle est nommée,
          // jamais la personne. Même composition que la carte de priorité du
          // rapport de diagnostic.
          label: prioriteIntitule(
            epreuvePresentation(p.epreuve).label,
            p.taskCode,
          ),
          pill: prioritePastille(p.rang).label,
          tone: switch (prioritePastille(p.rang).tone) {
            EpreuveMentionTone.ok => SfTone.ok,
            EpreuveMentionTone.warn => SfTone.warn,
            EpreuveMentionTone.hot => SfTone.hot,
          },
        ),
    ],
    encart: null,
    checks: planUnlockChecksTcf(r.priorites.length),
  );
}

/// La matière TCF **lue sur le PLAN** — le repli quand le diagnostic
/// 4 épreuves n'existe pas.
///
/// 🛑 **C'est le cas NORMAL, pas un cas limite.** Le Plan existe dès que le
/// diagnostic **rapide** est clos (`prep.planDisponible`) ; le diagnostic
/// 4 épreuves, lui, est un geste distinct que la plupart des candidats n'ont
/// pas fait. Sans ce repli, l'écran n'avait rien à raconter et se retirait
/// aussitôt — le candidat retombait sur le paywall direct, exactement ce que
/// cet écran existe pour éviter (A145).
///
/// Ce qu'on montre ne change pas : le palier de départ face à l'objectif, et
/// les priorités. Seule la **source** change — et c'est celle que le Plan
/// affiche déjà, donc l'écran de vente ne peut pas nommer autre chose que le
/// Plan qu'on vend.
_Matiere _matiereTcfDuPlan(LearningPlan plan) {
  // 🛑 `cycle` est **nullable** : sans démarche déclarée, il n'y a ni palier de
  // départ ni objectif — on n'en invente aucun, le hero dit « — » et le rail
  // ne se dessine pas. Les priorités, elles, restent servies.
  final cycle = plan.cycle;
  // 🛑 **L'objectif DÉCLARÉ, jamais le palier en construction.**
  // `targetLevel` est le palier que le cycle bâtit ; l'annoncer « Objectif
  // B2 » à un candidat qui n'a pas déclaré sa démarche lui promettrait une
  // cible qu'il n'a pas choisie.
  final cible = cycle?.objectiveLevel?.asNiveau;
  final track = cecrlTrack(cycle?.startingLevel, cible);
  final priorites = <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ];
  return (
    heroValue: cycle?.startingLevel?.shortName ?? kPlanUnlockLevelUnknown,
    heroPill: planUnlockGoalPill(cible?.shortName),
    heroRatio: track == null || track.levels.length < 2
        ? null
        : track.currentIndex / (track.levels.length - 1),
    heroMeta: track?.levels.join(' · '),
    // 🛑 La pastille dit la **nature servie** de l'action, jamais un rang : une
    // compétence *à acquérir* n'a rien d'observé et ne peut pas se lire « à
    // renforcer ».
    lignes: [
      for (final p in priorites)
        SfMiniRow(
          label: p.title,
          pill: p.nature.label,
          tone: planUnlockNatureTone(p.nature),
        ),
    ],
    encart: null,
    checks: planUnlockChecksTcf(priorites.length),
  );
}

/// La matière civique, lue **sur le résultat du diagnostic civique**.
_Matiere _matiereCivique(CivicDiagnosticResultDto r) {
  final titre = civicSituationsTitre(r);
  return (
    heroValue: civicScoreLabel(r) ?? kPlanUnlockLevelUnknown,
    heroPill: planUnlockSeuilPill(r.seuilReussite, r.formatQuestions),
    heroRatio: civicScoreRatio(r),
    heroMeta: civicEcartLine(r),
    lignes: [
      for (final p in r.priorites)
        SfMiniRow(
          label: p.label,
          // 🛑 L'état est SERVI (`CivicThemeState`), pas déduit du rang.
          pill: p.etat.label,
          tone: sfToneOf(p.etat),
        ),
    ],
    encart: titre == null ? null : (titre: titre, note: civicSituationsNote(r)),
    checks: kPlanUnlockChecksCivique,
  );
}

class PlanUnlockScreen extends ConsumerStatefulWidget {
  const PlanUnlockScreen({super.key, required this.module});

  final PlanUnlockModule module;

  @override
  ConsumerState<PlanUnlockScreen> createState() => _PlanUnlockScreenState();
}

class _PlanUnlockScreenState extends ConsumerState<PlanUnlockScreen> {
  _Matiere? _matiere;

  /// `true` dès qu'on sait qu'il n'y a rien à raconter : on passe la main à
  /// l'offre sans jamais rendre un écran vide.
  bool _sansDiagnostic = false;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  Future<void> _charger() async {
    try {
      if (widget.module == PlanUnlockModule.civique) {
        final repo = ref.read(civicDiagnosticRepositoryProvider);
        final session = await repo.current();
        if (session == null ||
            session.status != TcfDiagnosticStatus.completed) {
          _rienARaconter();
          return;
        }
        // 🛑 `readResult` (GET) et non `result` (POST) : cet écran LIT un
        // diagnostic déjà clos, il n'en clôture aucun.
        final r = await repo.readResult(session.sessionId);
        if (!mounted) return;
        setState(() => _matiere = _matiereCivique(r));
        return;
      }
      // Le diagnostic 4 épreuves d'abord — c'est la matière la plus riche (un
      // palier par épreuve, la tâche officielle nommée). Il est **rarement
      // là** : c'est un geste à part.
      final repo = ref.read(tcfDiagnosticRepositoryProvider);
      final session = await repo.current();
      if (session != null &&
          session.status == TcfDiagnosticStatus.completed) {
        final r = await repo.readResult(session.sessionId);
        // Un diagnostic clos sans aucune priorité n'a pas de liste à montrer :
        // on retombe sur le Plan plutôt que de fabriquer un écran vide.
        if (r.priorites.isNotEmpty) {
          if (!mounted) return;
          setState(() => _matiere = _matiereTcf(r));
          return;
        }
      }
      // 🛑 **Le repli est le chemin ORDINAIRE.** Le Plan est déjà chargé par
      // l'écran qui a poussé celui-ci : on le lit, on ne le redemande pas.
      final plan = await ref.read(learningPlanProvider.future);
      if (plan.currentPriority == null && plan.nextPriorities.isEmpty) {
        _rienARaconter();
        return;
      }
      if (!mounted) return;
      setState(() => _matiere = _matiereTcfDuPlan(plan));
    } catch (_) {
      _rienARaconter();
    }
  }

  /// 🛑 **On ne bloque jamais un achat.** Sans diagnostic exploitable, l'écran
  /// s'efface et laisse l'offre à sa place — il se retire de la pile pour que
  /// le retour depuis l'offre ramène au Plan, pas ici.
  void _rienARaconter() {
    if (!mounted || _sansDiagnostic) return;
    _sansDiagnostic = true;
    unawaited(_ouvrirOffre().then((_) {
      if (mounted) _retour();
    }));
  }

  Future<void> _ouvrirOffre() => showPaywallSheet(
        context,
        initialTarget: planUnlockPassModule(widget.module),
      );

  void _acheter() {
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.premiumCtaClicked,
          ctaLocation: AnalyticsCtaLocation.lockedPlan,
          path: AnalyticsPath.plan,
        );
    unawaited(_ouvrirOffre());
  }

  /// 🛑 **Jamais un `pop()` nu** : cet écran est poussé par le Plan, mais un
  /// lien profond ou un démarrage à froid le laisserait sans personne en
  /// dessous — et la croix ne répondrait plus. `retourOuRepli` dépile si elle
  /// peut, sinon elle rejoint le Plan, où le candidat aurait atterri.
  void _retour() => retourOuRepli(context, repli: AppRoutes.plan);

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final m = _matiere;
    final prix = planUnlockPriceLine(
      passFromPrice(
        ref.watch(_plansProvider).valueOrNull,
        planUnlockPassModule(module),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: m == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SfSheetHead(
                    eyebrow: planUnlockEyebrow(module),
                    onClose: _retour,
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.blue),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        SfSheetHead(
                          eyebrow: planUnlockEyebrow(module),
                          onClose: _retour,
                        ),

                        // 1 — l'écart, en un coup d'œil. Palier ou score :
                        // deux faits servis, posés dans la même brique.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SfGoalHero(
                            label: planUnlockHeroLabel(module),
                            value: m.heroValue,
                            pill: m.heroPill,
                            ratio: m.heroRatio,
                            metaLabel: m.heroMeta,
                          ),
                        ),

                        // 2 — ce que le plan promet, et sur quoi il s'appuie.
                        SfSection(
                          flush: true,
                          child: SfPanelHead(
                            lead: true,
                            title: planUnlockTitle(module),
                            sub: planUnlockLead(module, m.lignes.length),
                          ),
                        ),

                        // 3 — la liste numérotée, dans l'ordre SERVI.
                        SfSection(
                          title: planUnlockListTitle(module),
                          flush: true,
                          child: SfCard(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: SfMiniPlan(rows: m.lignes),
                          ),
                        ),

                        // 4 — le bloc propre au module : l'encart des mises en
                        // situation côté civique, rien côté TCF.
                        if (m.encart != null)
                          SfSection(
                            flush: true,
                            child: SfNoteCard(
                              icon: LucideIcons.circleAlert,
                              variant: SfCardVariant.warn,
                              title: m.encart!.titre,
                              child: m.encart!.note == null
                                  ? null
                                  : SfTiny(m.encart!.note!),
                            ),
                          ),

                        // 5 — ce que le pass ouvre.
                        SfSection(
                          flush: true,
                          child: SfCard(
                            variant: SfCardVariant.soft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final c in m.checks) SfCheckRow(label: c),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SfStickyBar(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SfButton(
                          label: kPlanUnlockCta,
                          lead: prix,
                          caption: kPlanUnlockPriceNote,
                          onPressed: _acheter,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _retour,
                          child: Text(
                            kPlanUnlockSkip,
                            style: AppFonts.ui(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
