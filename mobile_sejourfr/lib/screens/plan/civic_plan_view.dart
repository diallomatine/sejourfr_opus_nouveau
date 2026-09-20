import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/civique_examen.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_plan_labels.dart';
import 'civic_serie_launcher.dart';
import 'civic_plan_provider.dart';
import 'journey_labels.dart';
import 'learning_plan_provider.dart';
import 'plan_now_card.dart';
import 'widgets/plan_cycle_section.dart';

/// **Le plan civique** (L10, `20_` §6), dans l'ordre de la maquette.
///
/// Le plan est un **moteur** : il relit tout l'historique des réponses à chaque
/// lecture, y compris celles des séries et des examens blancs, et il dit
/// **quand y revenir**.
///
/// 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise,
/// l'état de leur thème, leur échéance et leur verrou arrivent **servis**. Cet
/// écran les met en mots (`civic_plan_labels.dart`) et ouvre ce qui existe déjà.
///
/// 🛑 **La boîte Leitner ne s'affiche jamais** : on montre `maitrise` et
/// `prochaineRevue`, jamais `boite`.
///
/// 🛑 **Le constat est intégralement gratuit.** Le `locked` servi porte sur la
/// **série**, jamais sur ce que le candidat a mesuré.
///
/// ## ⚠️ UNE SEULE ANATOMIE, ABONNÉ COMME GRATUIT (2026-09-20)
///
/// **Demande du propriétaire, verbatim** : « pour la partie Examen civique du
/// plan, pour un non abonné, il faut aussi la même chose qu'un abonné, sauf
/// qu'il peut pas travailler dessus. comme ce qu'on fait actuellement sur le
/// TCF. il voit le plan, mais il peut pas travailler dessus, il doit débloquer
/// son plan. »
///
/// ⚠️ **Ceci RÉVOQUE A89** (« ce que D-50 arbitre, c'est le Plan civique
/// *abonné* ; l'écran gratuit garde ses sections ») et, avec elle, l'anatomie
/// gratuite : la carte de score du diagnostic, « Thèmes à travailler »,
/// « Vos priorités » et « Votre première étape est prête » sont **supprimées**.
/// C'est la transposition exacte de la passe TCF du même jour (A114).
///
/// L'ordre est donc le même pour les deux : [SfTop] → bande objectif →
/// « À faire maintenant » → le **cycle** → « À revoir bientôt ». Seul le pied
/// change — l'offre et sa barre basse pour un compte sans accès, « Aller plus
/// loin » pour un abonné.
///
/// 🛑 **Ce qui TIENT** : « dans le plan, on ne travaille rien si on n'est pas
/// abonné » (D-33, que `CivicPlanService` oppose déjà en **403**). La garantie
/// n'est pas dans cet écran — [civicNowCard] et [civicCibleGeste] rendent
/// [PlanNowGeste.debloquer] dès que `free`, et les lanceurs ne sont attachés
/// qu'à la branche [PlanNowGeste.lancer].
///
/// 🛑 **La contradiction #1 reste fermée** : le nom de l'étape, l'état de
/// maîtrise, les compteurs et les échéances sont des **résultats mesurés** — ils
/// restent lisibles. On floute l'**action**, jamais le **résultat**.
class CivicPlanView extends ConsumerStatefulWidget {
  const CivicPlanView({super.key});

  @override
  ConsumerState<CivicPlanView> createState() => _CivicPlanViewState();
}

class _CivicPlanViewState extends ConsumerState<CivicPlanView> {
  /// 🛑 **Seul l'état d'ÉCRAN vit ici.** Le plan, lui, vient de
  /// [civicPlanProvider] : il vivait en `initState` + `setState`, donc chaque
  /// bascule de parcours démontait cette vue, jetait le plan et **rappelait
  /// `/api/me/civic-plan`** — pour une réponse identique. Le provider est
  /// **maintenu vivant par `PlanScreen`**, qui observe les deux parcours : la
  /// bascule ne coûte plus aucun appel.
  String? _enCours;
  /// Le tiré-pour-rafraîchir, seul point qui redemande le plan — avec le retour
  /// d'un entraînement joué au-dessus (`PlanScreen.didPopNext`).
  Future<void> _load() async {
    ref.invalidate(civicPlanProvider);
    try {
      await ref.read(civicPlanProvider.future);
    } catch (_) {
      // Best-effort : l'onglet reste sobre. Le constat existe déjà côté
      // diagnostic, on ne remplace pas un plan par une erreur.
    }
  }

