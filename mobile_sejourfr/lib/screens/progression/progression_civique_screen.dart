import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/dashboard_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/models/progression_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/router/shell_navigation.dart';
import '../../core/utils/situation_icons.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../home/home_labels.dart';
import '../module/module_labels.dart';
import '../progres/progres_labels.dart';
import '../reviser/reviser_labels.dart';
import 'progression_labels.dart';
import 'progression_providers.dart';
import 'widgets/prochaine_etape_hero.dart';
import 'widgets/progression_page.dart';

/// **La progression globale civique** — Navigation v2 (phase 4b) : maquette
/// `docs/redesign/sejourfr-navigation-mobile.html` (`#civiqueprogress`), puis
/// la « Prochaine étape » de la maquette web ; sous eux, les blocs existants
/// (maquette `progression_global_civique.html`, état téléphone), tous gardés.
///
/// Ordre : titre + phrase → « Maîtrise globale » (NOUVEAU : le % du parcours
/// par [avancementSeriesCivique], 6ᵉ emplacement du même nombre) → « Par
/// thème » (% et séries du thème par la même fonction, état SERVI
/// `CivicThemeState`, code = rang du thème) → « Examens blancs » (taux servis
/// des derniers examens globaux ; aucun ⇒ état vide) → « Prochaine étape »
/// (`journey.current` civique, geste de l'Accueil) → héros /40, tuiles, cartes
/// de thème, liste des examens.
///
/// 🛑 **Tout est servi** (`GET /api/me/progression/civique`) : score /40 et
/// seuil 32, état (D12), écart et sens, anneau = taux servi + seuil atteint
/// servi (D5), les **5** thèmes officiels sur leurs seuls examens de thème
/// (D10), et les parts d'un examen global en « x / n posées », jamais « / 20 »
/// (D11).
///
/// Miroir web : `app/(app)/progression/civique`.
class ProgressionCiviqueScreen extends ConsumerWidget {
  const ProgressionCiviqueScreen({super.key, this.tous = false});

