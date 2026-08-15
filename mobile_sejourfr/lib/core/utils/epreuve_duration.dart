import '../models/enums.dart';

/// **Miroir mobile de `DureeEpreuve` (backend).** Une épreuve a la même durée
/// où qu'elle soit jouée — examen blanc d'épreuve isolé comme sous-épreuve d'un
/// examen blanc TCF complet. La compréhension écrite valait 35 min en
/// standalone et 30 min dans l'examen complet (raccourcie pour tenir dans une
/// enveloppe globale de 90 min, qui **n'existe plus**) : les fronts en avaient
/// recopié deux valeurs différentes.
///
/// 🛑 **Ces valeurs ne se recopient nulle part ailleurs dans l'app.** Dès que la
/// donnée serveur est disponible sur l'écran (`FullTcfExamSubAttempt
/// .timeLimitSeconds`, `Attempt.timeLimitSeconds`), c'est **elle** qui fait foi
/// et cette table ne sert plus. Elle n'existe que pour les écrans de catalogue
/// et de briefing, qui annoncent une durée **avant** qu'aucune session n'ait été
/// créée : aucun endpoint ne la publie à ce moment-là.
///
/// **L'expression orale n'a volontairement pas de durée d'épreuve** (`null`) :
/// au TCF le temps se compte **par tâche**, et il ne démarre qu'au moment où le
/// candidat lance la tâche (« Je suis prêt »). La borne est alors
/// `ProductionTaskDto.dureeMaxSec` (180 / 210 / 210 s), pas un compte à rebours
/// global.
const Map<EpreuveType, int?> kEpreuveDurationSeconds = <EpreuveType, int?>{
  EpreuveType.tcfCo: 20 * 60,
  EpreuveType.tcfCe: 35 * 60,
  EpreuveType.tcfStructure: 20 * 60,
  EpreuveType.tcfEe: 30 * 60,
  EpreuveType.tcfEo: null,
};

/// Temps de parole cumulé des 3 tâches d'expression orale (180 + 210 + 210 s).
/// **Ce n'est pas un chrono** : c'est la durée annoncée dans les briefings. Le
/// vrai plafond est posé tâche par tâche depuis `dureeMaxSec`.
const int kEoTempsDeParoleSeconds = 180 + 210 + 210;

/// Durée **annoncée** d'un examen blanc TCF complet : la somme des 4 épreuves,
/// l'oral comptant son temps de parole. Ordre de grandeur, jamais un décompte —
/// les 4 épreuves courent chacune la leur et rien ne se reporte de l'une à
/// l'autre.
int get kExamenCompletSecondes =>
    kEpreuveDurationSeconds[EpreuveType.tcfCo]! +
    kEpreuveDurationSeconds[EpreuveType.tcfCe]! +
    kEpreuveDurationSeconds[EpreuveType.tcfEe]! +
    kEoTempsDeParoleSeconds;

/// « 20 min », « 35 min », « 1 min 30 ». `null` quand l'épreuve n'a pas de
/// durée — l'appelant décide alors quoi dire, il n'invente pas un chiffre.
String? epreuveDurationLabel(int? seconds) {
  if (seconds == null || seconds <= 0) return null;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes == 0) return '$seconds s';
  return rest == 0 ? '$minutes min' : '$minutes min $rest';
}

/// Ce qu'on affiche à la place d'une durée quand l'épreuve n'en a pas : l'oral
/// se chronomètre **par tâche**, au lancement de la tâche.
const String kChronoParTacheLabel = 'Chronométré par tâche';

/// Durée d'épreuve annoncée avant qu'une session existe (catalogue, briefing).
/// Passe par [kEpreuveDurationSeconds] — jamais une constante locale.
String epreuveDurationLabelFor(EpreuveType epreuve) =>
    epreuveDurationLabel(kEpreuveDurationSeconds[epreuve]) ??
    kChronoParTacheLabel;

/// **Temps conseillé par tâche d'expression écrite — indicatif, JAMAIS
/// bloquant.** Le seul chrono opposable de l'EE porte sur les **3 tâches
/// ensemble** (30 min, servi par le backend) ; ce repère aide seulement le
/// candidat à répartir son temps, et rien ne se ferme quand il le dépasse.
///
/// Valeurs éditoriales (7 / 10 / 13 min) : elles ne se dérivent d'aucune donnée
/// serveur — la longueur attendue d'une copie ne les explique pas — et aucun
/// endpoint ne les publie. `null` hors T1/T2/T3.
int? eeTempsConseilleMinutes(int tacheNumero) => switch (tacheNumero) {
      1 => 7,
      2 => 10,
      3 => 13,
      _ => null,
    };

/// « ≈ 10 min conseillées ». `null` quand la tâche n'a pas de repère.
String? eeTempsConseilleLabel(int tacheNumero) {
  final minutes = eeTempsConseilleMinutes(tacheNumero);
  return minutes == null ? null : '≈ $minutes min conseillées';
}
