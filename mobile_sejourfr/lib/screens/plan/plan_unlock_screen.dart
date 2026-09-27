import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cecrl_track.dart';
import 'learning_plan_provider.dart';
import '../../core/widgets/paywall_context.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic_civique/civic_diagnostic_blocks.dart';
import '../diagnostic_civique/civic_diagnostic_labels.dart';
import 'journey_labels.dart';
import 'plan_labels.dart';
import 'plan_unlock_labels.dart';

/// **L'écran de transition « Débloquer mon plan »** — entre le Plan et l'écran
/// de choix du pass (maquettes du propriétaire, 2026-09-20).
///
/// 🛑 **UN SEUL écran pour les deux modules.** Les deux maquettes partagent
/// l'anatomie et ne diffèrent que par leur matière : deux écrans divergeraient
/// au premier correctif (D-50 / A86). Miroir web : `PlanUnlockScreen`.
///
/// 🛑 **Le héros dit ce que les réponses ont montré** : un ancien résultat de
/// diagnostic 4 épreuves s'il existe, sinon le Plan (le cas ordinaire).
///
/// 🛑 **« Vos priorités » est rangé COMME LE PLAN** (demande du propriétaire,
/// 2026-09-26) : un encart rétractable par épreuve TCF (`plan.domaines`) ou par
/// thème civique (le regroupement du cycle civique), avec au plus
/// [kPlanUnlockMaxParGroupe] lignes chacun — un plafond d'**affichage** ; le
/// sous-titre annonce le total **servi**. Une épreuve ou un thème **non
/// évalué** (fait servi : `evaluated`, `nonEvalue`) garde son encart, sans
/// liste : *null = inconnu, jamais mauvais*.
///
/// 🛑 **Aucun état n'est dérivé d'un nombre.** Côté civique la pastille est
/// l'`etat` SERVI du thème ([CivicThemeState]) ; côté TCF c'est la `nature`
/// servie de chaque action et l'urgence servie de chaque épreuve
/// ([PlanDomainPriority]).
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

/// **Un encart** : une épreuve du TCF, ou un thème civique — le même
/// regroupement que le cycle du Plan.
///
/// 🛑 `evalue` est **servi** (`PlanDomain.evaluated`, [CivicThemeState]),
/// jamais déduit d'une liste vide. `lignes == null` = on ne sait pas ce que le
/// Plan y demande (parcours civique illisible) : on n'affirme alors rien.
typedef _Groupe = ({
  String key,
  String mark,
  String title,
  String meta,
  ({String label, SfTone tone}) status,
  bool evalue,
  List<SfMiniRow>? lignes,
  String? autres,
});

/// Le héros : palier de départ face à l'objectif, sur le rail du kit.
typedef _Heros = ({
  String heroValue,
  String? heroPill,
  double? heroRatio,
  String? heroMeta,
});

/// Ce que l'écran a besoin de savoir, quel que soit le module.
typedef _Matiere = ({
  _Heros heros,
  List<_Groupe> groupes,
  int total,
  ({String titre, String? note})? encart,
  List<String> checks,
});

/// Le héros TCF, lu **sur le résultat du diagnostic 4 épreuves** quand un
/// ancien résultat existe (le parcours est retiré des fronts depuis le
/// 2026-09-26, ses résultats restent lus).
///
/// 🛑 Le rail est celui du kit ([cecrlTrack]) : la seule échelle affichée de
/// l'app, et en inventer une seconde ici ferait deux positions différentes pour
/// le même palier.
_Heros _herosDuDiagnostic(TcfDiagnosticResultDto r) {
  final track = cecrlTrack(r.niveauGlobal, r.cible);
  return (
    heroValue: r.niveauGlobal?.shortName ?? kPlanUnlockLevelUnknown,
    heroPill: planUnlockGoalPill(r.cible?.shortName),
    heroRatio: track == null || track.levels.length < 2
        ? null
        : track.currentIndex / (track.levels.length - 1),
    heroMeta: track?.levels.join(' · '),
  );
}