  /// **La seule porte d'achat** : l'écran d'offre, qui porte les vrais passes
  /// et leurs prix du store. La durée choisie ici n'est qu'une préférence
  /// affichée — c'est là-bas qu'on achète.
  /// 🛑 **Depuis le Plan, TOUT chemin vers le paywall passe par l'ÉCRAN DE
  /// TRANSITION** (demande du propriétaire, 2026-09-20, TCF **et** civique) :
  /// il dit au candidat ce qu'il achète — ses priorités, son écart à
  /// l'objectif, le prix d'entrée — avant de lui montrer des durées et des
  /// montants. Deux chemins vers le même achat, dont un plus pauvre, c'est la
  /// porte que personne ne pense à corriger.
  ///
  /// ⚠️ Les paywalls qui répondent à un **403** restent en place : ce sont des
  /// refus, pas des gestes d'achat.
  Future<void> _ouvrirOffre() async =>
      context.push(AppRoutes.planUnlockPath(civique: true));

  @override
  Widget build(BuildContext context) {
    // 🛑 **La bascule de parcours ne se fait jamais attendre.** C'est l'en-tête
    // qui la porte (`SfTopSlot`), donc on le rend dès le premier passage, avant
    // le plan : une roue seule laissait l'écran sans aucune porte vers le TCF
    // tant que `/api/me/civic-plan` n'avait pas répondu.
    final async = ref.watch(civicPlanProvider);
    // 🛑 **Le plan déjà lu reste affiché pendant un rechargement** : sans ça, un
    // tiré-pour-rafraîchir ramenait la roue par-dessus un écran qu'on avait.
    if (async.isLoading && !async.hasValue) {
      return ListView(
        children: const [
          SfTop(kicker: kCivicPlanTopKicker, title: kCivicPlanScreenTitle),
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator(color: AppColors.blue)),
        ],
      );
    }
    final plan = async.valueOrNull;
    // Même raison : un plan civique indisponible ne rend pas un écran muet,
    // il garde son en-tête — donc la bascule vers l'autre parcours.
    if (plan == null || !plan.disponible) {
      return ListView(
        children: const [
          SfTop(kicker: kCivicPlanTopKicker, title: kCivicPlanScreenTitle),
        ],
      );
    }

    final auth = ref.watch(authControllerProvider);
    final free = !(auth is AuthAuthenticated && auth.user.hasCivique);

