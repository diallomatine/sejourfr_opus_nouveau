import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import 'criteria_overview.dart';
import 'evaluation_notice.dart';
import 'production_action_plan.dart';
import 'production_text_card.dart';
import 'results_hero.dart';
import 'results_summary_tiles.dart';
import 'results_section_head.dart';
import 'target_level_reached_card.dart';

/// Limite de l'evaluation orale, mot pour mot (cf. `docs/notation-ia-eo-ee.md`
/// §9). Le correcteur la renvoie normalement dans ses `avertissements` ; ce
/// texte est le REPLI quand la liste arrive vide sur une tache orale — le
/// candidat doit savoir dans tous les cas que sa voix n'a pas ete ecoutee.
const String kOralEvaluationLimitNotice =
    'Cette évaluation est fondée sur la transcription écrite de votre '
    'production : nous n\'analysons pas votre voix. L\'aisance, la fluidité, '
    'le débit et la prononciation ne sont donc pas évalués ici — c\'est une '
    'limite technique de notre correction, pas un choix pédagogique. '
    'À l\'examen officiel, ces dimensions comptent.';

/// Corps commun des ecrans de resultats EE et EO : meme correction, meme ordre,
/// un seul endroit a faire evoluer.
///
/// **Le contenu etait juste, sa restitution etait illisible** : le candidat
/// traversait un bandeau « Évaluation terminée », une carte objectif, une carte
/// note, deux blocs de puces et trois paragraphes d'explication avant le
/// premier conseil. Personne ne lit ca. La refonte ne retire aucune
/// information : elle **fusionne ce qui dit la meme chose** et **replie ce qui
/// se consulte** au lieu de se lire.
///
/// Quatre sections, dans cet ordre :
/// 1. **le verdict et le niveau** — un seul hero ([ProductionResultsHero]).
///    Pas de note : sur une tache isolee, le /20 n'existe pas au TCF (cf. le
///    widget) ;
/// 2. **ce qui marche / a corriger en priorite** ([ResultsSummaryTiles]) : deux
///    bandeaux pleine largeur, replies, qui ouvrent leur detail en dessous — la
///    check-list de la consigne (points traites puis oublies) et les points
///    forts d'un cote, la priorite complete (avec sa technique et sa
///    reecriture) de l'autre ;
/// 3. **le profil par critere** ([CriteriaOverview]), une carte par critere,
///    depliable — il vivait dans le repli, donc personne ne le voyait ;
/// 4. **la production** ([ProductionTextCard]), puis **le seul texte modele de
///    l'ecran** ([ProductionActionPlan] : les leviers, une version plus aboutie
///    — ou, a l'oral, des passages redits — et la tournure a retenir) ; ou,
///    quand le palier vise est deja tenu, [TargetLevelReachedCard] qui
///    l'annonce a sa place.
///
/// ⚠️ **« Voir l'analyse complète » n'existe plus (contrat v15/v9)** : le
/// correcteur ne produit plus `exemples_corriges` ni `suggestions`, et ce repli
/// ne restait ouvert par personne. Les deux champs restent **decodes** dans
/// `production_models.dart` (une centaine d'evaluations en base les portent),
/// aucun ecran candidat ne les lit. Ce qui vivait avec eux dans le repli :
/// - **les avertissements**, ecrits par le SERVEUR (limite de l'oral, purges
///   automatiques) : remontes en note discrete sous le hero
///   ([EvaluationNotice]) — ils ne dependent d'aucun champ du LLM ;
/// - **le detail de l'accomplissement** : le bandeau « Ce qui marche » de
///   [ResultsSummaryTiles] montrait deja les points **traites** ; il montre
///   desormais aussi les points **oublies**, faute de quoi le candidat lisait
///   « 2/3 points traités » sans jamais savoir lequel manquait. Les pistes non
///   abordees, qui ne coutent aucun point, ne sont plus rendues.
///
/// ⚠️ **`version_amelioree` n'est plus affichee nulle part (2026-08-08)** :
/// elle reecrivait la production au niveau **deja constate**, en bascule juste
/// sous la redaction — donc le texte le plus visible et le plus copiable de
/// l'ecran etait celui qui ne fait pas progresser (mesure : recopie puis
/// resoumis, meme note, meme niveau). Le champ reste servi par l'API et decode
/// dans `production_models.dart`, aucun widget ne le lit.
///
/// Chaque bloc est optionnel : une evaluation ancienne n'expose ni objectif, ni
/// niveau, ni accomplissement — les blocs concernes disparaissent et l'ecran
/// reste coherent.
class EvaluationReport extends StatelessWidget {
  const EvaluationReport({
    super.key,
    required this.evaluation,
    required this.isOral,
    this.eyebrow,
    this.productionText,
    this.targetLevel,
  });