/// Le héros TCF **lu sur le PLAN** — le cas ordinaire : le Plan existe pour
/// tout compte (D-69).
_Heros _herosDuPlan(LearningPlan plan) {
  // 🛑 `cycle` est **nullable** : sans démarche déclarée, il n'y a ni palier de
  // départ ni objectif — on n'en invente aucun, le hero dit « — » et le rail
  // ne se dessine pas.
  final cycle = plan.cycle;
  // 🛑 **L'objectif DÉCLARÉ, jamais le palier en construction.**
  final cible = cycle?.objectiveLevel?.asNiveau;
  final track = cecrlTrack(cycle?.startingLevel, cible);
  return (
    heroValue: cycle?.startingLevel?.shortName ?? kPlanUnlockLevelUnknown,
    heroPill: planUnlockGoalPill(cible?.shortName),
    heroRatio: track == null || track.levels.length < 2
        ? null
        : track.currentIndex / (track.levels.length - 1),
    heroMeta: track?.levels.join(' · '),
  );
}

/// **Les priorités TCF, épreuve par épreuve** — lues sur `plan.domaines`, les
/// quatre épreuves du Plan (jamais `TCF_STRUCTURE`), dans l'ordre d'urgence
/// **servi**.
///
/// 🛑 **Jamais sur `currentPriority` + `nextPriorities`** : une vue bornée à
/// cinq lignes pour tout le Plan, et une carte d'épreuve ne dérive jamais d'une
/// liste déjà tronquée. `domaines[].skills` porte **toutes** les actions du
/// pool (`nature` non nulle), et `priorityRank` leur place dans le classement
/// complet : l'encart les montre dans l'ordre du Plan.
///
/// 🛑 La pastille d'une ligne dit la **nature servie** : une compétence *à
/// acquérir* n'a rien d'observé et ne se lit jamais « à renforcer ».
({List<_Groupe> groupes, int total}) _groupesTcf(LearningPlan plan) {
  const module = PlanUnlockModule.tcf;
  var total = 0;
  final groupes = <_Groupe>[];
  for (final d in plan.domaines) {
    final mark = planDomainSection(d.epreuve)?.wire ?? '';
    final title = planDomainLabel(d.epreuve);
    if (!d.evaluated) {
      groupes.add((
        key: d.epreuve.wire,
        mark: mark,
        title: title,
        meta: planUnlockNonEvalueMeta(module),
        status: (label: planUnlockNonEvalue(module), tone: SfTone.muted),
        evalue: false,
        lignes: const <SfMiniRow>[],
        autres: null,
      ));
      continue;
    }
    // L'ordre du classement servi ; un backend antérieur au rang garde l'ordre
    // du référentiel (tri stable).
    final servies = [
      for (final sk in d.skills)
        if (sk.nature != null) sk,
    ];
    // Tri stable : à rang égal (ou absent), l'index servi départage.
    final ordre = [for (var i = 0; i < servies.length; i++) i]
      ..sort((a, b) {
        final ra = servies[a].priorityRank ?? 1 << 30;
        final rb = servies[b].priorityRank ?? 1 << 30;
        return ra != rb ? ra.compareTo(rb) : a.compareTo(b);
      });
    final actions = [for (final i in ordre) servies[i]];
    total += actions.length;
    final montrees = actions.take(kPlanUnlockMaxParGroupe).toList();
    groupes.add((
      key: d.epreuve.wire,
      mark: mark,
      title: title,
      meta: planUnlockGroupeMeta(module, actions.length),
      status: (
        label: d.priority.label,
        tone: planUnlockDomainTone(d.priority),
      ),
      evalue: true,
      lignes: [
        for (final sk in montrees)
          SfMiniRow(
            label: sk.title,
            pill: sk.nature!.label,
            tone: planUnlockNatureTone(sk.nature!),
          ),
      ],
      autres: planUnlockAutres(module, actions.length - montrees.length),
    ));
  }
  return (groupes: groupes, total: total);
}

