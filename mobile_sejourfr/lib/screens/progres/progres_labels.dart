import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/progress_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic_civique/civic_diagnostic_blocks.dart';

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

/* ------------------------ L'ÉTAT d'une épreuve face à l'objectif (servi) --- */

const String kEtatObjectifAtteint = 'Objectif atteint';
const String kEtatObjectifProche = "Proche de l'objectif";
const String kEtatObjectifARenforcer = 'À renforcer';
const String kEtatObjectifNonEvalue = 'Non évalué';

/// **L'état d'une épreuve face à l'objectif, et son ton** — la seule
/// correspondance du mobile entre le `StatutObjectif` **servi**
/// (`ProgressDto.tcf.epreuves[].status`) et ce que l'écran affiche
/// (Entraînement, Progression TCF).
///
/// 🛑 **Aucun seuil** : on lit un enum servi, jamais un nombre.
/// 🛑 `TO_REINFORCE` recouvre aussi « jamais mesuré » : c'est [niveau] servi
/// qui les distingue, et une épreuve sans palier se dit « Non évalué », au ton
/// neutre — `null` = inconnu, jamais mauvais (V040/V041/V042).
/// `status == null` (aucune démarche déclarée) ⇒ `null` : rien à comparer.
///
/// Miroir web : `etatEpreuveTcf` (`lib/etats-servis.ts`) — un seul mapping par
/// front.
SfState? etatEpreuveTcf(StatutObjectif? status, NiveauCecrl? niveau) {
  if (niveau == null) {
    return (label: kEtatObjectifNonEvalue, tone: SfTone.muted);
  }
  return switch (status) {
    null => null,
    StatutObjectif.targetReached => (
        label: kEtatObjectifAtteint,
        tone: SfTone.ok
      ),
    StatutObjectif.closeToTarget => (
        label: kEtatObjectifProche,
        tone: SfTone.warn
      ),
    StatutObjectif.toReinforce => (
        label: kEtatObjectifARenforcer,
        tone: SfTone.hot
      ),
  };
}

/// **L'état servi d'un thème civique** (`CivicThemeState`) et son ton
/// ([sfToneOf]) — la seule correspondance du mobile. Miroir web :
/// `etatThemeCivique` (`lib/etats-servis.ts`).
SfState etatThemeCivique(CivicThemeState etat) =>
    (label: etat.label, tone: sfToneOf(etat));
