/// **Les phrases du rapport de diagnostic.**
///
/// L'écran lit son bilan **épreuve par épreuve** : un niveau estimé, la phrase
/// qui l'explique, puis les compétences qui l'ont produit. Le serveur ne sert
/// **aucune** de ces phrases — il sert des faits (un niveau, des compteurs, un
/// palier qui bloque). Elles vivent donc ici plutôt que dans les widgets : une
/// chaîne posée au milieu d'un `Text` est exactement la façon dont les deux
/// fronts ont déjà divergé.
///
/// ⚠️ **Vouvoiement.** La maquette du propriétaire tutoie, mais elle ne donne
/// que la direction **visuelle** — structure, ordre des blocs, densité, ce
/// qu'on retire. Le registre, lui, reste celui de l'application : le rapport et
/// le Plan vouvoient, seul le module « Compétences » tutoie (arbitrage du
/// 2026-08-21).
///
/// 🛑 Les libellés en **capitales** sont écrits ici en casse normale et mis en
/// majuscules **à l'affichage** (`toUpperCase()`) : côté web c'est le CSS qui
/// s'en charge, et deux casses différentes ne seraient plus des miroirs.
library;

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../plan/plan_labels.dart';

/* ------------------------------------------------------------- l'en-tête */

/// Titre de l'en-tête d'écran une fois le rapport rendu.
///
/// ⚠️ C'est **« Diagnostic »**, pas « Votre rapport » : la référence de cet
/// écran est le bilan **in-app** d'un candidat connecté, et non le rapport du
/// **visiteur**. La confusion entre les deux maquettes est ce qui avait fait
/// dériver l'écran.
const String kDiagnosticReportTitle = 'Diagnostic';
const String kDiagnosticReportSubPremium = 'Rapport complet';
const String kDiagnosticReportSubFree = 'Estimation d\'entraînement Séjour';

/* ------------------------------------------------------ le résumé global */

const String kDiagnosticLevelEyebrow = 'Niveau estimé';
const String kDiagnosticLevelObjective = 'Objectif';
const String kDiagnosticLevelObjectiveUnknown = 'à définir';

/// Les quatre épreuves **dans l'ordre de lecture du rapport** : ce qu'on vient
/// de produire d'abord (l'écrit puis l'oral), ce qui se mesure ensuite.
///
/// 🛑 Ordre **figé**, identique au web : c'est une décision de lecture, pas
/// l'ordre d'urgence du Plan (`domaines`, trié serveur), qu'on ne rejoue jamais
/// ici.
const List<EpreuveType> kDiagnosticEpreuveOrder = <EpreuveType>[
  EpreuveType.tcfEe,
  EpreuveType.tcfEo,
  EpreuveType.tcfCe,
  EpreuveType.tcfCo,
];

const String kDiagnosticProfileComplete = 'Diagnostic complet';

/// « 2 / 4 épreuves évaluées ». Le dénominateur vient du serveur
/// (`cycle.domainsExpected`) : on ne l'écrit jamais en dur.
String diagnosticEvaluatedCount(int done, int total) =>
    '$done / $total épreuve${total > 1 ? 's' : ''} '
    'évaluée${total > 1 ? 's' : ''}';

/// Ce que vaut une estimation partielle — dite sans reproche : les épreuves
/// manquantes ne sont pas ratées, elles ne sont pas mesurées.
String diagnosticPartialText(int done, int total) =>
    'Estimation basée sur $done épreuve${done > 1 ? 's' : ''} sur $total. '
    'Elle se précisera dès que les autres seront évaluées.';

/* --------------------------------------------------------- mes épreuves */

const String kDiagnosticEpreuvesTitle = 'Mes 4 épreuves';
const String kDiagnosticEpreuvesSub =
    'Votre niveau épreuve par épreuve, et les compétences qui l\'expliquent';

/// La pastille d'une épreuve **jamais mesurée**.
///
/// ⚠️ Elle porte volontairement le **même mot** que `PlanDomainPriority
/// .aEvaluer` et `PlanActionNature.aEvaluer` : les trois disent la même chose,
/// elles ne s'affichent simplement pas au même endroit. Ce n'est pas une
/// collision à « réparer ».
const String kDiagnosticToAssessTag = 'À évaluer';

/// La pastille d'une production **rendue mais inexploitable** — le serveur n'en
/// a tiré aucun niveau (`ProductionEvaluabilite.nonEvaluable`).
const String kDiagnosticIncompleteTag = 'Évaluation incomplète';

String diagnosticToAssessText(EpreuveType epreuve) =>
    'Cette épreuve n\'a pas encore été évaluée : aucun niveau n\'est estimé en '
    '${planDomainLabel(epreuve).toLowerCase()}.';

