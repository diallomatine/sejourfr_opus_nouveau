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
/// 🛑 **Le plan travaille au grain que le tagging permet**, et il le dit
/// (`20_` §3.3) : thème par thème tant que les questions ne sont pas taguées,
/// notion par notion ensuite. Ce n'est pas une panne, c'est la phase 1.
///
/// 🛑 **Le constat est intégralement gratuit.** Le `locked` servi porte sur la
/// **série**, jamais sur ce que le candidat a mesuré : un compte sans pass voit
/// ses priorités entières, avec leurs états.
///
/// ## ⚠️ L'écran ABONNÉ a été refondu (P8.7, D-50, 2026-09-20)
///
/// Il portait huit sections ; quatre d'entre elles n'étaient pas des « en plus »
/// mais des **retards** — le TCF les a retirées les 18 et 19 septembre, au motif
/// qu'elles redisaient les blocs du cycle en moins précis et sous un plafond
/// d'affichage.
///
/// **Ce qui PART** : « Vos priorités », « Déjà travaillé et validé »,
/// « Progression détectée », la carte de contexte (deux pastilles + la phrase du
/// moteur) et le « parcours de la notion » — il illustrait la cible du plan
/// **dérivé**, et « À faire maintenant » lit désormais le **cycle**.
///
/// **Ce qui RESTE** : « À revoir bientôt ». C'est le seul affichage du Leitner,
/// que le cycle ne porte pas — D-49 a posé deux autorités exactement pour ça, et
/// la supprimer perdrait un fait vrai.
///
/// **Ce qui ARRIVE** : la bande objectif (D-50 §1), « À faire maintenant » lu sur
/// `journey.current` (D-50 §2) et la **même** [PlanCycleSection] que le TCF, avec
/// son module en paramètre.
///
/// 🛑 **L'écran GRATUIT n'est pas touché** : il ne lit pas le cycle, et les
/// arbitrages de D-50 portent sur le plan d'un abonné.
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
  CivicPassDuree _duree = CivicPassDuree.troisMois;

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

  /// Ouvre la série ciblée. Le geste vit dans [startCivicSerie], partagé avec
  /// l'écran Réviser : seul le témoin d'attente est local.
  Future<void> _commencer(CivicPlanCible cible) async {
    if (_enCours != null) return;
    setState(() => _enCours = cible.id);
    await startCivicSerie(context, ref, cible);
    if (!mounted) return;
    setState(() => _enCours = null);
  }

  /// **La seule porte d'achat** : l'écran d'offre, qui porte les vrais passes
  /// et leurs prix du store. La durée choisie ici n'est qu'une préférence
  /// affichée — c'est là-bas qu'on achète.
  Future<void> _ouvrirOffre() => openCivicOffer(context);

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
    final hasCivique = auth is AuthAuthenticated && auth.user.hasCivique;

    if (!hasCivique) {
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _load,
              child: ListView(children: _free(plan)),
            ),
          ),
          SfStickyBar(
            child: SfButton(
              label: kCivicPlanUnlockCta,
              caption: civicPlanUnlockCaption(_duree),
              variant: SfButtonVariant.blue,
              onPressed: () => unawaited(_ouvrirOffre()),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(children: _premium(plan)),
    );
  }

  /* --------------------------------------------------------- avec pass ---- */

  List<Widget> _premium(CivicPlan plan) {
    final maintenant = DateTime.now();
    // 🛑 Le parcours est **observé**, jamais attendu : son absence ne retarde pas
    // le plan d'une seconde, et un backend antérieur à `?module=` garde un écran
    // entier. Même geste que `PlanTcfView`.
    final parcours = ref.watch(journeyCiviqueProvider).valueOrNull;
    final objectif = parcours?.objectif;
    return <Widget>[
      const SfTop(
        kicker: kCivicPlanTopKicker,
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

      // 🛑 « À FAIRE MAINTENANT » VIENT DU CYCLE (D-50 §2), plus du plan dérivé.
      // Une seule réponse alimente la carte et la timeline — c'est ce qui a
      // supprimé, le 2026-09-16, la contradiction où l'Accueil annonçait une
      // action et le Plan une autre au même instant.
      ..._actionMaintenant(parcours),

      // Le cycle en blocs — la MÊME section que le TCF, module en paramètre.
      PlanCycleSection(plan: null, journey: parcours, module: AppModule.civique),

      ..._reviewSection(plan, maintenant),
      _allerPlusLoin(context),
      const SizedBox(height: 28),
    ];
  }

  /// **L'accès à « Ma progression »**, au bas du Plan civique.
  ///
  /// 🛑 **Le MÊME point d'entrée que le TCF** (`PlanTcfView._links`) : même
  /// brique ([ListGroup] / [ListRow]), même icône, même libellé, même écran
  /// d'arrivée — seul le parcours affiché change ce que l'écran raconte. Un
  /// second chemin vers une archive aurait été une deuxième façon de faire la
  /// même chose.
  ///
  /// ⚠️ **Une seule ligne, là où le TCF en a deux.** Sa seconde mène à « Mon
  /// diagnostic » ; le civique a bien la sienne (`/diagnostic-civique`), mais
  /// l'ajouter serait une entrée de navigation que personne n'a demandée — à
  /// rouvrir sur un mot du propriétaire, pas ici.
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

  /// **« À faire maintenant », depuis le CYCLE** (D-50 §2).
  ///
  /// 🛑 **L'étape courante est SERVIE** (`journey.current`) : l'écran ne choisit
  /// pas quoi faire ensuite, il l'affiche. Son geste est la série sur l'**unité**
  /// de l'étape, quand elle en porte une — un examen de bloc, lui, se lance
  /// depuis son encart dans le cycle.
  ///
  /// 🛑 `null` est un cas NORMAL : cycle terminé, plus rien à faire, ou rien
  /// d'exécutable. La carte disparaît, elle n'affiche jamais un squelette.
  List<Widget> _actionMaintenant(Journey? parcours) {
    final etape = parcours?.current;
    if (etape == null) return const <Widget>[];
    final unite = etape.unite;
    final sousTitre = journeyStepSubtitle(etape);
    return <Widget>[
      SfSection(
        title: kCivicPlanNowTitle,
        flush: true,
        child: SfNowCard(
          icon: LucideIcons.landmark,
          title: journeyStepTitle(etape),
          subtitle: etape.bloc?.label,
          badge: etape.locked ? kJourneyLockedBadge : null,
          // `journeyStepSubtitle` peut ne rien avoir à dire : on n'affiche alors
          // aucune méta plutôt qu'une ligne vide.
          meta: sousTitre == null
              ? const <SfMeta>[]
              : [SfMeta(LucideIcons.list, sousTitre)],
          // 🛑 Un geste seulement quand il y en a un : une étape verrouillée ou
          // un examen de bloc n'ouvre rien ICI. C'est le garde-fou du
          // 2026-09-17 — rien ne se résout ⇒ aucun bouton.
          action: unite == null || etape.locked
              ? null
              : SfButton(
                  label: kCivicPlanWorkCta,
                  variant: SfButtonVariant.blue,
                  onPressed: _enCours == unite.code
                      ? null
                      : () => unawaited(_commencerUnite(unite.code)),
                ),
        ),
      ),
    ];
  }

  /// Ouvre la série d'une **unité officielle**. Le geste vit dans
  /// [startCivicUniteSerie] : seul le témoin d'attente est local.
  Future<void> _commencerUnite(String uniteCode) async {
    if (_enCours != null) return;
    setState(() => _enCours = uniteCode);
    await startCivicUniteSerie(context, ref, uniteCode);
    if (!mounted) return;
    setState(() => _enCours = null);
  }

  /* -------------------------------------------------------- sans pass ----- */

  List<Widget> _free(CivicPlan plan) {
    final resultat = plan.resultat;
    return <Widget>[
      const SfTop(
        kicker: kCivicPlanTopKickerFree,
        title: kCivicPlanScreenTitle,
      ),
      const SizedBox(height: 14),
      if (resultat != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfCard(
            variant: SfCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfLabel(kCivicPlanResultLabel),
                const SizedBox(height: 6),
                SfScore(
                  score: resultat.bonnes,
                  total: resultat.posees,
                  compact: true,
                ),
                const SizedBox(height: 8),
                SfTiny(civicPlanResultNote(resultat)),
              ],
            ),
          ),
        ),
      ..._themesSection(plan),
      ..._prioritiesSection(plan),
      if (plan.prochaine != null)
        SfSection(
          title: kCivicPlanFirstStepTitle,
          flush: true,
          child: _nowCard(plan.prochaine!),
        ),
      const SfSection(
        flush: true,
        child: SfUnlockHero(
          title: kCivicPlanUnlockHeroTitle,
          text: kCivicPlanUnlockHeroText,
        ),
      ),
      _passSection(),
      // 🛑 **Le plan DIT à quel grain il travaille** (`20_` §3.3) : thème par
      // thème tant que les questions ne sont pas taguées. Elle vivait dans la
      // carte de contexte de l'abonné, que D-50 a retirée — or c'est justement
      // l'écran gratuit qui liste des thèmes. Miroir du pied de `CiviqueGratuit`
      // côté web, qui la portait déjà.
      if (civicPlanGrainNote(plan.grain) case final note?) ...[
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfTiny(note),
        ),
      ],
      const SizedBox(height: 24),
    ];
  }

  /* ------------------------------------------------------------ blocs ----- */

  /// La carte d'action du plan **gratuit** — « Votre première étape est prête ».
  ///
  /// ⚠️ Elle portait un drapeau `free` et servait aussi l'abonné : depuis P8.7 ce
  /// dernier lit le **cycle** (D-50 §2), donc il n'y a plus qu'un appelant et
  /// plus qu'une mise en page. Ce qui décide du bouton ou des cadenas reste le
  /// `locked` **servi** sur la cible.
  Widget _nowCard(CivicPlanCible cible) {
    final card = SfNowCard(
      icon: LucideIcons.landmark,
      title: cible.label,
      subtitle: cible.themeLabel.isEmpty ? null : cible.themeLabel,
      objectiveLabel: kCivicPlanNowWhy,
      objective: civicPlanRaison(cible),
      meta: [SfMeta(LucideIcons.list, civicSerieLabel(cible))],
      action: cible.locked
          ? null
          : SfButton(
              label: cible.locked ? kCivicPlanLockedCta : kCivicPlanNowCta,
              variant: SfButtonVariant.blue,
              onPressed: _enCours == cible.id
                  ? null
                  : () => unawaited(_commencer(cible)),
            ),
      caption: cible.locked ? kCivicPlanLockedNote : null,
    );

    if (!cible.locked) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: sfGap),
        SfCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final label in kCivicPlanStepLocks) SfLockItem(label: label),
            ],
          ),
        ),
      ],
    );
  }

  /// Les thèmes **mesurés et non solides**, avec leur état servi. Un thème
  /// jamais mesuré n'y figure pas : il n'a rien raté.
  List<Widget> _themesSection(CivicPlan plan) {
    final themes = civicPlanThemesATravailler(plan);
    if (themes.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kCivicPlanThemesTitle,
        flush: true,
        child: SfCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < themes.length; i++)
                SfThemeLine(
                  tone: _tone(civicThemeTone(themes[i].etatDuTheme)),
                  name: themes[i].themeLabel,
                  status: themes[i].etatDuTheme.label,
                  last: i == themes.length - 1,
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _prioritiesSection(CivicPlan plan) {
    if (plan.prioritesVisibles.isEmpty) return const <Widget>[];
    final autres = civicPlanAutresLabel(plan);
    return <Widget>[
      SfSection(
        title: kCivicPlanPrioritiesTitle,
        child: SfStack(
          children: [
            for (var i = 0; i < plan.prioritesVisibles.length; i++)
              _priorityCard(plan.prioritesVisibles[i], i + 1),
            if (autres != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SfTiny(autres),
              ),
          ],
        ),
      ),
    ];
  }

  /// Une priorité.
  ///
  /// ⚠️ **Pas de sous-liste de compétences** : le serveur n'en sert aucune sur
  /// une cible civique (`20_` §4). On montre la maîtrise servie et la raison,
  /// jamais un sous-arbre fabriqué.
  Widget _priorityCard(CivicPlanCible cible, int rank) {
    return SfPrio(
      rank: rank,
      tag: cible.themeLabel.isEmpty ? kCivicPlanPrioritiesTitle : cible.themeLabel,
      title: cible.label,
      text: cible.maitrise.label,
    );
  }

  /// « À revoir bientôt ». 🛑 Jamais une alerte : ce sont des points acquis
  /// qu'on entretient — et **jamais** la boîte Leitner.
  List<Widget> _reviewSection(CivicPlan plan, DateTime maintenant) {
    if (plan.aRevoirVisibles.isEmpty) return const <Widget>[];
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
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// Le sélecteur de durée du Pass Civique. **Aucun prix** : il dit la durée,
  /// l'écran d'offre porte les tarifs du store et l'achat.
  Widget _passSection() {
    return SfSection(
      flush: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SfLabel(kCivicPassTitle),
          const SizedBox(height: 8),
          for (final duree in CivicPassDuree.values) ...[
            SfChoiceCard(
              label: duree.label,
              subtitle: kCivicPassSubtitle,
              selected: _duree == duree,
              onTap: () => setState(() => _duree = duree),
            ),
            const SizedBox(height: sfGap),
          ],
          const SfTiny(kCivicPassNote),
        ],
      ),
    );
  }

  /// Le ton du kit correspondant au ton servi. `muted` n'a pas d'équivalent —
  /// les cibles non mesurées ne sont jamais rendues avec une couleur d'alerte,
  /// elles sont filtrées en amont.
  SfTone _tone(CivicCibleTone tone) => switch (tone) {
        CivicCibleTone.hot => SfTone.hot,
        CivicCibleTone.warn => SfTone.warn,
        CivicCibleTone.ok => SfTone.ok,
        CivicCibleTone.muted => SfTone.warn,
      };
}
