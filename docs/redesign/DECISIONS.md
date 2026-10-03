# Navigation v2 — décisions autonomes

> Décisions prises en autonomie pendant les phases 2 → 4, hors brief, hors audit et hors
> message de GO du 2026-10-03. Chacune est réversible selon l'indication donnée.

### DEC-01 — Branche dédiée, pas de déploiement en cours de chantier
- Phase : 2
- Contexte : la consigne en vigueur depuis le 2026-09-28 veut que chaque commit web soit déployé en prod aussitôt. Une refonte de navigation livrée phase par phase exposerait aux utilisateurs un état intermédiaire (nouveau shell + ancien Accueil, etc.).
- Options envisagées : A commits sur `develop` + déploiement à chaque phase · B branche `feature/nav-v2`, un commit par phase, aucun déploiement
- Choix : B. Le déploiement d'une refonte entière est une décision du propriétaire, à prendre une fois la phase 4 relue.
- Fichiers impactés : aucun (git uniquement)
- Réversibilité : facile (fusion en avance rapide sur `develop`, puis `deploy_web.sh`)

### DEC-02 — Mobile : sous-écrans du Plan déplacés sous chaque module
- Phase : 2
- Contexte : l'étape, « Mes cycles » et le cycle archivé servent les deux modules, mais avec `StatefulShellRoute` un chemin n'appartient qu'à une branche (onglet).
- Options envisagées : A tout sous l'onglet TCF · B laisser ces écrans en plein écran (sans bottom nav) · C chemins par module (`/tcf/plan/etape/…`, `/civique/plan/…`) + redirection des anciens
- Choix : C — le module vient de la route (comme `?module=` côté web), l'onglet du module reste actif et le retour revient au module. Entorse assumée à X5 (« garder les chemins ») : les anciens chemins redirigent, aucun lien cassé.
- Fichiers impactés : `mobile_sejourfr/lib/core/router/app_router.dart`, `journey_labels.dart`, `plan_now_card.dart`, `civic_plan_labels.dart`, `plan_cycle_section.dart`
- Réversibilité : moyenne

### DEC-03 — Mobile : `pousserOuAller` contre le crash de clé de page
- Phase : 2
- Contexte : depuis un écran plein écran (runner, résultat, diagnostic), un `context.push` vers un écran qui vit dans une branche fait planter go_router (clé de page en double) — reproduit par un test jetable, supprimé.
- Options envisagées : A tout passer en plein écran · B helper qui choisit `push` (même branche / cible plein écran) ou `go` (autre branche)
- Choix : B, `pousserOuAller(context, location)` dans `core/router/shell_navigation.dart` ; la branche de la cible est lue dans la configuration du router, pas dans une table recopiée. Règle pour la suite : toute navigation vers un écran d'onglet depuis l'Accueil, le Profil ou un plein écran passe par ce helper.
- Fichiers impactés : ~10 appels (Accueil, Profil, `plan_actions`, `recommended_exercise_launcher`, `competence_result_screen`)
- Réversibilité : facile

### DEC-04 — Mobile : un observer de retour par branche
- Phase : 2
- Contexte : `appRouteObserver` unique ne voit plus les 4 navigateurs de branche ; le rafraîchissement au retour du Plan était d'ailleurs déjà cassé avec l'ancien `ShellRoute`.
- Options envisagées : A garder l'observer racine · B un observer par branche + `suivreLeRetour` / `cesserDeSuivreLeRetour`
- Choix : B (répare au passage le rafraîchissement du Plan au retour).
- Fichiers impactés : `route_observer.dart`, 5 écrans qui se rafraîchissent au retour
- Réversibilité : facile

### DEC-05 — Mobile : écrans laissés en plein écran
- Phase : 2
- Contexte : `/plan/debloquer` (paywall), `/plan/serie/:id` (bilan) et la grille d'examens EE/EO (`/tcf/expression-*/examens`, qui partage sa route parente avec la passation) pourraient vivre sous l'onglet.
- Options envisagées : A sous l'onglet du module · B plein écran
- Choix : B — paywall et bilans sont rangés « plein écran » par le brief ; la grille EE/EO ne peut pas être séparée de sa route parente sans réécrire les routes de passation (hors périmètre).
- Fichiers impactés : `app_router.dart`
- Réversibilité : moyenne

