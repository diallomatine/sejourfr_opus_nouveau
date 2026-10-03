# AUDIT — Navigation v2 (phase 1)

> Livrable de la phase 1 de `docs/redesign/BRIEF_NAVIGATION_V2.md`. **Aucun code modifié.**
> Établi le 2026-10-03 sur `develop` (d7d8a136). Requêtes SQL en lecture seule sur `sejourfr_db`.
> Conventions : `maq-web` = `docs/redesign/sejourfr-navigation-web.html`, `maq-mob` =
> `docs/redesign/sejourfr-navigation-mobile.html`, `web/` = `web_sejoufr/`, `mob/` = `mobile_sejourfr/`.

## 0. Synthèse — ce qui bloque avant STOP 1

Le brief est **faisable sans toucher au backend**, à condition de trancher les points ci-dessous.
Les D1–D6 du brief sont au §8 ; les arbitrages **supplémentaires** découverts par l'audit sont
numérotés **X1–X14** (§8.2). Les plus lourds :

| # | Problème | Pourquoi ça bloque |
|---|---|---|
| X1 | **Couleurs de module inversées** : l'app actuelle met **TCF en rouge, Civique en bleu** (mobile `segmented_tabs.dart:82-90`, `AppColors` doc l.11-12, `CLAUDE.md` mobile ; web `examens-blancs/page.tsx:347,369`). La maquette fait l'inverse. `docs/identite-visuelle.md:8` réserve le rouge aux CTA critiques. | Touche les deux fronts, la doc d'identité et tous les écrans hors périmètre qui gardent l'ancien code couleur. |
| X2 | **Polices mobile** : l'app Flutter est en **Bricolage Grotesque + Hanken Grotesk** ; Jakarta, Fraunces et JetBrains Mono y ont été **supprimés** (`app_theme.dart:231-293`, `mono` `@Deprecated`). Le brief §8.2 et le `CLAUDE.md` racine disent Jakarta/Mono/Fraunces. | Le web est conforme au brief ; le mobile non. Changer la police mobile = refonte typographique de toute l'app. |
| X3 | **« Testée unitairement » (§6, §12)** contredit la règle racine « aucun NOUVEAU test sur les fronts », qui **prime sur toute consigne écrite ailleurs**. | Il faut renoncer au test ou lever la règle pour ce cas. |
| X4 | **% civique « des séries de la mention »** : impossible. Les lots civiques ne sont **pas filtrés par mention** côté serveur (`LotService.java:145,179` : `countActiveMatching(CIVIQUE, themeId, null, null)`). | Change la définition D5 et le chiffre affiché. |
| X5 | **URL** : le brief veut « une vraie route par entrée » ; de nouvelles URL (`/tcf/plan`…) sortent de l'allow-list analytics `TrackedScreen.java` → suivi admin perdu sans modifier le backend (interdit par R4). | Reco : garder les URL actuelles (§6). |
| X6 | **Arbitrages antérieurs du propriétaire révoqués** par la maquette (sidebar « laisser comme elle était », Accueil scopé par module, « une seule action dominante », pas de topbar desktop, bas de l'Accueil supprimé, ordre mobile ≠ web assumé le 2026-09-12). | Il faut une révocation explicite pour ne pas défaire une décision en silence. |

---

## 1. Inventaire de l'existant

### 1.1 Web (Next.js)

**Routes connectées** (`web/app/(app)/`) : `/dashboard` (Accueil, scopé `?module=`), `/plan`
(+ `etape/[stepId]`, `domaine/[domaine]`, `debloquer`, `progression`, `progression/cycle/[id]`),
`/progression/tcf` (+ `[epreuve]`), `/progression/civique` (+ `[theme]`), `/favoris`, `/aide`,
`/parcours`, `/profil` (+ `abonnement` = « Mon pass », `informations/**`, `notifications`),
`/paiement/**`, `/diagnostic-civique/**`.

**Routes duales** (visiteur + connecté, `DualChromeShell`, à la racine de `app/`) :
`/entrainement` (Réviser, `?module=`, civique par défaut), `/entrainement/tcf/**`,
`/entrainement/civique/**`, `/examens-blancs/**`, `/sessions/[attemptId]`, `/diagnostic`.

**Publiques** : `/`, `/tarifs`, `/reussir`, `/blog/**`, `/faq`, `/contact`, `/a-propos`, légales,
auth, `/completer-profil`, `/continuer-sur-app`, `/examen-blanc` (→ `/examens-blancs`).

**Shell actuel** :
- `app/(app)/layout.tsx:25-79` et `DualChromeShell.tsx:21-60` : grille `248px 1fr`, bascule à
  **900 px**, fond `#F7F8FC` **en dur** (à corriger).
- `AppSidebar.tsx` : liste plate Accueil · Plan · TCF IRN · Examen civique · Examens blancs ·
  Progression, carte streak, carte utilisateur (nom + objectif), déconnexion ; cocarde **dupliquée**
  en dégradés avec `#fff` en dur (260-268) au lieu de `Brand.tsx`.
- `AppTopBar.tsx` : seulement ≤ 900 px (burger + titre + tiroir), titres via `lib/app-bar.ts`,
  flèche de retour des sous-écrans via `useAppBarBack`.
- `middleware.ts:17` protège `/dashboard`, `/favoris`, `/paiement`, `/plan`, `/progression`.
- Redirections existantes : `next.config.ts:95-128` (8 règles 307).

**Logo** : `app/_components/Brand.tsx` (`Cocarde`, `Wordmark` FR rouge, `Brand`) + `.cocarde`
dans `globals.css:210-254`. Conforme au brief ; il suffit de le réutiliser.

**Kit** : `app/_components/sejour/SejourKit.tsx` (3 232 l.) + `sejour.module.css` (5 002 l.).
Écrans sur le kit : Accueil, Plan, Réviser, Progression. **Hors kit** : `/examens-blancs`
(`<style>` scoped `.ebh`, `ModuleToggle` à état local) et `/profil` (`.pr-*`).

### 1.2 Mobile (Flutter)

- **Shell** : `ShellRoute` **simple** (`app_router.dart:697-733`), **pas** de `StatefulShellRoute` →
  aucune pile par onglet. Bottom nav **5 onglets** Accueil · Plan · Réviser · Examens · Profil
  (`screens/shell/main_shell.dart:112-122`), actif toujours `AppColors.blue`.
- Routes du shell : `/`, `/plan`, `/reviser`, `/examens`, `/profile` ; `/tcf` et `/civique`
  redirigent vers `/reviser` (l.714-723).
- Tout le reste est **hors shell** (sans bottom nav) : progression (`/progression/tcf|civique/**`),
  plan (`/plan/etape|domaine|progression|debloquer|serie`), hubs TCF/civique, EE/EO, examens,
  runner, diagnostics, profil/**, aide, favoris.
- Toggles de module : `parcoursCiviqueProvider` / `examensParcoursProvider` (9 fichiers).
- Aucun `PopScope` sur les écrans du shell. `retourOuRepli` (`core/router/retour.dart:25`).
- **Icônes** : `lucide_icons_flutter` (trait) — tous les pictos de la maquette ont un équivalent
  Lucide. `flutter_svg` présent mais peu utilisé.

### 1.3 Tokens

**Les 9 couleurs du §8.1 existent déjà, à l'identique, des deux côtés.**

| Brief | Web (`globals.css @theme`) | Mobile (`AppColors`) |
|---|---|---|
| `#1E3A8C` | `--color-blue` | `blue` |
| `#15296B` | `--color-blue-dark` | `blueDark` |
| `#E8ECF8` | `--color-blue-light` ⚠️ (pas `-soft` = `#F4F6FC`) | `blueLight` ⚠️ (pas `blueSoft`) |
| `#E1372F` | `--color-red` | `red` |
| `#B5251E` | `--color-red-dark` | `redDark` |
| `#FDECEB` | `--color-red-light` | `redLight` |
| `#0F1839` | `--color-ink` | `ink` |
| `#168F5B` | `--color-green` | `green` |
| `#E8A317` | `--color-amber` | `amber` |
| ambre texte | `--color-amber-dark #8A6100` ✅ | `amberDark #9A6A0B` ✅ |

- Neutres : on prend ceux de l'app (`paper`/`bg`, `muted`, `line`, `surface2`…), proches de la
  maquette.
- **À créer** (comme tokens) : fond clair des blocs module (`#EFF3FE`/`#FFF4F1` dans la maquette →
  dériver de `blue-light`/`red-light`), fond `tip-card` (dérivé ambre), ombres teintées, dégradés
  sombre→marque (`blue-dark → blue`, `red-dark → red` ; les dégradés web actuels vont dans l'autre
  sens), rayons 22/26/28/30 px (le kit web plafonne à 24, `AppRadii` = 8/12/18/26).
- Web : JetBrains Mono chargé en **400/500 seulement** (`app/layout.tsx:14-34`) ; les labels de la
  maquette sont en 850/900 → charger au moins 700. Jakarta plafonne à 800 (850/900 → 800).
- Doc en retard : `docs/identite-visuelle.md:13` indique `#FAFAF7`/`#F2F1EC` ; le code est en
  `#F7F8FC`/`#ECEFF7`.

---

## 2. Correspondance écran actuel → emplacement cible

| Cible | Web actuel | Mobile actuel |
|---|---|---|
| Accueil | `/dashboard` (contenu **remplacé**) | `HomeScreen` `/` (contenu **remplacé**) |
| TCF · Mon plan | `/plan?module=TCF` → `LearningPlanView` | `PlanScreen` → `PlanTcfView` |
| TCF · Entraînement | `/entrainement?module=TCF` → `ReviserScreen` `TcfBody` | `ReviserScreen` branche `_tcf` |
| TCF · Examens blancs | `/examens-blancs`, onglet TCF (**état local**, pas dans l'URL) | `ExamensScreen` → `TcfFullExamsView` |
| TCF · Progression | `/progression/tcf` | `ProgressionTcfScreen` (poussé) |
| Civique · Plan | `/plan?module=CIVIQUE` → `CivicPlanPanel` | `PlanScreen` → `CivicPlanView` |
| Civique · Entraînement | `/entrainement?module=CIVIQUE` → `CiviqueBody` | `ReviserScreen` branche `_civique` |
| Civique · Examens | `/examens-blancs`, onglet civique | `ExamensScreen` → `CiviqueFullExamsView` |
| Civique · Progression | `/progression/civique` | `ProgressionCiviqueScreen` (poussé) |
| Profil | `/profil` | `ProfileScreen` |

**Écrans sans entrée de navigation — proposition** (identique web et mobile) :

| Écran | Place proposée |
|---|---|
| « Renforcer mon français » (Structure) | Sous les 4 tuiles de TCF · Entraînement (bloc hors maquette conservé, R5) |
| Mes cycles, étape, domaine, débloquer | Sous-écrans de Mon plan du module ; l'item du module reste actif |
| Hubs `/entrainement/tcf/**`, `/entrainement/civique/**` (mobile `/tcf/co…`, `/civique/theme/:id`) | Sous-écrans d'Entraînement du module |
| Compétences | Inchangé (accès via le Plan et la tâche EE/EO) |
| Exécution d'examen, runner, bilans | Hors périmètre ; plein écran, liens conservés |
| Détails de progression (`[epreuve]`, `[theme]`) | Sous-écrans de Progression |
| Favoris, Aide, À propos, Mes informations, Notifications, Mon pass, `/parcours` | Sous-écrans de Profil |
| Diagnostics | Hors nav (liens « Mon diagnostic » du Plan conservés) |
| Mobile `/tcf/examens-blancs`, `/civique/examens-blancs` (plein écran) | Redondants avec les segments Examens → redirigés vers le segment (voir X10) |

---

## 3. Mapping des données (R3/R4)

Légende : **S** = servi, affiché tel quel · **F** = agrégat/formatage côté front de faits servis ·
**ABSENT** = pas de source, ne pas inventer.

### 3.1 Identité, mention, pass

| Valeur maquette | Source | Statut |
|---|---|---|
| Nom, initiales | `GET /api/auth/me` → `AuthenticatedUser.firstName/lastName` | S (+ formatage) |
| « Objectif · Naturalisation » | `AuthenticatedUser.targetProcedure` + libellé `TargetProcedure.getLabel()` (miroirs `objectifLabel` web / `mentionLabel` mobile) | S |
| Nom du pass / accès gratuit | `GET /api/billing/subscription-status` → `moduleAccess`, `isPremium`, `productId`. **Aucun nom servi** ; les fronts mappent `moduleAccess` → « Pass Intégral / Pass Civique / Découverte » (`profil/page.tsx:149-160`, `profile_screen.dart:441-452`) | S (enum) + libellé front existant. Voir X12 |
| « paiement unique » | `SubscriptionStatusResponse.oneTime` | S |
| « Membre depuis 2026 » | — (`users.created_at` non exposé) | **ABSENT** |
| « Votre semaine · 7 jours » | `GET /api/me/dashboard` → `currentStreakDays` | S |

### 3.2 TCF

| Valeur maquette | Source | Statut |
|---|---|---|
| Niveau actuel (« B1 ») | `ProgressionTcfDto.niveauActuel` = `DashboardSummaryResponse.estimatedTcfLevel` (même autorité `TcfProfileService.levelProfileAccueil`) | S ; `null` → « — / Non évalué » |
| Niveau cible (« B2 ») | `AuthenticatedUser.targetLevel` (plancher appliqué) = `ProgressDto.tcf.objectif` = `JourneyDto.objectif` | S — **une seule source à retenir** : `AuthenticatedUser.targetLevel` (cf. X13) |
| Nb épreuves (4) | `ProgressDto.tcf.epreuves.length` / `JourneyDto.blocs` ; miroir `TCF_EPREUVES_OFFICIELLES` ⇄ `tcf_epreuves.dart` | S |
| Épreuves au niveau cible (« 1/4 ») | comptage de `ProgressDto.tcf.epreuves[].status == TARGET_REACHED` | F (comptage d'états servis) |
| États par épreuve (Solide / À renforcer / Prioritaire) | `StatutObjectif` servi : Objectif atteint / Proche de l'objectif / À renforcer. **« Prioritaire » n'existe pas** | S — libellés servis, pas ceux de la maquette |
| « Cycle 2 · 0/4 » | `GET /api/me/plan/journey` → `JourneyCycleDto.numero`, `etapesTerminees/etapesTotal` | S |
| Prochaine activité : titre, type, code | `JourneyDto.current` (`type`, `bloc.code/label`) via `planNowCard` (web `lib/plan-domain.ts:977`) / `journeyProvider` (mobile) | S |
| Prochaine activité : durée | `current.assessment.estimatedMinutes` ou `current.exercise.estimatedMinutes` ; pour une série CO/CE, appel supplémentaire `JourneyStepDetailDto.dureeEstimeeMin` | S, **nullable** |
| Destination du CTA | geste de `planNowCard` / `civicNowCard` (`LANCER`, `OUVRIR_ETAPE`, `DEBLOQUER`, `AUCUN`) | S — répond au §4.3 |
| Examens blancs « 2/4 » | Total : `GET /api/exam-slots?epreuve=TCF_COMPLET` → **20 créneaux** avec `locked`. Faits : `ProgressionTcfDto.examensComplets.nombre` (compte les rejeux) | S, mais **le total réel est 20**, pas 4. Pas de « créneaux faits » servi |
| Verrou d'examen (« se débloque à la fin du cycle 2 ») | `slots[].locked` (créneau 1 offert, 2+ pass TCF). La règle « fin de cycle » **n'existe pas** | S (vrai verrou) |
| Timeline « A2 → B1 → B1 → B1+ », « A2+ » | niveaux des examens complets (`ProgressionTcfDto`) ; **les demi-paliers « + » n'existent pas** dans `NiveauCecrl` | S sans « + » |
| « environ 95 min » | durée servie du gabarit d'examen complet (à confirmer phase 4) | S |
| Entretien en temps réel | `GET /api/realtime/eo/quota`, `SubscriptionStatusResponse.realtimeSessionsRemaining` ; lancement exige une tâche → destination = hub EO | S (lien vers hub EO) |
| Conseil du plan, Analyse IA | — | **ABSENT** |

### 3.3 Civique

| Valeur maquette | Source | Statut |
|---|---|---|
| Nb thèmes (5) | `JourneyDto(CIVIQUE).blocs` / `summary.civique.length` | S |
| Séries terminées / totales par thème | `GET /api/me/dashboard` → `civique[].seriesDone/seriesTotal` (`LotService.seriesCountCivique`) | S |
| Séries globales (« 17/43 ») | somme des 5 thèmes | F |
| % (« 34 % ») | `floor(Σdone / Σtotal × 100)` | F — **aucune autorité serveur** (voir §5) |
| Thème de la prochaine série | `JourneyDto(CIVIQUE).current.bloc.label` via `civicNowCard`. ⚠️ Dans le cycle par défaut (D-69) l'étape courante est un **examen de thème**, pas une série | S |
| « Série 4 », « série 4/5 » | — (aucune autorité ne recommande un numéro de lot) | **ABSENT** |
| Meilleur score (« 91 % ») | `GET /api/me/progression/civique` → `global.meilleur.taux` (+ `seuilAtteint`) | S |
| Historique 76 → 84 → 91 % | `ProgressionCiviqueDto.examens[]` (3 derniers) | S. « Réussi » = `seuilAtteint` seul |
| Seuil 32/40, 40 questions | `ProgressionCiviqueDto.echelle.seuil/max` ; `ExamTemplateSummary.passingScore/totalQuestions` | S |
| « Objectif 80 % » | fictif (règle réelle 32/40) | remplacé par `seuil/max` |
| États de thème (En cours / À travailler) | `CivicThemeState` servi (Solide / À renforcer / Faible / Non évalué), ou `themeStatus` existant de Réviser | S — jamais déduit du % |
| Codes PV / SI / DD / HC / VF | — (code servi `CIV_PRINCIPES`…) ; l'Accueil mobile affiche déjà un rang | **ABSENT** |
| Descriptions de thème | `ThemeUserResponse.description` (servi d'après l'audit données ; à confirmer phase 4, l'audit web l'a jugé absent) | à vérifier |
| Statistiques par thème (texte) | — | **ABSENT** |
| Examen blanc par thème | `GET /api/themes/{id}/exam-slots` (20 créneaux, `locked`). La règle « 50 % du parcours » est inventée | S (vrai verrou) |

### 3.4 Nouvel utilisateur (§7)

Un USER a **toujours une mention** (`ProfilObligatoire` impose `/completer-profil` /
`/target-path` avant l'app ; seul un ADMIN peut en être dépourvu → `JourneyDto.state =
NEEDS_OBJECTIVE`). Toute mention a **les deux modules** ; le vrai cas est l'**accès**
(`AuthenticatedUser.hasTcf/hasCivique`, jamais `isPremium`).

Compte neuf : `niveauActuel = null`, `examensComplets.nombre = 0`, streak 0, 5 thèmes à
`seriesDone = 0` avec un `seriesTotal` réel, `ProgressionCiviqueDto.global.nombre = 0`, journeys
créés à la première lecture (cycle 1 d'examens, `current` = examen CO / examen du 1ᵉʳ thème, non
verrouillé). ⚠️ `ProgressDto.tcf.epreuves[].status = TO_REINFORCE` même sans mesure : ne pas
l'afficher comme un verdict (« null = inconnu ») — utiliser `provenance == null` pour « Non évalué ».

---

## 4. Blocs maquette sans équivalent / blocs existants absents

« Garder » = conservé et stylé avec le composant maquette le plus proche (brief §5.5).

### Accueil (contenu remplacé — seul écran où la maquette fait foi pour le contenu)

- **Maquette sans équivalent, à créer** : « Mes objectifs » (mobile : carte groupée ; web :
  `.obj-card`), les **deux** cartes d'action simultanées (aujourd'hui une seule, selon la bascule).
- **Existant absent de la maquette** — décision par bloc (X7) :

| Bloc existant | Reco |
|---|---|
| Bascule TCF / Civique | Supprimer (la nav la remplace) |
| « Où vous en êtes » (`LevelCardGrid`) | Supprimer (remplacé par « Mes objectifs ») |
| Carte diagnostic en cours / en analyse | Garder, au-dessus de « À faire maintenant », seulement quand elle existe |
| Invitation à déclarer un objectif / bandeau « choisir un parcours » | Garder (cas ADMIN / profil incomplet) |
| `_IndependenceNote` (mobile) | **Garder impérativement** (conformité stores) |
| CTA secondaires de la carte d'action (`HomeSoftAction`) | Supprimer (maquette : un CTA par carte) |

### TCF · Mon plan
- Maquette sans équivalent : hero « Ma progression » (données OK, barre → D4), « Conseil du plan »
  (**ABSENT** → masqué), liste plate « Priorités actuelles » (l'existant est un cycle par blocs).
- Existant absent : `GoalStrip`, « À faire maintenant » (`NowCard`), `ExamenCompletJalon`,
  `PlanCycleSection` (blocs, étapes, fin de cycle « Actualiser mon plan »), `PlanMilestoneCard`,
  liens Mes cycles / Mon diagnostic, note « Estimation non officielle », barre « Débloquer » gratuit.
  → **Tous gardés** (règles D-64/D-66/D-69). Reco : « Priorités actuelles » de la maquette **=**
  `PlanCycleSection` restylé en `info-card`, pas une liste supplémentaire.

### TCF · Entraînement
- Maquette sans équivalent : gros niveau par épreuve (servi : `tcfDomainProfile`), hero « Entretien
  en temps réel » (→ lien hub EO, D3-B).
- Existant absent : carte « Reprendre » (`PlanRecoCard`), compteurs séries/sujets, `DemoLink`,
  invitation objectif, « Renforcer mon français » → gardés.

### TCF · Examens blancs
- Maquette : 4 examens, « 2/4 », « A2+ », verrou « fin du cycle 2 » → **remplacés** par la grille
  servie de 20 créneaux et son `locked`.
- Existant absent : 3 stats, tips, grille repliée (« Voir les examens 8 à 20 »), briefing, paywall,
  mention de l'examen gratuit → gardés.

### TCF · Progression
- Maquette sans équivalent : `level-row` avec point d'état (états **servis**), timeline (sans « + »),
  hero « Prochaine étape » (= `journey.current`), « Analyse IA » (**ABSENT** → masqué).
- Existant absent : `ProgressHero` (pastilles, « partiel »), 4 tuiles, cartes d'épreuve avec
  sparkline, liste des examens, « Voir tous », `MicroNote`, bascule TCF/Civique
  (`ProgressionBascule`) → tout gardé **sauf la bascule** (redondante avec la nav).

### Civique · Plan
- Maquette sans équivalent : hero « N séries terminées / % » (voir X8), carte « Examen blanc
  disponible · dernier score » (servi).
- Existant absent : `GoalStrip`, `NowCard` du cycle, `ExamenCompletJalon`, cycle civique,
  « À revoir » (Leitner), liens, paywall → gardés.

### Civique · Entraînement
- Maquette sans équivalent : « Statistiques par thème » (**ABSENT** → masqué), description de
  thème (à vérifier), états « En cours / À travailler » (→ états servis).
- Existant absent : carte « Reprendre », `DemoLink` → gardés. Le reste correspond déjà (`EpreuveRow`
  ≈ `theme-card` avec anneau et « x/y séries »).

### Civique · Examens
- Maquette : 3 lignes, « Examen blanc par thème · 50 % » → **grille servie de 20 créneaux**
  conservée ; examens par thème restent dans `/entrainement/civique/[theme]/examens`.
- Existant absent : stats, tips, feuille d'introduction, paywall → gardés.

### Civique · Progression
- **Écart de nature** : l'existant est fondé sur les **examens** (score /40, état par thème) ; la
  maquette sur les **séries** (%). Reco : garder l'existant (R5) et **ajouter** la « Maîtrise globale »
  en % de séries en tête ; codes PV/SI… remplacés par le rang ou le libellé servi.
- Existant absent : hero /40 + anneau + verdict de seuil, 4 tuiles, cartes de thème, liste des
  examens → gardés.

### Profil
- Maquette sans équivalent : « Membre depuis » (**ABSENT** → masqué), entrée unique « Paramètres »
  (aujourd'hui « Mes informations » + « Notifications » : reco = garder les deux lignes), « Résumé de
  préparation » (servi), « Votre semaine » (servi).
- Existant absent : e-mail + pastille démarche, 3 tuiles (Maîtrise, Série, Niveau estimé), « Mon
  objectif », Mes favoris, À propos, version, Se déconnecter, Supprimer mon compte → gardés.

### Shell
- Web, existant absent de la maquette : carte streak de la sidebar (→ déplacée dans « Votre
  semaine » du Profil), bouton de déconnexion (→ Profil, déjà présent), flèche de retour des
  sous-écrans (→ conservée dans la topbar).

---

## 5. Pourcentage civique

**Trois objets s'appellent « série » côté serveur** : (1) les **lots** d'entraînement libre (20 Q par
thème, `LotService`) ; (2) les séries d'étape du Plan (`journey_step_series`, ne comptent pas dans
les lots) ; (3) la série ciblée du plan civique. Le brief désigne (1).

- Servi par thème : `DashboardSummaryResponse.civique[].seriesDone/seriesTotal`.
  « Terminée » = un attempt **fini** existe sur le lot, quel que soit le score
  (`LotService.java:205-208`) = **D5-A**. Le total compte **toutes** les séries, verrouillées
  comprises.
- **Non filtré par mention** : total en base = 5 + 11 + 10 + 11 + 10 = **47** lots, identique pour
  CSP, CR et NAT.
- Aucun total ni pourcentage global servi.

**Méthode retenue** : `floor(Σ seriesDone / Σ seriesTotal × 100)` sur les 5 thèmes, `0 %` si
total nul, **une fonction unique par front**, logée à côté de l'actuel `epreuveRatio`
(`web/lib/reviser.ts:318` ⇄ `mob/…/reviser_labels.dart`). Endpoint : `GET /api/me/dashboard`
(déjà en cache côté web via `summaryCached`). C'est une agrégation de faits servis, comme le ratio
par thème déjà affiché ; il n'y a **aucun classement** du nombre en état.

- D5-B impossible : aucune « série accessible » n'est servie (`LotDto` n'a pas de `locked`, le verrou
  se déduit encore du rang — dette `freemium.md:399-402`).
- D5-C impossible : le front devrait comparer `lastScore` à un seuil (classement interdit).

---

## 6. Anciennes routes → redirections

### 6.1 Web — **garder les URL actuelles comme canoniques** (reco)

Motifs : allow-list `TrackedScreen.java:26-50` (R4), liens d'e-mails (`EmailLinks.java:31-54` :
`/dashboard`, `/plan?module=…`, `/profil/abonnement`, `/profil/notifications`, `/contact`,
`/reinitialiser-mot-de-passe`), retour Stripe (`/paiement/succes`, `/paiement/recapitulatif`),
middleware et préfixes du chrome. `?module=` donne déjà une URL par entrée et un retour navigateur
correct.

| Entrée | URL | Changement |
|---|---|---|
| Accueil | `/dashboard` | `?module=` ignoré (plus de bascule) |
| TCF · Mon plan / Civique · Plan | `/plan?module=TCF` / `CIVIQUE` | aucun |
| TCF / Civique · Entraînement | `/entrainement?module=TCF` / `CIVIQUE` | aucun |
| TCF / Civique · Examens | `/examens-blancs?module=TCF` / `CIVIQUE` | **module lu dans l'URL** au lieu de `useState` (`page.tsx:99,568`) ; nu → TCF |
| TCF / Civique · Progression | `/progression/tcf` / `civique` | aucun |
| Profil | `/profil` | aucun |

Aucune route supprimée ⇒ aucune nouvelle redirection, aucun 404, liens d'e-mails intacts.
L'item actif de la sidebar se déduit par préfixe : `/plan/**` et `/plan/etape|domaine|…` selon
`?module=` (à vérifier écran par écran), `/entrainement/tcf/**` → TCF Entraînement,
`/entrainement/civique/**` + `/diagnostic-civique/**` → Civique Entraînement, `/examens-blancs/tcf/**`
→ TCF Examens, `/progression/<m>/**` → Progression, `/profil/**` `/favoris` `/aide` `/parcours` →
Profil, `/sessions/**` → aucun item.

### 6.2 Mobile

`StatefulShellRoute.indexedStack` à 4 branches (go_router 14.8.1, disponible). Une branche peut
porter plusieurs chemins absolus ⇒ **on garde les chemins existants** et on les déclare dans la
branche de leur module (la bottom nav reste visible). Segments en sous-route
(`/tcf/plan|entrainement|examens`, `/civique/…`) pour que le segment survive et soit adressable.

| Route actuelle | Cible |
|---|---|
| `/` | branche Accueil |
| `/plan` | `/tcf/plan` (segment Plan TCF) |
| `/plan` avec `parcoursCiviqueProvider` | `/civique/plan` |
| `/reviser` | `/tcf/entrainement` (module non déductible de l'URL) |
| `/examens` | `/tcf/examens` |
| `/tcf`, `/civique` | racines d'onglet (→ segment Plan) |
| `/tcf/examens-blancs`, `/civique/examens-blancs` | segment Examens du module |
| `/diagnostic-tcf` | `/tcf/plan` |
| `/progression/**`, `/plan/**`, hubs | même chemin, déclaré dans la branche du module |
| `/profile/**` | branche Profil |

À repointer : 8 `go(AppRoutes.reviser)` et 15 `go(AppRoutes.plan)` (liste dans le rapport mobile ;
ex. `plan_etape_screen.dart:58,89,217`, `exam_report_screen.dart:77`,
`competence_result_screen.dart:1270`). `parcoursCiviqueProvider` / `examensParcoursProvider` :
supprimés (refonte = suppression). `tracked_screens.dart` : nouveaux gabarits mappés sur les
clés **existantes** (`PLAN`, `REVISER`, `EXAMENS_BLANCS`, `ACCUEIL`), et `PLAN_OPENED` (étape 5
du funnel) émis à l'affichage du segment Plan.

### 6.3 Liens entrants

- E-mails : **web uniquement**, tous conservés (§6.1).
- Push : **aucune** notification (ni Firebase ni locale).
- App Link / Universal Link : un seul chemin, `/continuer-sur-app` → `/` ou `/register`. Inchangé.

---

## 7. Écarts maquette / contraintes techniques

1. **Kit obligatoire** (Accueil, Plan, Réviser, cycle, Progression) : chaque nouveau motif
   (`obj-card`, `objectives-card`, `progress-summary`, `hero`, `metric`, `info-card`, `level-row`,
   `timeline`, `theme-card`, `tip-card`, `action-card`, segment rouge) entre **dans les deux kits dans
   la même passe**. Équivalents à faire évoluer plutôt que doubler : `NowCard`/`SfNowCard` (action),
   `Ring`/`SfRing`, `EpreuveRow`, `ExamRow`, `GoalStrip`, `CycleProgress`, `HeroBanner`.
   `/examens-blancs` et `/profil` (hors kit) : restylage local.
2. **Breakpoints web** : le shell bascule à **900 px** (5 fichiers + media queries
   `--app-bar-gap`) ; la maquette à 1180/1024/760/520 avec sidebar 292 px. Le kit interdit une
   « quatrième borne » et plafonne ses colonnes à 1080 px (maquette : 1240 px). Reco : le **shell**
   prend les bornes de la maquette, le **contenu du kit** garde les siennes (une media query n'est
   pas une primitive) ; `split`/`grid-4` sont des primitives web nouvelles.
3. **Topbar desktop** : nouvelle (aujourd'hui aucune barre > 900 px). Fil d'Ariane via
   `lib/app-bar.ts`, flèche de retour des sous-écrans conservée.
4. **Coût de la sidebar** : ses tails demandent ~7 lectures sur chaque page (dashboard, progress,
   progression TCF et civique, exam-slots, journey TCF et civique). Cache partagé obligatoire ; la
   sidebar est montée deux fois (desktop + tiroir) → une seule source de données.
5. **Retour navigateur** : la maquette fait `history.replaceState` ; on utilise de vraies routes.
6. **Mobile — retour Android** : `PopScope(canPop:false)` au niveau du shell → `goBranch(0)` depuis
   une racine d'onglet ≠ Accueil. Depuis Accueil, ouvrir une Progression **change de branche** (l'onglet
   TCF/Civique devient actif, comme la maquette) ; le retour revient alors à l'écran module, pas à
   l'Accueil — conforme §3.2.
7. **Mobile — scroll** : la maquette remonte en haut à chaque changement d'écran ; le brief demande
   de conserver le scroll par onglet. On suit le brief (IndexedStack conserve, changement de segment
   remonte). Le retour depuis Progression revient au **segment d'origine** (la maquette le remet à Plan).
8. **Mobile — vues à démonter** : `PlanTcfView`, `CivicPlanView` et les branches de `ReviserScreen`
   embarquent leur `SfTop` et un toggle de module → extraire des corps sans en-tête.
9. **Contraste ambre** : texte → `--color-amber-dark` / `AppColors.amberDark` (existants).
10. **Graisses** : 850/900 de la maquette → 800 (max Jakarta). Mono à charger en 700 côté web.
11. **Rayons/espacements mobile** : 17/21/28/30 px hors `AppRadii` et hors grille d'espacement du
    `CLAUDE.md` mobile → arrondis aux tokens les plus proches (signalé, pas de nouveau token par valeur).
12. **Constantes en dur existantes (R7)** : 20 créneaux et 40 questions dans
    `tcf_full_exams_screen.dart:45`, `civique_full_exams_screen.dart:27-29` ; miroir figé
    `web/lib/civique-examen.ts`. À remplacer par `slots.length` / `echelle` en phase 4.
13. **Vocabulaire** : « abonnement » visible seulement dans des phrases « sans abonnement » (tarifs,
    passes, plan-unlock) et dans le paywall mobile (hors périmètre). Le Profil dit déjà « Mon pass ».
14. **Test existant à mettre à jour** : `mob/test/plan_navigation_test.dart:11-15` exige 5 onglets
    dont « Plan » → mis à jour ou supprimé (règle : un test rendu rouge par un changement voulu se
    met à jour).
15. **Doc à mettre à jour en phase 2** : `CLAUDE.md` mobile (§ Bottom nav, couleurs de module),
    `web_sejoufr/CLAUDE.md` (arbo `(app)/` périmée), `docs/identite-visuelle.md` (papier, rôle du
    rouge).

---

## 8. Décisions à valider (STOP 1)

### 8.1 Décisions du brief

| # | Sujet | Reco de l'audit | Motif |
|---|---|---|---|
| D1 | Libellés civiques | **A** — Plan / Entraînement / Examens partout | Parité web ⇄ mobile ; « Réviser » disparaît de la nav |
| D2 | Ordre Accueil | **A** — respecter chaque maquette | Écart de mise en page, pas de règle métier |
| D3 | Blocs sans donnée | **B** : afficher « Votre semaine » (`currentStreakDays`), « Examen blanc par thème » (vrai verrou servi), « Entretien en temps réel » (lien hub EO). **Masquer** : Conseil du plan, Analyse IA, Statistiques par thème, Membre depuis | Seuls les trois premiers ont une source |
| D4 | Barre TCF | **B** — avancement du cycle (`etapesTerminees/etapesTotal`, servi) ; « n/4 épreuves au {cible} » en compteur **sans** barre | ⚠️ diffère de la reco du brief : une barre % à côté de « B1 → B2 » est interdite par `docs/regles/progression.md` et refusée par `scripts/verifier-contrat-front-progression.mjs` |
| D5 | Série terminée / total | **A amendé** — terminée au moins une fois ; total = **toutes les séries du thème, toutes mentions** (pas « de la mention ») | Seule définition servie ; B et C impossibles sans backend (§5) |
| D6 | Fraunces | **A** — usage actuel de l'app (web : titres `Top`) | Dépend de X2 côté mobile |

### 8.2 Arbitrages supplémentaires

| # | Sujet | Options | Reco |
|---|---|---|---|
| X1 | Couleur des modules | **A** maquette : TCF bleu, Civique rouge, sur les deux fronts et tous les écrans (y compris hors périmètre qui portent l'ancien code) · **B** garder l'actuel (TCF rouge, Civique bleu) | **A**, avec mise à jour de `identite-visuelle.md` (rouge = couleur du module civique + CTA critiques) |
| X2 | Polices mobile | **A** garder Bricolage + Hanken (l'existant), le brief §8.2 ne vaut que pour le web · **B** revenir à Jakarta/Mono/Fraunces sur tout le mobile | **A** (B = refonte typographique de l'app entière, hors périmètre) — et corriger le `CLAUDE.md` racine qui annonce Jakarta pour le mobile |
| X3 | Test de la fonction % civique | **A** pas de test (règle racine), vérification par `tsc`/`flutter analyze` + règle ajoutée au script `verifier-contrat-front-progression.mjs` · **B** exception explicite : un test par front | **A** |
| X4 | Fonction % civique côté front | **A** calcul front (agrégat de faits servis, fonction unique par front) · **B** reporter le % tant que le serveur ne le sert pas | **A** |
| X5 | URL | **A** garder les URL actuelles (web) et les chemins actuels (mobile) · **B** nouvelles URL `/tcf/…` en web, avec redirections | **A** |
| X6 | Révocation des arbitrages antérieurs (sidebar « comme avant », Accueil scopé, « une seule action dominante », pas de topbar desktop, bas d'Accueil supprimé, ordre mobile ≠ web) | confirmer la révocation | Confirmer |
| X7 | Blocs actuels de l'Accueil | tableau du §4 « Accueil » | Appliquer le tableau |
| X8 | Hero du Plan civique | **A** % de séries (brief) · **B** avancement servi du cycle (existant) | **B** pour le hero (« du parcours » = le cycle dans ce produit) ; le % de séries vit sur l'Accueil, la sidebar, la carte « Ma progression » et l'écran Progression civique. ⚠️ brief §6 dit « 6 emplacements » : on passerait à 5 |
| X9 | Examens : 4 lignes (maquette) vs 20 créneaux servis | garder les 20 créneaux restylés en `exam-row` | Garder 20 (R5 + verrous servis) |
| X10 | Mobile : écrans plein écran `/tcf/examens-blancs`, `/civique/examens-blancs` | rediriger vers le segment Examens · garder | Rediriger (doublon) |
| X11 | Valeurs ABSENTES (« + », « Série n », codes PV/SI…, Membre depuis, Conseil, Analyse IA) | ne pas les afficher ; « Série n » → méta statique ; codes → rang ou libellé servi | Ne pas afficher |
| X12 | Nom du pass | garder le mapping front existant `moduleAccess` → « Pass Intégral / Pass Civique / Découverte » | Garder ; le grep §12 sur « Pass Intégral » doit l'exclure (c'est un libellé d'enum, pas une donnée fictive) |
| X13 | Source unique du niveau cible | `AuthenticatedUser.targetLevel` partout ; supprimer le recalcul `niveauViseTcf()` côté web (`lib/types.ts:3852`) s'il sert l'écran | Oui |
| X14 | `ProgressionBascule` (bascule TCF/Civique dans Progression) | supprimer (redondant avec la nav) | Supprimer |

> ⛔ **STOP 1** — En attente de validation de cet audit, de D1–D6 et de X1–X14. Aucun code ne sera
> écrit avant.