  final EvaluationResult evaluation;

  /// Tache orale : la limite de l'evaluation orale s'applique (cf.
  /// [kOralEvaluationLimitNotice]) et aucun texte modele n'est attendu.
  final bool isOral;

  /// Situe la correction en tete du hero (« Expression écrite · Tâche 1 »).
  final String? eyebrow;

  /// Le texte rendu par le candidat. Fourni en expression ECRITE. A l'oral, la
  /// transcription vit dans sa propre feuille (dialogue en bulles) : ce
  /// parametre reste nul.
  final String? productionText;

  /// Palier vise par la demarche du candidat, pour le rappel d'enjeu du hero.
  /// `null` = inconnu → aucun rappel n'est affiche.
  final TargetLevel? targetLevel;

  /// Une tache orale porte toujours la limite de l'oral, meme si le correcteur
  /// a rendu une liste vide.
  List<String> get _avertissements {
    final fromAi = evaluation.feedback.avertissements;
    if (fromAi.isNotEmpty) return fromAi;
    return isOral ? const [kOralEvaluationLimitNotice] : const [];
  }

  @override
  Widget build(BuildContext context) {
    final feedback = evaluation.feedback;
    final priorites = feedback.pointsAAmeliorer;
    final accomplissement = feedback.accomplissement;

    final production = productionText;
    // Le plan d'action est servi a l'ecrit COMME a l'oral depuis le contrat
    // v2 : ce qui change, c'est sa forme (version plus aboutie vs
    // reformulations), et c'est le bloc lui-meme qui la porte — pas un `isOral`
    // recopie ici.
    final versionCiblee = feedback.versionCiblee;
    // Exclusif du precedent, et servi par le SERVEUR : un front ne saurait pas
    // distinguer « objectif atteint » d'un second appel LLM en echec.
    final niveauViseAtteint =
        versionCiblee != null ? null : feedback.niveauViseAtteint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductionResultsHero(
          evaluation: evaluation,
          eyebrow: eyebrow,
          targetLevel: targetLevel,
        ),
        // Ecrit par le SERVEUR, pas par le correcteur : la limite de l'oral et
        // les purges automatiques se lisent juste sous le verdict, en note.
        EvaluationNotice(avertissements: _avertissements),
        ResultsSummaryTiles(
          accomplissement: accomplissement,
          priorites: priorites,
          pointsForts: feedback.pointsForts,
        ),
        CriteriaOverview(criteres: feedback.scoresCriteres),
        if (production != null && production.isNotEmpty) ...[
          const ResultsSectionHead(title: 'Votre rédaction'),
          const SizedBox(height: 8),
          ProductionTextCard(
            texte: production,
            // La phrase visee par la priorite n° 1, surlignee dans le texte.
            highlight: priorites.isEmpty ? null : priorites.first.exemple?.avant,
          ),
        ],
        // Le plan d'action, juste sous la redaction : l'ordre de lecture est
        // « ce que j'ai produit » → « ce qu'il faut viser, et a quoi ca
        // ressemble ». Absent (eval anterieure, second appel en echec, oral
        // degrade) ⇒ rien n'est rendu, et le rapport se termine sur la
        // production : ni section vide, ni titre orphelin.
        ProductionActionPlan(version: versionCiblee),
        // Meme emplacement, cas exclusif : le palier vise est DEJA tenu. On
        // l'annonce au lieu de laisser un trou — le candidat qui reussit avait
        // un rapport plus vide que celui qui echoue.
        TargetLevelReachedCard(atteint: niveauViseAtteint),
      ],
    );
  }
}