/// La matière TCF : le héros d'une source, les encarts du Plan.
_Matiere _matiereTcf(_Heros heros, LearningPlan plan) {
  final g = _groupesTcf(plan);
  return (
    heros: heros,
    groupes: g.groupes,
    total: g.total,
    encart: null,
    checks: planUnlockChecksTcf(g.total),
  );
}

/// **Les thèmes civiques**, le regroupement du cycle civique du Plan.
///
/// - l'encart et son **état** viennent du diagnostic (`themes`, les cinq,
///   `etat` servi — `nonEvalue` compris) ;
/// - ses **lignes** sont les unités officielles que le cycle civique garde
///   ouvertes dans ce thème (`JourneyBloc.steps`, non bornées), dans l'ordre
///   de la file.
///
/// 🛑 **Aucune pastille par unité** : l'état servi du diagnostic civique est au
/// grain du THÈME. Il est dans l'en-tête ; en fabriquer un par unité serait
/// l'inventer.
List<_Groupe> _groupesCivique(CivicDiagnosticResultDto r, Journey? journey) {
  const module = PlanUnlockModule.civique;
  return [
    for (final t in r.themes) _groupeCivique(module, t, journey),
  ];
}

_Groupe _groupeCivique(
    PlanUnlockModule module, CivicThemeResultat t, Journey? journey) {
  // `CivicThemeState.nonEvalue.label` vaut déjà « Non évalué ».
  final status = (label: t.etat.label, tone: sfToneOf(t.etat));
  if (t.etat == CivicThemeState.nonEvalue) {
    return (
      key: t.code,
      mark: '',
      title: t.label,
      meta: planUnlockNonEvalueMeta(module),
      status: status,
      evalue: false,
      lignes: const <SfMiniRow>[],
      autres: null,
    );
  }
  JourneyBloc? bloc;
  for (final b in journey?.blocs ?? const <JourneyBloc>[]) {
    if (b.bloc.code == t.code) {
      bloc = b;
      break;
    }
  }
  final ouvertes = bloc?.steps
      .where((st) =>
          st.status == JourneyStepStatus.upcoming ||
          st.status == JourneyStepStatus.current)
      .toList();
  final montrees = ouvertes?.take(kPlanUnlockMaxParGroupe).toList();
  return (
    key: t.code,
    mark: '',
    title: t.label,
    meta: ouvertes == null ? '' : planUnlockGroupeMeta(module, ouvertes.length),
    status: status,
    evalue: true,
    lignes: montrees == null
        ? null
        : [for (final st in montrees) SfMiniRow(label: journeyStepTitle(st))],
    autres: ouvertes == null || montrees == null
        ? null
        : planUnlockAutres(module, ouvertes.length - montrees.length),
  );
}

/// La matière civique, lue **sur le résultat du diagnostic civique**.
_Matiere _matiereCivique(CivicDiagnosticResultDto r, Journey? journey) {
  final titre = civicSituationsTitre(r);
  return (
    heros: (
      heroValue: civicScoreLabel(r) ?? kPlanUnlockLevelUnknown,
      heroPill: planUnlockSeuilPill(r.seuilReussite, r.formatQuestions),
      heroRatio: civicScoreRatio(r),
      heroMeta: civicEcartLine(r),
    ),
    groupes: _groupesCivique(r, journey),
    // Le sous-titre civique compte les thématiques que le diagnostic classe —
    // inchangé.
    total: r.priorites.length,
    encart: titre == null ? null : (titre: titre, note: civicSituationsNote(r)),
    checks: kPlanUnlockChecksCivique,
  );
}