  final bool tous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = progressionCiviqueProvider(tous);
    return ProgressionPage<ProgressionCivique>(
      async: ref.watch(provider),
      barSub: kCiviqueLabel,
      // Le lien retour ramène à l'écran du module, sur son segment d'origine.
      lienRetour: (label: kCiviqueLabel, civique: true),
      onBack: () => retourOuRepli(
        context,
        repli: racineDuModule(ref, civique: true),
      ),
      onRefresh: () => ref.refresh(provider.future),
      children: (data) => _corps(context, data),
      entete: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SfModuleHeader(
            civique: true,
            title: kProgressionTitre,
            lead: kCiviqueProgressionLead,
          ),
        ),
      ],
    );
  }

  List<Widget> _corps(BuildContext context, ProgressionCivique data) {
    final global = data.global;
    final dernier = global.dernier;
    final meilleur = global.meilleur;
    final premier = global.premier;
    final verdict = progressionSeuilVerdict(dernier, data.echelle.seuil);
    return [
      ProgressionBlocs(
        children: [
          const _MaitriseGlobale(),
          ProgressionSection(
            title: kCiviqueParThemeTitle,
            child: _ParTheme(themes: data.themes),
          ),
          ProgressionSection(
            title: kCiviqueExamensBlancsTitle,
            child: SfTimeline(
              civique: true,
              label: kCiviqueEvolutionScoreLabel,
              steps: [
                for (final e in data.examens
                    .take(kProgressionReperesMax)
                    .toList()
                    .reversed)
                  if (progressionTaux(e.mesure.taux) case final taux?) taux,
              ],
              caption: civiqueMeilleurScore(meilleur) ?? kCiviqueListeVide,
            ),
          ),
          const ProchaineEtapeHero(civique: true),
          SfProgressHero(
            label: kCiviqueHeroLabel,
            value: progressionValeur(dernier?.score),
            unit: dernier == null ? null : progressionUnite(dernier.max),
            level: dernier == null ? null : progressionEtatLabel(dernier.etat),
            levelTone: progressionEtatTon(dernier?.etat),
            trend: progressionEcart(global.ecart, global.sens,
                depuisLeDebut: true),
            trendTone: progressionSensTon(global.sens),
            notes: [if (verdict != null) verdict],
            ring: progressionAnneau(dernier),
          ),
          SfProgressStatGrid(
            framed: true,
            tiles: [
              SfProgressStatTile(
                inset: true,
                label: kCiviqueStatNombre,
                value: '${global.nombre}',
                caption: progressionTermines(global.nombre),
              ),
              SfProgressStatTile(
                inset: true,
                label: kCiviqueStatMeilleur,
                value: meilleur == null
                    ? kProgressionVide
                    : progressionScore(meilleur.score, meilleur.max),
                caption: progressionEtatLabel(meilleur?.etat),
              ),
              SfProgressStatTile(
                inset: true,
                label: kCiviqueStatPremier,
                value: premier == null
                    ? kProgressionVide
                    : progressionScore(premier.score, premier.max),
                caption: progressionEtatLabel(premier?.etat),
              ),
              SfProgressStatTile(
                inset: true,
                label: kCiviqueStatDernier,
                value: progressionDateCourte(dernier?.date),
                caption:
                    dernier == null ? null : progressionAnnee(dernier.date),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: SfPanelHead(
              title: kCiviqueThemesTitle,
              sub: kCiviqueThemesSub,
              lead: true,
            ),
          ),
          for (final carte in data.themes) _carte(context, carte),
          ProgressionPanneau(
            title: tous ? kCiviqueListeTousTitle : kCiviqueListeTitle,
            sub: kCiviqueListeSub,
            children: [
              if (data.examens.isEmpty)
                const SfTiny(kCiviqueListeVide)
              else
                for (final e in data.examens) _ligne(context, e),
              if (!tous && global.nombre > data.examens.length)
                ProgressionLien(
                  label: kCiviqueListeTousLink,
                  onTap: () => context.push(AppRoutes.progressionCiviqueTous),
                ),
              if (tous)
                ProgressionLien(
                  label: kProgressionListeMoinsLink,
                  onTap: () => retourOuRepli(context,
                      repli: AppRoutes.progressionCivique),
                ),
              const SfMicroNote(kCiviqueHint),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _carte(BuildContext context, ProgressionCarte carte) {
    final resume = carte.resume;
    final dernier = resume.dernier;
    final themeId = carte.themeId;
    return SfProgressDomainCard(
      icon: situationThemeIcon(carte.code),
      title: carte.label ?? kProgressionVide,
      sub: kCiviqueCarteSub,
      onTap: themeId == null
          ? () {}
          : () => context.push(AppRoutes.progressionThemePath(themeId)),
      empty: dernier == null ? kProgressionSansExamenTheme : null,
      value: progressionValeur(dernier?.score),
      unit: progressionUnite(carte.echelle.max),
      pill: progressionEtatLabel(dernier?.etat),
      pillTone: progressionEtatTon(dernier?.etat),
      delta: progressionEcart(resume.ecart, resume.sens),
      deltaTone: progressionSensTon(resume.sens),
      spark: progressionSpark(carte),
    );
  }

  Widget _ligne(BuildContext context, ProgressionExamenGlobal e) {
    final m = e.mesure;
    final rapport = progressionRapportPath(m.rapportKind, m.rapportAttemptId);
    return SfProgressGlobalExamRow(
      title: civiqueExamenTitre(m.numero),
      date: progressionDateLongue(m.date),
      badge: civiqueGlobalBadge(m),
      badgeTone: progressionEtatTon(m.etat),
      stacked: true,
      parts: [
        for (final p in e.parTheme)
          (label: p.label, value: civiquePart(p.bonnes, p.posees)),
      ],
      onTap: rapport == null ? null : () => context.push(rapport),
    );
  }
}

/// **« Maîtrise globale »** — le pourcentage du parcours en séries
/// ([avancementSeriesCivique], la fonction unique) et le nombre de séries
/// terminées, avec la barre du module. Lit le tableau de bord (séries servies
/// par thème) ; bloc à états propres.
class _MaitriseGlobale extends ConsumerWidget {
  const _MaitriseGlobale();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final themes = async.valueOrNull?.civique;
    if (themes == null) {
      if (async.hasError) {
        return SfBlockError(
          message: kHomeBlockError,
          retryLabel: kHomeRetry,
          onRetry: () => ref.invalidate(dashboardProvider),
        );
      }
      return const SfBlockSkeleton(height: 130);
    }
    final avancement = avancementSeriesCivique(themes);
    return SfProgressionHead(
      civique: true,
      label: kCiviqueMaitriseLabel,
      primary: (
        value: moduleCiviqueProgressValue(avancement.pourcentage),
        label: kCiviqueDuParcours,
      ),
      secondary: (
        value: '${avancement.terminees}',
        label: civiqueSeriesTermineesLabel(avancement.terminees),
      ),
      progress: avancement.pourcentage / 100,
    );
  }
}

/// **« Par thème »** — une ligne par thème officiel (ordre servi par la
/// progression) : rang du thème (aucune abréviation inventée), % du thème en
/// séries (`avancementSeriesCivique([stat])`), « x/y séries · nom », et l'état
/// SERVI du dernier examen du thème en pastille — absent ⇒ pas de pastille.
class _ParTheme extends ConsumerWidget {
  const _ParTheme({required this.themes});

  final List<ProgressionCarte> themes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final stats = async.valueOrNull?.civique;
    if (stats == null) {
      if (async.hasError) {
        return SfBlockError(
          message: kHomeBlockError,
          retryLabel: kHomeRetry,
          onRetry: () => ref.invalidate(dashboardProvider),
        );
      }
      return const SfBlockSkeleton(height: 320);
    }
    return SfLevelList(
      rows: [
        for (var i = 0; i < themes.length; i++)
          _ligne(context, i + 1, themes[i], _statDe(stats, themes[i].themeId)),
      ],
    );
  }

  DashboardCategoryStat? _statDe(
    List<DashboardCategoryStat> stats,
    String? themeId,
  ) {
    if (themeId == null) return null;
    for (final s in stats) {
      if (s.themeId == themeId) return s;
    }
    return null;
  }

  SfLevelRow _ligne(
    BuildContext context,
    int rang,
    ProgressionCarte carte,
    DashboardCategoryStat? stat,
  ) {
    final avancement = stat == null ? null : avancementSeriesCivique([stat]);
    final etat = carte.resume.dernier?.etat;
    final themeId = carte.themeId;
    return SfLevelRow(
      civique: true,
      code: '$rang',
      value: avancement == null
          ? kProgressionVide
          : moduleCiviqueProgressValue(avancement.pourcentage),
      caption: avancement == null
          ? carte.label
          : civiqueThemeCaption(
              avancement.terminees, avancement.total, carte.label),
      trailing: etat == null
          ? null
          : SfBadge(etatThemeCivique(etat).label,
              tone: etatThemeCivique(etat).tone),
      onTap: themeId == null
          ? null
          : () => context.push(AppRoutes.progressionThemePath(themeId)),
    );
  }
}
