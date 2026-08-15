import '../../core/models/diagnostic_models.dart';

/// **Une compétence ouverte depuis le Plan reste dans son étape.**
///
/// Une étape du Plan, ce sont les 5 premiers sujets actifs d'une compétence
/// (`stepPromptIds`, servis par le serveur). La carte d'étape affiche déjà
/// « 2/5 » ; sans marqueur, ouvrir la compétence retombait sur la fiche
/// générique et son « 1/15 », donc le candidat perdait de vue ce qu'il lui
/// reste à faire pour finir son étape.
///
/// Deux vues d'une même compétence selon la porte d'entrée, c'est **assumé** :
/// par « Réviser → épreuve → Compétences », la fiche complète (les 15 sujets,
/// « x/15 ») ne bouge pas d'un pixel.
///
/// 🛑 **Rien n'est recalculé ici** : ni « les 5 premiers par ordre
/// d'affichage », ni un statut de sujet, ni un compteur. Le serveur sert le
/// périmètre et les compteurs, ce fichier ne fait que les retrouver.
///
/// ⚠️ **Aucun identifiant ne voyage dans la route** : on passe un simple
/// marqueur (`?etape=1`) et on relit le Plan **déjà chargé** par l'écran d'où
/// l'on vient. Aucun appel réseau supplémentaire.

/// Marqueur de route. Sa valeur ne porte aucune information : seule sa présence
/// dit « on arrive du Plan ».
const String kPlanStepParam = 'etape';
const String kPlanStepValue = '1';

/// Vrai quand l'écran a été ouvert depuis le Plan.
bool isPlanStepQuery(Map<String, String> query) =>
    query[kPlanStepParam] == kPlanStepValue;

/// L'étape du Plan qui porte cette compétence — priorité n°1 comprise.
///
/// `null` est un cas **normal et fréquent** : le Plan n'est pas chargé, ou la
/// compétence **n'est plus une priorité** (le serveur l'en sort dès qu'une
/// vérification en situation a réussi). L'appelant retombe alors silencieusement
/// sur la fiche complète.
LearningPlanPriority? planStepFor(LearningPlan? plan, String skillId) {
  if (plan == null || skillId.isEmpty) return null;
  final priorities = <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ];
  for (final priority in priorities) {
    if (priority.skillId == skillId) {
      return priority.stepPromptIds.isEmpty ? null : priority;
    }
  }
  return null;
}

/* ------------------------------------------------------------------ libellés
 *
 * ⚠️ **Contrat gelé, miroir mot pour mot du web** (`web_sejoufr/lib/plan-step.ts`).
 * Ces chaînes ne transitent pas par le réseau : chaque front en tient sa copie,
 * un libellé qui bouge, ce sont **deux** fichiers à changer dans la même passe.
 *
 * **Tutoiement** : on est dans le module « Compétences », qui tutoie son chrome.
 */

const String kPlanStepPill = 'Étape de ton plan';
const String kPlanStepBackLabel = 'Mon plan';
const String kPlanStepSectionTitle = 'Les sujets de cette étape';
const String kPlanStepLink = 'Voir mon plan';
const String kPlanStepDoneTitle = 'Étape terminée';
const String kPlanStepDoneCta = 'Revenir à mon plan';

/// « Cette étape, ce sont les 5 premiers sujets de cette compétence. » — le
/// nombre vient du serveur, il n'est jamais écrit en dur (une compétence qui
/// publie moins de sujets a une étape plus courte).
String planStepSectionText(int total) => total > 1
    ? 'Cette étape, ce sont les $total premiers sujets de cette compétence.'
    : 'Cette étape, c\'est le premier sujet de cette compétence.';

/// Ce qu'on dit quand les sujets de l'étape ont tous été traités. On ne promet
/// aucune suite : c'est le Plan qui décide de ce qui vient après.
String planStepDoneText(int total) => total > 1
    ? 'Tu as traité les $total sujets de cette étape. La suite se décide dans '
        'ton plan.'
    : 'Tu as traité le sujet de cette étape. La suite se décide dans ton plan.';
