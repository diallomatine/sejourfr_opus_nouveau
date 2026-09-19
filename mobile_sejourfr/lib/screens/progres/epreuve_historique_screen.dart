import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/epreuve_historique_models.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../home/widgets/home_blocks.dart';
import 'progres_labels.dart';

/// Les dernières évaluations qualifiantes d'une épreuve.
///
/// 🛑 **`autoDispose` et non gardé en vie** : c'est un détail qu'on ouvre, pas
/// une source d'écran d'accueil. Le garder en cache retiendrait un historique
/// périmé après un examen blanc passé entre-temps.
final epreuveHistoriqueProvider = FutureProvider.autoDispose
    .family<EpreuveHistorique, EpreuveType>((ref, epreuve) {
  return ref.watch(progressRepositoryProvider).historique(epreuve);
});

const String kHistoriqueTitle = 'Vos résultats';

/// 🛑 Une absence de mesure n'est pas une erreur, et se dit comme telle.
const String kHistoriqueVide = 'Aucune évaluation qualifiante pour l\'instant.';
const String kHistoriqueVideAide =
    'Un examen blanc, une épreuve passée seule ou un diagnostic apparaîtront '
    'ici dès qu\'ils auront été corrigés.';

/// Ce que la liste contient, dit au candidat plutôt que deviné par lui.
///
/// ⚠️ **Formulée pour rester vraie même quand la liste est vide.** « Les
/// évaluations qui déterminent votre niveau » était faux en EE/EO : le profil y
/// compte aussi l'entraînement libre, que cette page ne montre pas (arbitrage
/// ouvert, cf. `EpreuveHistoriqueService`). On dit donc ce que la liste
/// **contient**, pas ce qu'elle prétend expliquer.
const String kHistoriqueLead =
    'Vos épreuves complètes et vos diagnostics sur cette épreuve. '
    'Vos entraînements libres et vos petits sujets n\'y figurent pas.';

const String kHistoriqueErreur =
    'Vos résultats n\'ont pas pu être chargés. Réessayez dans un instant.';

/* ---------------------------------------------------------------- héros -- */

const String kHistoriqueNiveauLabel = 'Niveau actuel';
const String kHistoriqueObjectifLabel = 'Objectif';

/* --------------------------------------------------------------- courbe -- */

const String kHistoriqueCourbeTitle = 'Votre évolution';
const String kHistoriqueCourbeSub = 'Touchez un point pour voir l\'évaluation.';

/* ----------------------------------------------------------- historique -- */

const String kHistoriqueListeTitle = 'Historique';

/// « 4 évaluations complètes ». 🛑 On compte des lignes servies, rien d'autre.
String historiqueCountLabel(int n) =>
    '$n évaluation${n > 1 ? 's' : ''} complète${n > 1 ? 's' : ''}';

/// Les trois filtres de la liste. 🛑 Ils partitionnent les **quatre** sources.
enum HistoriqueFiltre { tout, diagnostic, examen }

const Map<HistoriqueFiltre, String> kHistoriqueFiltreLabel = {
  HistoriqueFiltre.tout: 'Tout',
  HistoriqueFiltre.diagnostic: 'Diagnostics',
  HistoriqueFiltre.examen: 'Examens',
};

/// À quel filtre appartient une source.
///
/// 🛑 **Les quatre valeurs ne se fondent pas deux à deux** ailleurs : ici on ne
/// les fond que pour **filtrer**, jamais pour les nommer — chaque ligne garde
/// son libellé gelé (`SourceEvaluation.label`).
HistoriqueFiltre historiqueFamille(SourceEvaluation source) =>
    switch (source) {
      SourceEvaluation.diagnosticRapide ||
      SourceEvaluation.diagnosticComplet =>
        HistoriqueFiltre.diagnostic,
      SourceEvaluation.epreuveSeule ||
      SourceEvaluation.examenBlanc =>
        HistoriqueFiltre.examen,
    };

/// Ce que le détail d'une ligne raconte : d'où vient la mesure.
///
/// 🛑 **Rien qui prétende expliquer le palier courant.** Le niveau affiché est
/// la moyenne des trois derniers examens qualifiants (règle serveur) : écrire
/// « résultat pris en compte dans votre niveau actuel » sur une ligne précise
/// serait une affirmation que l'app ne peut pas vérifier.
const Map<SourceEvaluation, String> kHistoriqueSourceDetail = {
  SourceEvaluation.diagnosticRapide:
      'Mesure issue de votre diagnostic rapide.',
  SourceEvaluation.diagnosticComplet:
      'Mesure issue de votre diagnostic complet.',
  SourceEvaluation.epreuveSeule:
      'Épreuve passée seule, en dehors d\'un examen complet.',
  SourceEvaluation.examenBlanc:
      'Cette épreuve faisait partie d\'un examen blanc complet.',
};

