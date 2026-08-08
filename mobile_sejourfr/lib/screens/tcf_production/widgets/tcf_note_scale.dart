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
    required this.rangeLabel,
    required this.min,
    required this.max,
  });

  final NiveauCecrl niveau;

  /// Ce qui rend la note lisible : « 2-5 », pas un pourcentage.
  final String rangeLabel;
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
  TcfNoteBand(
      niveau: NiveauCecrl.a1NonAtteint, rangeLabel: '0', min: 0, max: 0),
  TcfNoteBand(niveau: NiveauCecrl.a1, rangeLabel: '1', min: 1, max: 1),
  TcfNoteBand(niveau: NiveauCecrl.a2, rangeLabel: '2-5', min: 2, max: 5),
  TcfNoteBand(niveau: NiveauCecrl.b1, rangeLabel: '6-9', min: 6, max: 9),
  TcfNoteBand(niveau: NiveauCecrl.b2, rangeLabel: '10-20', min: 10, max: 20),
];

/// Regle de lecture de la note, rendue visible : les cinq paliers du TCF, leurs
/// notes, et un curseur sur celle du candidat.
///
/// Les paliers sont dessines a largeur EGALE, jamais proportionnelle a leur
/// etendue en points : sur cette echelle comprimee, un B2 (10-20) occuperait la
/// moitie de la barre et un A1 (1) un trait invisible. Ce qu'on montre ici,
/// c'est la suite des paliers, pas un axe metrique.
class TcfNoteScale extends StatelessWidget {
  const TcfNoteScale({super.key, required this.note});

  /// Note 0..20 ; null quand la production n'a pas pu etre notee — la barre
  /// reste affichee (la regle de lecture vaut toujours), sans curseur. Une
  /// note qui n'est pas un nombre (`NaN`) est traitee pareil : pas de palier
  /// determine, donc pas de curseur.
  final double? note;

  static const cursorKey = ValueKey<String>('tcf-note-cursor');

  static const double _gap = 4;
  static const double _barHeight = 8;
  static const double _cursorSize = 16;

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

  /// Curseur insere de [_inset] de chaque cote de sa case : une note pile au
  /// seuil (2/20) tomberait sinon sur la frontiere entre deux paliers, et se
  /// lirait dans la mauvaise case.
  static const double _inset = 0.1;

  /// Position 0..1 DANS le palier, avant insertion.
  ///
  /// Un palier a valeur unique (0 → A1 non atteint, 1 → A1) n'a pas d'interieur
  /// a parcourir : le curseur s'y **centre**, sinon il se collerait au bord
  /// gauche de la case et donnerait a lire un palier plus bas.
  static double _fractionInBand(double note, int index) {
    final band = kTcfNoteBands[index];
    if (band.min == band.max) return 0.5;
    final end = index == kTcfNoteBands.length - 1
        ? band.max + 1
        : kTcfNoteBands[index + 1].min;
    return ((note - band.min) / (end - band.min)).clamp(0.0, 1.0);
  }

  /// Position 0..1 DANS la case dessinee, insertion comprise.
  static double positionInBand(double note, int index) =>
      _inset + _fractionInBand(note, index) * (1 - 2 * _inset);

  @override
  Widget build(BuildContext context) {
    final value = note;
    final activeIndex = value == null ? -1 : (bandIndexFor(value) ?? -1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final segment = (width - _gap * (kTcfNoteBands.length - 1)) /
                kTcfNoteBands.length;
            return SizedBox(
              height: _cursorSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (_cursorSize - _barHeight) / 2,
                    child: Row(
                      children: [
                        for (var i = 0; i < kTcfNoteBands.length; i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: Container(
                              height: _barHeight,
                              decoration: BoxDecoration(
                                color: kTcfNoteBands[i].tone.withValues(
                                      alpha: i == activeIndex ? 1 : 0.22,
                                    ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (value != null && activeIndex >= 0)
                    Positioned(
                      left: activeIndex * (segment + _gap) +
                          positionInBand(value, activeIndex) * segment -
                          _cursorSize / 2,
                      top: 0,
                      child: Container(
                        key: cursorKey,
                        width: _cursorSize,
                        height: _cursorSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          border: Border.all(
                            color: kTcfNoteBands[activeIndex].tone,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < kTcfNoteBands.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                child: _BandLabel(
                  band: kTcfNoteBands[i],
                  active: i == activeIndex,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({required this.band, required this.active});

  final TcfNoteBand band;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Plage en premier : « A1 non atteint » passe sur deux lignes sur les
    // petits ecrans, et les plages doivent rester alignees entre elles.
    return Column(
      children: [
        Text(
          band.rangeLabel,
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 10,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.ink : AppColors.muted2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          band.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppFonts.ui(
            size: 10,
            weight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? band.tone : AppColors.muted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