/// 🛑 **Aucun reproche** : on décrit ce qui manque à la machine, jamais ce qui
/// manquerait au candidat.
const String kDiagnosticIncompleteText =
    'Nous n\'avons pas reçu suffisamment de contenu pour estimer votre niveau. '
    'Une nouvelle production de deux minutes suffit.';

/// « mon expression écrite » / « ma compréhension orale ». Le français ne
/// s'accorde pas sur le domaine mais sur son nom : *expression* est féminin
/// mais commence par une voyelle, donc « mon ».
String _diagnosticPossessive(EpreuveType epreuve) =>
    epreuve.isProduction ? 'mon' : 'ma';

String diagnosticAssessCta(EpreuveType epreuve) =>
    'Évaluer ${_diagnosticPossessive(epreuve)} '
    '${planDomainLabel(epreuve).toLowerCase()}';

/// Uniquement pour une **production** (EE/EO) : elle seule peut être rendue
/// sans être exploitable. Les deux libellés commencent par une voyelle, donc
/// l'élision est toujours correcte.
String diagnosticRedoCta(EpreuveType epreuve) =>
    'Refaire l\'${planDomainLabel(epreuve).toLowerCase()}';

const String kDiagnosticEstimatedLabel = 'Estimé';

/// « Objectif B2 · prochain palier B1 ». L'objectif est **nullable** — il vient
/// de la démarche déclarée, et on n'en invente aucun.
String diagnosticEpreuveMeta(String? objective, TargetLevel? next) {
  final target = objective ?? kDiagnosticLevelObjectiveUnknown;
  if (next == null) return '$kDiagnosticLevelObjective $target';
  return '$kDiagnosticLevelObjective $target · prochain palier ${next.wire}';
}

/* ------------------------------------------------ ce qu'explique le niveau */

/// **La phrase qui explique un niveau, épreuve par épreuve.**
///
/// Une par couple (épreuve × palier). Elle dit ce que le niveau **veut dire**
/// et ce qui sépare de la marche suivante — jamais un jugement sur la personne,
/// jamais un mot de manque quand rien n'a été observé.
///
/// `null` = aucun niveau mesuré ⇒ **aucune phrase**. C1/C2 (historique) se
/// lisent comme B2 : le contrat en vigueur s'arrête là.
String? diagnosticEpreuveResume(EpreuveType epreuve, NiveauCecrl? level) {
  if (level == null) return null;
  final palier = switch (level) {
    NiveauCecrl.c1 || NiveauCecrl.c2 => NiveauCecrl.b2,
    _ => level,
  };
  return _kDiagnosticResume[epreuve]?[palier];
}

const Map<EpreuveType, Map<NiveauCecrl, String>> _kDiagnosticResume =
    <EpreuveType, Map<NiveauCecrl, String>>{
  EpreuveType.tcfEe: <NiveauCecrl, String>{
    NiveauCecrl.a1NonAtteint:
        'Votre texte reste très court : les compétences attendues au A2 sont '
            'encore à construire.',
    NiveauCecrl.a1:
        'Vous écrivez des phrases simples ; les compétences attendues au A2 '
            'restent à installer.',
    NiveauCecrl.a2:
        'Vos productions sont compréhensibles, mais certaines compétences '
            'attendues au B1 restent à consolider.',
    NiveauCecrl.b1:
        'Vos textes tiennent le B1. Ce qui manque pour le B2 : des arguments '
            'développés et nuancés.',
    NiveauCecrl.b2:
        'Vos productions atteignent le niveau attendu : il s\'agit maintenant '
            'de le conserver.',
  },
  EpreuveType.tcfEo: <NiveauCecrl, String>{
    NiveauCecrl.a1NonAtteint:
        'Votre enregistrement reste très bref : les compétences attendues au '
            'A2 sont encore à construire.',
    NiveauCecrl.a1:
        'Vous répondez par des phrases courtes ; les compétences attendues au '
            'A2 restent à installer.',
    NiveauCecrl.a2:
        'Vous répondez aux questions simples, mais plusieurs compétences '
            'nécessaires au B1 restent fragiles.',
    NiveauCecrl.b1:
        'Vous tenez l\'échange. Défendre un avis développé est ce qui vous '
            'sépare du B2.',
    NiveauCecrl.b2: 'Votre discours est structuré et tenu dans la durée.',
  },
  EpreuveType.tcfCo: <NiveauCecrl, String>{
    NiveauCecrl.a1NonAtteint:
        'Les messages les plus simples ne sont pas encore repérés : c\'est le '
            'A2 qui se construit d\'abord.',
    NiveauCecrl.a1:
        'Vous saisissez quelques mots-clés ; comprendre un message simple en '
            'entier reste à travailler.',
    NiveauCecrl.a2:
        'Vous comprenez les messages simples et directs ; une situation B1 sur '
            'deux reste difficile.',
    NiveauCecrl.b1:
        'Votre B1 est stable : les documents B2 deviennent la prochaine '
            'marche.',
    NiveauCecrl.b2:
        'Vos résultats sont réguliers, y compris sur les documents longs.',
  },
  EpreuveType.tcfCe: <NiveauCecrl, String>{
    NiveauCecrl.a1NonAtteint:
        'Les documents les plus simples ne sont pas encore décodés : c\'est le '
            'A2 qui se construit d\'abord.',
    NiveauCecrl.a1:
        'Vous repérez quelques mots ; lire un document simple en entier reste '
            'à travailler.',
    NiveauCecrl.a2:
        'Vous repérez les informations explicites ; l\'implicite vous échappe '
            'encore souvent.',
    NiveauCecrl.b1:
        'Votre B1 est presque stabilisé : quelques documents B2 sont déjà '
            'réussis.',
    NiveauCecrl.b2:
        'Votre domaine le plus stable : rien à consolider en priorité.',
  },
};

