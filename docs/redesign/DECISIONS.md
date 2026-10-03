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

### DEC-06 — Mobile : boutons du Plan restés bleus en module civique ⚠️ révoquée par DEC-26
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

### DEC-23 — Briques de la maquette : on fait évoluer plutôt que doubler
- Phase : 4
- Contexte : `HeroBanner`/`SfHeroBanner` et `ExamRow`/`SfExamRow` existaient avec un autre dessin et un seul lecteur chacun.
- Options envisagées : A nouvelles primitives à côté · B renommer/refaire (`Hero`/`SfHero`, `ExamRow`/`SfExamRow` au dessin maquette) et migrer le lecteur
- Choix : B. L'historique des cycles passe sur `Hero` (bleu dans les deux parcours : le chiffre accentué rouge vif est illisible sur le dégradé rouge) ; le rapport de diagnostic passe de l'ancien `ExamRow` à `InfoCard`/`SfInfoCard`. `Ring`/`SfRing` gagnent une couleur de module (rendu inchangé sans elle). Ton servi : web `StateTone` (`success|warning|danger|neutral`) ⇄ mobile `SfTone` existant (`ok|warn|hot|muted`) via `SfState`, pas de 2ᵉ enum.
- Fichiers impactés : `SejourKit.tsx`, `sejour.module.css`, `sejour_kit.dart`, `PlanHistoryView.tsx` ⇄ `plan_history_screen.dart`, `DiagnosticReport.tsx` ⇄ `diagnostic_result.dart`
- Réversibilité : moyenne

