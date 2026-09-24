import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/models/progression_models.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'progression_labels.dart';
import 'progression_providers.dart';
import 'widgets/progression_page.dart';

/// **La progression d'une épreuve TCF** — maquette
/// `progression_epreuve_tcf.html`, état téléphone.
///
/// Ouvert depuis la carte de l'épreuve sur l'écran global, et depuis
/// « Voir mes résultats » d'une carte de l'Accueil (D17).
///
/// 🛑 **Tout est servi** (`GET /api/me/progression/tcf/{epreuve}`) : score,
/// palier de chaque examen, écart et sens, meilleur, ordinal, durée fiable,
/// bandes (EE/EO seulement — D2 : aucune en CO/CE), niveau actuel (D4) et
/// verrou du bouton (D20). Pas d'anneau en TCF (D5).
///
/// Miroir web : `app/(app)/progression/tcf/[domaine]`.
class ProgressionEpreuveScreen extends ConsumerWidget {
  const ProgressionEpreuveScreen({
    super.key,
    required this.epreuve,
    this.depuisGlobal = false,
  });

  final EpreuveType epreuve;

  /// Poussé depuis l'écran global TCF : le retour dépile.
  final bool depuisGlobal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = progressionEpreuveProvider(epreuve);
    return ProgressionPage<ProgressionEpreuve>(
      async: ref.watch(provider),
      backLabel: kEpreuveBackLabel,
      onBack: () => retourVersGlobal(
        context,
        depuisGlobal: depuisGlobal,
        global: AppRoutes.progressionTcf,
      ),
      onRefresh: () => ref.refresh(provider.future),
      cta: (data) => (
        label: kEpreuveCta,
        locked: data.cta.locked,
        onTap: () => ouvrirProgressionCta(
              context,
              ref,
              locked: data.cta.locked,
              grille: progressionEpreuveCtaPath(epreuve),
            ),
      ),
      children: (data) => _corps(context, data),
    );
  }

  List<Widget> _corps(BuildContext context, ProgressionEpreuve data) {
    final resume = data.resume;
    final dernier = resume.dernier;
    final meilleur = resume.meilleur;
    final echelle = data.echelle;
    final courbe = progressionCourbe(echelle, data.examens);
    final legende = progressionLegende(echelle);
    final niveauActuel = epreuveNiveauActuel(data.niveauActuel);
    return [
      SfProgressIntro(
        eyebrow: kProgressionEyebrow,
        title: epreuveTitre(epreuve),
        lead: epreuveLead(epreuve),
      ),
      ProgressionBlocs(
        children: [
          SfProgressHero(
            label: kEpreuveHeroLabel,
            value: progressionValeur(dernier?.score),
            unit: dernier == null ? null : progressionUnite(dernier.max),
            level: progressionNiveauPill(dernier?.niveau),
            trend: progressionEcart(resume.ecart, resume.sens,
                depuisLeDebut: true),
            trendTone: progressionSensTon(resume.sens),
            notes: [if (niveauActuel != null) niveauActuel],
          ),
          SfProgressStatGrid(
            tiles: [
              SfProgressStatTile(
                label: kEpreuveMeilleurLabel,
                value: progressionScore(meilleur?.score, echelle.max),
                caption: epreuveMeilleurSub(meilleur),
              ),
              SfProgressStatTile(
                label: kEpreuveNombreLabel,
                value: '${resume.nombre}',
                caption: progressionExamensTermines(resume.nombre),
              ),
            ],
          ),
          ProgressionPanneau(
            title: kEpreuveCourbeTitle,
            sub: epreuveCourbeSub(epreuve),
            children: [
              if (courbe.points.isEmpty)
                const SfTiny(kEpreuveVide)
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
              // D2 : pas de bande en CO/CE — la note de portée prend la place
              // de la légende.
              if (legende.isNotEmpty)
                SfProgressScaleLegend(items: legende)
              else
                const SfMicroNote(kProgressionPortee499),
            ],
          ),
          ProgressionPanneau(
            title: kEpreuveListeTitle,
            sub: kEpreuveListeSub,
            children: [
              if (data.examens.isEmpty)
                const SfTiny(kEpreuveVide)
              else
                for (final m in data.examens) _ligne(context, m),
              if (echelle.unite == ProgressionUnite.note20)
                const SfMicroNote(kEpreuveNote20Portee),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _ligne(BuildContext context, ProgressionMesure m) {
    final rapport =
        progressionRapportPath(m.rapportKind, m.rapportAttemptId, epreuve);
    return SfProgressExamRow(
      title: examenBlancTitre(m.numero),
      date: epreuveExamenDate(m),
      scoreLabel: kProgressionScoreLabel,
      score: progressionScore(m.score, m.max),
      durationLabel: kProgressionTempsLabel,
      duration: progressionDuree(m.dureeSecondes),
      badge: m.niveau == null ? null : progressionPalier(m.niveau),
      onTap: rapport == null ? null : () => context.push(rapport),
    );
  }
}
