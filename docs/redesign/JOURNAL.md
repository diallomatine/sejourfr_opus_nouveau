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