### DEC-24 — Un seul « niveau actuel » par écran du Plan TCF
- Phase : 4
- Contexte : le bandeau « Niveau actuel → Objectif » du Plan TCF (`GoalStrip`/`CycleGoal`) affichait le niveau de DÉPART du cycle, alors que l'en-tête / la carte « Ma progression » affichent le niveau estimé (`estimatedTcfLevel`). Deux « niveau actuel » différents sur le même écran.
- Options envisagées : A garder les deux · B garder seulement le niveau estimé (celui de l'Accueil et de la sidebar)
- Choix : B, des deux côtés ; le bouton « Choisir mon objectif » que portait le bandeau est conservé. Le bandeau reste sur le Plan civique (pas de doublon là).
- Fichiers impactés : `LearningPlanView.tsx`, `plan_tcf_view.dart`
- Réversibilité : facile

### DEC-25 — « Priorités actuelles » = le cycle existant en cartes de la maquette
- Phase : 4
- Contexte : la maquette montre une liste plate de priorités ; l'existant est un cycle par blocs (frise + accordéons, règles D-64/D-66/D-69).
- Options envisagées : A ajouter une liste de priorités en plus du cycle · B restyler le cycle en cartes `InfoCard` ouvrables (une par bloc), mêmes faits et gestes servis
- Choix : B. La frise et le liseré « bloc courant » disparaissent du Plan (l'écran d'archive d'un cycle les garde). La carte Cycle (`Cycle N`, `x/y`, phrase servie) passe en tête.
- Fichiers impactés : `PlanCycleSection.tsx`, `plan_cycle_section.dart`, `LearningPlanView.tsx`, `plan_tcf_view.dart`
- Réversibilité : moyenne

### DEC-26 — Boutons du Plan civique en rouge (révoque DEC-06 / A46)
- Phase : 4
- Contexte : en phase 2 le mobile avait gardé ces boutons bleus pour réserver le rouge à « Débloquer » (règle autonome A46) ; le web les a passés en rouge comme la maquette.
- Options envisagées : A bleu partout (A46) · B rouge partout (maquette + X1)
- Choix : B — X1 fait du rouge la couleur du module civique ; pour un compte gratuit, le geste de la carte d'action est justement « Débloquer », il reste donc un seul geste dominant. Exception : la carte « Examen blanc civique » du Plan reste une info-card cliquable, sans bouton.
- Fichiers impactés : `CivicPlanPanel.tsx`, vues Plan civique mobile
- Réversibilité : facile

### DEC-27 — Ordre de TCF · Entraînement : grille → Entretien en temps réel → Renforcer mon français
- Phase : 4
- Contexte : la spec plaçait « Renforcer mon français » « sous la grille » ; la maquette web met le hero « Entretien en temps réel » juste après la grille. Les deux agents ont lu différemment.
- Options envisagées : A grille → Renforcer → hero · B grille → hero → Renforcer
- Choix : B des deux côtés (fidélité maquette ; Structure reste un complément, pas une 5ᵉ épreuve).
- Fichiers impactés : `ReviserScreen.tsx`, `reviser_body.dart`
- Réversibilité : facile

### DEC-28 — États d'objectif servis : une fonction par front
- Phase : 4
- Contexte : tuiles, lignes de niveau et cartes de thème doivent porter un état et un ton SERVIS.
- Options envisagées : A libellés de la maquette (« Solide », « Prioritaire »…) · B libellés de l'état servi
- Choix : B. `StatutObjectif` → « Objectif atteint » (success) / « Proche de l'objectif » (warning) / « À renforcer » (danger) ; aucun niveau mesuré → « Non évalué » (neutral, « null = inconnu »). Web `lib/etats-servis.ts` (`etatEpreuveTcf`, `etatThemeCivique`) ⇄ mobile `etatObjectifEpreuve` (`progres_labels.dart`). Les états de thème civique de l'Entraînement gardent la ligne existante (`themeStatus`) en ton neutre ; ceux de la Progression civique = état servi du dernier examen du thème, aucun badge sans examen. « Prioritaire » de la maquette n'existe pas.
- Fichiers impactés : `lib/etats-servis.ts`, `progres_labels.dart`
- Réversibilité : facile

### DEC-29 — Examens : badge « 2/20 » masqué, « réussi » civique retiré, stat civique renommée
- Phase : 4
- Contexte : (1) le badge `{faits}/{total}` doublonnait la tuile « Terminés » et `examensComplets.nombre` compte les rejeux ; (2) la maquette affiche « réussi » dans l'historique civique, mais aucun verdict n'est servi par créneau ; (3) la stat civique « Progression % » était, côté web, une moyenne des maîtrises de thème (`moduleAverage`) et, côté mobile, des créneaux faits en % — deux notions sous le nom du % du parcours.
- Options envisagées : (3) A remplacer par `avancementSeriesCivique` · B renommer en « Terminés x/N » comme la tuile TCF
- Choix : badge masqué ; « réussi » retiré ; (3) B, des deux côtés — aucune seconde notion n'est affichée sous le nom « Progression ». Hero : « Reprendre l'examen n » / « Commencer l'examen n » (1ᵉʳ créneau libre non verrouillé) / « Voir le pass Intégral » si tout est verrouillé / pas de bouton s'il n'y a rien à faire. Constantes 20/40/32/45 en dur supprimées (R7).
- Fichiers impactés : `app/examens-blancs/page.tsx`, `lib/examens-blancs.ts`, `tcf_full_exams_screen.dart`, `civique_full_exams_screen.dart`, `full_exams_labels.dart`
- Réversibilité : facile

### DEC-30 — Écrans Progression : blocs maquette d'abord, existant ensuite
- Phase : 4
- Contexte : l'existant (hero, tuiles, cartes avec sparkline, liste d'examens) n'a pas d'équivalent dans la maquette ; R5 interdit de le perdre.
- Options envisagées : A fondre l'existant dans les blocs maquette · B blocs maquette en tête (Objectif global / Maîtrise globale, Par compétence / Par thème, Évolution / Examens blancs, Prochaine étape), puis les blocs existants inchangés
- Choix : B. « Objectif global » sans barre (règle de progression). Code de thème = rang (pas d'abréviation inventée). Frise plafonnée à 4 repères (plafond d'affichage). « Prochaine étape » = même geste que l'Accueil, code partagé (web `ProchaineEtape.tsx`, mobile `plan/now_card_gestes.dart`). « Analyse IA » masquée.
- Fichiers impactés : `ProgressionTcfView.tsx`, `ProgressionCiviqueView.tsx`, `progression_tcf_screen.dart`, `progression_civique_screen.dart`
- Réversibilité : moyenne (les écrans sont plus longs ; un allègement est à arbitrer après relecture à l'écran)

### DEC-31 — Profil : « Mon compte » sans « Paramètres », carte profil locale
- Phase : 4
- Contexte : la maquette a une entrée « Paramètres » unique ; l'app a « Mes informations » et « Notifications ». La carte profil n'est pas un écran du kit.
- Options envisagées : A créer un écran « Paramètres » · B garder les entrées existantes
- Choix : B — « Mon compte » = Mon pass (+ « paiement unique, aucun renouvellement » si pass actif `oneTime`, web), Mes informations, Notifications, Aide (« Questions fréquentes et contact ») ; Mes favoris gardé (web dans « Mon compte »). Carte profil locale à chaque front (pas de primitive). « Membre depuis » masqué. Nom du pass : `passAccessName` des deux côtés (le mobile perd « Pass TCF » / « Pass actif »).
- Fichiers impactés : `app/(app)/profil/page.tsx`, `profile_screen.dart`, `profile_labels.dart`, `billing_models.dart`
- Réversibilité : facile

### DEC-32 — Descriptions de thème civique affichées
- Phase : 4
- Contexte : l'audit hésitait sur l'existence de `ThemeUserResponse.description`.
- Options envisagées : A masquer · B afficher si non vide
- Choix : B — le champ est servi par le DTO Java, présent dans le miroir mobile, et renseigné pour les 5 thèmes en base ; ajouté au miroir web (`lib/types.ts`, champ optionnel). Masqué si vide.
- Fichiers impactés : `web_sejoufr/lib/types.ts`, `ReviserScreen.tsx`, `reviser_body.dart`
- Réversibilité : facile

### DEC-33 — Emphases de bouton de carte alignées sur la maquette
- Phase : 4 (QA)
- Contexte : le CTA « soft » mobile était teinté du module, la maquette le veut gris ; le web avait trois emphases.
- Options envisagées : A garder la teinte · B `solid | soft | ghost` des deux côtés (soft gris, ghost pour la carte de thème)
- Choix : B.
- Fichiers impactés : `sejour_kit.dart`, `SejourKit.tsx`
- Réversibilité : facile

### DEC-34 — Examens : « Offert » remplacé par le verrou servi, repli à 8, hero civique verrouillé
- Phase : 4 (QA)
- Contexte : la méta « Offert » était déduite du rang n° 1 (interdit : le verrou est servi) ; la liste se repliait à 7 sur le civique mobile et à 8 ailleurs ; le hero civique n'avait pas de bouton quand tout est verrouillé ; le web mettait en avant un autre créneau pendant un examen TCF en cours.
- Options envisagées : A laisser chaque front · B une règle commune
- Choix : B — « Disponible » / « Inclus dans le pass X » (nom via la table des pass) selon `locked` ; repli à 8 ; « Voir le pass Civique » (offre) quand tout est verrouillé, sur le modèle du TCF ; pas de mise en avant d'un autre créneau pendant un examen en cours ; un examen en attente d'évaluation s'affiche « Fait ».
- Fichiers impactés : `app/examens-blancs/page.tsx`, `lib/examens-blancs.ts`, `full_exams_labels.dart`, vues d'examens mobiles
- Réversibilité : facile

### DEC-35 — Tous les boutons du Plan civique suivent le module
- Phase : 4 (QA)
- Contexte : extension de DEC-26 au jalon « examen blanc complet » et au bouton « Commencer » des blocs du cycle ; « À revoir bientôt » mobile avait un bouton bleu.
- Options envisagées : A seulement la carte « À faire maintenant » · B tous les boutons du Plan civique
- Choix : B (`ExamStepAction.module` ⇄ `SfExamStepAction.civique`, variantes `Cta tcf|civique`) ; « À revoir bientôt » en `InfoCard` + badge des deux côtés. Exception laissée : la carte de fin de cycle (`NextStepCard`, dégradé bleu des deux côtés).
- Fichiers impactés : les deux kits, `ExamenCompletJalon`, `plan_cycle_section` web et mobile, `civic_plan_view.dart`
- Réversibilité : facile

### DEC-36 — Tuile d'épreuve sans « Niveau estimé » répété
- Phase : 4 (QA)
- Contexte : la méta de la tuile web répétait « Niveau estimé » sous une valeur qui est déjà ce niveau.
- Options envisagées : A l'ajouter au mobile · B le retirer du web
- Choix : B (doublon).
- Fichiers impactés : `ReviserScreen.tsx`
- Réversibilité : facile

### DEC-37 — Carte « À faire maintenant » du Plan à la couleur du module (après relecture à l'écran)
- Phase : 4 (retour du propriétaire, captures mobiles)
- Contexte : sur le Plan TCF, le bouton « Passer l'épreuve » restait rouge (variante par défaut de `Cta`/`SfButton`) et la pastille d'icône de la carte civique restait bleue.
- Options envisagées : A garder (A46) · B carte entière à la couleur du module
- Choix : B, web et mobile : `NowCard.module` ⇄ `SfNowCard.civique` (pastille d'icône), boutons TCF en variante `tcf`. Corollaire de X1 / DEC-26.
- Fichiers impactés : `SejourKit.tsx`, `sejour.module.css`, `LearningPlanView.tsx`, `CivicPlanPanel.tsx`, `sejour_kit.dart`, `plan_tcf_view.dart`, `civic_plan_view.dart`
- Réversibilité : facile

### DEC-38 — Section « Votre prochain jalon » retirée du Plan TCF (demande du propriétaire)
- Phase : 4 (retour du propriétaire)
- Contexte : le propriétaire demande de retirer cette section du Plan TCF, web et mobile.
- Options envisagées : — (demande explicite)
- Choix : section supprimée des deux Plans TCF, avec ce qui n'avait plus de lecteur (web `PlanMilestoneCard.tsx`, libellés et `planMilestoneTitle/Text/Meta` ; mobile `plan_milestone_labels.dart`, `_milestoneSection`). Conservés : le DTO `milestone` (miroir backend), le lanceur `startPlanMilestone` (encore lu par la séance et l'exercice recommandé) et la pastille `PLAN_MILESTONE_PILL` (lue par `plan-domain.ts`). L'examen reste accessible par TCF · Examens blancs ; le jalon d'examen complet (`ExamenCompletJalon`, D-68) n'est pas concerné.
- Fichiers impactés : `LearningPlanView.tsx`, `lib/diagnostic.ts`, `plan_tcf_view.dart`, `diagnostic_models.dart` (commentaire)
- Réversibilité : facile (historique git)

### DEC-39 — Retraits demandés par le propriétaire après relecture à l'écran
- Phase : 4 (retours du propriétaire)
- Contexte : relecture sur téléphone.
- Options envisagées : — (demandes explicites)
- Choix, web et mobile :
  - Plan TCF et civique : lien « Tout l'entraînement » de « Priorités actuelles » retiré ; « À faire maintenant » passe avant la carte du plan, dont la phrase d'explication est retirée ; côté utilisateur, « cycle » se dit « plan » (« Plan N », « Mes plans »).
  - Plan TCF web : hero « Ma progression » de la colonne droite retiré (absent du segment Plan mobile ; le mobile porte « Ma progression » au-dessus des segments, le web dans la sidebar).
  - Plan civique : hero rouge « Progression globale » et badge « Objectif examen · 32/40 » (web) retirés — **révoque X8 A** : le % civique n'a plus que 5 emplacements (Accueil, carte objectif / ligne d'objectif, tail sidebar, carte « Ma progression » mobile, écran Progression civique).
  - Écrans Progression globaux, mobile : la ligne d'un examen blanc ne montre plus le détail par épreuve / par thème (titre, date, badge, chevron) ; le web le garde au palier large (> 860 px de contenu) et le masquait déjà en dessous.
  - Profil : tuiles « Maîtrise » et « Série » retirées (web + mobile, reste « Niveau estimé ») ; Profil web : colonne « Résumé de préparation » + « Votre semaine » retirée, `ObjectivesCard`/`ObjectiveRow` retirées du kit web (le mobile garde `SfObjectivesCard`, lu par son Accueil).
  - Écrans Progression TCF et civique (globaux) : sections « Par compétence » / « Par thème » retirées (redite des cartes d'épreuve / de thème plus bas), avec `LevelList`/`LevelRow` ⇄ `SfLevelList`/`SfLevelRow`.
  - Écrans Progression TCF et civique (globaux) : bloc « Prochaine étape » retiré (web + mobile) ; `ProchaineEtape.tsx` / `prochaine_etape_hero.dart` supprimés, les gestes partagés (`now-card-gestes`) restent lus par l'Accueil.
  - Plan civique : carte « Examen blanc civique » retirée (l'accès reste par Civique · Examens).
  - Entraînement TCF et civique : carte « Recommandé par votre plan » retirée **sur le mobile seulement** (le Plan est le segment voisin) ; **le web la garde** — écart web ⇄ mobile ASSUMÉ par le propriétaire (sur le web, le Plan est une autre page). Mobile : `reviserResumeTcf/Civique` supprimées ; web : inchangé.
  - TCF · Entraînement : hero « Entretien en temps réel » retiré (D3-B révoqué pour ce bloc ; la simulation reste accessible depuis le hub de l'expression orale).
- Fichiers impactés : `PlanCycleSection.tsx`, `LearningPlanView.tsx`, `CivicPlanPanel.tsx`, `ReviserScreen.tsx`, `lib/module-ecrans.ts`, `lib/journey.ts`, `plan_cycle_section.dart`, `plan_tcf_view.dart`, `civic_plan_view.dart`, `civic_plan_labels.dart`, `reviser_body.dart`, `module_labels.dart`, `journey_labels.dart`
- Réversibilité : facile (historique git)
