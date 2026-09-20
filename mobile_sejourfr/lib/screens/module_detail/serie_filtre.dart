import '../../core/models/lot_models.dart';

/// **Le filtre des listes de séries** — TCF (CO / CE / Structure, par niveau)
/// et chaque thème civique.
///
/// 🛑 **« Faite » se lit sur un FAIT SERVI** : `lastScore`, le score du dernier
/// attempt terminé sur ce lot, que le backend joint à la liste. Ni un compteur
/// local, ni un marqueur posé par l'app — un candidat qui change d'appareil
/// retrouve exactement les mêmes séries cochées.
///
/// ⚠️ **Une série faite reste refaisable** : le filtre range, il n'interdit
/// rien. C'est pourquoi « À faire » ne veut pas dire « autorisé », et le verrou
/// freemium reste ailleurs (le rang du lot, opposé par le serveur).
///
/// Miroir web : `lib/serie-filtre.ts`.
enum SerieFiltre {
  tous,
  aFaire,
  faites;

  bool accepte(LotDto lot) => switch (this) {
        SerieFiltre.tous => true,
        SerieFiltre.aFaire => lot.lastScore == null,
        SerieFiltre.faites => lot.lastScore != null,
      };
}

/// Les trois libellés, **compteur compris** — « À faire · 4 ». Un compteur qui
/// vit dans la puce évite de faire compter le candidat, et il dit tout de suite
/// si le filtre a quelque chose à montrer.
List<String> serieFiltreLabels(List<LotDto> lots) {
  final faites = lots.where((l) => l.lastScore != null).length;
  return [
    'Toutes · ${lots.length}',
    'À faire · ${lots.length - faites}',
    'Faites · $faites',
  ];
}

/// Le sous-ensemble à afficher. 🛑 **L'ordre servi est conservé** : on filtre,
/// on ne retrie jamais — les séries se suivent par numéro.
List<LotDto> serieFiltrer(List<LotDto> lots, SerieFiltre filtre) =>
    lots.where(filtre.accepte).toList();

/// Ce qu'on dit quand le filtre ne retient aucune série. **Miroir web**
/// (`SERIE_FILTRE_VIDE`).
const String kSerieFiltreVide = 'Aucune série dans ce filtre.';
