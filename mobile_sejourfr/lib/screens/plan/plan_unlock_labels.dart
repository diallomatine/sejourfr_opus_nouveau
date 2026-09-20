import '../../core/models/billing_models.dart';

/// **L'écran de déblocage du Plan** (`/plan/debloquer`) — ses règles et ses
/// libellés, déclarés **une seule fois** pour toute l'app.
///
/// C'est l'écran de transition ouvert par « Débloquer mon plan », entre le Plan
/// et l'écran de choix du pass. Il raconte **ce que le diagnostic a trouvé**,
/// puis il annonce le prix d'entrée du module.
///
/// 🛑 **UN SEUL écran pour les deux modules**, paramétré par [PlanUnlockModule].
/// Les deux maquettes du propriétaire partagent l'anatomie — œil-de-bœuf, héros
/// bleu, titre, sous-titre, trois lignes numérotées, un bloc propre au module,
/// le prix, le bouton rouge, le lien discret — et ne diffèrent que par leur
/// **matière**. Deux écrans divergeraient au premier correctif : c'est ce que
/// D-50 / A86 ont refusé pour `PlanCycleSection`, et la raison est la même.
///
/// 🛑 **Rien n'est dérivé ici.** Le palier, le score, l'état de chaque priorité
/// et le prix d'entrée arrivent **servis** ; ce fichier ne fait que les mettre
/// en mots. Aucun nombre n'est classé en état pédagogique.
///
/// Miroir mot pour mot de `web_sejoufr/lib/plan-unlock.ts` : un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.

/// Le parcours dont on débloque le plan.
enum PlanUnlockModule { tcf, civique }

/// 🛑 **Le TCF s'achète avec le pass INTÉGRAL**, jamais avec le Pass Civique —
/// c'est exactement ce que l'écran de choix doit rendre évident. Cette table
/// est la seule qui fasse la correspondance côté mobile.
PlanModuleTarget planUnlockPassModule(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique
        ? PlanModuleTarget.civique
        : PlanModuleTarget.integral;

/* ------------------------------------------------------------- les mots -- */

String planUnlockEyebrow(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? 'Examen civique' : 'Diagnostic terminé';

String planUnlockTitle(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique
        ? 'Votre plan de révision est prêt'
        : 'Votre plan de progression est prêt';

/// Le sous-titre annonce **le nombre réellement servi**, jamais « 3 ».
///
/// 🛑 Le serveur plafonne déjà les priorités ; les compter ici sur la liste
/// servie évite d'annoncer trois compétences quand il en reste deux.
String planUnlockLead(PlanUnlockModule module, int priorites) {
  final s = priorites > 1 ? 's' : '';
  if (module == PlanUnlockModule.civique) {
    return 'Vos réponses classent les $priorites thématique$s '
        'officielle$s par urgence.';
  }
  return 'Vos réponses font ressortir $priorites compétence$s '
      'à travailler en priorité.';
}

/// Le sur-titre de la liste numérotée.
String planUnlockListTitle(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? 'On commence par' : 'Vos priorités';

/// L'intitulé du héros, à gauche.
String planUnlockHeroLabel(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? 'Votre diagnostic' : 'Niveau estimé';

/// Le palier non mesuré s'écrit « — » : `null = inconnu, jamais mauvais`.
const String kPlanUnlockLevelUnknown = '—';

/// « Objectif B2 ». `null` quand la démarche n'est pas déclarée.
String? planUnlockGoalPill(String? cible) =>
    cible == null ? null : 'Objectif $cible';

/// « Seuil 32 / 40 ». Les deux nombres sont **servis**.
String planUnlockSeuilPill(int seuil, int format) => 'Seuil $seuil / $format';

/* ----------------------------------------------- ce que le pass ouvre ---- */

/// Les trois puces du TCF. La première nomme **le nombre servi** de priorités —
/// « ces 3 priorités » sur une liste qui en montre deux serait faux.
List<String> planUnlockChecksTcf(int priorites) => <String>[
      'Des entraînements ciblés sur ces $priorites '
          'priorité${priorites > 1 ? 's' : ''}',
      'Chaque réponse corrigée et expliquée',
      'Un plan réévalué après chaque session',
    ];

/// Les deux faits du civique, sous l'encart des mises en situation.
const List<String> kPlanUnlockChecksCivique = <String>[
  'Corrections expliquées',
  'Examens blancs 40 questions',
];

/* ------------------------------------------------------------- le prix --- */

/// « À partir de 9,99 € achat unique ».
///
/// 🛑 `null` ⇒ **aucune ligne de prix**. Le catalogue est injoignable, on se
/// tait : un montant de repli est un prix faux.
String? planUnlockPriceLine(double? minPrice) {
  if (minPrice == null) return null;
  return 'À partir de ${formatPassPrice(minPrice)} € achat unique';
}

/// « 29,99 » / « 30 ». Le séparateur décimal est la virgule (fr-FR).
/// Miroir de `formatPassPrice` côté web.
String formatPassPrice(double n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(2).replaceAll('.', ',');
}

const String kPlanUnlockPriceNote =
    'Sans abonnement ni reconduction automatique';

/* -------------------------------------------------------------- gestes --- */

const String kPlanUnlockCta = 'Débloquer mon plan';
const String kPlanUnlockSkip = 'Continuer sans le plan';
