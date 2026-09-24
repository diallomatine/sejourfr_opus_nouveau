import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/progression_models.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'progression_labels.dart';
import 'progression_providers.dart';
import 'widgets/progression_page.dart';

/// **La progression d'un thème civique** — maquette
/// `progression_theme_civique.html`, état téléphone.
///
/// Ouvert depuis la carte du thème sur l'écran civique global, et depuis
/// « Voir mes résultats » d'une carte de thème de l'Accueil (D17).
///
/// 🛑 **Examens de thème seulement** (D10). L'état est celui du **dernier
/// examen de ce thème** et la phrase servie le dit (D13) : il peut différer de
/// l'Accueil, qui lit le diagnostic. Bandes et seuil servis (Faible ·
/// À renforcer · Solide, seuil 16), anneau = taux servi (D5).
///
/// Miroir web : `app/(app)/progression/civique/[theme]`.
class ProgressionThemeScreen extends ConsumerWidget {
  const ProgressionThemeScreen({
    super.key,
    required this.themeId,
    this.depuisGlobal = false,
  });

  final String themeId;

  /// Poussé depuis l'écran civique global : le retour dépile.
  final bool depuisGlobal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = progressionThemeProvider(themeId);
    return ProgressionPage<ProgressionTheme>(
      async: ref.watch(provider),
      backLabel: kThemeBackLabel,
      onBack: () => retourVersGlobal(
        context,
        depuisGlobal: depuisGlobal,
        global: AppRoutes.progressionCivique,
      ),
      onRefresh: () => ref.refresh(provider.future),
      notFound: kThemeIntrouvable,
      cta: (data) => (
        label: kThemeCta,
        locked: data.cta.locked,
        onTap: () => ouvrirProgressionCta(
              context,
              ref,
              locked: data.cta.locked,
              grille: AppRoutes.civiqueThemeExamsPath(data.themeId),
            ),
      ),
      children: (data) => _corps(context, data),
    );
  }

  List<Widget> _corps(BuildContext context, ProgressionTheme data) {
    final resume = data.resume;
    final dernier = resume.dernier;
    final meilleur = resume.meilleur;
    final echelle = data.echelle;
    final courbe = progressionCourbe(echelle, data.examens);
    final legende = progressionLegende(echelle);
    final verdict = progressionSeuilVerdict(dernier, echelle.seuil);
    final etat = progressionEtatLabel(data.etat);
    return [
      SfProgressIntro(
        eyebrow: kProgressionEyebrow,
        title: themeTitre(data.label),
        lead: kThemeLead,
      ),
      ProgressionBlocs(
        children: [
          SfProgressHero(
            label: kThemeHeroLabel,
            value: progressionValeur(dernier?.score),
            unit: dernier == null ? null : progressionUnite(dernier.max),
            level: etat,
            levelTone: progressionEtatTon(data.etat),
            trend: progressionEcart(resume.ecart, resume.sens,
                depuisLeDebut: true),
            trendTone: progressionSensTon(resume.sens),
            notes: dernier == null
                ? const [kProgressionSansExamenTheme]
                : [
                    if (etat != null && data.etatSourceLabel.isNotEmpty)
                      data.etatSourceLabel,
                    if (verdict != null) verdict,
                  ],
            ring: progressionAnneau(dernier),
          ),
          SfProgressStatGrid(
            tiles: [
              SfProgressStatTile(
                label: kThemeMeilleurLabel,
                value: progressionScore(meilleur?.score, echelle.max),
                caption: themeMeilleurSub(meilleur),
              ),
              SfProgressStatTile(
                label: kThemeNombreLabel,
                value: '${resume.nombre}',
                caption: kThemeNombreSub,
              ),
            ],
          ),
          ProgressionPanneau(
            title: kThemeCourbeTitle,
            sub: kThemeCourbeSub,
            children: [
              if (courbe.points.isEmpty)
                const SfTiny(kThemeVide)
              else
                SfProgressChart(
                  min: echelle.min.toDouble(),
                  max: echelle.max.toDouble(),
                  bands: courbe.bands,
                  reperes: courbe.reperes,
                  seuil: courbe.seuil,
                  points: courbe.points,
                  note: progressionEchelleNote(echelle),
                ),
              if (legende.isNotEmpty) SfProgressScaleLegend(items: legende),
            ],
          ),
          ProgressionPanneau(
            title: kThemeListeTitle,
            sub: kThemeListeSub,
            children: [
              if (data.examens.isEmpty)
                const SfTiny(kThemeVide)
              else
                for (final m in data.examens) _ligne(context, m),
              const SfMicroNote(kThemeFoot),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _ligne(BuildContext context, ProgressionMesure m) {
    final rapport = progressionRapportPath(m.rapportKind, m.rapportAttemptId);
    return SfProgressExamRow(
      title: themeExamenTitre(m.numero),
      date: progressionDateLongue(m.date),
      scoreLabel: kProgressionScoreLabel,
      score: progressionScore(m.score, m.max),
      durationLabel: kProgressionTempsLabel,
      duration: progressionDuree(m.dureeSecondes),
      badge: progressionEtatLabel(m.etat),
      badgeTone: progressionEtatTon(m.etat),
      onTap: rapport == null ? null : () => context.push(rapport),
    );
  }
}