/// **L'encart ouvert à l'arrivée** : le premier, dans l'ordre servi, qui a des
/// priorités à montrer.
///
/// Le cycle du Plan déplie son premier bloc ; ici le premier peut être une
/// épreuve non évaluée — sans liste —, et l'ouvrir montrerait un encart vide au
/// moment où l'écran doit dire ce que le plan contient. L'ordre TCF est déjà
/// celui de l'urgence (`domaines`), donc c'est l'épreuve la plus urgente qui a
/// du travail. Aucun ⇒ tout reste replié. Miroir web : `groupeOuvertParDefaut`.
String? _groupeOuvertParDefaut(List<_Groupe> groupes) {
  for (final g in groupes) {
    if (g.lignes != null && g.lignes!.isNotEmpty) return g.key;
  }
  return null;
}

class PlanUnlockScreen extends ConsumerStatefulWidget {
  const PlanUnlockScreen({super.key, required this.module});

  final PlanUnlockModule module;

  @override
  ConsumerState<PlanUnlockScreen> createState() => _PlanUnlockScreenState();
}

class _PlanUnlockScreenState extends ConsumerState<PlanUnlockScreen> {
  _Matiere? _matiere;

  /// `null` = le candidat n'a rien touché : on suit l'encart par défaut. Une
  /// fois un en-tête touché, c'est **son** choix qui vaut — « tout replié »
  /// compris. Même geste que le cycle du Plan.
  ({String? key})? _choix;

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
        // Le cycle civique donne les lignes de chaque thème. Il est déjà en
        // mémoire (le Plan l'a lu) ; illisible, les encarts restent — sans
        // lignes, et sans rien affirmer.
        Journey? journey;
        try {
          journey = await ref.read(journeyCiviqueProvider.future);
        } catch (_) {
          journey = null;
        }
        if (!mounted) return;
        setState(() => _matiere = _matiereCivique(r, journey));
        return;
      }
      // 🛑 **Les encarts viennent TOUJOURS du Plan** — c'est le Plan qu'on
      // vend, et ses domaines portent toutes les actions de chaque épreuve. Le
      // Plan est déjà chargé par l'écran qui a poussé celui-ci.
      final plan = await ref.read(learningPlanProvider.future);
      // Le héros : un ancien diagnostic 4 épreuves s'il existe (un palier
      // global mesuré sur les quatre), sinon le Plan.
      final repo = ref.read(tcfDiagnosticRepositoryProvider);
      TcfDiagnosticDto? session;
      try {
        session = await repo.current();
      } catch (_) {
        session = null;
      }
      final heros = session != null &&
              session.status == TcfDiagnosticStatus.completed
          ? _herosDuDiagnostic(await repo.readResult(session.sessionId))
          : _herosDuPlan(plan);
      final matiere = _matiereTcf(heros, plan);
      // Aucune action servie nulle part : rien à raconter.
      if (matiere.total == 0) {
        _rienARaconter();
        return;
      }
      if (!mounted) return;
      setState(() => _matiere = matiere);
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

  bool get _civique => widget.module == PlanUnlockModule.civique;

  /// Le `journey.id` du Plan qui a poussé cet écran — déjà chargé, jamais
  /// redemandé. `null` s'il ne l'est pas : l'achat reste attribué au CTA.
  String? get _journeyId => ref
      .read(_civique ? journeyCiviqueProvider : journeyProvider)
      .valueOrNull
      ?.journeyId;

  /// 🛑 Toute offre ouverte d'ici est un CTA **du Plan** (`LOCKED_PLAN`) : avec
  /// le parcours, c'est ce qui rattache l'achat au tunnel (Q12, D32).
  Future<void> _ouvrirOffre() => showPaywallSheet(
        context,
        ctaLocation: AnalyticsCtaLocation.lockedPlan,
        journeyId: _journeyId,
      );

  void _acheter() {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.track(
      AnalyticsEvent.premiumCtaClicked,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
      path: AnalyticsPath.plan,
    );
    // Étape 6 du tunnel « Suivi » : ce que le candidat avait sous les yeux —
    // le pass d'entrée et son prix AFFICHÉ, jamais un montant payé.
    final pass = passFromPlan(
      ref.read(_plansProvider).valueOrNull,
      planUnlockPassModule(widget.module),
    );
    analytics.track(
      AnalyticsEvent.planUnlockClicked,
      path: AnalyticsPath.planUnlock,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
      planCode: pass?.code,
      displayedPriceCents: pass == null ? null : (pass.price * 100).round(),
      journeyId: _journeyId,
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

    // 🛑 **CET ÉCRAN N'EXISTE QUE TANT QUE L'ACCÈS MANQUE.** Il est poussé par
    // le Plan pour proposer le déblocage, et il pousse lui-même l'offre par
    // dessus : quand l'achat est vérifié, la feuille se ferme et le candidat
    // retombait ICI, devant « Débloquer mon plan » — alors qu'il venait de
    // payer. Il se retire donc de lui-même dès que l'accès arrive.
    //
    // ⚠️ `accesModuleProvider` observe l'`AuthController`, que
    // `refreshSubscriptionStatus` met à jour à la vérification du reçu : le
    // retrait suit le paiement, sans rien savoir du chemin d'achat.
    ref.listen<bool>(accesModuleProvider(planUnlockAccessModule(module)),
        (_, ouvert) {
      if (ouvert && mounted) _retour();
    });

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
                            value: m.heros.heroValue,
                            pill: m.heros.heroPill,
                            ratio: m.heros.heroRatio,
                            metaLabel: m.heros.heroMeta,
                          ),
                        ),

                        // 2 — ce que le plan promet, et sur quoi il s'appuie.
                        SfSection(
                          flush: true,
                          child: SfPanelHead(
                            lead: true,
                            title: planUnlockTitle(module),
                            sub: planUnlockLead(module, m.total),
                          ),
                        ),

                        // 3 — les priorités, épreuve par épreuve (ou thème
                        // par thème) : le regroupement du cycle du Plan, dans
                        // l'ordre SERVI.
                        SfSection(
                          title: planUnlockListTitle(module),
                          flush: true,
                          child: _Groupes(
                            module: module,
                            groupes: m.groupes,
                            ouvert: _choix == null
                                ? _groupeOuvertParDefaut(m.groupes)
                                : _choix!.key,
                            onToggle: (key, ouvert) => setState(
                              () => _choix = (key: ouvert == key ? null : key),
                            ),
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

/// Les encarts rétractables — le `SfBlocAccordion` du cycle du Plan, même
/// en-tête d'épreuve (repère, nom, méta, état) et même geste de dépliage.
class _Groupes extends StatelessWidget {
  const _Groupes({
    required this.module,
    required this.groupes,
    required this.ouvert,
    required this.onToggle,
  });

  final PlanUnlockModule module;
  final List<_Groupe> groupes;
  final String? ouvert;
  final void Function(String key, String? ouvert) onToggle;

  @override
  Widget build(BuildContext context) {
    return SfStack(
      pad: false,
      children: [
        for (final g in groupes)
          SfBlocAccordion(
            mark: g.mark,
            title: g.title,
            meta: g.meta,
            status: g.status,
            open: ouvert == g.key,
            onToggle: () => onToggle(g.key, ouvert),
            child: _corps(g),
          ),
      ],
    );
  }

  Widget _corps(_Groupe g) {
    if (!g.evalue) return SfTiny(planUnlockNonEvalueNote(module));
    final lignes = g.lignes;
    if (lignes == null) return const SizedBox.shrink();
    if (lignes.isEmpty) return SfTiny(g.meta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SfMiniPlan(rows: lignes),
        if (g.autres != null) ...[
          const SizedBox(height: 6),
          SfTiny(g.autres!),
        ],
      ],
    );
  }
}
