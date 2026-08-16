import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/action_plan.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Le **plan d'action « pour viser X »** — briques PARTAGEES.
///
/// Le micro-exercice de competence et la production complete EE/EO sortent du
/// meme second appel LLM et rendent le meme plan : leviers, version plus
/// aboutie (ou, a l'oral, passages redits) et tournure a retenir. Ces widgets
/// vivaient dans `competences/widgets/` ; ils ont ete **promus** ici a leur
/// deuxieme consommateur plutot que recopies — deux copies auraient diverge au
/// premier retouche, et c'est exactement ce que la regle de duplication du
/// depot interdit.
///
/// ⚠️ **Corps seulement, pas d'intertitre.** Chaque ecran rend le sien avec son
/// propre gabarit de titre (`SectionTitle` cote competences,
/// `ResultsSectionHead` dans le rapport de correction) : deux typographies de
/// titre empilees dans un meme ecran se lisent comme un bug. Les libelles, eux,
/// sont ici — ils sont geles et communs aux deux surfaces.

/// Intertitre des leviers d'une PRODUCTION complete. **Il garde le palier** :
/// c'est l'objectif du candidat, pas une affirmation sur un texte — donc il est
/// exact, contrairement a un titre qui etiquetterait un modele d'un niveau que
/// rien ne verifie.
String pourViserTitle(TargetLevel niveauVise) =>
    'Pour viser ${niveauVise.asNiveau.shortName}';

/// Intertitre des leviers d'un MICRO-EXERCICE de competence.
///
/// Depuis le contrat v2 de `competence-niveau-vise`, `niveauVise` n'y porte plus
/// l'objectif lointain du candidat mais le **palier cible** : la marche suivante
/// (`niveau constate + 1`, plafonnee a son objectif), que le texte modele doit
/// reellement demontrer. Le titre le nomme donc telle quelle — annoncer « Pour
/// viser B2 » sur un texte qui vaut B1 est exactement le defaut mesure.
///
/// ⚠️ Formulation **positive**, regle gelee du depot : on nomme la marche
/// atteignable, jamais un manque (« presque B1 » est banni).
///
/// Miroir web : `pourPasserAuTitle` (`skill-ui/ActionPlan.tsx`).
String pourPasserAuTitle(TargetLevel palierCible) =>
    'Pour passer au niveau ${palierCible.asNiveau.shortName}';

/// Intertitre du texte modele. **Il ne nomme aucun palier** : la grille impose a
/// ce texte une longueur proche de la production du candidat, ce qui ne laisse
/// pas la place de demontrer honnetement un niveau annonce (mesure : un candidat
/// a recopie un exemple etiquete B2 et l'analyse l'a note B1).
const String kActionPlanExempleTitle = 'Une version plus aboutie';

/// Meme regle, au pluriel : a l'oral il n'y a pas UN texte modele mais deux ou
/// trois passages redits — la production n'est jamais reecrite en entier.
const String kActionPlanReformulationsTitle = 'Des versions plus abouties';

// ---------------------------------------------------------------------------
// L'attente du plan d'action
//
// Ce bloc vient d'un SECOND appel LLM, lance par le serveur **apres** que la
// correction est persistee et la soumission passee a EVALUATED (invariant
// backend : il ne doit jamais pouvoir retarder ni faire echouer la correction).
// Un ecran qui s'arrete net sur EVALUATED s'affiche donc sans plan alors qu'il
// arrive dix a quinze secondes plus tard, et le candidat devait sortir puis
// revenir pour le voir.
//
// Le sursis, son indicateur et son libelle vivent ici, a cote des blocs qu'ils
// annoncent, et servent **les deux ecrans** qui rendent ce plan : le rapport
// d'une production EE/EO et le resultat d'un micro-exercice de competence.
// ---------------------------------------------------------------------------

/// Sursis de polling accorde au second appel, **une seule valeur pour les deux
/// ecrans** (les competences ont vecu a 10 s, les productions n'avaient rien :
/// deux durees pour la meme attente n'avaient aucune justification).
///
/// Miroir web : `ACTION_PLAN_GRACE_MS`. Le budget de polling global de chaque
/// ecran reste la **borne dure** : ce sursis s'y ajoute, il ne le remplace pas.
const Duration kActionPlanGrace = Duration(seconds: 15);

/// Libelle de l'indicateur d'attente. **Contrat gele**, miroir mot pour mot de
/// `ACTION_PLAN_PENDING_LABEL` cote web — et tutoye, comme tout ce qui entoure
/// ce plan.
const String kActionPlanPendingLabel = 'On prépare tes conseils…';

