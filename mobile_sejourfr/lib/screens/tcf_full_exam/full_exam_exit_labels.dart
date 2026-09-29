/// Sortir d'un examen blanc TCF complet — la règle et ses libellés, déclarés
/// **une seule fois** pour toute l'app.
///
/// > **Une épreuve COMMENCÉE ne se reprend jamais. Une épreuve JAMAIS COMMENCÉE
/// > attend le candidat aussi longtemps qu'il faut.**
///
/// Deux conséquences, appliquées partout de la même façon :
/// - **suspendre** un examen depuis son hub clôture sur-le-champ l'épreuve
///   commencée (s'il y en a une) et **épargne** celles qui n'ont jamais été
///   ouvertes — l'examen reste « en cours », sans résultat, indéfiniment
///   reprenable ;
/// - **quitter une épreuve** en cours la clôture aussi, avec ce qui a déjà été
///   fait.
///
/// Aucun de ces gestes ne finalise l'examen ni n'ouvre le bilan : **il n'y a pas
/// de résultat tant que les 4 épreuves ne sont pas terminées.**
///
/// Miroir mot pour mot du web : `web_sejoufr/lib/full-exam-exit.ts`.
library;

import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';

/// Les épreuves que « suspendre » va clôturer : [FullTcfExamSubAttempt.commencee]
/// et pas encore terminées. Les autres ne sont **jamais** touchées par un geste
/// de sortie.
///
/// En pratique il y en a au plus une (le hub ne laisse démarrer que l'épreuve
/// courante), mais rien n'oblige le serveur à le garantir : on raisonne en
/// liste.
List<FullTcfExamSubAttempt> epreuvesAClore(FullTcfExamResponse exam) => exam
    .subAttempts
    .where((sa) => sa.finishedAt == null && sa.commencee)
    .toList(growable: false);

/// Le nom d'une épreuve **avec son article**, pour l'insérer dans une phrase.
/// Épreuve inconnue ⇒ « cette épreuve » : on ne devine jamais un nom.
String epreuveAvecArticle(EpreuveType? epreuve) => switch (epreuve) {
      EpreuveType.tcfCo => 'la compréhension orale',
      EpreuveType.tcfCe => 'la compréhension écrite',
      EpreuveType.tcfEe => 'l\'expression écrite',
      EpreuveType.tcfEo => 'l\'expression orale',
      _ => 'cette épreuve',
    };

String _capitalize(String phrase) =>
    phrase.isEmpty ? phrase : phrase[0].toUpperCase() + phrase.substring(1);

/// « la compréhension orale et l'expression écrite ».
String _enumerer(List<String> phrases) {
  if (phrases.isEmpty) return '';
  if (phrases.length == 1) return phrases.first;
  return '${phrases.sublist(0, phrases.length - 1).join(', ')} '
      'et ${phrases.last}';
}

// ---------------------------------------------------------------------------
// Suspendre l'examen (hub de progression)
// ---------------------------------------------------------------------------

const String kFullExamSuspendTitle = 'Suspendre l\'examen ?';
const String kFullExamSuspendConfirm = 'Suspendre et reprendre plus tard';
const String kFullExamSuspendCancel = 'Continuer l\'examen';

/// Ce que la suspension va coûter, **épreuve par épreuve**, dit avant l'action.
///
/// Sans épreuve commencée, il n'y a rien à perdre : on ne fait pas peur pour
/// rien.
String fullExamSuspendMessage(List<FullTcfExamSubAttempt> aClore) {
  if (aClore.isEmpty) {
    return 'Votre progression est conservée : aucune épreuve n\'est commencée, '
        'et vous reprendrez cet examen là où vous en êtes.';
  }
  final noms =
      _enumerer(aClore.map((sa) => epreuveAvecArticle(sa.epreuve)).toList());
  final suite = aClore.length == 1
      ? '${_capitalize(noms)} est déjà commencée : elle sera clôturée '
          'maintenant, avec ce que vous avez déjà fait, et ne pourra plus être '
          'reprise.'
      : '${_capitalize(noms)} sont déjà commencées : elles seront clôturées '
          'maintenant, avec ce que vous avez déjà fait, et ne pourront plus '
          'être reprises.';
  return 'Vous reprendrez aux épreuves que vous n\'avez pas encore commencées. '
      '$suite';
}

// ---------------------------------------------------------------------------
// Quitter une épreuve en cours (runner CO/CE, sessions EE/EO)
// ---------------------------------------------------------------------------

const String kEpreuveExitTitle = 'Quitter cette épreuve ?';
const String kEpreuveExitConfirm = 'Quitter et clôturer l\'épreuve';
const String kEpreuveExitCancel = 'Continuer l\'épreuve';

/// [perteEnregistrement] : l'oral seulement — une capture en cours n'est jamais
/// envoyée, et le taire serait mentir.
String epreuveExitMessage(
  EpreuveType? epreuve, {
  bool perteEnregistrement = false,
}) {
  final perte =
      perteEnregistrement ? ' Votre enregistrement en cours sera perdu.' : '';
  return '${_capitalize(epreuveAvecArticle(epreuve))} sera clôturée maintenant, '
      'avec ce que vous avez déjà fait, et ne pourra plus être reprise.$perte '
      'Les épreuves suivantes, elles, vous attendent.';
}