    final liste = RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(children: _ecran(plan, free: free)),
    );
    if (!free) return liste;

    return Column(
      children: [
        Expanded(child: liste),
        // 🛑 **Le geste ouvre l'écran de TRANSITION**, plus l'offre directement
        // (demande du propriétaire, 2026-09-20). Il est **rouge** : c'est le
        // seul CTA critique de cet écran (A46), et les deux parcours portent
        // désormais le même bouton.
        SfStickyBar(
          child: SfButton(
            label: kCivicPlanUnlockCta,
            onPressed: () => context.push(
              AppRoutes.planUnlockPath(civique: true),
            ),
          ),
        ),
      ],
    );
  }

  /* ------------------------------------------------------------ l'écran --- */

  List<Widget> _ecran(CivicPlan plan, {required bool free}) {
    final maintenant = DateTime.now();
    // 🛑 Le parcours est **observé**, jamais attendu : son absence ne retarde pas
    // le plan d'une seconde, et un backend antérieur à `?module=` garde un écran
    // entier. Même geste que `PlanTcfView`.
    final parcours = ref.watch(journeyCiviqueProvider).valueOrNull;
    final objectif = parcours?.objectif;
    return <Widget>[
      SfTop(
        kicker: free ? kCivicPlanTopKickerFree : kCivicPlanTopKicker,
        title: kCivicPlanScreenTitle,
      ),
      const SizedBox(height: 14),

      // 🛑 LA BANDE OBJECTIF (D-50 §1) : la démarche visée et le seuil, deux
      // FAITS du référentiel. ⛔ **Jamais un score d'entrée** — `entry_score`
      // existe en base et se lirait comme un niveau acquis alors que c'est un
      // résultat d'examen blanc.
      if (objectif != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfGoalStrip(
            currentLabel: 'Objectif',
            current: objectif.label,
            goalLabel: 'Seuil de réussite',
            goal: '${CivicExamFormat.seuil}/${CivicExamFormat.questions}',
          ),
        ),
        const SizedBox(height: sfGap),
      ],

      // 🛑 « À FAIRE MAINTENANT » VIENT DU CYCLE (D-50 §2), avec repli sur le
      // plan dérivé — la même forme que `planNowCard`. Le contenu est identique
      // pour les deux accès ; seul le geste change.
      ..._actionMaintenant(plan, parcours, free: free),

      // Le cycle en blocs — la MÊME section que le TCF, module en paramètre.
      // 🛑 **Il reste ENTIER sans accès** : ses blocs et toutes leurs étapes
      // sont affichés à leur place, avec leur cadenas et le geste d'offre que
      // `PlanCycleSection` attache à une étape `locked`.
      PlanCycleSection(plan: null, journey: parcours, module: AppModule.civique),

      ..._reviewSection(plan, maintenant, free: free),

      // 🛑 **La carte bleue « Passez du diagnostic à la progression » ET le
      // sélecteur de pass sont SUPPRIMÉS** (demande du propriétaire,
      // 2026-09-20). La promesse vit sur l'écran de transition, et le choix de
      // la durée sur l'écran d'offre, qui est déjà l'autorité du catalogue.
      // Deux grilles de durées à deux écrans d'intervalle, et la même promesse
      // dite deux fois de suite : les deux défauts constatés. Ne pas les
      // réintroduire.
      if (!free) _allerPlusLoin(context),
      const SizedBox(height: 28),
    ];
  }

  /// **L'accès à « Ma progression »**, au bas du Plan civique.
  ///
  /// 🛑 **Le MÊME point d'entrée que le TCF** (`PlanTcfView._links`) : même
  /// brique ([ListGroup] / [ListRow]), même icône, même libellé, même écran
  /// d'arrivée — seul le parcours affiché change ce que l'écran raconte.
  ///
  /// ⚠️ **Une seule ligne, là où le TCF en a deux.** Sa seconde mène à « Mon
  /// diagnostic » ; le civique a bien la sienne (`/diagnostic-civique`), mais
  /// l'ajouter serait une entrée de navigation que personne n'a demandée — à
  /// rouvrir sur un mot du propriétaire, pas ici.
  ///
  /// ⚠️ **Absente sur un compte sans accès**, comme sur le Plan TCF gratuit :
  /// la seule action dominante de cet écran-là est « Débloquer mon plan ».
  Widget _allerPlusLoin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: ListGroup(
        children: [
          ListRow(
            icon: LucideIcons.trendingUp,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kJourneyHistoryTitle,
            sub: journeyHistorySub(AppModule.civique),
            onTap: () => context.push(AppRoutes.planProgress),
          ),
        ],
      ),
    );
  }

  /// **« À faire maintenant »** — la carte d'action, **la même pour un abonné et
  /// pour un compte sans accès**.
  ///
  /// 🛑 **Son contenu ET son geste sont décidés par [civicNowCard], pas ici** :
  /// l'écran assemble le kit, il ne choisit ni l'identité de la carte ni ce
  /// qu'elle lance. Il n'y a donc **aucun `if (free)` ici** — le drapeau est
  /// passé tel quel et ne sert qu'à l'autorité.
  ///
  /// 🛑 `null` est un cas NORMAL : plus rien à faire. La carte disparaît, elle
  /// n'affiche jamais un squelette.
  List<Widget> _actionMaintenant(
    CivicPlan plan,
    Journey? parcours, {
    required bool free,
  }) {
    final carte = civicNowCard(plan, journey: parcours, free: free);
    if (carte == null) return const <Widget>[];
    final meta = carte.meta;
    final source = carte.source;
    return <Widget>[
      SfSection(
        title: kCivicPlanNowTitle,
        flush: true,
        child: SfNowCard(
          icon: LucideIcons.landmark,
          title: carte.title,
          subtitle: carte.subtitle,
          badge: carte.badge,
          objectiveLabel: carte.objectiveLabel,
          objective: carte.objective,
          meta: meta == null
              ? const <SfMeta>[]
              : [SfMeta(LucideIcons.list, meta)],
          // 🛑 **Le geste vient de [civicNowCard], il ne se redéduit pas ici.**
          // `aucun` ⇒ aucun bouton (garde-fou du 2026-09-17) ; `debloquer` ⇒
          // l'offre, jamais un lanceur. En **bleu** : le seul bouton rouge de
          // l'écran reste la barre basse « Débloquer mon plan » (A46).
          action: switch (carte.geste) {
            PlanNowGeste.aucun => null,
            PlanNowGeste.debloquer => SfButton(
                label: carte.cta,
                variant: SfButtonVariant.blue,
                onPressed: () => unawaited(_ouvrirOffre()),
              ),
            PlanNowGeste.lancer => source == null
                ? null
                : SfButton(
                    label: carte.cta,
                    variant: SfButtonVariant.blue,
                    onPressed: _enCoursSur(source)
                        ? null
                        : () => unawaited(_lancer(source)),
                  ),
          },
          caption: carte.geste == PlanNowGeste.debloquer
              ? kCivicPlanLockedNote
              : null,
        ),
      ),
    ];
  }

  /// Le témoin d'attente du lanceur **de ce grain-là**.
  bool _enCoursSur(CivicNowSource source) => switch (source) {
        CivicNowUnite(code: final code) => _enCours == code,
        CivicNowCible(cible: final cible) => _enCours == cible.id,
      };

  /// 🛑 **Un lanceur par GRAIN** (A87) : l'unité officielle du cycle et la cible
  /// du plan dérivé sont deux routes serveur distinctes. Un aiguillage à
  /// l'intérieur d'un lanceur unique aurait mis les deux règles au même endroit.
  Future<void> _lancer(CivicNowSource source) async {
    if (_enCours != null) return;
    switch (source) {
      case CivicNowUnite(code: final code):
        setState(() => _enCours = code);
        await startCivicUniteSerie(context, ref, code);
      case CivicNowCible(cible: final cible):
        setState(() => _enCours = cible.id);
        await startCivicSerie(
          context,
          ref,
          cible,
          onVerrou: () => unawaited(_ouvrirOffre()),
        );
    }
    if (!mounted) return;
    setState(() => _enCours = null);
  }

  /// « À revoir bientôt ». 🛑 Jamais une alerte : ce sont des points acquis
  /// qu'on entretient — et **jamais** la boîte Leitner.
  List<Widget> _reviewSection(
    CivicPlan plan,
    DateTime maintenant, {
    required bool free,
  }) {
    if (plan.aRevoirVisibles.isEmpty) return const <Widget>[];
    final note = civicPlanGrainNote(plan.grain);
    return <Widget>[
      SfSection(
        title: kCivicPlanReviewTitle,
        child: SfStack(
          children: [
            for (final cible in plan.aRevoirVisibles)
              SfCard(
                variant: SfCardVariant.soft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SfLabel(kCivicPlanReviewPill),
                    const SizedBox(height: 4),
                    Text(
                      cible.label,
                      style: AppFonts.display(size: 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    SfTiny(civicPlanReviewText(cible, maintenant)),
                    const SizedBox(height: 10),
                    _reviewAction(cible, free: free),
                  ],
                ),
              ),
            // 🛑 **Le plan DIT à quel grain il travaille** (`20_` §3.3), et il
            // le dit **ici** : c'est la dernière surface qui montre des cibles
            // du plan dérivé, donc la seule que cette note qualifie encore. Elle
            // vivait sur les deux écrans gratuits (A84) ; les deux anatomies
            // ayant fusionné, elle accompagne désormais ce qu'elle décrit,
            // abonné compris.
            if (note != null) SfTiny(note),
          ],
        ),
      ),
    ];
  }

  /// Le geste d'une révision — **la même autorité que la carte d'action**.
  Widget _reviewAction(CivicPlanCible cible, {required bool free}) {
    final geste = civicCibleGeste(cible, free: free);
    return SfButton(
      label: geste == PlanNowGeste.debloquer
          ? kCivicPlanLockedCta
          : kCivicPlanWorkCta,
      variant: SfButtonVariant.line,
      onPressed: _enCours == cible.id
          ? null
          : () => unawaited(geste == PlanNowGeste.debloquer
              ? _ouvrirOffre()
              : _lancer(CivicNowCible(cible))),
    );
  }
}