/// Ce que voit le candidat pendant le sursis : un petit spinner et une ligne, a
/// **l'emplacement exact** ou le plan apparaitra.
///
/// Trois regles, a ne pas defaire :
/// - **non bloquant** — ni overlay, ni ecran de chargement, ni squelette qui
///   remplace le rapport : tout le reste reste lisible et utilisable ;
/// - **il disparait en silence** a la fin du sursis si rien n'arrive. Aucun
///   message d'echec, aucun « indisponible » : un plan absent est un cas NORMAL
///   (objectif deja atteint, oral degrade, second appel reste muet) ;
/// - **il ne s'arme que dans la fenetre qui suit l'analyse.** Un rapport rouvert
///   trois jours plus tard n'attend rien : c'est aux ecrans de ne le rendre que
///   pendant leur polling, et seulement s'ils ont vu la correction en vol.
///
/// Le spinner est la brique deja employee par `EvaluationLoadingView` pour son
/// etape active — pas un composant de plus.
class ActionPlanPending extends StatelessWidget {
  const ActionPlanPending({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kActionPlanPendingLabel,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Pour viser B1 » : les 2 a 3 leviers du second appel, du plus rentable au
/// moins rentable — l'ordre du serveur, jamais retrie.
///
/// Chaque ligne dit le geste ([ActionPlanLevier.action]) et les mots pour le
/// faire ([ActionPlanLevier.exemple]). Aucun texte n'est ajoute : tout est deja
/// plafonne en mots cote serveur.
class ActionPlanLeviers extends StatelessWidget {
  const ActionPlanLeviers({super.key, required this.leviers});

  final List<ActionPlanLevier> leviers;

  /// Trois teintes qui tournent : elles separent les leviers a l'oeil sans
  /// hierarchiser (le rang est deja donne par l'ordre serveur).
  static const _tints = <(Color, Color)>[
    (AppColors.blueLight, AppColors.blue),
    (AppColors.greenLight, AppColors.green),
    (AppColors.amberLight, AppColors.amberDark),
  ];

  @override
  Widget build(BuildContext context) {
    if (leviers.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < leviers.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.line2),
            _LevierRow(
              levier: leviers[i],
              soft: _tints[i % _tints.length].$1,
              strong: _tints[i % _tints.length].$2,
            ),
          ],
        ],
      ),
    );
  }
}

class _LevierRow extends StatelessWidget {
  const _LevierRow({
    required this.levier,
    required this.soft,
    required this.strong,
  });

  final ActionPlanLevier levier;
  final Color soft;
  final Color strong;

  @override
  Widget build(BuildContext context) {
    final exemple = levier.exemple;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.arrowUpRight, size: 14, color: strong),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              levier.action,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          if (exemple != null) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                exemple,
                textAlign: TextAlign.right,
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w600,
                  height: 1.35,
                  color: strong,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// « Une version plus aboutie » : la reponse du candidat reecrite, avec les
/// passages qui font la difference mis en evidence, puis ce que chacun apporte.
///
/// Le serveur garantit que chaque `extrait` est une **sous-chaine exacte** du
/// texte : le surlignage se fait par recherche de chaine, sans normalisation.
/// Un extrait introuvable est simplement ignore — le texte reste lisible, on
/// n'invente jamais un surlignage et on ne plante jamais.
class ActionPlanExempleCard extends StatelessWidget {
  const ActionPlanExempleCard({
    super.key,
    required this.exemple,
    this.label,
  });

  final ActionPlanExempleCible exemple;

  /// Petit label posé **dans** la carte, quand l'écran l'oppose à une autre
  /// carte citée juste au-dessus (l'avant/après du diagnostic). Les rapports
  /// de production et de compétence n'en ont pas besoin : leur intertitre de
  /// section suffit. **N'annonce jamais un palier** — cf.
  /// [kActionPlanExempleTitle].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final base = AppFonts.ui(size: 13, height: 1.55);
    final mark = base.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.blueDark,
      backgroundColor: AppColors.blue.withValues(alpha: 0.14),
    );
    final segments = exemple.segments;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: AppFonts.label(size: 10, color: AppColors.blue)),
            const SizedBox(height: 7),
          ],
          Text.rich(
            TextSpan(
              children: _highlightedSpans(
                exemple.texte,
                segments,
                base: base,
                mark: mark,
              ),
            ),
          ),
          for (final segment in segments)
            if (segment.apport != null) ...[
              const SizedBox(height: 9),
              _SegmentRow(extrait: segment.extrait, apport: segment.apport!),
            ],
        ],
      ),
    );
  }
}