/// **Sur quoi ce niveau repose**, en une phrase de faits servis — jamais une
/// interprétation.
///
/// - **Expression** : combien de compétences ont été observées sur combien, et
///   comment elles se répartissent. Le détail par statut n'existe que sur cet
///   écran, d'où une phrase à lui.
/// - **Compréhension** : le palier consolidé et celui qui bloque. C'est
///   exactement ce que dit déjà [planDomainSummary], qu'on **appelle** au lieu
///   d'en écrire une seconde copie.
///
/// `null` ⇒ l'encart n'existe pas. Rien n'est deviné pour le remplir.
String? diagnosticEpreuveExplanation(
  PlanDomain domain, {
  required int observed,
  required int fragile,
  required int solid,
}) {
  if (!domain.evaluated) return null;
  if (domain.paliers.isNotEmpty) return planDomainSummary(domain);

  final total = domain.skills.length;
  if (total == 0 || observed == 0) return null;

  final tasks = domain.taches.length;
  final scope = tasks == 0
      ? ''
      : ', réparties sur $tasks tâche${tasks > 1 ? 's' : ''}';
  final detail = <String>[
    if (fragile > 0) '$fragile à travailler',
    if (solid > 0) '$solid déjà solide${solid > 1 ? 's' : ''}',
  ].join(' et ');

  final head = '$observed compétence${observed > 1 ? 's' : ''} '
      'observée${observed > 1 ? 's' : ''} sur $total$scope';
  return detail.isEmpty ? '$head.' : '$head : $detail.';
}

/* ---------------------------------------------------------- les groupes */

/// Les quatre familles d'une carte d'épreuve.
///
/// ⚠️ « À renforcer » et « À acquérir » portent **volontairement** les libellés
/// gelés de `PlanActionNature` : quand les deux s'appliquent, ils disent la
/// même chose. Ce sont ici des **titres de groupe**, décidés par le `status`
/// (et par la `nature` pour l'acquisition), pas des pilules.
///
/// 🛑 « À acquérir » ne se dit **jamais** « à renforcer » : renforcer suppose un
/// constat négatif, et sur une compétence jamais travaillée il n'y en a aucun.
const String kDiagnosticGroupPriority = 'Priorité';
const String kDiagnosticGroupReinforce = 'À renforcer';
const String kDiagnosticGroupAcquire = 'À acquérir';
const String kDiagnosticGroupSolid = 'Déjà solide';

/// Ce que « À acquérir » veut dire, dit une fois par carte. Aucun mot de
/// manque : rien n'a été observé, donc rien n'a échoué.
String diagnosticAcquireNote(TargetLevel? level) => level == null
    ? 'Compétences que votre plan va commencer à enseigner.'
    : 'Compétences du palier ${level.wire} que votre plan va commencer à '
        'enseigner.';

/// Les titres de la vue **repliée** (ou d'un compte sans accès), où les trois
/// familles ne sont pas séparées.
const String kDiagnosticGroupWork = 'Priorités';
const String kDiagnosticGroupMainWork = 'Priorité principale';
const String kDiagnosticGroupFirstWork = 'À travailler en premier';

/// « 1 sur 6 » — ce qu'un compte sans accès voit sur ce qui a été détecté.
///
/// 🛑 Les **deux** nombres sont vrais : ce que la carte montre réellement, sur
/// ce que le serveur a servi. Miroir de `freeCounter` côté web.
String diagnosticFreeWorkCount(int visible, int total) => '$visible sur $total';

String diagnosticMoreToWork(int hidden) =>
    '+ $hidden autre${hidden > 1 ? 's' : ''} '
    'compétence${hidden > 1 ? 's' : ''} à travailler';

