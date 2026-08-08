import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Un palier de la table officielle du TCF. `min` est la borne BASSE incluse ;
/// le palier court jusqu'au `min` du suivant (exclu). `max` est la borne HAUTE
/// incluse : les paliers « 0 » et « 1 » ne valent qu'une seule note, ce que
/// `min` seul ne dit pas.
@immutable
class TcfNoteBand {
  const TcfNoteBand({
    required this.niveau,
    required this.min,
    required this.max,
  });

  final NiveauCecrl niveau;
  final double min;
  final double max;

  /// Teinte canonique du niveau ([CecrlColor]) — jamais une rampe scolaire :
  /// la couleur doit dire le meme palier que la pastille de niveau a cote.
  Color get tone => niveau.color;

  String get label => niveau.displayName;
}

/// Table officielle du TCF, dans l'ordre. Nos notes sont des ESTIMATIONS
/// exprimees sur cette echelle : 4,5/20 n'est pas un 4,5 scolaire francais,
/// c'est un A2. Ce qui est officiel ici, c'est l'echelle, pas la correction.
const List<TcfNoteBand> kTcfNoteBands = [
  TcfNoteBand(niveau: NiveauCecrl.a1NonAtteint, min: 0, max: 0),
  TcfNoteBand(niveau: NiveauCecrl.a1, min: 1, max: 1),
  TcfNoteBand(niveau: NiveauCecrl.a2, min: 2, max: 5),
  TcfNoteBand(niveau: NiveauCecrl.b1, min: 6, max: 9),
  TcfNoteBand(niveau: NiveauCecrl.b2, min: 10, max: 20),
];

/// Lecture d'une note sur l'échelle du TCF : à quel palier elle appartient.
///
/// **Ce n'est plus un widget.** La barre de notes du rapport de tâche a été
/// retirée le 2026-08-08 avec la note elle-même (au TCF, une tâche reçoit un
/// niveau, pas une note) ; le hero rend désormais les **paliers**, et le bilan
/// d'épreuve garde sa note avec `CecrlScale`. Ne subsiste donc ici que la table
/// officielle et sa lecture, utilisée pour **teinter** un résultat et pour
/// relire la bande d'un critère d'une évaluation trop ancienne pour la porter.
abstract final class TcfNoteScale {
  /// Palier d'une note : le dernier dont la borne basse est atteinte. `null`
  /// quand la note n'est pas un nombre exploitable : `NaN >= 0` est faux, donc
  /// une comparaison naive retomberait sur l'index 0 et **inventerait** un
  /// « A1 non atteint ». Ne rien afficher est moins faux.
  static int? bandIndexFor(double note) {
    if (note.isNaN) return null;
    var index = 0;
    for (var i = 0; i < kTcfNoteBands.length; i++) {
      if (note >= kTcfNoteBands[i].min) index = i;
    }
    return index;
  }

  static TcfNoteBand? bandFor(double note) {
    final index = bandIndexFor(note);
    return index == null ? null : kTcfNoteBands[index];
  }

  /// Bande qualitative d'une note, relue sur la table officielle du TCF.
  ///
  /// Sert aux evaluations anterieures au contrat v4, qui portent une note mais
  /// pas de `bande` : elles se rendent alors **exactement** comme les recentes,
  /// au lieu de retomber sur des seuils scolaires (15 = vert, 10 = ambre, sinon
  /// rouge) que l'echelle du TCF a rendus faux — 12/20 y est un B2.
  ///
  /// Les correspondances sont celles du serveur (`BandeCritere.of` avec les
  /// bornes 10 / 6 / 2 de la grille active) : un 0 est un hors-sujet, pas un
  /// niveau faible.
  static BandeCritere bandeFor(double note) {
    final band = bandFor(note);
    if (band == null) return BandeCritere.nonEvaluable;
    return switch (band.niveau) {
      NiveauCecrl.a1NonAtteint => BandeCritere.nonEvaluable,
      NiveauCecrl.a1 => BandeCritere.fragile,
      NiveauCecrl.a2 => BandeCritere.enCoursAcquisition,
      NiveauCecrl.b1 => BandeCritere.satisfaisant,
      NiveauCecrl.b2 ||
      NiveauCecrl.c1 ||
      NiveauCecrl.c2 =>
        BandeCritere.tresBonneMaitrise,
    };
  }
}
