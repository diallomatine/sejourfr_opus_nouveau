import '../../core/models/enums.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/// **L'écran de déblocage du Plan** (`/plan/debloquer`) — ses règles et ses
/// libellés, déclarés **une seule fois** pour toute l'app.
///
/// C'est l'écran de transition ouvert par « Débloquer mon plan », entre le Plan
/// et l'écran de choix du pass. Il raconte **ce que le diagnostic a trouvé**,
/// puis il annonce le prix d'entrée du module.
///
/// 🛑 **UN SEUL écran pour les deux modules**, paramétré par [PlanUnlockModule].
/// Les deux maquettes du propriétaire partagent l'anatomie — œil-de-bœuf, héros
/// bleu, titre, sous-titre, les priorités en encarts par épreuve (ou par
/// thème), un bloc propre au module,
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

/// **L'accès que cet écran attend** — celui qu'il faut avoir pour qu'il n'ait
/// plus lieu d'être.
///
/// ⚠️ À ne pas confondre avec [planUnlockPassModule] : on ACHÈTE le TCF avec le
/// pass Intégral, mais l'accès qui s'ouvre est `hasTcf`. Deux questions
/// différentes, deux tables.
AppModule planUnlockAccessModule(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? AppModule.civique : AppModule.tcf;

/* ------------------------------------------------------------- les mots -- */

String planUnlockEyebrow(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? 'Examen civique' : 'Diagnostic terminé';

String planUnlockTitle(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique
        ? 'Votre plan de révision est prêt'
        : 'Votre plan de progression est prêt';

/// Le sous-titre annonce **le TOTAL servi**, jamais le nombre affiché.
///
/// 🛑 TCF : c'est le nombre d'actions du Plan sur les épreuves mesurées, lu sur
/// les listes **complètes** des domaines — pas sur les cinq lignes que chaque
/// encart montre au plus. Civique : le nombre de thématiques que le diagnostic
/// classe.
String planUnlockLead(PlanUnlockModule module, int priorites) {
  final s = priorites > 1 ? 's' : '';
  if (module == PlanUnlockModule.civique) {
    return 'Vos réponses classent les $priorites thématique$s '
        'officielle$s par urgence.';
  }
  return 'Vos réponses font ressortir $priorites compétence$s '
      'à travailler en priorité.';
}

/// Le sur-titre des encarts d'épreuve (TCF) ou de thème (civique).
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

/* ------------------------------------------- les encarts par épreuve ---- */

/// 🛑 **Au plus cinq lignes par encart — un plafond d'AFFICHAGE, jamais un
/// budget.** Le serveur sert toutes les actions vraies de chaque épreuve ; seul
/// l'écran coupe, et il dit ce qu'il a coupé ([planUnlockAutres]). Le total du
/// sous-titre, lui, porte sur tout ce qui est servi. Miroir web :
/// `PLAN_UNLOCK_MAX_PAR_GROUPE`.
const int kPlanUnlockMaxParGroupe = 5;

/// L'état d'un encart que rien n'a mesuré. 🛑 *null = inconnu, jamais
/// mauvais* : une épreuve (ou un thème) non évalué(e) n'est ni faible ni
/// prioritaire, il n'a simplement pas de liste. L'accord suit le mot : **une**
/// épreuve, **un** thème.
String planUnlockNonEvalue(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique ? 'Non évalué' : 'Non évaluée';

/// La ligne sous le nom d'un encart non évalué — lisible aussi sous 366 px, où
/// la pastille d'état est masquée par le kit.
String planUnlockNonEvalueMeta(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique
        ? 'Pas encore mesuré'
        : 'Pas encore mesurée';

/// Le corps d'un encart non évalué, une fois déplié.
String planUnlockNonEvalueNote(PlanUnlockModule module) =>
    module == PlanUnlockModule.civique
        ? "Ce thème n'a pas encore été mesuré : aucune priorité n'en est tirée."
        : "Cette épreuve n'a pas encore été mesurée : aucune priorité n'en est "
            'tirée.';

/// Un encart mesuré sans aucune action servie.
const String kPlanUnlockGroupeVide = "Aucune priorité pour l'instant";

/// Le mot d'une ligne : une **compétence** TCF, une **unité** officielle
/// civique (le grain de chaque module, D-50).
String _motLigne(PlanUnlockModule module, int n) {
  final mot = module == PlanUnlockModule.civique ? 'unité' : 'compétence';
  return n > 1 ? '${mot}s' : mot;
}

/// « 3 compétences à travailler » — le compte **servi** de l'encart, pas le
/// nombre de lignes montrées.
String planUnlockGroupeMeta(PlanUnlockModule module, int n) {
  if (n == 0) return kPlanUnlockGroupeVide;
  return '$n ${_motLigne(module, n)} à travailler';
}

/// « + 2 autres compétences » sous un encart plafonné. `null` quand rien n'est
/// coupé.
String? planUnlockAutres(PlanUnlockModule module, int n) {
  if (n <= 0) return null;
  return '+ $n ${n > 1 ? 'autres' : 'autre'} ${_motLigne(module, n)}';
}

/// **Le ton de l'urgence d'une épreuve** dans l'en-tête de son encart. Le
/// libellé est [PlanDomainPriority.label], **servi** ; seule la teinte se
/// choisit ici, et le rouge reste à la seule urgence forte. Miroir web :
/// `PLAN_UNLOCK_DOMAIN_TONE`.
SfTone planUnlockDomainTone(PlanDomainPriority priority) => switch (priority) {
      PlanDomainPriority.forte => SfTone.hot,
      PlanDomainPriority.aTravailler => SfTone.warn,
      PlanDomainPriority.entretien => SfTone.ok,
      PlanDomainPriority.pasEncorePrioritaire => SfTone.muted,
      PlanDomainPriority.aEvaluer => SfTone.muted,
    };

/// **Le ton d'une priorité du Plan** sur cet écran (une ligne d'un encart
/// d'épreuve TCF).
///
/// 🛑 **Aucun ton ne se dérive d'un compteur ni d'un rang** : il suit la
/// `nature` **servie**, et il suit la doctrine du Plan — le rouge de fragilité
/// ([SfTone.hot]) est réservé à ce qui a été **observé** fragile, donc une
/// compétence *à acquérir* (rien d'observé) reste `muted`, jamais « à
/// renforcer ». Ce sont le **libellé** et la nature qui les distinguent, pas
/// la seule couleur.
///
/// Miroir web : `PLAN_UNLOCK_NATURE_TONE` (`lib/plan-unlock.ts`).
SfTone planUnlockNatureTone(PlanActionNature nature) => switch (nature) {
      PlanActionNature.aEvaluer => SfTone.muted,
      PlanActionNature.aAcquerir => SfTone.muted,
      PlanActionNature.aRenforcer => SfTone.hot,
      PlanActionNature.aVerifier => SfTone.ok,
    };

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