/// Le repère d'une compétence, **sous son titre** : la tâche en expression, le
/// palier en compréhension. Rien quand ni l'un ni l'autre n'est servi — on
/// n'invente pas de rattachement.
String diagnosticSkillSubtitle(PlanDomainSkill skill) {
  final tache = skill.tacheNumero;
  if (tache != null) return 'Tâche $tache';
  final level = skill.targetLevel;
  if (level != null) return 'Palier ${level.wire}';
  return skill.skillCode;
}

/// « {n} compétences : pas encore assez de données pour se prononcer. »
///
/// 🛑 *Non observée n'est pas faible* : c'est une absence de mesure, et la
/// phrase ne doit jamais se lire comme un reproche.
String diagnosticNotObserved(int count) =>
    '$count compétence${count > 1 ? 's' : ''} : pas encore assez de données '
    'pour se prononcer.';

/* ------------------------------------------------------------ le verrou */

/// Le compte **exact** de ce que le rideau cache, sur une épreuve.
///
/// 🛑 Il se lit sur `PlanDomain.fragileSkillCount` / `.solidSkillCount`, servis
/// par le serveur, jamais sur la longueur d'une liste tronquée à l'affichage.
/// Les deux à zéro ⇒ `null` ⇒ **le bloc n'existe pas**.
String? diagnosticHiddenCount({required int work, required int solid}) {
  final parts = <String>[
    if (work > 0)
      '+ $work compétence${work > 1 ? 's' : ''} '
          'détectée${work > 1 ? 's' : ''}',
    if (solid > 0) '$solid déjà solide${solid > 1 ? 's' : ''}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Le repli du titre flouté quand le serveur n'a plus de ligne à laisser
/// deviner. Jamais une compétence inventée : une formule qui n'affirme rien.
const String kDiagnosticLockedFallback = 'Compétence détectée';

/// Le mot du verrou, dans la ligne même du bloc flouté.
const String kDiagnosticUnlockShort = 'Débloquer';

/* ----------------------------------------------------------- les actions */

const String kDiagnosticWorkPrioritiesCta = 'Travailler mes priorités';

String diagnosticWorkDomainCta(EpreuveType epreuve) =>
    'Travailler la ${planDomainLabel(epreuve).toLowerCase()}';

const String kDiagnosticExpand = 'Voir le détail de l\'épreuve';
const String kDiagnosticCollapse = 'Réduire';

/* ------------------------------------------------------- prochaine étape */

const String kDiagnosticNextStepTitle = 'Prochaine étape';

String diagnosticNextStepText(String? objective) => objective == null
    ? 'Votre plan traite ces priorités une par une, dans l\'ordre qui vous '
        'fait progresser le plus vite.'
    : 'Votre plan traite ces priorités une par une, dans l\'ordre qui vous '
        'fait progresser le plus vite vers le $objective.';

const String kDiagnosticAllSkillsCta = 'Voir toutes mes compétences';

/* --------------------------------------------------------------- l'offre */

/// Le titre de la carte d'offre. ⚠️ Distinct de celui du Plan : ici on ferme un
/// rapport, là-bas on ouvre un écran.
const String kDiagnosticUnlockTitle = 'Votre analyse complète est prête';

String diagnosticUnlockText(String? objective) => objective == null
    ? 'Découvrez toutes vos priorités, tous vos points forts et votre plan '
        'personnalisé pour progresser.'
    : 'Découvrez toutes vos priorités, tous vos points forts et votre plan '
        'personnalisé pour progresser vers le $objective.';

/// Ce que l'abonnement ouvre, dit du point de vue du candidat qui vient de lire
/// son diagnostic.
///
/// 🛑 **Le premier argument porte un VRAI nombre**, celui que le serveur a
/// réellement compté sur les quatre épreuves — jamais une constante de
/// maquette. À zéro, il n'est pas rendu : on ne vend pas un compte vide.
///
/// ⚠️ Liste **distincte** de celle du Plan : elle ne vend pas le catalogue,
/// elle nomme la suite de CE rapport.
List<String> diagnosticUnlockBenefits(int detected) => <String>[
      if (detected > 0)
        'Les $detected compétence${detected > 1 ? 's' : ''} à travailler '
            'détectée${detected > 1 ? 's' : ''} sur vos épreuves',
      'Toutes vos compétences déjà solides',
      'Votre plan et vos entraînements ciblés',
    ];

const String kDiagnosticUnlockCta = 'Débloquer mon diagnostic complet';

/* ----------------------------------------------------------- la mention */

/// La seule phrase de l'écran qui dise ce que vaut l'estimation.
const String kDiagnosticEstimationNote =
    'Votre niveau est une estimation d\'entraînement Séjour, pas un score '
    'officiel du TCF.';
