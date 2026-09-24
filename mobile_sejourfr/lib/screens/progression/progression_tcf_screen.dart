import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/models/progression_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/utils/situation_icons.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/plan_labels.dart';
import 'progression_labels.dart';
import 'progression_providers.dart';
import 'widgets/progression_page.dart';

/// **La progression globale TCF** — maquette `progression_global_tcf.html`,
/// état téléphone.
///
/// 🛑 **D6 : aucun score global.** La carte de tête porte le palier global
/// **actuel** (servi), le dernier examen complet et l'évolution de PALIER.
/// Meilleur / première évaluation sont des paliers d'examens **non partiels**
/// (D7). Pas d'anneau (D5).
///
/// [tous] = « Tous mes examens blancs » (D8, `?tous=true`) : la même page, la
/// liste entière.
///
/// Miroir web : `app/(app)/progression/tcf`.
class ProgressionTcfScreen extends ConsumerWidget {
  const ProgressionTcfScreen({super.key, this.tous = false});

  final bool tous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = progressionTcfProvider(tous);
    return ProgressionPage<ProgressionTcf>(
      async: ref.watch(provider),
      backLabel: kTcfBackLabel,
      onBack: () => retourOuRepli(context),
      onRefresh: () => ref.refresh(provider.future),
      cta: (data) => (
        label: kTcfCta,
        locked: data.cta.locked,
        onTap: () => ouvrirProgressionCta(
              context,
              ref,
              locked: data.cta.locked,
              grille: AppRoutes.tcfFullExams,
            ),
      ),
      children: (data) => _corps(context, data),
      entete: const [
        SfProgressIntro(
          eyebrow: kProgressionEyebrow,
          title: kTcfTitle,
          lead: kTcfLead,
        ),
        ProgressionBascule(civique: false),
      ],
    );
  }

  List<Widget> _corps(BuildContext context, ProgressionTcf data) {
    final complets = data.examensComplets;
    final dernier = complets.dernier;
    final meilleur = complets.meilleur;
    final premier = complets.premier;
    final niveau = data.niveauActuel;
    final dernierComplet =
        tcfDernierComplet(dernier?.niveau, dernier?.partiel ?? false);
    final partiel = tcfNiveauPartielNote(
        data.niveauActuelEpreuves, data.niveauActuelPartiel);
    return [
      ProgressionBlocs(
        children: [
          SfProgressHero(
            label: kTcfHeroLabel,
            value: progressionPalier(niveau),
            level: dernierComplet,
            trend: progressionEvolutionPalier(complets.evolution),
            trendTone: progressionSensTon(complets.evolution),
            notes: [
              if (niveau == null)
                kTcfNiveauInconnuNote
              else if (partiel != null)
                partiel,
            ],
          ),
          SfProgressStatGrid(
            framed: true,
            tiles: [
              SfProgressStatTile(
                inset: true,
                label: kTcfStatNombre,
                value: '${complets.nombre}',
                caption: progressionTermines(complets.nombre),
              ),
              SfProgressStatTile(
                inset: true,
                label: kTcfStatMeilleur,
                value: progressionPalier(meilleur?.niveau),
                caption: meilleur == null
                    ? null
                    : tcfExamenSub(meilleur.numero, meilleur.date),
              ),
              SfProgressStatTile(
                inset: true,
                label: kTcfStatPremier,
                value: progressionPalier(premier?.niveau),
                caption: premier == null
                    ? null
                    : tcfExamenSub(premier.numero, premier.date),
              ),
              SfProgressStatTile(
                inset: true,
                label: kTcfStatDernier,
                value: progressionDateCourte(dernier?.date),
                caption:
                    dernier == null ? null : progressionAnnee(dernier.date),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: SfPanelHead(
              title: kTcfEpreuvesTitle,
              sub: kTcfEpreuvesSub,
              lead: true,
            ),
          ),
          for (final carte in data.epreuves)
            if (carte.epreuve != null) _carte(context, carte, carte.epreuve!),
          ProgressionPanneau(
            title: tous ? kTcfListeTousTitle : kTcfListeTitle,
            sub: tous ? kTcfListeTousSub : kTcfListeSub,
            children: [
              if (data.examens.isEmpty)
                const SfTiny(kTcfListeVide)
              else
                for (final e in data.examens) _ligne(context, e),
              // D8 : le total est servi ; le lien n'apparaît que s'il en reste
              // à montrer.
              if (!tous && complets.nombre > data.examens.length)
                ProgressionLien(
                  label: kTcfListeTousLink,
                  onTap: () => context.push(AppRoutes.progressionTcfTous),
                ),
              if (tous)
                ProgressionLien(
                  label: kProgressionListeMoinsLink,
                  onTap: () =>
                      retourOuRepli(context, repli: AppRoutes.progressionTcf),
                ),
              const SfMicroNote(kTcfHint),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _carte(
    BuildContext context,
    ProgressionCarte carte,
    EpreuveType epreuve,
  ) {
    final resume = carte.resume;
    final dernier = resume.dernier;
    return SfProgressDomainCard(
      icon: situationEpreuveIcon(planDomainSection(epreuve)),
      title: tcfEpreuveNom(epreuve),
      sub: kTcfCarteSub,
      onTap: () => context.push(AppRoutes.progressionEpreuvePath(
          planDomainKey(epreuve),
          depuisGlobal: true)),
      empty: dernier == null ? kProgressionSansExamen : null,
      value: progressionValeur(dernier?.score),
      unit: progressionUnite(carte.echelle.max),
      pill: progressionNiveauPill(dernier?.niveau),
      delta: progressionEcart(resume.ecart, resume.sens),
      deltaTone: progressionSensTon(resume.sens),
      spark: progressionSpark(carte),
    );
  }

  Widget _ligne(BuildContext context, ProgressionExamenComplet e) {
    return SfProgressGlobalExamRow(
      title: examenBlancTitre(e.numero),
      date: tcfExamenDate(e.date, e.partiel, e.epreuvesComptees),
      badge: progressionPalier(e.niveau),
      badgeTone: e.niveau == null ? SfBarTone.muted : SfBarTone.now,
      parts: [
        for (final p in e.parEpreuve)
          (
            label: tcfEpreuveMark(p.epreuve),
            value: progressionScore(p.score, p.max),
          ),
      ],
      onTap: () => context.push(AppRoutes.tcfFullExamBilanPath(e.attemptId)),
    );
  }
}
