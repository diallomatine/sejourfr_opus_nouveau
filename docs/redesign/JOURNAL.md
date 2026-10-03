# Navigation v2 — journal d'implémentation

> Branche `feature/nav-v2` (depuis `develop` d7d8a136). Brief : `BRIEF_NAVIGATION_V2.md`.
> Audit : `AUDIT.md`. Décisions autonomes : `DECISIONS.md`.

## Phase 2 terminée — fondations (2026-10-03)

**Fait**
- Tokens sémantiques de module (X1 : TCF bleu, civique rouge), centralisés : web
  `--color-module-tcf|civique*`, `--gradient-module-*`, ombres teintées, `--sf-radius-2xl..5xl`,
  JetBrains Mono 400→800 ; mobile `AppColors.moduleTcf*|moduleCivique*`, `AppGradients.module*`.
  Les usages existants qui coloraient un module lisent désormais ces tokens.
- Web : nouveau shell `app/_components/shell/` (sidebar maquette avec blocs de module, tails,
  carte utilisateur ; topbar sticky avec fil d'Ariane ; tiroir ≤ 1024 ; bornes 1180/1024/760/520),
  monté par `(app)/layout.tsx` et `DualChromeShell` pour un compte connecté. Ancienne sidebar,
  ancienne topbar, logique 900 px et `--app-bar-gap` supprimées. Bascules de module retirées
  (Plan, Accueil, Progression, `/examens-blancs` pour un compte) ; `/examens-blancs` lit
  `?module=`. URL inchangées (X5).
- Mobile : `StatefulShellRoute.indexedStack` à 4 branches (Accueil · TCF · Civique · Profil),
  écrans de module avec en-tête, carte « Ma progression » et segment Plan | Entraînement |
  Examens en sous-route (`/tcf/plan`…), Progression poussées dans la branche du module avec
  lien retour au segment d'origine, retour Android vers l'Accueil. Anciennes routes redirigées
  (`/plan`, `/reviser`, `/examens`, `/tcf|civique/examens-blancs`, `/diagnostic-tcf`).
  `ProgressionBascule`, `parcoursCiviqueProvider`, `examensParcoursProvider`, `plan_screen`,
  `reviser_screen`, `examens_screen` supprimés.
- Fonction % civique unique, même nom des deux côtés : `avancementSeriesCivique`
  (web `lib/reviser.ts`, mobile `reviser_labels.dart`) → `{pourcentage, terminees, total}`,
  `floor`, 0 si total nul.
- Docs : `docs/identite-visuelle.md` (couleurs de module, papier, polices mobile), `CLAUDE.md`
  racine (règle couleurs/polices).

**Vérifications** : web `tsc` 0 erreur, `npm run build` OK, `npm test` 278/278, script de
contrat conforme, lint 0 erreur sur les fichiers touchés (197 erreurs préexistantes ailleurs,
181 `react/no-unescaped-entities`, une de moins qu'avant) ; mobile `flutter analyze` 0,
`flutter test` 303/303 (`plan_navigation_test.dart` mis à jour pour 4 onglets).

**Checklist §12 (périmètre phase 2)** : hex maquette ✅ · données fictives ✅ · « abonnement » ✅ ·
cocarde + FR rouge ✅ · une URL/route par entrée ✅ · tiroir ✅ · civique rouge (sidebar, fil
d'Ariane, bottom nav, segment) ✅ · anciennes routes ✅ · % civique sur 6 emplacements ⏳ phases
3-4 · états chargement/erreur ⏳ · fidélité visuelle 3 largeurs : non vérifiée à l'écran.

**Points de vigilance**
- Mobile : toute navigation vers un écran d'onglet depuis l'Accueil, le Profil ou un plein écran
  passe par `pousserOuAller` (DEC-03).
- Kits : le web a supprimé `TopSlot`/`ModuleToggle`/`TopInAppBar` ; `SfTopSlot` reste utilisé
  côté mobile (Accueil, Plan civique) — à aligner en phases 3-4.
- Web : écrans hors kit en double gouttière desktop (DEC-11) jusqu'à la phase 4 ; `/examens-blancs`
  affiche encore un « % Progression » civique par `moduleAverage` (2ᵉ règle) → à brancher sur
  `avancementSeriesCivique` ; le Profil web calcule encore la cible via `niveauViseTcf` (X13).
- `CLAUDE.md` web et mobile (shell, bottom nav, couleurs de module) : mis à jour en fin de phase 4.

## Phase 3 terminée — Accueil (2026-10-03)

**Fait**
- Accueil web (`app/(app)/dashboard/page.tsx`, libellés `lib/accueil.ts`) et mobile
  (`screens/home/`) reconstruits sur le kit, contenu de la maquette, données servies :
  kicker `Objectif · {mention}` (`objectifKicker`), « Bonjour {prénom nom} », « Mes objectifs »
  (TCF `{actuel|—} → {cible}`, civique `{pct} %` via `avancementSeriesCivique` ; web : `ObjCard`
  avec barre = avancement du cycle (D4 B), épreuves au niveau cible, cycle ; civique : %,
  séries, seuil), « À faire maintenant » (2 cartes, gestes servis, durée masquée si nulle).
  Ordre propre à chaque maquette (D2 A).
- X7 appliqué : bascule, « Où vous en êtes » et CTA secondaires supprimés ; carte diagnostic en
  cours, invitation objectif et `_IndependenceNote` gardées. `?module=` ignoré sur `/dashboard`.
- États par bloc : squelette, erreur + « Réessayer ».
- Primitives miroirs ajoutées aux deux kits, primitives orphelines retirées (DEC-22).
- `docs/regles/plan.md` : la carte civique de l'Accueil lance l'examen de thème (DEC-18).

**Vérifications** : web `tsc` 0, eslint 0 sur les fichiers touchés, `npm test` 278/278,
`npm run build` OK, contrat de progression conforme ; mobile `flutter analyze` 0,
`flutter test` 303/303. Greps hex maquette / données fictives : rien.

**Checklist §12 (Accueil)** : hex ✅ · données fictives ✅ · « abonnement » ✅ · ordre des blocs ✅ ·
civique rouge ✅ · états chargement/erreur/gratuit/pass ✅ · % civique : 3 emplacements sur 6
(tail sidebar, carte « Ma progression » mobile, Accueil) ⏳ · fidélité visuelle : non vérifiée à
l'écran.

**Points de vigilance**
- Appariement d'en-tête : web `PageHead` ⇄ mobile `SfModuleHeader` (pas de `ModuleHeader` web).
- `ObjectivesCard` attend le « Résumé de préparation » du Profil web (phase 4).
- `/examens-blancs` : « % Progression » civique encore par `moduleAverage` ; Profil web :
  `niveauViseTcf` (X13) — phase 4.

## Phase 4 terminée — re-logement TCF / Civique / Profil (2026-10-03)

**Fait**
- 4a — primitives de la maquette ajoutées aux deux kits, mêmes noms (`Hero`, `InfoCard`,
  `Metric`, `LevelList`/`LevelRow`, `Timeline`, `ThemeCard`, `TipCard`, `ProgressionHead`,
  `ExamRow` refait, `Badge` ⇄ `Sf*`), `Split`/`Grid` côté web seulement (DEC-23).
- 4b — re-logement (4 agents : plans + entraînements, examens + progressions + profil, web et
  mobile) :
  - TCF · Mon plan : carte Cycle → À faire maintenant → jalon → « Priorités actuelles » (cycle
    existant en cartes, DEC-25) ; web : hero « Ma progression » à droite ; bandeau « niveau
    actuel » en double supprimé (DEC-24).
  - Civique · Plan : hero rouge = % de séries (X8 A), carte « Examen blanc civique », boutons à
    la couleur du module (DEC-26/35).
  - Entraînements : tuiles par épreuve (niveau + état servis, DEC-28), « Entretien en temps
    réel » → hub EO, « Renforcer mon français » (DEC-27) ; cartes de thème avec description
    servie (DEC-32) et anneau `avancementSeriesCivique([stat])`.
  - Examens : hero + grille servie de 20 créneaux en `ExamRow`, constantes 20/40/32/45 en dur
    supprimées (R7), badge et « réussi » non servis retirés, stat civique renommée (DEC-29/34).
  - Progressions : blocs maquette en tête (Objectif global sans barre / Maîtrise globale, par
    compétence / par thème, frise, « Prochaine étape » au geste partagé), existant conservé
    dessous (DEC-30).
  - Profil : carte profil, « Mon compte » (Mon pass, Mes informations, Notifications, Aide),
    web : « Résumé de préparation » + « Votre semaine » ; X13 (`targetLevel`) ; `passAccessName`
    partout (DEC-31).
  - Cartes « Ma progression » mobiles : squelette + erreur.
- QA/parité : écarts web ⇄ mobile alignés (ordre des Plans et de l'Entraînement, couleurs du Plan
  civique, emphases de bouton DEC-33, examens DEC-34, mapping d'états unique, gestes « Prochaine
  étape » partagés `now-card-gestes.tsx` ⇄ `now_card_gestes.dart`, nom du pass sur « Mon pass ») ;
  orphelins supprimés (`EpreuveRow`/`SfEpreuveRow`, `epreuveRatio`, `moduleAverage`, libellés
  Réviser…).
- Docs : § « Navigation v2 » en tête de `web_sejoufr/CLAUDE.md` et `mobile_sejourfr/CLAUDE.md`
  (sections historiques marquées « Périmé »), index du `CLAUDE.md` racine, `docs/regles/plan.md`
  (DEC-18).

**Vérifications** : web `tsc` 0 · lint 197 erreurs toutes préexistantes hors chantier, 0 sur les
fichiers du chantier · `npm test` 278/278 · `npm run build` OK · contrat de progression
conforme ; mobile `flutter analyze` 0 · `flutter test` 303/303. Aucun nouveau test (X3).

---

# Livraison finale

## Récapitulatif des 3 phases

| Phase | Commit | Contenu |
|---|---|---|
| 2 — Fondations | `b9861eb8` | Tokens de module (TCF bleu / civique rouge), shell web (sidebar à modules, topbar, tiroir, bornes maquette), 4 onglets mobiles (`StatefulShellRoute`), segments en sous-routes, redirections, `avancementSeriesCivique` |
| 3 — Accueil | `2e943b24` | Accueil web et mobile sur la maquette, données servies, états par bloc, primitives miroirs |
| 4 — Re-logement | (ce commit) | Primitives maquette, 9 écrans × 2 fronts re-logés, QA de parité, nettoyage, docs |

Branche `feature/nav-v2`, **non fusionnée, non déployée** (DEC-01).

## Checklist §12 du brief

- [x] **Aucun hex de la maquette dans le code** — grep des 11 valeurs sur `web_sejoufr/app`,
  `web_sejoufr/lib`, `mobile_sejourfr/lib` : 0.
- [x] **Aucune donnée fictive** — « Abdoul », « 34 % », « 17/43 », « 91 % » : 0 (les seuls « 34% »
  sont des `color-mix` CSS). Les noms de pass viennent de la table `PASS_MODULE_NAME` via
  `passAccessName` (X12) ; « Pass Intégral » écrit en dur ne subsiste que sur des pages hors
  périmètre (`/tarifs`, landing, `/reussir`, `PassOffers`).
- [x] **« abonnement » absent côté utilisateur** dans le périmètre — restent des négations
  (« sans abonnement ») et, hors périmètre, le paywall mobile et un `aria-label` de `/paiement`.
  La route `/profil/abonnement` (URL, non affichée) est conservée pour les liens d'e-mails.
- [x] **Logo cocarde + « FR » rouge dans la sidebar** (`Brand`/`Cocarde` existants).
- [ ] **Structure identique aux maquettes, 3 largeurs + mobile** — vérifiée dans le code
  seulement : **aucune vérification à l'écran** (ni navigateur, ni simulateur). À faire par toi.
  Écarts assumés et documentés : DEC-10 (rayons/tailles mobiles arrondis), DEC-24/25/30, X11
  (blocs sans donnée masqués).
- [x] **Une URL / route par entrée ; retour navigateur et Android** — web : URL actuelles
  (`?module=`) ; mobile : sous-routes de segment, `PopScope` du shell. Non éprouvé à l'écran.
- [x] **Tiroir web** : ouverture, overlay, fermeture à la navigation, Échap, scroll du body bloqué
  (code ; non éprouvé à l'écran).
- [x] **Civique actif en rouge** : bottom nav, segment, sidebar, fil d'Ariane (+ boutons du Plan
  civique, DEC-26/35).
- [~] **% civique identique sur les 6 emplacements, web = mobile** — oui : tous appellent
  `avancementSeriesCivique` (Accueil, carte objectif / ligne d'objectif, tail sidebar, carte
  « Ma progression » mobile, hero Plan civique, Progression civique ; + Entraînement et Profil),
  aucune seconde formule. **Tests unitaires : non, par arbitrage X3** (aucun nouveau test front).
- [x] **États chargement / vide / erreur / gratuit / pass** — squelettes et erreur + « Réessayer »
  par bloc, « — » / 0 % / états vides, verrous et gestes servis (code ; non éprouvé à l'écran).
- [x] **Anciennes routes et liens d'e-mails, aucun 404** — web : aucune route supprimée, liens
  d'e-mails (`EmailLinks.java`) intacts ; mobile : anciennes routes redirigées ; aucune
  notification push n'existe.
- [x] **Aucune donnée ni fonctionnalité perdue** — retraits volontaires, tous documentés :
  bascules de module (X14, DEC-13), « Où vous en êtes » et CTA secondaires de l'Accueil (X7),
  bandeau de niveau du Plan TCF (DEC-24), frise du cycle sur le Plan (DEC-25), stat
  « Progression % » civique renommée et « réussi » civique (DEC-29), carte streak de la sidebar
  (→ Profil), « Pass TCF » / « Pass actif » mobiles (DEC-31).

## DEC à relire en priorité (réversibilité moyenne ou difficile)

- **DEC-02** — sous-écrans du Plan mobiles déplacés sous chaque module (`/tcf/plan/…`,
  `/civique/plan/…`), entorse à X5.
- **DEC-05** — écrans mobiles laissés en plein écran (paywall, bilan de série, grille EE/EO).
- **DEC-22** — primitives de l'ancien Accueil supprimées des deux kits.
- **DEC-23** — `HeroBanner`/`ExamRow` refaits plutôt que doublés.
- **DEC-25** — « Priorités actuelles » = cycle restylé, frise retirée du Plan.
- **DEC-30** — écrans Progression plus longs (maquette + existant) : un allègement est à arbitrer
  après relecture à l'écran.
- Et, bien que faciles à défaire, à confirmer : **DEC-01** (pas de déploiement), **DEC-18**
  (l'Accueil lance l'examen de thème — règle de `plan.md` modifiée), **DEC-20** (pas de texte
  d'invitation dédié pour un compte neuf), **DEC-26** (révoque A46 : rouge sur le Plan civique).

## Reste à faire / hors périmètre

- **Vérification à l'écran** (web 1280 / 900 / 390, simulateur) : rien n'a été regardé.
- **Écarts de parité restants** (QA, à arbitrer) :
  - Accueil, carte civique sur une étape « série » du plan dérivé : le mobile lance la série,
    le web mène au Plan civique.
  - Examens TCF : 4 tuiles de stats sur le web (dont « Niveau estimé »), 3 sur le mobile.
  - Profil : ordre « Supprimer » / « Se déconnecter », badge de démarche (code ⇄ libellé),
    table de démarches locale web (`PROCEDURE_INFO`), textes des modales ; « Résumé de
    préparation » et « Votre semaine » présents sur le web seulement (absents de la maquette
    mobile).
  - Intitulés propres à chaque maquette (« Les 4 épreuves » ⇄ « Choisir une épreuve », kickers
    des Progressions).
  - Carte de fin de cycle (`NextStepCard`) restée bleue en civique.
- **Données absentes, masquées** (nécessiteraient le backend) : « Membre depuis », « Série n »,
  codes de thème, demi-paliers « + », « Conseil du plan », « Analyse IA », « Statistiques par
  thème », total de séries par mention.
- **Lint web** : 197 erreurs préexistantes (181 `react/no-unescaped-entities`), hors chantier.
- **Exports sans lecteur antérieurs au chantier** (`SkillList`, `PillMeta`, `SfPathCard/Row`,
  `SfSkillRow`, `SfPillMeta`, `SfEmphasis`, quelques `kPlan*`) : non traités.
- **Mise en prod** : fusion `feature/nav-v2` → `develop` puis `deploy_web.sh` ; le mobile part
  par les stores (publication par toi). Aucun changement backend.
