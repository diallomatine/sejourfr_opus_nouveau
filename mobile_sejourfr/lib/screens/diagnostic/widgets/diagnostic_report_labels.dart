/// **Les phrases du résultat du diagnostic rapide.**
///
/// Le serveur sert des **faits** — un niveau estimé, un paragraphe d'analyse,
/// des points forts, des priorités. Les titres de section, les kickers et les
/// phrases de mise en perspective vivent ici : une chaîne posée au milieu d'un
/// `Text` est exactement la façon dont les deux fronts ont déjà divergé.
///
/// ⚠️ **Vouvoiement.** La maquette tutoie, mais elle ne donne que la direction
/// **visuelle**. Le registre reste celui de l'application.
///
/// 🛑 Les libellés en **capitales** sont écrits ici en casse normale et mis en
/// majuscules **à l'affichage** : côté web c'est le CSS qui s'en charge, et
/// deux casses différentes ne seraient plus des miroirs.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';

/* ------------------------------------------------------------- l'en-tête */

/// 🛑 « Votre estimation », pas « Votre niveau TCF » : le diagnostic rapide
/// n'observe qu'une production écrite.
const String kDiagnosticReportTitle = 'Votre estimation';
const String kDiagnosticReportKicker = 'Diagnostic rapide terminé';

/* ---------------------------------------------------------- la carte hero */

/// 🛑 **Wording imposé** : « Niveau estimé **sur cet exercice** », jamais
/// « votre niveau TCF ». Trois épreuves sur quatre n'ont pas été mesurées.
const String kDiagnosticLevelEyebrow = 'Niveau estimé sur cet exercice';

/// La ligne d'objectif de la carte hero. Le palier est **servi** (la démarche
/// déclarée) : sans lui, la ligne n'est pas rendue.
const String kDiagnosticGoalPrefix = 'Votre objectif : ';

/// La production a été rendue, mais le serveur n'a rien pu y observer
/// (`ProductionEvaluabilite.nonEvaluable`, ou aucun niveau estimé).
///
/// 🛑 On n'affiche alors **ni A1, ni 0** : l'état est nommé.
const String kDiagnosticIncompleteTag = 'Évaluation incomplète';

/// 🛑 **Aucun reproche** : on décrit ce qui manque à la machine, jamais ce qui
/// manquerait au candidat.
const String kDiagnosticIncompleteText =
    'Nous n\'avons pas reçu suffisamment de contenu pour estimer votre niveau. '
    'Une nouvelle production de deux minutes suffit.';

/* --------------------------------------------- ce que nous avons observé */

const String kDiagnosticObserveTitle = 'Ce que nous avons observé';
const String kDiagnosticObservePositive = 'Positive';
const String kDiagnosticObserveAmeliorer = 'À améliorer';

/// Plafond d'affichage : deux points à améliorer, pas une liste. C'est la
/// seule chose que le candidat retient d'un rapport qu'il lit une fois.
const int kDiagnosticObserveMaxAmeliorer = 2;

/// Plafond d'affichage du point fort. Le serveur en sert jusqu'à trois.
const int kDiagnosticObserveMaxPositive = 1;

typedef DiagnosticObservation = ({
  bool positive,
  String kicker,
  String titre,
  String? texte,
});

/// Les observations, dans l'ordre de la maquette : les positives d'abord.
///
/// 🛑 **Rien n'est dérivé.** [strengths] sont les points forts que le serveur a
/// rédigés (des phrases nues : elles font le titre, il n'y a pas de second
/// niveau de texte) ; [priorites] sont les priorités qu'il a **classées**. Le
/// front choisit dans des listes servies, il ne juge pas — et il n'invente
/// jamais une ligne pour remplir le bloc.
List<DiagnosticObservation> diagnosticObservations(
  List<String> strengths,
  List<DiagnosticSkillObservation> priorites,
) =>
    <DiagnosticObservation>[
      for (final force in strengths.take(kDiagnosticObserveMaxPositive))
        (
          positive: true,
          kicker: kDiagnosticObservePositive,
          titre: force,
          texte: null,
        ),
      for (final p in priorites.take(kDiagnosticObserveMaxAmeliorer))
        (
          positive: false,
          kicker: kDiagnosticObserveAmeliorer,
          titre: p.skillTitle,
          texte: p.explanation,
        ),
    ];

/* ------------------------------------------------------- la mise au point */

/// 🛑 **Le bloc de transition n'est pas décoratif, c'est une obligation
/// d'honnêteté.** Le diagnostic rapide n'observe qu'une production ÉCRITE :
/// annoncer un palier sans dire de quoi il est tiré laisserait le candidat
/// croire qu'il connaît son niveau TCF.
const String kDiagnosticTransitionTitle =
    'Ce n\'est qu\'une première estimation';
const String kDiagnosticTransitionText =
    'Cet exercice analyse votre manière de vous exprimer à l\'écrit. '
    'Au TCF, votre niveau dépend aussi de votre expression orale, de votre '
    'compréhension orale et de votre compréhension écrite.';
const String kDiagnosticTransitionEmphasis =
    'Votre niveau peut donc être différent selon les épreuves.';

/* ------------------------------------------------- le diagnostic complet */

const String kDiagnosticCompletTitle =
    'Découvrez où vous en êtes vraiment au TCF';

/// Les quatre épreuves du diagnostic complet, dans l'ordre de la maquette.
/// Aucun niveau n'y figure : elles ne sont pas encore mesurées.
const List<({IconData icon, String label})> kDiagnosticCompletEpreuves = [
  (icon: LucideIcons.headphones, label: 'Compréhension orale'),
  (icon: LucideIcons.bookOpen, label: 'Compréhension écrite'),
  (icon: LucideIcons.penLine, label: 'Expression écrite'),
  (icon: LucideIcons.mic, label: 'Expression orale'),
];

const String kDiagnosticCompletPromise = 'À la fin, vous connaîtrez :';
const List<String> kDiagnosticCompletBenefits = [
  'votre niveau par épreuve',
  'les tâches qui vous limitent actuellement',
  'vos priorités pour atteindre votre objectif',
];
const String kDiagnosticCompletCta = 'Faire mon diagnostic complet';

/// 🛑 « en plusieurs fois » est la moitié qui fait accepter les 75 minutes.
/// ⚠️ Et jamais le mot « examen blanc » de la maquette : le diagnostic TCF
/// n'en est pas un.
const String kDiagnosticCompletNote =
    '4 épreuves · environ 75 min · vous pouvez le faire en plusieurs fois';