/// « Niveau estimé : B1. » — le palier servi, remis en tête du détail.
String historiqueNiveauEstime(NiveauCecrl niveau) =>
    'Niveau estimé : ${niveau.shortName}.';

/// Le pictogramme d'une provenance.
IconData historiqueSourceIcon(SourceEvaluation source) => switch (source) {
      SourceEvaluation.diagnosticRapide => LucideIcons.compass,
      SourceEvaluation.diagnosticComplet => LucideIcons.clipboardCheck,
      SourceEvaluation.epreuveSeule => LucideIcons.circleCheck,
      SourceEvaluation.examenBlanc => LucideIcons.fileText,
    };

/// Ce que la liste compte, et ce qu'elle ne compte pas.
const String kHistoriquePorteeTitle = 'Ce qui compte ici :';
const String kHistoriquePorteeText =
    ' diagnostics et épreuves complètes. Les petits sujets et les entraînements '
    'libres restent disponibles ailleurs, mais ne modifient pas cet historique.';

/// Le lien vers le hub des historiques. 🛑 **Miroir du web**, où la même carte
/// porte la même sortie : cet écran ne montre qu'UNE épreuve, et il faut
/// pouvoir rejoindre le reste sans repasser par l'Accueil.
const String kHistoriqueTousLabel = 'Tous mes résultats';

/* ------------------------------------------------------------------ vue -- */

/// **« D'où sort mon niveau ? »** — l'écran ouvert depuis une carte d'épreuve
/// de l'Accueil, refait sur la maquette du propriétaire (2026-09-16).
///
/// 🛑 **Ce n'est pas une seconde liste d'historique.** `/historiques` liste
/// **toutes** les sessions, entraînements compris ; celui-ci ne montre que les
/// **évaluations qualifiantes** de UNE épreuve — exactement celles qui ont
/// produit le palier affiché sur la carte. C'est la seule page qui répond à
/// « pourquoi ce niveau ? », et elle n'a pas d'équivalent.
///
/// 🛑 **Rien n'est dérivé ici** : date, provenance et palier sont **servis**
/// (`GET /api/me/progress/tcf/{epreuve}/historique`) ; le palier courant,
/// l'objectif et le sens d'évolution viennent du **même** `progressProvider`
/// que l'Accueil — donc **aucun appel de plus**, il est gardé en vie pour la
/// session.
///
/// 🛑 **Miroir de `EpreuveHistoriqueView` côté web**, bloc pour bloc.
class EpreuveHistoriqueScreen extends ConsumerStatefulWidget {
  const EpreuveHistoriqueScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  @override
  ConsumerState<EpreuveHistoriqueScreen> createState() =>
      _EpreuveHistoriqueScreenState();
}

