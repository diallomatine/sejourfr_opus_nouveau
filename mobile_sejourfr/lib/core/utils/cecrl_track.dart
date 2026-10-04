import 'dart:math' as math;

import '../models/enums.dart';

/// Ce qu'il faut passer à `SfLevelTrack` pour situer un candidat sur l'échelle
/// du TCF IRN : la suite de paliers affichée, sa place, celle de sa cible.
typedef CecrlTrack = ({List<String> levels, int currentIndex, int goalIndex});

/// Le nombre minimal de colonnes de la piste, quand l'échelle le permet.
const int _kColonnesMin = 3;

/// Compose la piste du rail à partir de deux paliers **servis**.
///
/// 🛑 **Règle UNIQUE, miroir de `levelTrackPosition` (web)** — 2026-10-04 :
/// - échelle `<A1 · A1 · A2 · B1 · B2` ([kTcfPaliers]) ;
/// - `null` (aucune piste) si le niveau **ou** l'objectif est inconnu, ou si
///   l'un des deux est C1/C2 (hors de l'échelle du TCF IRN) : *null = inconnu,
///   jamais mauvais*, et un rail sans objectif placerait le candidat par
///   défaut ;
/// - fenêtre : d'un palier sous le plus bas des deux jusqu'au plus haut,
///   **étendue vers le bas jusqu'à au moins trois colonnes** si l'échelle le
///   permet (B2 visant B2 → A2 · B1 · B2 ; A1 visant A2 → <A1 · A1 · A2).
///
/// 🛑 Les paliers ne sont **pas** tronqués : `A1_NON_ATTEINT` s'affiche `<A1`
/// (via [NiveauCecrl.shortName]), jamais « A1 ».
CecrlTrack? cecrlTrack(NiveauCecrl? niveau, NiveauCecrl? cible) {
  if (niveau == null || cible == null) return null;
  if (_horsEchelle(niveau) || _horsEchelle(cible)) return null;
  final courant = niveau.tcfPalierIndex;
  final vise = cible.tcfPalierIndex;
  final fin = math.max(courant, vise);
  final bas = math.min(courant, vise);
  final debut = math.max(0, math.min(bas - 1, fin - (_kColonnesMin - 1)));
  return (
    levels: [
      for (var i = debut; i <= fin; i++) kTcfPaliers[i].shortName,
    ],
    currentIndex: courant - debut,
    goalIndex: vise - debut,
  );
}

bool _horsEchelle(NiveauCecrl niveau) =>
    niveau == NiveauCecrl.c1 || niveau == NiveauCecrl.c2;