/// Decoupe [texte] sur les extraits trouves. Le premier emplacement libre de
/// chaque extrait gagne ; les chevauchements et les extraits absents sont
/// ignores, jamais approches.
List<TextSpan> _highlightedSpans(
  String texte,
  List<ActionPlanSegment> segments, {
  required TextStyle base,
  required TextStyle mark,
}) {
  final ranges = <({int start, int end})>[];
  for (final segment in segments) {
    var from = 0;
    while (from <= texte.length) {
      final start = texte.indexOf(segment.extrait, from);
      if (start < 0) break;
      final end = start + segment.extrait.length;
      final overlaps = ranges.any((r) => start < r.end && r.start < end);
      if (!overlaps) {
        ranges.add((start: start, end: end));
        break;
      }
      from = start + 1;
    }
  }
  if (ranges.isEmpty) return [TextSpan(text: texte, style: base)];

  ranges.sort((a, b) => a.start.compareTo(b.start));
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final range in ranges) {
    if (range.start > cursor) {
      spans.add(
        TextSpan(text: texte.substring(cursor, range.start), style: base),
      );
    }
    spans.add(
      TextSpan(text: texte.substring(range.start, range.end), style: mark),
    );
    cursor = range.end;
  }
  if (cursor < texte.length) {
    spans.add(TextSpan(text: texte.substring(cursor), style: base));
  }
  return spans;
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.extrait, required this.apport});

  final String extrait;
  final String apport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          extrait,
          style: AppFonts.ui(
            size: 11.5,
            weight: FontWeight.w800,
            color: AppColors.blueDark,
          ),
        ),
        const Icon(LucideIcons.arrowRight, size: 12, color: AppColors.inkFaint),
        Text(apport, style: AppFonts.ui(size: 11.5, color: AppColors.inkSoft)),
      ],
    );
  }
}

/// « Des versions plus abouties » : l'equivalent ORAL, deux ou trois passages
/// redits au niveau vise.
///
/// **Il n'y a jamais de texte modele complet a l'oral** : ce que lit le
/// correcteur est une transcription automatique, en refaire un beau discours
/// tromperait le candidat sur ce qu'il a reellement dit. On montre donc son
/// passage (attenue), puis la meme chose mieux dite (en accent), puis ce que la
/// reformulation apporte.
class ActionPlanReformulationsList extends StatelessWidget {
  const ActionPlanReformulationsList({super.key, required this.reformulations});

  final List<ActionPlanReformulation> reformulations;

  @override
  Widget build(BuildContext context) {
    if (reformulations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < reformulations.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _ReformulationCard(reformulation: reformulations[i]),
        ],
      ],
    );
  }
}

class _ReformulationCard extends StatelessWidget {
  const _ReformulationCard({required this.reformulation});

  final ActionPlanReformulation reformulation;

  @override
  Widget build(BuildContext context) {
    final apport = reformulation.apport;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ce que le candidat a dit : present, mais en retrait — ce n'est pas
          // le modele.
          Text(
            reformulation.original,
            style: AppFonts.ui(size: 12, height: 1.55, color: AppColors.muted),
          ),
          const SizedBox(height: 7),
          Text(
            reformulation.reformule,
            style: AppFonts.ui(
              size: 13,
              height: 1.6,
              weight: FontWeight.w700,
              color: AppColors.blueDark,
            ),
          ),
          if (apport != null) ...[
            const SizedBox(height: 9),
            _ApportChip(apport: apport),
          ],
        ],
      ),
    );
  }
}

/// Ce que la reformulation apporte, en trois mots : une pastille, jamais une
/// phrase — le serveur la plafonne deja.
class _ApportChip extends StatelessWidget {
  const _ApportChip({required this.apport});

  final String apport;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.blueLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.arrowRight,
              size: 12,
              color: AppColors.inkFaint,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                apport,
                style: AppFonts.label(size: 10, color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « À retenir » : la tournure a emporter ailleurs, ecrite comme un patron, et
/// quand elle sert.
///
/// Carte teintee chaude : c'est le seul bloc qu'on veut voir revenir en memoire
/// une fois l'ecran ferme. Elle porte son propre libelle — c'est un memo, pas
/// une section de plus.
class ActionPlanMemoCard extends StatelessWidget {
  const ActionPlanMemoCard({super.key, required this.memo});

  final ActionPlanMemo memo;

  @override
  Widget build(BuildContext context) {
    final explication = memo.explication;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.bookmark,
                size: 14,
                color: AppColors.amberDark,
              ),
              const SizedBox(width: 6),
              Text(
                'À retenir',
                style: AppFonts.label(size: 10, color: AppColors.amberDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            memo.formule,
            style: AppFonts.ui(size: 13.5, weight: FontWeight.w800, height: 1.4),
          ),
          if (explication != null) ...[
            const SizedBox(height: 5),
            Text(
              explication,
              style: AppFonts.ui(
                size: 11.5,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