class _EpreuveHistoriqueScreenState
    extends ConsumerState<EpreuveHistoriqueScreen> {
  HistoriqueFiltre _filtre = HistoriqueFiltre.tout;

  /// L'index **dans la liste servie** (la plus récente d'abord).
  int? _choisi;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(epreuveHistoriqueProvider(widget.epreuve));
    // 🛑 **Le palier courant est un CONFORT** : son absence laisse la liste
    // entière, elle ne doit jamais empêcher de lire son historique.
    final progres = ref.watch(progressProvider).valueOrNull;
    final situation = progres?.tcf.epreuves
        .where((e) => e.epreuve == widget.epreuve)
        .firstOrNull;
    final objectif = progres?.tcf.objectif;

    final evaluations = async.valueOrNull?.evaluations ?? const [];
    // 🛑 **L'échelle et les points viennent de `progresCourbe`**, partagée avec
    // « Votre progression » : deux copies auraient fini par ne plus situer un
    // palier à la même hauteur pour la même liste servie.
    final courbe = progresCourbe(evaluations, objectif);
    final ladder = courbe.ladder;
    final points = courbe.points;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              onBack: () => retourOuRepli(context, repli: '/'),
              kicker: widget.epreuve.displayLabel,
              title: kHistoriqueTitle,
            ),
            SfSection(
              flush: true,
              child: SfStack(
                pad: false,
                children: [
                  // 🛑 **Le palier et l'objectif sont SERVIS**, et « — » est le
                  // rendu d'une absence de mesure : jamais « A1 ».
                  SfResultHero(
                    label: kHistoriqueNiveauLabel,
                    level: situation?.niveau?.shortName ?? '—',
                    goalLabel: kHistoriqueObjectifLabel,
                    goal: objectif?.shortName,
                    trend: situation == null
                        ? null
                        : progresEvolutionLabel(situation),
                    note: kHistoriqueLead,
                  ),
                  // 🛑 **Pas de courbe sans point** : un panneau vide
                  // raconterait une absence comme un incident.
                  if (points.isNotEmpty)
                    SfCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SfPanelHead(
                            title: kHistoriqueCourbeTitle,
                            sub: points.length > 1
                                ? kHistoriqueCourbeSub
                                : null,
                          ),
                          const SizedBox(height: 12),
                          SfLevelChart(
                            ladder: ladder,
                            points: points,
                            activeIndex: _choisi == null
                                ? points.length - 1
                                : evaluations.length - 1 - _choisi!,
                            onSelect: (i) => setState(
                                () => _choisi = evaluations.length - 1 - i),
                          ),
                        ],
                      ),
                    ),
                  SfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SfPanelHead(
                          title: kHistoriqueListeTitle,
                          sub: evaluations.isEmpty
                              ? null
                              : historiqueCountLabel(evaluations.length),
                        ),
                        const SizedBox(height: 12),
                        async.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          ),
                          // 🛑 Un échec de chargement n'est pas « aucune
                          // évaluation » : on ne range pas une panne dans le
                          // verdict le plus bas.
                          error: (_, __) => const SfTiny(kHistoriqueErreur),
                          data: (historique) => historique.evaluations.isEmpty
                              ? const _Vide()
                              : _Liste(
                                  evaluations: historique.evaluations,
                                  filtre: _filtre,
                                  choisi: _choisi,
                                  onFiltre: (f) => setState(() => _filtre = f),
                                  onToggle: (i) => setState(
                                      () => _choisi = _choisi == i ? null : i),
                                ),
                        ),
                        const SizedBox(height: 12),
                        SfInfoNote(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: kHistoriquePorteeTitle,
                                  style: AppFonts.ui(
                                    size: 11.5,
                                    weight: FontWeight.w800,
                                    color: AppColors.amberDark,
                                    height: 1.45,
                                  ),
                                ),
                                TextSpan(
                                  text: kHistoriquePorteeText,
                                  style: AppFonts.ui(
                                    size: 11.5,
                                    color: AppColors.amberDark,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: HomeLink(
                            label: kHistoriqueTousLabel,
                            onTap: () => context.push(AppRoutes.historiques),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kHistoriqueVide,
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const SfTiny(kHistoriqueVideAide),
      ],
    );
  }
}

/// La liste filtrable des évaluations.
class _Liste extends StatelessWidget {
  const _Liste({
    required this.evaluations,
    required this.filtre,
    required this.choisi,
    required this.onFiltre,
    required this.onToggle,
  });

  final List<EvaluationQualifiante> evaluations;
  final HistoriqueFiltre filtre;
  final int? choisi;
  final ValueChanged<HistoriqueFiltre> onFiltre;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final visibles = <int>[
      for (var i = 0; i < evaluations.length; i++)
        if (filtre == HistoriqueFiltre.tout ||
            historiqueFamille(evaluations[i].source) == filtre)
          i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🛑 **Le filtre ne se montre que s'il a de quoi trier** : une rangée
        // d'onglets au-dessus d'une ligne unique ne filtre rien.
        if (evaluations.length > 1) ...[
          SfFilterChips<HistoriqueFiltre>(
            options: [
              for (final f in HistoriqueFiltre.values)
                (id: f, label: kHistoriqueFiltreLabel[f]!),
            ],
            value: filtre,
            onChanged: onFiltre,
          ),
          const SizedBox(height: 12),
        ],
        for (var k = 0; k < visibles.length; k++) ...[
          if (k > 0) const SizedBox(height: 10),
          _Ligne(
            evaluation: evaluations[visibles[k]],
            open: choisi == visibles[k],
            onToggle: () => onToggle(visibles[k]),
          ),
        ],
      ],
    );
  }
}

/// Une évaluation : sa provenance, sa date, son palier, et son détail.
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.evaluation,
    required this.open,
    required this.onToggle,
  });

  final EvaluationQualifiante evaluation;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SfHistoryRow(
      icon: historiqueSourceIcon(evaluation.source),
      title: evaluation.source.label,
      date: jourLong(evaluation.mesureA),
      level: evaluation.niveau.shortName,
      open: open,
      onToggle: onToggle,
      detail: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: historiqueNiveauEstime(evaluation.niveau),
              style: AppFonts.ui(
                size: 11.5,
                weight: FontWeight.w800,
                height: 1.45,
              ),
            ),
            TextSpan(
              text: ' ${kHistoriqueSourceDetail[evaluation.source]}',
              style: AppFonts.ui(
                size: 11.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
