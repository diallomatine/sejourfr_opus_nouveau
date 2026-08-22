import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/utils/epreuve_duration.dart';
import 'diagnostic_intro_labels.dart';

/// **Le choix d'entrée du diagnostic : rapide ou complet.**
///
/// 🛑 **La variante n'est PAS persistée** — ni en base, ni sur l'appareil. Le
/// backend a tranché : le profil réel se lit sur les **domaines mesurés**
/// (`LearningPlan.domaines` / `domainesAEvaluer`), et au moment du choix le
/// candidat est encore **invité** : aucune ligne ne pourrait la porter.
///
/// Conséquence directe : les deux variantes sont **le même parcours d'écrans**
/// — expression écrite puis expression orale, exactement les deux productions
/// du diagnostic. Ce qui change, c'est **ce que le front enchaîne après
/// l'analyse** : le complet propose immédiatement de mesurer la compréhension
/// (CO puis CE), le rapide renvoie au Plan.
///
/// ⚠️ **Un invité ne peut pas jouer CO/CE avant son compte** : un attempt sans
/// compte n'a personne à qui attribuer un progrès. La compréhension se joue
/// donc **toujours après la création du compte**, et les deux variantes le
/// disent.
///
/// L'intention vit en **mémoire de processus** (`diagnosticVariantProvider`,
/// non `autoDispose`) : elle survit à la recréation de
/// `diagnosticControllerProvider` au moment de l'inscription et au
/// remplacement de pile du router après `register`. Perdue à la fermeture de
/// l'app, on retombe sur [DiagnosticVariant.rapide] — sans rien perdre : la
/// proposition de compléter le profil reste servie par le Plan.
enum DiagnosticVariant {
  rapide,
  complet;

  bool get isComplet => this == DiagnosticVariant.complet;
}

/// L'intention du candidat, pour cette exécution de l'app seulement.
final diagnosticVariantProvider =
    StateProvider<DiagnosticVariant>((ref) => DiagnosticVariant.rapide);

/// Le titre de la carte d'option.
String diagnosticVariantTitle(DiagnosticVariant variant) => switch (variant) {
      DiagnosticVariant.rapide => 'Diagnostic rapide',
      DiagnosticVariant.complet => 'Diagnostic complet',
    };

/// Les épreuves couvertes, en abrégé — la ligne de méta de la carte.
String diagnosticVariantScope(DiagnosticVariant variant) => switch (variant) {
      DiagnosticVariant.rapide => 'Expression écrite + expression orale',
      DiagnosticVariant.complet => 'EE + EO, puis CO + CE',
    };

/// Ce que la variante apporte. Aucune promesse de résultat : ce sont les
/// mesures que le parcours produit.
List<String> diagnosticVariantHighlights(DiagnosticVariant variant) =>
    switch (variant) {
      DiagnosticVariant.rapide => const <String>[
          'Analyse de votre capacité réelle de production',
          'Première estimation de niveau',
          'Premières compétences détectées',
        ],
      DiagnosticVariant.complet => const <String>[
          'Un profil complet sur les 4 épreuves du TCF',
          'La compréhension se mesure juste après la création de votre compte',
        ],
    };

/// Le libellé du bouton de démarrage, par variante.
String diagnosticVariantCta(DiagnosticVariant variant) => switch (variant) {
      DiagnosticVariant.rapide => 'Commencer le diagnostic',
      DiagnosticVariant.complet => 'Faire le diagnostic complet',
    };

/// Minutes des **deux productions**, dérivées des sujets servis. `0` quand la
/// base ne porte aucune borne exploitable — on n'invente alors aucun chiffre.
int _productionMinutes(
  DiagnosticExerciseView? written,
  DiagnosticExerciseView? oral,
) =>
    (diagnosticWrittenMinutes(written) ?? 0) +
    (diagnosticOralMinutes(oral) ?? 0);

/// Minutes des deux épreuves de **compréhension**, lues dans la seule table de
/// durées autorisée avant qu'une session existe
/// (`kEpreuveDurationSeconds`, miroir de `DureeEpreuve`). Jamais un chiffre
/// écrit ici : raccourcir la CE côté serveur raccourcit la promesse.
int get _comprehensionMinutes =>
    ((kEpreuveDurationSeconds[EpreuveType.tcfCo] ?? 0) +
            (kEpreuveDurationSeconds[EpreuveType.tcfCe] ?? 0)) ~/
        60;

/// Le coût en temps annoncé sur la carte d'une variante.
///
/// C'est un **ordre de grandeur**, jamais un chrono : rien du parcours ne
/// chronomètre le candidat sur cette valeur. Sans mesure exploitable, on
/// annonce le nombre d'épreuves plutôt qu'une durée inventée.
String diagnosticVariantDurationLabel(
  DiagnosticVariant variant,
  DiagnosticExerciseView? written,
  DiagnosticExerciseView? oral,
) {
  final productions = _productionMinutes(written, oral);
  return switch (variant) {
    DiagnosticVariant.rapide =>
      productions > 0 ? '≈ $productions min' : '2 exercices',
    DiagnosticVariant.complet => productions > 0
        ? '≈ ${productions + _comprehensionMinutes} min au total'
        : '4 épreuves',
  };
}

/// Le sous-titre de l'en-tête : la variante choisie et son coût, dans la même
/// formule que sa carte. **Une seule table de durées** — celle ci-dessus — pour
/// que l'en-tête ne puisse pas annoncer autre chose que la carte sélectionnée.
String diagnosticVariantHeaderSub(
  DiagnosticVariant variant,
  DiagnosticExerciseView? written,
  DiagnosticExerciseView? oral,
) =>
    '${diagnosticVariantTitle(variant)} · '
    '${diagnosticVariantDurationLabel(variant, written, oral)}';

/// Ce qui reste à faire après l'analyse, dit au moment où le candidat crée son
/// compte. `null` en rapide : il n'y a rien de plus à annoncer.
String? diagnosticVariantAccountNote(DiagnosticVariant variant) =>
    variant.isComplet
        ? 'Vous avez choisi le diagnostic complet : la compréhension orale et '
            'écrite se mesure juste après, depuis votre bilan.'
        : null;