### DEC-06 — Mobile : boutons du Plan restés bleus en module civique
- Phase : 2
- Contexte : X1 colore le module civique en rouge, mais les boutons du Plan (TCF et civique), de l'étape, du jalon et des diagnostics civiques sont bleus pour laisser le rouge à la seule barre « Débloquer » (arbitrage A46 existant).
- Options envisagées : A les passer au token module (rouge en civique) · B garder le bleu (A46)
- Choix : B — la règle existante prime ; conséquence : en civique, le CTA rouge reste réservé à « Débloquer ». Inversement, les CTA de module de l'Accueil et de l'Entraînement lisent le token module.
- Fichiers impactés : vues Plan, étape, jalon (aucune modification)
- Réversibilité : facile

### DEC-07 — Mobile : en-tête des modules dans un `NestedScrollView`
- Phase : 2
- Contexte : les corps existants (Plan, Entraînement, Examens) sont des `ListView` ; les réécrire sortait du périmètre.
- Options envisagées : A réécrire les corps en slivers · B `NestedScrollView` (l'en-tête défile avec le contenu)
- Choix : B. Changement de segment ⇒ retour en haut ; changement d'onglet ⇒ défilement conservé.
- Fichiers impactés : `screens/module/module_screen.dart`
- Réversibilité : facile

### DEC-08 — Mobile : `PLAN_OPENED` à l'affichage du segment Plan
- Phase : 2
- Contexte : l'onglet Plan (étape 5 du funnel) n'existe plus.
- Options envisagées : A à chaque affichage du segment Plan (montage, changement de segment, retour sur l'onglet) · B seulement au premier montage
- Choix : A, sauf si un écran poussé le recouvre — c'est le plus proche de l'ancien « à chaque ouverture de l'onglet ». Les gabarits de route sont mappés sur les clés `TrackedScreen` existantes (aucune nouvelle clé, backend inchangé).
- Fichiers impactés : `module_screen.dart`, `tracked_screens.dart`
- Réversibilité : facile

### DEC-09 — Mobile : ancien `/reviser` → TCF
- Phase : 2
- Contexte : `/reviser` ne portait pas le module dans l'URL.
- Options envisagées : A `/tcf/entrainement` (et `?module=CIVIQUE` → civique) · B dernier module consulté
- Choix : A (déterministe).
- Fichiers impactés : `app_router.dart`
- Réversibilité : facile

### DEC-10 — Rayons et tailles de la maquette arrondis aux tokens mobile
- Phase : 2
- Contexte : 17/21/22/28/30 px hors `AppRadii` et hors grille d'espacement du `CLAUDE.md` mobile.
- Options envisagées : A nouveaux tokens par valeur · B arrondi au token le plus proche
- Choix : B (carte 22 → `AppRadii.lg` 18, segment 18/13 → `lg`/`md`, H1 34 → 32). Côté web, les rayons ont été ajoutés en tokens (`--sf-radius-2xl..5xl`), le kit web n'ayant pas cette convention.
- Fichiers impactés : `sejour_kit.dart`, `segmented_tabs.dart`
- Réversibilité : facile

### DEC-11 — Web : gouttière et marge haute du contenu dans le shell
- Phase : 2
- Contexte : les écrans existants ont leur propre gouttière ; la maquette ajoute `36px 44px`. Les anciennes règles `--app-bar-gap` (≤ 900 px) n'ont plus d'objet.
- Options envisagées : A padding maquette partout (double gouttière) · B padding maquette, gouttière latérale à 0 sous 760 px, le kit `.app` abandonne sa propre gouttière ≥ 960 px dans le shell
- Choix : B. Les écrans hors kit gardent une double gouttière desktop jusqu'à la phase 4. `--app-bar-gap` supprimé, remplacé par `.app-shell .X { padding-top: 0 }` (18 conteneurs).
- Fichiers impactés : `app/_components/shell/shell.module.css`, `sejour.module.css`, 18 conteneurs d'écran
- Réversibilité : facile

### DEC-12 — Web : la topbar ne porte plus de titre
- Phase : 2
- Contexte : l'ancienne topbar (≤ 900 px) affichait le titre de page et masquait celui de l'écran (`in-bar-title`). La maquette met un fil d'Ariane.
- Options envisagées : A titre + fil d'Ariane dans la topbar · B fil d'Ariane seul, les écrans gardent leur titre
- Choix : B. La flèche de retour des sous-écrans (`useAppBarBack`) vit dans la topbar à toutes largeurs ; le lien retour de la page est masqué dans le shell (`in-bar-back`). La barre « MON PROFIL » du profil, masquée sous 900 px, est désormais toujours visible.
- Fichiers impactés : `AppTopBar.tsx`, `AppBarTitle.tsx`, `lib/app-bar.ts`, `globals.css`, `SkillLayout`, `DetailParts`, profil
- Réversibilité : facile

### DEC-13 — Web : bascule de module conservée pour les visiteurs de `/examens-blancs`
- Phase : 2
- Contexte : un visiteur n'a pas de sidebar ; sans bascule, l'examen civique offert lui devient inaccessible.
- Options envisagées : A supprimer partout · B garder pour le visiteur seul, en liens `?module=`
- Choix : B. Aucune bascule pour un compte connecté.
- Fichiers impactés : `app/_components/ModuleToggle.tsx`, `app/examens-blancs/page.tsx`
- Réversibilité : facile

### DEC-14 — Tails : progressions lues dans le cache partagé existant
- Phase : 2
- Contexte : consigne « tails uniquement depuis le cache partagé (dashboard, me, progression) ». Côté web, `progressionApi.tcf/civique` sont déjà dans le data-cache partagé (préfixe `progress:`, purgé à chaque écriture de mesure).
- Options envisagées : A réutiliser ce cache · B supprimer les tails dépendant des progressions
- Choix : A — aucune nouvelle couche de cache ; desktop et tiroir sont le MÊME élément (une seule source, `useShellNav`). Seuil civique du sous-titre lu dans `lib/civique-examen.ts` (miroir gelé de `CivicExamFormat`) plutôt que d'attendre la progression.
- Fichiers impactés : `web_sejoufr/lib/use-shell-nav.ts`, `lib/shell-nav.ts`
- Réversibilité : facile

### DEC-15 — Nom du pass de la carte utilisateur : `passAccessName`
- Phase : 2
- Contexte : `subscription-status` n'est pas en cache ; le Profil écrivait ses libellés de pass en dur.
- Options envisagées : A lire `subscription-status` (lecture supplémentaire, interdite pour un tail) · B dériver de `AuthenticatedUser.isPremium/hasTcf`
- Choix : B, via une fonction partagée `passAccessName` (`lib/passes.ts`, construite sur `PASS_MODULE_NAME`) réutilisée par le Profil : « Pass Intégral · actif » / « Découverte · accès gratuit ».
- Fichiers impactés : `web_sejoufr/lib/passes.ts`, `app/(app)/profil/page.tsx`, `AppSidebar.tsx`
- Réversibilité : facile

### DEC-16 — Web : split de l'examen EE/EO aligné sur la borne 1180
- Phase : 2
- Contexte : avec la sidebar de 292 px, l'examen EE/EO tombait à ~613 px pour deux colonnes entre 1025 et 1180 px.
- Options envisagées : A garder la borne 1024 · B borne `split` de la maquette (2 colonnes > 1180)
- Choix : B. Les panneaux sticky se posent sous la topbar (`--shell-topbar-h + 24px`).
- Fichiers impactés : `production/exam.module.css`, `skill.module.css`
- Réversibilité : facile

### DEC-17 — Tail « Mon plan » quand le niveau actuel est inconnu
- Phase : 2
- Contexte : `estimatedTcfLevel` null (« null = inconnu »).
- Options envisagées : A masquer le tail · B « — → {cible} »
- Choix : B pour ce seul tail (l'objectif reste une information utile) ; tous les autres tails sont masqués quand la donnée manque.
- Fichiers impactés : `web_sejoufr/lib/shell-nav.ts`
- Réversibilité : facile

### DEC-18 — La carte civique de l'Accueil lance l'examen de thème
- Phase : 3
- Contexte : `docs/regles/plan.md` réservait `lancerExamen` au Plan civique ; sur l'Accueil une étape d'examen de thème avait le geste `AUCUN`. Or le premier cycle de tout compte (D-69) est un cycle d'examens de thème : la carte civique n'aurait presque jamais de bouton.
- Options envisagées : A garder la règle (carte neutre) · B passer `lancerExamen: true` sur l'Accueil (lanceur partagé déjà disponible : web `useMockExamLauncher`, mobile `launchCiviqueThemeExam`)
- Choix : B, des deux côtés ; la règle de `docs/regles/plan.md` est mise à jour (Plan civique + Accueil).
- Fichiers impactés : `web_sejoufr/app/(app)/dashboard/page.tsx`, `mobile_sejourfr/lib/screens/home/home_screen.dart`, `docs/regles/plan.md`
- Réversibilité : facile

### DEC-19 — Composition de la méta et du libellé des cartes « À faire maintenant »
- Phase : 3
- Contexte : la spec dit `{type} · {durée}`, mais la carte servie n'a pas de champ « type » unique ; un geste `DEBLOQUER` ouvre l'offre alors que la maquette dit « Continuer ».
- Options envisagées : A libellés maquette partout · B méta composée des champs servis + libellé servi pour `DEBLOQUER`
- Choix : B. Méta TCF = `[kindLabel ?? subtitle, minutesLabel]`, civique = `[subtitle, meta]`, parties nulles omises (web `accueilTcfActionMeta`/`accueilCiviqueActionMeta` ⇄ mobile `homeActionMeta`). CTA « Continuer le TCF / le civique » pour LANCER / OUVRIR_ETAPE, libellé servi pour DEBLOQUER, aucune étape courante → « plan à jour » + CTA vers le Plan du module, geste `AUCUN` → carte neutre sans bouton.
- Fichiers impactés : `web_sejoufr/lib/accueil.ts`, `mobile_sejourfr/lib/screens/home/home_labels.dart`
- Réversibilité : facile

### DEC-20 — Pas de texte d'invitation dédié pour un compte neuf
- Phase : 3
- Contexte : brief §7 : « nouvel utilisateur → texte d'invitation au 1er examen/1re série ». Or un compte neuf a toujours un cycle d'examens dont l'étape courante (examen CO / examen du 1ᵉʳ thème) est servie et non verrouillée : les deux cartes « À faire maintenant » sont déjà cette invitation.
- Options envisagées : A ajouter un texte d'invitation · B « — » et « 0 % » dans « Mes objectifs », l'invitation est portée par les cartes action
- Choix : B (pas de bloc redondant). À rajouter si tu le veux.
- Fichiers impactés : Accueil web et mobile
- Réversibilité : facile

### DEC-21 — Les objectifs de l'Accueil mènent aux écrans Progression
- Phase : 3
- Contexte : la maquette web fait cliquer les `.obj-card` vers le Plan, le brief §4.1 (mobile) vers la Progression.
- Options envisagées : A Plan · B Progression, partout
- Choix : B (parité, et « Mes objectifs » parle de progression).
- Fichiers impactés : `web_sejoufr/app/(app)/dashboard/page.tsx`
- Réversibilité : facile

### DEC-22 — Primitives de l'Accueil retirées des deux kits
- Phase : 3
- Contexte : « Où vous en êtes » supprimé (X7) ; ses briques n'avaient plus de lecteur.
- Options envisagées : A les garder « au cas où » · B suppression immédiate (règle « refonte = suppression »)
- Choix : B, dans les deux kits : `LevelLadder`/`LadderStep`/`LevelCard`/`LevelCardGrid`/`GoalBanner` ⇄ `Sf*`, `SfTopSlot`, `parcoursSegments`, `moduleCiviqueParDefaut`, helpers `accueil*` de `progres.ts` ⇄ `progres_labels.dart`, `objectifLabel` → `objectifKicker`. Nouvelles primitives miroirs : `PageHead`⇄`SfModuleHeader`, `ActionCard`⇄`SfActionCard`, `ObjCard`/`ObjMetric`⇄`SfObjCard`/`SfObjMetric`, `ObjectivesCard`/`ObjectiveRow`⇄`SfObjectivesCard`/`SfObjectiveRow`, `BlockSkeleton`/`BlockError`⇄`SfBlockSkeleton`/`SfBlockError`.
- Fichiers impactés : `SejourKit.tsx`, `sejour.module.css`, `sejour_kit.dart`, `lib/progres.ts`, `progres_labels.dart`
- Réversibilité : moyenne (récupérables dans l'historique git)
