import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/epreuve_historique_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/plan_labels.dart';
import 'epreuve_historique_screen.dart';
import 'progres_labels.dart';
import 'progres_mouvement.dart';

/// **« Votre progression »** — la progression **globale**, ouverte depuis le
/// Profil (`AppRoutes.progress`).
///
/// ⚠️ **À ne pas confondre avec `/plan/progression`** (« Ma progression »,
/// l'historique des cycles) ni avec `/historiques/epreuve/{domaine}`
/// (« Vos résultats » d'une épreuve). Cet écran-ci répond à « où en est mon
/// niveau, épreuve par épreuve ».
///
/// 🛑 **La partie TCF est refaite sur le template du propriétaire**
/// (`docs/progression/ecran_progression_normal.html`, première partie) : le
/// bandeau d'objectif et sa bande de paliers, « Votre évolution » à onglets, et
/// « Vos épreuves ». Le **parcours civique** reste en dessous, inchangé : le
/// template ne le couvre pas.
///
/// 🛑 **Rien n'est classé ici.** Paliers, tendances et mots d'état arrivent
/// **servis** — `GET /api/me/progress` pour les 4 épreuves (le palier vient de
/// `TcfProfileService.levelProfileAccueil`, **l'autorité d'affichage**, la même
/// que l'Accueil, le Profil, le Diagnostic et Réviser) et
/// `GET /api/me/progress/tcf/{epreuve}/historique` pour la série d'examens
/// qualifiants. Les dérivations vivent dans `progres_labels.dart`, miroir mot
/// pour mot de `web_sejoufr/lib/progres.ts`.
///
/// 🛑 **Miroir de `/statistiques` côté web**, bloc pour bloc.
class ProgresScreen extends ConsumerStatefulWidget {
  const ProgresScreen({super.key});

