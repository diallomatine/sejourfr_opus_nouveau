import '../models/enums.dart';

/// Ce qu'il faut passer à `SfLevelTrack` pour situer un candidat sur l'échelle
/// du TCF IRN : la suite de paliers affichée, sa place, celle de sa cible.
typedef CecrlTrack = ({List<String> levels, int currentIndex, int goalIndex});

/// Compose la piste du rail à partir de deux paliers **servis**.
///
/// 🛑 `null` quand aucun niveau n'est mesuré : un rail sans point allumé
/// placerait le candidat quelque part par défaut, et *null = inconnu, jamais
/// mauvais*.
///
/// 🛑 Les paliers ne sont **pas** tronqués : `A1_NON_ATTEINT` s'affiche `<A1`
/// (via [NiveauCecrl.shortName]), jamais « A1 ». C'est pourquoi la piste est
/// découpée dans les cinq paliers du TCF IRN plutôt que dans les trois de la
/// maquette, qui ne savent pas dire « en dessous de A1 ».
///
/// La piste va d'un palier d'élan en amont du plus bas des deux jusqu'au plus
/// haut : dans le cas nominal (B1 visant B2) elle rend exactement les trois
/// colonnes de la maquette, A2 · B1 · B2.
CecrlTrack? cecrlTrack(NiveauCecrl? niveau, NiveauCecrl? cible) {
  if (niveau == null) return null;
  final courant = niveau.tcfPalierIndex;
  final vise = cible?.tcfPalierIndex ?? courant;
  final fin = courant > vise ? courant : vise;
  final bas = courant < vise ? courant : vise;
  final debut = bas > 0 ? bas - 1 : 0;
  return (
    levels: [
      for (var i = debut; i <= fin; i++) kTcfPaliers[i].shortName,
    ],
    currentIndex: courant - debut,
    goalIndex: vise - debut,
  );
}
