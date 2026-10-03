import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';

/// L'**autorité d'affichage du niveau** d'une épreuve (Réviser, tableau de
/// bord) — **pure**, miroir mot pour mot de `web_sejoufr/lib/progres.ts`.
///
/// ⚠️ **« Où vous en êtes » a quitté l'Accueil** (Navigation v2, phase 3,
/// 2026-10-03) : ses mots (`accueilEpreuve*`, `accueilEchel*`,
/// `kProgresStatutLabel`, `kNonMesureLabel`, `progresCiviqueScore`…) sont
/// supprimés avec lui, des deux côtés. Les écrans de progression ont leurs
/// propres mots : `screens/progression/progression_labels.dart`.

/* ------------------------ L'AUTORITÉ D'AFFICHAGE du niveau d'une épreuve --- */

/// **Le niveau ACTUEL d'une épreuve, tel qu'il est AFFICHÉ partout.**
///
/// 🛑 **L'autorité d'affichage, et elle seule** : `tcfDomainProfile` publie le
/// niveau de `TcfProfileService.levelProfileAccueil` — la **moyenne des ≤ 3
/// derniers examens qualifiants** —, exactement ce que disent l'Accueil, le
/// Profil, le Diagnostic et Réviser. Les écrans de suivi lisaient
/// `DashboardCategoryStat.level`, une **troisième** autorité (le dernier
/// niveau CECRL de n'importe quelle soumission, **entraînements compris**) :
/// un candidat dont la seule trace EO était un entraînement de trois minutes y
/// lisait un palier pendant que tous les autres écrans disaient « à évaluer ».
/// → `docs/decisions/diagnostic.md`, 2026-09-16.
///
/// 🛑 **`null` = pas mesuré, jamais un plancher** : la ligne retombe alors sur
/// ce que son écran sait **compter**.
///
/// Le code de catégorie **est** la valeur de `epreuve` pour les quatre
/// épreuves : aucune table de correspondance n'est écrite ici.
/// `TCF_STRUCTURE` et les thèmes civiques n'y figurent pas — ils rendent
/// `null`, ce qui est exact : aucun palier CECRL ne leur est servi.
///
/// 🛑 **Miroir de `niveauActuelEpreuve` côté web** (`lib/progres.ts`).
NiveauCecrl? niveauActuelEpreuve(TcfDomainProfile? profil, String code) {
  for (final domaine in profil?.domaines ?? const <TcfDomain>[]) {
    if (domaine.epreuve.wire == code) return domaine.niveau;
  }
  return null;
}