  @override
  ConsumerState<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends ConsumerState<ProgresScreen> {
  /// L'onglet de la courbe. 🛑 Une **épreuve**, pas un index : la liste servie
  /// décide de l'ordre et du nombre d'onglets.
  EpreuveType _onglet = EpreuveType.tcfCo;

  /// Le point choisi sur la courbe, **dans l'ordre servi** (le plus récent
  /// d'abord). `null` ⇒ la mesure la plus récente, ce que le template montre.
  int? _point;

  /// Pour ramener la courbe sous les yeux quand une ligne d'épreuve la
  /// sélectionne — le `scrollIntoView` du template.
  final GlobalKey _courbeKey = GlobalKey();

  void _choisirEpreuve(EpreuveType epreuve) {
    setState(() {
      _onglet = epreuve;
      _point = null;
    });
    final box = _courbeKey.currentContext;
    if (box != null) {
      Scrollable.ensureVisible(
        box,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progres = ref.watch(progressProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            ref.invalidate(progressProvider);
            ref.invalidate(dashboardProvider);
            for (final epreuve in kProgressionEpreuves) {
              ref.invalidate(epreuveHistoriqueProvider(epreuve));
            }
            await Future.wait([
              ref.read(progressProvider.future),
              ref.read(dashboardProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              SfTop(
                // 🛑 Une flèche ne fait jamais un `pop()` nu : atteint par un
                // lien profond, cet écran n'a personne sous lui.
                onBack: () => retourOuRepli(context, repli: AppRoutes.profile),
                kicker: kProgressionEyebrow,
                title: kProgressionTitle,
                lead: kProgressionLead,
              ),
              // ------------------------------------------------ TCF (template)
              progres.when(
                loading: () => const _Chargement(),
                error: (e, _) => _Erreur(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(progressProvider),
                ),
                data: (p) => _PartieTcf(
                  progres: p,
                  onglet: _onglet,
                  point: _point,
                  courbeKey: _courbeKey,
                  onOnglet: _choisirEpreuve,
                  onPoint: (i) => setState(() => _point = i),
                ),
              ),
              // -------------------------------------- Civique (inchangé)
              dashboard.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (d) => _PartieCivique(summary: d),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les quatre épreuves, dans l'ordre où le serveur les publie.
///
/// 🛑 Elle ne sert qu'à **invalider** les historiques au tiré-pour-rafraîchir :
/// l'écran, lui, n'affiche que la liste servie.
const List<EpreuveType> kProgressionEpreuves = [
  EpreuveType.tcfCo,
  EpreuveType.tcfCe,
  EpreuveType.tcfEe,
  EpreuveType.tcfEo,
];

class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80, bottom: 40),
      child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SfSection(
      flush: true,
      child: AppCard(
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.soft,
              height: 44,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================================================================== */
/*  La partie TCF — le template, à la lettre                                  */
/* ========================================================================== */

class _PartieTcf extends ConsumerWidget {
  const _PartieTcf({
    required this.progres,
    required this.onglet,
    required this.point,
    required this.courbeKey,
    required this.onOnglet,
    required this.onPoint,
  });

  final Progress progres;
  final EpreuveType onglet;
  final int? point;
  final GlobalKey courbeKey;
  final ValueChanged<EpreuveType> onOnglet;
  final ValueChanged<int> onPoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epreuves = progres.tcf.epreuves;
    // Les 4 épreuves sont toujours servies depuis le 2026-09-16 ; un client
    // servi par un backend antérieur verrait la liste vide, et le bloc se tait
    // plutôt que d'afficher un titre au-dessus du vide.
    if (epreuves.isEmpty) return const SizedBox.shrink();

    final objectif = progres.tcf.objectif;
    // 🛑 **Un onglet par épreuve SERVIE**, et jamais un onglet sur une épreuve
    // que le serveur ne publie pas.
    final courant = epreuves.any((e) => e.epreuve == onglet)
        ? onglet
        : epreuves.first.epreuve;

    // 🛑 **La série d'une épreuve est SERVIE** : `epreuveHistoriqueProvider`
    // est `autoDispose` par épreuve, donc les quatre lectures tiennent tant que
    // l'écran vit — une bascule d'onglet ne coûte alors aucun appel. C'est le
    // même total que visiter les quatre onglets un à un.
    final histos = <EpreuveType, AsyncValue<EpreuveHistorique>>{
      for (final e in epreuves)
        e.epreuve: ref.watch(epreuveHistoriqueProvider(e.epreuve)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SfSection(
          flush: true,
          child: _Bandeau(epreuves: epreuves, objectif: objectif),
        ),
        SfSection(
          flush: true,
          child: Column(
            key: courbeKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SfPanelHead(
                title: kProgressionCourbeTitle,
                sub: kProgressionCourbeSub,
              ),
              const SizedBox(height: 10),
              _Courbe(
                epreuves: epreuves,
                courant: courant,
                objectif: objectif,
                historique: histos[courant]!,
                point: point,
                onOnglet: onOnglet,
                onPoint: onPoint,
              ),
            ],
          ),
        ),
        SfSection(
          flush: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SfPanelHead(
                title: kProgressionEpreuvesTitle,
                sub: kProgressionEpreuvesSub,
              ),
              const SizedBox(height: 10),
              SfEpreuveStatList(
                children: [
                  for (final epreuve in epreuves)
                    _LigneEpreuve(
                      epreuve: epreuve,
                      selected: epreuve.epreuve == courant,
                      historique:
                          histos[epreuve.epreuve]?.valueOrNull?.evaluations ??
                              const <EvaluationQualifiante>[],
                      onTap: () => onOnglet(epreuve.epreuve),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le `.hero` du template : « Vers votre objectif », le compteur, la pastille
/// d'objectif, le rail, la ligne de mesure, puis la bande des 4 paliers.
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.epreuves, required this.objectif});

  final List<ProgressEpreuve> epreuves;
  final NiveauCecrl? objectif;

  @override
  Widget build(BuildContext context) {
    final compte = accueilEvaluees(epreuves);
    final valeur = progressionMesureesLabel(compte);
    return SfGoalHero(
      label: kProgressionHeroLabel,
      // 🛑 Sans les deux nombres servis, on n'annonce **aucun chiffre** : le
      // bandeau garde son intitulé et sa bande de paliers.
      value: valeur,
      pill: progressionObjectifPill(objectif),
      ratio: progressionMesureesPart(compte),
      metaLabel: valeur == null ? null : kProgressionHeroMeta,
      metaValue: progressionMesureesPourcent(compte),
      child: SfLevelStrip(
        items: [
          for (final epreuve in epreuves)
            SfLevelStripItem(
              mark: planDomainSection(epreuve.epreuve)?.wire ??
                  epreuve.epreuve.wire,
              level: progressionPalier(epreuve),
              // 🛑 La flèche **lit** le sens servi (`evolution`), elle ne le
              // déduit d'aucune série de paliers.
              trend: progresEvolutionFleche(epreuve.evolution),
              trendTone: progresEvolutionTrendTone(epreuve.evolution),
              // 🛑 Le mot est celui de l'ACCUEIL, la seule dérivation du dépôt
              // pour cet état servi. Le template en proposait trois à lui
              // (« En progrès » / « Stable » / « À évaluer ») : un second
              // vocabulaire d'état aurait fait dire deux mots différents du
              // même fait sur deux écrans que le candidat voit à la suite.
              caption: accueilEpreuveStatut(epreuve),
            ),
        ],
      ),
    );
  }
}

/// La carte « Votre évolution » : les onglets, la tête, la courbe et son pied.
class _Courbe extends StatelessWidget {
  const _Courbe({
    required this.epreuves,
    required this.courant,
    required this.objectif,
    required this.historique,
    required this.point,
    required this.onOnglet,
    required this.onPoint,
  });

  final List<ProgressEpreuve> epreuves;
  final EpreuveType courant;
  final NiveauCecrl? objectif;
  final AsyncValue<EpreuveHistorique> historique;
  final int? point;
  final ValueChanged<EpreuveType> onOnglet;
  final ValueChanged<int> onPoint;

  @override
  Widget build(BuildContext context) {
    final situation =
        epreuves.where((e) => e.epreuve == courant).firstOrNull;
    final servies = historique.valueOrNull?.evaluations ??
        const <EvaluationQualifiante>[];
    final courbe = progresCourbe(servies, objectif);
    final points = courbe.points;
    final choisi = point == null || point! >= servies.length ? 0 : point!;
    final mesure = servies.isEmpty ? null : servies[choisi];

    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfFilterChips<EpreuveType>(
            options: [
              for (final e in epreuves)
                (
                  id: e.epreuve,
                  label: planDomainSection(e.epreuve)?.wire ?? e.epreuve.wire,
                ),
            ],
            value: courant,
            onChanged: onOnglet,
          ),
          const SizedBox(height: 16),
          SfChartTitle(
            name: courant.displayLabel,
            // 🛑 Le palier vient de l'autorité d'affichage servie, « — »
            // compris : jamais « A1 » pour une absence de mesure.
            level: situation == null ? '—' : progressionPalier(situation),
            caption: kProgressionNiveauActuelLabel,
          ),
          const SizedBox(height: 6),
          if (historique.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 46),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          // 🛑 **Pas de courbe sans point** : un panneau vide raconterait une
          // absence comme un incident.
          else if (points.isEmpty)
            _CourbeVide(epreuve: courant)
          else
            SfLevelChart(
              ladder: courbe.ladder,
              points: points,
              // Les points sont chronologiques, la liste servie ne l'est pas :
              // l'index se retourne, exactement comme sur « Vos résultats ».
              activeIndex: servies.length - 1 - choisi,
              onSelect: (i) => onPoint(servies.length - 1 - i),
            ),
          const SizedBox(height: 5),
          SfChartNote(
            title: progressionDerniereMesure(mesure) ?? kSuiviSansExamenLabel,
            // 🛑 **Aucun score n'est servi** par l'historique : on affiche ce
            // qui l'est (la provenance, la date, le palier) et rien de plus.
            // Le « x / 25 bonnes réponses » du template n'existe pas ici.
            text: mesure == null
                ? kProgressionSansExamenText
                : suiviNiveauLabel(mesure.niveau),
            actionLabel: mesure == null ? null : kProgressionVoirLabel,
            onAction: mesure == null
                ? null
                : () => context.push(
                      AppRoutes.epreuveHistoriquePath(planDomainKey(courant)),
                    ),
          ),
        ],
      ),
    );
  }
}

class _CourbeVide extends StatelessWidget {
  const _CourbeVide({required this.epreuve});

  final EpreuveType epreuve;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(LucideIcons.plus,
                size: 22, color: AppColors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            kProgressionCourbeVideTitle,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 13, weight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            progressionCourbeVideText(epreuve),
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 11.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de « Vos épreuves ». Le tap **sélectionne l'onglet** de la courbe,
/// comme dans le template.
class _LigneEpreuve extends StatelessWidget {
  const _LigneEpreuve({
    required this.epreuve,
    required this.selected,
    required this.historique,
    required this.onTap,
  });

  final ProgressEpreuve epreuve;
  final bool selected;
  final List<EvaluationQualifiante> historique;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SfEpreuveStatRow(
      mark: planDomainSection(epreuve.epreuve)?.wire ?? epreuve.epreuve.wire,
      title: epreuve.epreuve.displayLabel,
      pill: accueilEpreuveStatut(epreuve),
      pillTone: accueilEpreuveTon(epreuve),
      // 🛑 **La série vient de l'historique SERVI**, dans l'ordre servi : on la
      // lit du plus ancien au plus récent, rien n'y est interprété.
      desc: progressionSerieLabel(historique) ?? kSuiviSansExamenLabel,
      level: progressionPalier(epreuve),
      levelCaption: progressionPalierCaption(epreuve),
      measured: epreuve.niveau != null,
      selected: selected,
      onTap: onTap,
    );
  }
}

/* ========================================================================== */
/*  Le parcours CIVIQUE — inchangé : le template ne le couvre pas             */
/* ========================================================================== */

int _average(List<DashboardCategoryStat> stats) {
  if (stats.isEmpty) return 0;
  final values = stats.map((s) => s.percent ?? 0).toList();
  return (values.reduce((a, b) => a + b) / values.length).round();
}

class _PartieCivique extends StatelessWidget {
  const _PartieCivique({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final global = summary.globalSuccessPercent ?? 0;
    final civAvg = _average(summary.civique);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🛑 **Ce qui a BOUGÉ** (T28, `30_` §7) : il couvre les DEUX parcours,
          // donc il reste ici.
          const ProgresMouvement(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SyntheseCard(
                  value: global,
                  color: AppColors.blue,
                  label: 'Réussite globale',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SyntheseCard(
                  value: civAvg,
                  color: AppColors.blue,
                  label: 'Examen civique',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ParcoursSection(
            label: 'Examen civique',
            color: AppColors.blue,
            stats: summary.civique,
            examOutOf: 20,
            profil: summary.tcfDomainProfile,
          ),
          const SizedBox(height: 20),
          AppCard(
            color: AppColors.surface2,
            onTap: () => context.push(AppRoutes.progresReco),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(LucideIcons.sparkles,
                      size: 22, color: AppColors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes recommandations',
                        style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                      ),
                      Text(
                        'Plan de révision personnalisé',
                        style:
                            AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    size: 18, color: AppColors.inkFaint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyntheseCard extends StatelessWidget {
  const _SyntheseCard({
    required this.value,
    required this.color,
    required this.label,
  });

  final int value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ProgressRing(
              value: value.toDouble(), size: 56, stroke: 6, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcoursSection extends StatelessWidget {
  const _ParcoursSection({
    required this.label,
    required this.color,
    required this.stats,
    required this.examOutOf,
    required this.profil,
  });

  final String label;
  final Color color;
  final List<DashboardCategoryStat> stats;

  /// L'autorité d'affichage du niveau d'une épreuve, servie par le **même**
  /// appel que les catégories (`GET /api/me/dashboard`) — aucun appel de plus.
  final TcfDomainProfile? profil;

  /// Nombre de questions d'un examen blanc de ce parcours.
  final int examOutOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppFonts.display(size: 17, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListGroup(
          children: [
            for (final stat in stats)
              _CategoryRow(
                stat: stat,
                examOutOf: examOutOf,
                profil: profil,
              ),
          ],
        ),
      ],
    );
  }
}

/// Une ligne de catégorie.
///
/// 🛑 **Le niveau vient de l'AUTORITÉ D'AFFICHAGE** ([niveauActuelEpreuve] sur
/// `tcfDomainProfile`), la même que l'Accueil, le Profil, le Diagnostic et
/// Réviser — jamais de `DashboardCategoryStat.level`, qui voyait le dernier
/// niveau de **n'importe quelle** soumission, entraînements compris.
/// → `docs/decisions/diagnostic.md`, 2026-09-16.
///
/// 🛑 **Seules les 4 épreuves TCF ont un palier.** Un thème civique rend
/// `null` : la ligne retombe alors sur ce qu'elle sait **compter**.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.stat,
    required this.examOutOf,
    required this.profil,
  });

  final DashboardCategoryStat stat;
  final int examOutOf;
  final TcfDomainProfile? profil;

  @override
  Widget build(BuildContext context) {
    final percent = stat.percent ?? 0;
    // Accent de marque, pas un verdict : la couleur ne classe plus le
    // pourcentage. Ce chiffre-ci est un taux de réussite brut, pas un état.
    const tone = AppColors.blue;

    final String sub;
    if (stat.isProduction) {
      sub = suiviNiveauLabel(niveauActuelEpreuve(profil, stat.code));
    } else if (stat.mockExams > 0 && stat.bestMockScore != null) {
      final n = stat.mockExams;
      sub = '$n examen${n > 1 ? 's' : ''} · record '
          '${stat.bestMockScore}/$examOutOf';
    } else {
      sub = 'Aucun examen passé';
    }

    return ListRow(
      icon: dashboardCategoryIcon(stat.code),
      iconBg: Color.alphaBlend(
        tone.withValues(alpha: 0.15),
        AppColors.white,
      ),
      iconColor: tone,
      title: stat.label,
      sub: sub,
      onTap: () => context.push(dashboardCategoryRoute(stat)),
      right: SizedBox(
        width: 102,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 64,
              child: Container(
                height: 6,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent / 100,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: tone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
