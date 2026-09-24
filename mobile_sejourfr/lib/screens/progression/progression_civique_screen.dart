import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/progression_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/utils/situation_icons.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'progression_labels.dart';
import 'progression_providers.dart';
import 'widgets/progression_page.dart';

/// **La progression globale civique** — maquette
/// `progression_global_civique.html`, état téléphone.
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
      backLabel: kCiviqueBackLabel,
      onBack: () => retourOuRepli(context),
      onRefresh: () => ref.refresh(provider.future),
      cta: (data) => (
        label: kCiviqueCta,
        locked: data.cta.locked,
        onTap: () => ouvrirProgressionCta(
              context,
              ref,
              locked: data.cta.locked,
              grille: AppRoutes.civiqueExamsBlanc,
            ),
      ),
      children: (data) => _corps(context, data),
      entete: const [
        SfProgressIntro(
          eyebrow: kProgressionEyebrow,
          title: kCiviqueTitle,
          lead: kCiviqueLead,
        ),
        ProgressionBascule(civique: true),
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
          : () => context.push(
              AppRoutes.progressionThemePath(themeId, depuisGlobal: true)),
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
