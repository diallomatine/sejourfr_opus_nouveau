# SejourFR Mobile — Guide pour Claude Code

Ce projet est l'application mobile **SejourFR**, une plateforme d'entraînement aux examens civique et TCF pour
les étrangers en France qui préparent leur titre de séjour (CSP), leur carte de résident (CR) ou leur
naturalisation (NAT).

L'app sert d'**entraînement par QCM** (pas de cours magistral) : l'utilisateur répond à des questions proches
des examens réels, reçoit une correction expliquée après chaque réponse, et peut passer des examens blancs en
conditions réelles.

## Stack technique

- **Flutter 3.6+ / Dart 3.6+**
- **Riverpod 2** (`flutter_riverpod`) pour le state management
- **Dio 5** pour les appels HTTP (avec intercepteurs JWT + refresh automatique)
- **go_router 14** pour le routing déclaratif avec guards d'auth
- **flutter_secure_storage** pour les tokens (Keychain iOS / EncryptedSharedPreferences Android)
- **google_fonts** pour Plus Jakarta Sans, Fraunces, JetBrains Mono
- **just_audio** + **video_player** pour les médias TCF (compréhension orale, images, vidéos)

Pas de Bloc, pas de Provider classique, pas de GetX. **Tout en Riverpod.**

## Architecture

Organisation **par feature**, comme le backend Spring Boot et le React admin :

```
lib/
├── main.dart                      Entry point + verrouillage portrait
├── app.dart                       MaterialApp.router + theme + ProviderScope
│
├── core/                          Transverse à toutes les features
│   ├── api/                       HTTP + repositories
│   │   ├── api_client.dart        Client Dio (intercepteurs JWT, refresh auto)
│   │   ├── api_config.dart        Base URL via dart-define
│   │   ├── api_exception.dart     ApiException typée
│   │   ├── auth_repository.dart
│   │   ├── themes_repository.dart
│   │   ├── attempts_repository.dart
│   │   ├── user_content_repository.dart
│   │   └── repositories.dart      Providers Riverpod
│   ├── auth/
│   │   ├── token_storage.dart     Persistance sécurisée des tokens
│   │   └── auth_controller.dart   AuthState + StateNotifier
│   ├── models/                    DTOs miroirs des DTOs backend
│   │   ├── enums.dart             AppModule, Difficulty, QuestionType, MediaType, UserRole
│   │   ├── auth_models.dart
│   │   ├── question_models.dart
│   │   └── attempt_models.dart
│   ├── router/
│   │   └── app_router.dart        Routes + redirects auth
│   ├── theme/
│   │   └── app_theme.dart         Couleurs, typographies, Material theme
│   ├── utils/
│   │   └── selected_module.dart   Provider du module actif (CIVIQUE/TCF)
│   └── widgets/                   Primitives UI réutilisables
│       ├── sejourfr_logo.dart     Cocarde + Wordmark + Tagline
│       ├── app_button.dart        Primary / Secondary / Ghost / Danger
│       ├── app_card.dart
│       ├── app_tag.dart           Tags CSP/CR/NAT/A2/B1/B2/...
│       └── eyebrow.dart           Petits labels mono majuscule
│
└── screens/                       Une feature = un dossier
    ├── splash/
    ├── auth/                      login, register, forgot
    ├── home/
    │   └── widgets/               module_switch.dart
    ├── shell/
    │   └── main_shell.dart        Bottom nav 5 onglets : Accueil · Civique · TCF · Progression · Profil
    ├── hub/
    │   └── widgets/hub_widgets.dart  Widgets partagés des 2 hubs (topbar, hero, progress, module card, exam card)
    ├── civique/
    │   └── civique_screen.dart    Hub Civique : hero bleu + progress + 5 thèmes officiels + exam card inactive
    ├── tcf/
    │   └── tcf_screen.dart        Hub TCF : hero rouge + progress + 4 modules (CO/CE/EE IA/EO IA) + exam card inactive
    ├── module_detail/             Écran détail intermédiaire entre hub et runner / production hub
    │   ├── civique_theme_detail_screen.dart   Détail d'un thème civique (par themeId)
    │   ├── tcf_qcm_detail_screen.dart         Détail TCF CO/CE (enum TcfQcmModule) — onglet Séries = cards niveau
    │   ├── tcf_level_lots_screen.dart         Liste des lots pour un (module CO/CE, niveau A2/B1/B2)
    │   ├── tcf_lot_result_screen.dart         Bilan affiché à la fin d'un lot (score circle + résumé + CTAs)
    │   ├── tcf_production_detail_screen.dart  Détail TCF EE/EO (enum TcfProductionModule) → ProductionHubScreen
    │   └── widgets/module_detail_widgets.dart Layout partagé (topbar, hero, stats, score card)
    ├── exam/                      Écrans de résultat et rapport d'examen blanc (le setup a été supprimé,
    │                              le tirage d'examen blanc se fera depuis la carte sombre des hubs)
    ├── question_runner/           Le runner partagé (le cœur de l'app)
    │   ├── runner_controller.dart Riverpod controller avec state d'attempt
    │   ├── runner_screen.dart
    │   └── widgets/
    │       ├── audio_player.dart  SejourAudioPlayer (just_audio)
    │       ├── question_media_view.dart Dispatch image/audio/vidéo
    │       ├── choice_tile.dart   4 états visuels
    │       ├── exam_timer.dart    Chrono décompte
    │       └── explanation_box.dart Bloc correction post-réponse
    ├── tcf_production/            EO + EE (productions évaluées par IA)
    │   ├── audio_recorder_service.dart  record 6 + permission_handler + audio_session
    │   ├── draft_service.dart           Brouillon EE en SharedPreferences
    │   ├── ee_session_controller.dart   Session EE (1 ou 3 tâches, attempt parent partagé)
    │   ├── eo_session_controller.dart   Session EO (idem)
    │   ├── ee_briefing_writing_screen.dart  Briefing + zone d'écriture combinés
    │   ├── eo_briefing_screen.dart      + recording + finished + results screens
    │   ├── history_session_screen.dart  Bilan détaillé d'une session (live ou historique) :
    │   │                                hero CECRL + détail par tâche tappable, polling
    │   │                                automatique sur les évals IA quand `?live=1`
    │   └── widgets/                     production_app_header, donut_chart_score,
    │                                    mots_card, writing_zone, criterion_row,
    │                                    feedback_block, transcription_section, etc.
    ├── review/                    Favoris + erreurs récentes (tabs)
    └── profile/                   Compte + paramètres + logout
```

**Règle simple** : si une feature a son domaine métier (login, training, exam, runner...), elle a son dossier
dans `screens/`. Les widgets vraiment génériques (boutons, tags, cards) montent dans `core/widgets/`. Les
widgets locaux à une feature restent dans `screens/<feature>/widgets/`.

## Identité visuelle

Couleurs officielles (toutes dans `core/theme/app_theme.dart`) :

- **Bleu France** : `#1E3A8C` (foncé : `#15296B`, clair : `#E8ECF8`, très clair : `#F4F6FC`)
- **Rouge France** : `#E1372F` (foncé : `#B5251E`, clair : `#FDECEB`)
- **Ink** : `#0F1839` (texte principal)
- **Muted** : `#6B7299` / `#9CA2BD` (secondaire)
- **Vert succès** : `#168F5B`
- **Ambre** : `#E8A317`

Typographies :

- **Plus Jakarta Sans** (corps, boutons, navigation) — poids 400 à 800
- **Fraunces** (titres éditoriaux, italiques décoratives) — poids 500/600
- **JetBrains Mono** (eyebrows, labels techniques, badges) — taille 10-11 avec letter-spacing

**Le logo** est un lockup de 3 composants : `Cocarde` (3 cercles concentriques bleu/blanc/rouge),
`SejourFrWordmark` ("Sejour" en bleu + "FR" en rouge), `SejourFrTagline` ("EXAMEN CIVIQUE · TCF"). Tous trois
exposés dans `core/widgets/sejourfr_logo.dart`. Pour l'écran d'accueil/splash, utiliser le helper
`SejourFrLogoLockup` qui combine les trois.

**Ne jamais hardcoder une couleur** ailleurs que dans `app_theme.dart` — toujours utiliser `AppColors.blue`,
`AppColors.red`, etc. Idem pour les polices : passer par les helpers `AppFonts.jakarta(...)`,
`AppFonts.fraunces(...)`, `AppFonts.mono(...)`.

## Backend

L'API Spring Boot 4 / Java 21 tourne en parallèle, sur `http://localhost:8080` par défaut. L'URL est
paramétrée via `--dart-define=API_BASE_URL=...`.

**Attention émulateurs** : sous Android emulator, `localhost` pointe sur l'émulateur lui-même, pas la machine
hôte. Utiliser `http://10.0.2.2:8080`. Sous iOS simulator, `localhost` fonctionne normalement.

Endpoints utilisés (à implémenter côté backend si pas encore fait) :

- `POST /api/auth/login`, `POST /api/auth/register`, `POST /api/auth/refresh`, `GET /api/auth/me`,
  `POST /api/auth/forgot-password`
- `GET /api/themes?module=CIVIQUE|TCF`
- `POST /api/attempts` (StartAttemptRequest), `GET /api/attempts/{id}`, `POST /api/attempts/{id}/answers`,
  `POST /api/attempts/{id}/finish`
- `GET /api/me/questions/favorites?module=...`, `POST/DELETE /api/me/questions/{id}/favorite`
- `GET /api/me/questions/wrong?module=...`
- `GET /api/me/stats?module=...`

**Auth JWT** : access token + refresh token. Le refresh est automatique au niveau de `ApiClient` quand une
requête prend un 401 — pas besoin de le gérer dans les controllers ou les écrans.

Les types Dart dans `core/models/` sont **alignés à la main** sur les DTOs Java du backend. Quand le backend
change un DTO, mettre à jour le model Dart correspondant.

## Conventions de code

**Style général**

- Dart strict (mode null-safety), pas de `dynamic` sauf interop JSON.
- `class` en `PascalCase`, fichiers en `snake_case.dart`, dossiers en `snake_case`.
- Imports relatifs sauf pour les packages tiers.
- Pas de commentaires inutiles, code expressif d'abord. Les commentaires servent à expliquer le **pourquoi**,
  pas le quoi.

**Widgets**

- `StatelessWidget` par défaut, `StatefulWidget` ou `ConsumerStatefulWidget` uniquement si on a un controller
  local TextEditingController, AnimationController, ou un timer.
- Pour les widgets qui lisent Riverpod : `ConsumerWidget` (lecture) ou `ConsumerStatefulWidget` (lecture +
  state local).
- Préfixer les widgets internes au fichier par `_` (ex: `_StatsCard`, `_ActionCard`).
- Pas de `const` oublié — Dart 3 est strict, le linter te le dira.

**State management**

- **Riverpod partout**. Pas de `setState` dans les écrans Consumer, sauf pour du state purement local (focus,
  animation, toggle visuel sans impact métier).
- Les controllers métier sont des `StateNotifier<AsyncValue<T>>` ou `StateNotifier<T>` exposés via un
  `StateNotifierProvider`.
- Pour les listes serveur, utiliser `FutureProvider.autoDispose` + `ref.refresh(...)` pour le pull-to-refresh.
- Family providers pour les controllers paramétrés (ex: `runnerControllerProvider.family(attemptId)`).
- `autoDispose` par défaut pour les providers liés à un écran — on garde la mémoire propre quand on quitte
  l'écran.

**Réseau**

- **Toujours** passer par un `Repository` du dossier `core/api/`. Ne jamais appeler Dio directement depuis un
  écran.
- Les repositories prennent l'`ApiClient` en injection, exposé via `apiClientProvider`.
- Pour traiter une erreur, utiliser `ApiClient.toApiException(e)` qui mappe les `DioException` en
  `ApiException` propre avec status code + message + fieldErrors.

**Formulaires**

- `Form` + `GlobalKey<FormState>` + `TextFormField` avec validators inline.
- Pour les erreurs serveur sur champs précis, le backend renvoie `fieldErrors: [{field, message}]` et
  `ApiException` les expose en `Map<String, String>`. Les afficher inline sous le champ correspondant.

**Navigation**

- Toujours utiliser `context.go(...)` ou `context.push(...)` de go_router. Pas de `Navigator.push` direct.
- Les routes sont centralisées dans `AppRoutes` (`core/router/app_router.dart`).
- Le router redirige automatiquement vers `/login` quand non authentifié, et vers `/` quand authentifié. **Pas
  besoin de gérer la redirection dans les écrans.**

**UI**

- Couleurs : **toujours** via `AppColors`, jamais en littéral hex.
- Polices : **toujours** via `AppFonts.jakarta()`, `AppFonts.fraunces()`, `AppFonts.mono()`.
- Spacing standardisé : 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32. Pas de 17 ou 23.
- Border radius : 4 (badges), 8 (boutons petits/chips), 10 (cards intérieures), 12 (boutons/inputs), 14 (
  cards), 16 (cards), 20 (modals).
- `withValues(alpha: 0.x)` pour la transparence (Flutter 3.27+) — pas `withOpacity` qui est déprécié.

**Hygiène (rappel transverse, cf. CLAUDE.md racine)**

- Si un widget apparaît 2 fois dans 2 écrans, **l'extraire** dans `core/widgets/` (générique) ou
  `screens/<area>/widgets/` (local à un domaine). Ex: `screens/hub/widgets/hub_widgets.dart` et
  `core/widgets/paywall_sheet.dart` ont été extraits dès qu'une 2ᵉ surface en avait besoin.
- Quand un écran est remplacé par une nouvelle archi, supprimer dans la foulée : le fichier, les
  routes (`AppRoutes`), les imports, et tous les CTA `context.go(...)` qui pointaient dessus. Pas
  de dead code "au cas où". Faire `grep` sur le nom du screen et du route avant de fermer le lot.
- Pas de nouveau fichier `.md` à côté du CLAUDE.md mobile : tout ce qui mérite d'être noté pour le
  futur va **dans ce CLAUDE.md**. Si une section devient trop longue, la restructurer plutôt que
  d'éclater l'info.
- Mettre à jour ce fichier en même temps que les modifs structurantes (nouveau dossier `screens/*`,
  nouveau pipeline réseau, changement de convention Riverpod/router…). Pas de PR qui modifie
  l'archi sans synchroniser la doc.

## Démarrage local

```bash
# Installer les dépendances
flutter pub get

# Lancer sur iOS simulator (backend sur localhost)
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Lancer sur Android emulator (10.0.2.2 = host depuis l'émulateur)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Sur device physique avec backend sur la même WiFi
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8080
```

Compte de test en dev (créé par le seed Flyway du backend) :

- `user@sejourfr.fr` / `User123!`
- `karim.test@sejourfr.fr` / `User123!`

Pour avoir des permissions natives (audio en arrière-plan, par exemple), penser à éditer
`ios/Runner/Info.plist` et `android/app/src/main/AndroidManifest.xml` selon les besoins. Pour l'instant, juste
internet suffit, c'est l'autorisation par défaut.

## Bottom nav et hubs Civique / TCF

La bottom nav a 5 onglets : **Accueil · Civique · TCF · Progression · Profil**. Les onglets Civique et
TCF remplacent les anciens "Entraîner" et "Examen". Les écrans `TrainingSetupScreen` et `ExamSetupScreen`
ont été **supprimés** : un tap module dans un hub démarre directement un attempt et push le runner
(plus d'écran setup intermédiaire). Le quota démo (`kDemoBatchSize = 20`) et premium (`kInitialBatchSize = 30`)
vivent désormais dans `core/widgets/paywall_sheet.dart` avec le bottom sheet `PaywallSheet` réutilisable.

Les 2 hubs (`screens/civique/civique_screen.dart` et `screens/tcf/tcf_screen.dart`) partagent une
structure visuelle identique implémentée dans `screens/hub/widgets/hub_widgets.dart` :

- `HubTopBar` : icône notifications à gauche, pastille de niveau/parcours à droite (bleue sur Civique
  affiche CSP/CR/NAT, rouge sur TCF affiche A2/B1/B2 d'après `user.targetProcedure`).
- `HubHero` : bandeau gradient (bleu sur Civique, rouge sur TCF) avec eyebrow mono, titre Jakarta gras
  sur 2 lignes, description.
- `HubProgressCard` : objectif (libellé du parcours / niveau visé) + % de maîtrise calculé sur les
  stats `byTheme` (correct / total).
- `HubModuleCard` : icône colorée + titre + description + meta + chevron. Flag `aiTag: true` pour
  EE/EO. Flag `locked: true` réservé aux modules premium futurs.
- `HubExamCard` : carte sombre "Examen blanc" en bas. Côté TCF → push
  `/tcf/examens-blancs` (liste 20 slots) → briefing modal → POST
  `/api/full-tcf-exams` → push `/tcf/examen-blanc/:parentId` (hub
  progression). Côté Civique → push `/civique/examens-blancs`
  (`CiviqueExamBlancScreen`, 20 slots) → briefing modal
  (`showCiviqueExamBriefingSheet`) → POST `/api/attempts {type:MOCK_EXAM,
  module:CIVIQUE}` (40 Q / 45 min / seuil 32) → push runner.

**Modules affichés :**
- **Civique** = les 5 thèmes officiels chargés via `/api/themes?module=CIVIQUE` (Principes &
  symboles, Institutions, Droits & devoirs, Histoire-Géo, Société). Tap → push
  `/civique/theme/:themeId` (écran détail).
- **TCF** = 4 modules, **tous** avec un écran détail :
  - CO → `/tcf/co`, CE → `/tcf/ce` → `TcfQcmDetailScreen` → CTA "Commencer l'entraînement"
    → `POST /api/attempts` + push runner.
  - EE → `/tcf/ee`, EO → `/tcf/eo` → `TcfProductionDetailScreen` → CTA "Voir les tâches"
    → push `ProductionHubScreen` (sélection T1/T2/T3) après paywall check si non-premium.

**Écran détail (lot 3 + 3 bis)** — vit dans `screens/module_detail/`. Routes hors shell (pas de
bottom nav) :
- `/civique/theme/:themeId` → `CiviqueThemeDetailScreen` (fetch theme via `themesRepository`,
  cherche les stats du thème dans `byTheme[themeId]`). **3 onglets** (Lots / Examens / Erreurs)
  calqués sur le pattern TCF QCM :
  - **Lots** : liste des lots civique (15 Q chacun) du thème via `civiqueLotsProvider(themeId)` →
    `GET /api/lots?module=CIVIQUE&themeId=...`. Tap lot → `POST /api/attempts {type:TRAINING,
    module:CIVIQUE, themeId, lotNumero}` puis push runner. Backend trace via `lot_theme_id` +
    `lot_numero` (cf. migration V089 + CLAUDE.md racine § Lots).
  - **Examens** : 20 slots d'examens blancs civique (40 Q / 45 min / seuil 32). L'historique
    `_civiqueExamsHistoryProvider` (`GET /api/me/attempts?type=MOCK_EXAM&module=CIVIQUE`) est
    partagé entre les 5 écrans détail thème — le mock_exam civique n'est pas scopé par thème
    côté backend, c'est par design (le vrai examen civique touche aux 5 thèmes).
  - **Erreurs** : 20 dernières questions ratées du user sur **ce thème précis**, via
    `_civiqueWrongProvider(themeId)` → `GET /api/me/questions/wrong?module=CIVIQUE&themeId=...`.
    Tap question → `showQuestionDetailSheet` partagé.
- `/tcf/co` et `/tcf/ce` → `TcfQcmDetailScreen` avec l'enum `TcfQcmModule.{co,ce}` qui porte
  l'intitulé, l'icône, le `QuestionType` et le label de durée.
- `/tcf/eo` et `/tcf/ee` → `TcfProductionDetailScreen` avec l'enum `TcfProductionModule.{eo,ee}`
  qui porte en plus la route du `ProductionHubScreen` cible.

Layout uniforme (`widgets/module_detail_widgets.dart`) :
1. `ModuleDetailTopBar` (back + icône décorative).
2. `ModuleDetailTitle` (eyebrow "Module civique" / "Module TCF" + titre Jakarta gras).
3. `ModuleDetailHero` (gradient — bleu pour civique, rouge pour TCF QCM, vert/rouge pour EE/EO).
4. `ModuleDetailStats` (3 cellules : Questions ou Tâches / Durée / Parcours-Niveau).
5. **QCM uniquement** : `ModuleDetailScoreCard` (% de maîtrise + badge "Bon niveau" / "En progression" /
   "À renforcer" / "À démarrer" + barre + nb de sessions).
   **EE/EO** : carte "Comment ça marche" en 3 étapes (rédige/enregistre → IA évalue → niveau CECRL)
   — pas de score % parce que les productions renvoient un niveau CECRL par submission, donnée trop
   fine pour une % de maîtrise globale.
6. **TCF QCM uniquement (CO/CE) — Lot 4 + 5** : `ModuleDetailTabs` segmentés (Séries / Examens /
   Erreurs) pilotés par un `_DetailTab` local. Le contenu sous les tabs est dispatché par
   `_TabContent` :
   - **Séries** (lot 5 + 6) = 3 cards niveau (`_seriesLevels` dans `tcf_qcm_detail_screen.dart`,
     A2 vert / B1 ambre / B2 rouge) — gros chip de niveau à gauche, sous-titre "X questions par lot".
     Tap niveau → push `/tcf/{co|ce}/niveau/{a2|b1|b2}` qui ouvre `TcfLevelLotsScreen`. Ce nouvel
     écran a son propre topbar + hero coloré par niveau + stats (nb de lots, taille, niveau) +
     liste des lots chargés via le provider partagé `lotsProvider` (family `LotsKey`, dans
     `core/providers/lots_provider.dart`). Tap d'un lot → `POST /api/attempts` avec `lotNumero`
     puis push runner avec `?from=tcfLot&moduleKey=co&level=a2` en query. Le runner détecte ce
     contexte dans `initState` et appelle `setFixedBatch(true)` sur son controller : passe en
     **mode batch fixe** (pas d'extension auto, "Question X / N" affichée, bouton Terminer à la
     dernière question du lot). À la fin, `_navigateToResult` lit à nouveau le query et push
     **`TcfLotResultScreen`** (`/tcf/lot-result/:attemptId?moduleKey&level`) au lieu du dialog
     d'entraînement standard. L'écran de bilan affiche le score donut, un résumé (bonnes / erreurs
     / temps / niveau), un conseil dynamique, et un CTA "Retour aux lots" qui ramène à
     `/tcf/:moduleKey/niveau/:level`. Non-premium → `showPaywallSheet` direct sur tap d'un lot
     (le backend renvoie 403 sinon).
     Chaque `LotDto` porte aussi `lastScore` + `lastAttemptedAt` (dernier attempt fini du user sur
     ce lot — backend `AttemptManager.findLastFinishedByLots`). Quand `lastScore != null`, la card
     est rendue avec un fond légèrement teinté de la couleur de niveau + un badge **`scoreBadge`**
     (ex: `8/15`) à la place du chevron. Le rafraîchissement est porté par l'autoDispose du
     `lotsProvider` : revenir depuis `TcfLotResultScreen` via `context.go` recrée le widget et
     refetch les lots.
   - **Examens** = `_ExamsTab` qui affiche une intro (25 Q · 20 min CO ou 35 min CE · difficulté
     progressive A2 → B1 → B2) + l'historique des examens module passés du user via
     `_moduleExamsHistoryProvider(QuestionType)` (`GET /api/me/attempts?moduleExamQuestionType=CO|CE`).
     Chaque ligne d'historique montre la date, le nombre de bonnes réponses, la durée et un badge
     score pondéré X/50 coloré (vert / ambre / rouge). Le bouton primary du bas devient
     "Lancer un examen" qui appelle `_startModuleExam` → `POST /api/attempts {type:MOCK_EXAM,
     moduleExamQuestionType}` → push runner (chrono auto via `attempt.timeLimitSeconds`).
   - **Erreurs** = `_ErrorsTab` branché sur `_wrongQuestionsProvider(QuestionType)`
     (`GET /api/me/questions/wrong?module=TCF&questionType=CO|CE`). Liste plate des questions
     ratées avec chip niveau et preview du statement. Empty state propre si zéro erreur.

   L'entrée "Mes questions" du profil a été retirée — l'accès aux erreurs se fait désormais par
   l'onglet Erreurs du module concerné, plus contextuel.
7. `AppButton` primary :
   - QCM / onglet Séries : "Commencer l'entraînement" → entraînement standard 25 Q (POST sans
     filtre difficulté), à côté des séries filtrées qui partent depuis les cards.
   - EE/EO : "Voir les tâches" → push `ProductionHubScreen` (paywall si non-premium).
   Le bouton du bas n'apparaît PAS sur les onglets Examens / Erreurs (les CTAs viendront avec leur
   contenu propre en lot 4b).

**Limite assumée** : la maîtrise affichée pour TCF CO et CE est l'agrégat TCF global
(somme `byTheme` côté `/api/me/stats`), pas un score par épreuve — le backend n'expose pas encore
de découpage par `QuestionType`. À raffiner quand on aura le besoin.

**Prochaine étape pressentie** (cf. design `tcf_entrainement_mobile_design.html` racine, écrans 2-7) :
écran détail par module avec onglets *Séries / Examens / Erreurs* puis briefing → questions →
feedback → fin de série. L'archi actuelle est délibérément minimale : le tap module redirige vers
les écrans `/training` et `/tcf/expression-*` existants en attendant.

## Le runner — le cœur de l'app

Le `RunnerScreen` est l'écran le plus complexe. Il gère :

1. **Chargement** d'un attempt depuis l'API (`AttemptsRepository.getById`)
2. **Affichage** de la question courante avec son média éventuel (audio/image/vidéo via `QuestionMediaView`)
3. **Sélection** des choix (single-select pour l'instant, prêt pour multi-select)
4. **Soumission** d'une réponse :
    - En **entraînement** : le backend renvoie immédiatement `correct` + `explanation`. On affiche
      `ExplanationBox`, on bloque les choix, puis le bouton "Question suivante" apparaît.
    - En **examen blanc** : on enregistre silencieusement la réponse et on passe à la suivante. Pas de
      correction immédiate.
5. **Chrono** : pour les examens blancs, `ExamTimer` décompte depuis `attempt.startedAt` jusqu'à
   `timeLimitSeconds`. Quand ça atteint 0, finalisation automatique.
6. **Finalisation** : `POST /api/attempts/{id}/finish`, dialog de résultat avec score / seuil / passé-échoué.

**Reprise d'un attempt** : si l'utilisateur quitte le runner avant de finir, l'attempt reste en cours côté
backend. À la reprise, `RunnerController._load()` recalcule l'index de départ : première question non
répondue, sinon dernière.

**Médias** : le `QuestionDto.media` est un `MediaDto` optionnel avec un `type` (AUDIO/IMAGE/VIDEO) + une
`url`. Le `QuestionMediaView` dispatche vers le bon widget. Pour l'instant, les questions du seed ne
contiennent que du texte, mais l'architecture est prête pour le TCF complet.

## TCF Expression orale + écrite (`screens/tcf_production/`)

Module distinct du runner QCM : l'utilisateur **produit** un audio (EO) ou un texte (EE), envoyé au backend
qui le transcrit (Whisper) + le note (Claude) en 10-15 s. Cf. `CLAUDE.md` racine pour le pipeline backend.

**Deux modes d'entrée** :
- **Onglet Tâches** du détail module → entraînement libre **single-task** (depuis le
  `ProductionHubScreen` à `/tcf/expression-X` : 3 cards T1/T2/T3 par niveau cible, tap → 1 tâche).
  Après soumission, l'écran résultats est affiché immédiatement (correction IA tâche par tâche).
- **Onglet Examens** du détail module → session **3 tâches enchaînées**, fidèle au vrai TCF :
  **aucune correction n'est visible entre T1/T2/T3**. Après T3, on push directement le bilan
  détaillé (`HistorySessionScreen` en mode `?live=1`) qui pollera les évaluations IA jusqu'à ce
  qu'elles soient toutes EVALUATED/FAILED, puis le user peut tapoter chaque ligne pour voir le
  détail complet de l'évaluation Claude (donut + critères + feedback + transcription).

**Onglet Examens — slots remplis (parité avec TCF QCM CO/CE)** : 10 slots numérotés. Le provider
`_productionExamsHistoryProvider` (dans `tcf_production_detail_screen.dart`) regroupe les
submissions du user par `attemptId` et ne garde **que les attempts à ≥3 submissions** (single-task
exclus). Slot 1 = plus ancien examen. Tap slot vide → briefing + start nouvelle session. Tap
slot fait → bottom sheet `_ProductionExamActionSheet` : "Voir les détails" (push
`/sessions/{attemptId}`, mode historique) ou "Reprendre" (briefing + start). Badge slot : niveau
CECRL plancher des 3 submissions, teinté rouge/ambre/bleu/vert selon le palier. Si l'éval IA
tourne encore (badge `…`, sous-titre "évaluation en cours"), c'est qu'on est revenu sur le détail
avant la fin du pipeline — tap → bilan détaillé qui poll.

**Routes EO** (idem EE en remplaçant `expression-orale` par `expression-ecrite`) :
- `/tcf/expression-orale` → **hub** d'entraînement (`ProductionHubScreen`)
- `/tcf/expression-orale/historique` → liste des sessions passées (`ProductionHistoryScreen`)
- `/tcf/expression-orale/sessions/:attemptId[?live=1]` → bilan détaillé d'une session,
  `HistorySessionScreen`. En mode `live=1` (juste après T3) il poll les évaluations IA. Sinon
  (depuis historique) il lit la donnée déjà figée. Chaque ligne de tâche est tappable → push
  l'écran `resultats/:submissionId` du detail complet.
- `/tcf/expression-orale/t/:idx` → briefing T(idx+1)
- `/tcf/expression-orale/t/:idx/enregistrement` → capture audio (EO uniquement)
- `/tcf/expression-orale/t/:idx/termine` → écoute + soumission (EO uniquement)
- `/tcf/expression-orale/resultats/:id?taskIndex=N&history=1` → résultats détaillés d'une
  submission (correction IA complète) — push en single-task après soumission, ou depuis le
  bilan en tap d'une ligne.

**Hub** (`production_hub_screen.dart` + `production_hub_controller.dart`) :
- `ProductionHubController` (family indexée par `EpreuveType`) charge en parallèle les 3 listes de tâches
  via `/api/production-tasks?epreuve=...&niveau=...&tacheNumero=1|2|3` + la dernière submission par tâche
  via `/api/users/me/production-submissions/last-per-task`.
- **T1** = consigne fixe (présentation), pas de bouton "Changer". **T2 et T3** = pick aléatoire à chaque
  visite, bouton "Changer de sujet" pour re-roll.
- Tap "Commencer" sur une card → `EoSessionController.startSingle(task)` ou `EeSessionController.startSingle(task)`
  (state contient `tasks=[singleTask]`, niveau = `task.niveauCible`) puis push `/t/0`.
- `refreshLast()` est appelé au mount → la note fraîchement obtenue apparaît en badge sur la card.
- L'entrée historique du hub remonte juste à `/historique` (sous-route du hub).

**Flow EO (3 écrans + résultats)** — inchangé en single-task, le SessionController a juste 1 tâche :
1. **Briefing** (`eo_briefing_screen.dart`) : consigne + conseils + CTA "Commencer" qui demande la permission
   micro via `_recorder.hasPermission()` du package `record` directement (✋ **ne pas utiliser
   `permission_handler` seul** : il court-circuite l'auth iOS dans certains cas et ne déclenche pas le dialog).
2. **Recording** (`eo_recording_screen.dart`) : timer big + waveform animée (33 barres calées sur
   l'amplitude réelle + sinusoïde) + bouton stop rond rouge. Auto-stop à `dureeMaxSec`.
3. **Finished** (`eo_finished_screen.dart`) : check vert + mini-player just_audio sur le fichier local +
   CTA "Voir mon évaluation" → swap vers `EvaluationLoadingView(includeTranscription: true)` pendant
   l'upload R2 + Whisper + Claude (~15 s), puis push résultats.
4. **Résultats** (`eo_results_screen.dart`) : score donut violet + critères + feedback + **transcription
   Whisper**. Atteint en single-task après soumission, ou depuis le bilan en tap d'une ligne, ou
   depuis l'historique des sessions passées (mode `isHistory`). En 3-tâches, `eo_finished_screen`
   **bypasse** ce screen entre les tâches : il push direct le briefing suivant, et après T3 le
   bilan détaillé. CTAs : "Retour aux sujets" (single-task) ou "Continuer l'examen blanc" (full
   TCF exam) ou "Retour" (history).

**Flow EE** : 1 seul écran combiné `ee_briefing_writing_screen.dart` (briefing + textarea + compteur live +
`MotsCard` ambre + brouillon auto-save 3 s dans `SharedPreferences` via `EeDraftService`).
- Textarea avec `FocusNode` partagé entre le screen state et `WritingZone` → quand le clavier ouvre,
  `ConsigneCard`/`TipsCard`/`CriteresCard` se replient et les 2 boutons du bas (Valider / Brouillon)
  disparaissent → le textarea grandit (`minLines: 12`). `keyboardDismissBehavior: onDrag` sur la
  ListView. **Important** : ne pas conditionner les enfants de la ListView sur le focus avec
  `if (!isWriting) ...[ConsigneCard, ...]` — ça change les indices et Flutter recrée le State de
  `WritingZone` → focus perdu, clavier se ferme immédiatement. Garder tous les enfants présents +
  ValueKey stable sur chacun.
- `TextField.onTapOutside: (_) => focusNode.unfocus()` pour dismiss le clavier au tap hors champ (API
  officielle Flutter 3.10+). **Ne pas** wrapper le body dans un `GestureDetector(onTap: unfocus)` : ça
  rentre en compétition avec le tap de focus du TextField → "il faut 2 taps pour ouvrir le clavier".
- Bordure bleue 1.5px + fond `blueSoft` + ombre douce au focus, `AnimatedContainer` 150ms.
- Info button (`ProductionAppHeaderInfo`) du header ouvre une `showModalBottomSheet` avec le texte de
  confidentialité (cf. `_ConfidentialitySheet` privé dans le screen).

**Sessions** : `EeSessionController` / `EoSessionController` (StateNotifier **non-autoDispose**) portent
les tasks (1 en single-task, 3 en session examens) + l'attempt parent + la map des submissions. Trois
points d'entrée :
- `start(niveau:...)` → mode 3-tâches (session examens depuis l'onglet Examens du détail).
- `startSingle(task:...)` → mode entraînement libre (1 tâche pickée par le hub).
- `startInFullExam(subAttemptId:..., niveau:...)` → reprend le sous-attempt EE/EO créé par le
  backend dans un examen blanc TCF complet.
- `refreshSubmission(taskIndex)` permet au bilan d'aller chercher la dernière version d'une
  submission (utilisé par le polling mode `live=1` de `HistorySessionScreen`).

Reset manuel après "Retour aux tâches" / "Terminer la session" / abandon.

**Bilan unique pour les sessions EE/EO** : `HistorySessionScreen` (`history_session_screen.dart`)
sert à la fois pour le post-T3 d'une session examens (`?live=1` → polling actif + CTA "Terminer
la session" → go au hub TCF) et pour les sessions passées (depuis l'onglet historique → CTA
"Retour"). Lecture des submissions par `productionRepository.listMine` filtré par `attemptId`.
Tap sur une ligne → push `resultats/:submissionId?history=1` du détail complet d'évaluation.
Les ex `SessionProgressScreen` / `SessionBilanScreen` / `session_view.dart` ont été **supprimés**
(doublons dégradés sans drill-down).

**Gotchas iOS** :
- `record_ios 1.2.0` produit un fichier vide (28 B) sur **iOS 26 en AAC-LC**. Workaround : `AudioEncoder.wav`
  (PCM 16 kHz mono, ~32 KB/s). Repasser à AAC dès qu'une version récente sort.
- **AVAudioSession** doit être configurée explicitement en `playAndRecord` avant chaque
  `_recorder.start()`, sinon le micro est muet si `just_audio` a précédemment saisi la session en
  `.playback`. `AudioRecorderService.start()` le fait via le package `audio_session`.
- `NSMicrophoneUsageDescription` dans `ios/Runner/Info.plist` + `RECORD_AUDIO` dans le manifest Android.

**Backend gotcha relayé** : le DTO `Attempt` du backend renvoie `totalQuestions=null` pour les attempts de
type production. `core/models/attempt_models.dart` coerce `null → 0` pour ne pas casser le parsing existant.

## Examen blanc TCF complet (orchestration des 4 épreuves)

Backend : cf. `CLAUDE.md` racine section « Examen blanc TCF complet ». Côté mobile, l'orchestration vit
dans `screens/tcf_full_exam/` :

- **`TcfFullExamProgressScreen`** (route `/tcf/examen-blanc/:parentId`) — hub de progression. Charge le
  parent + ses 4 sous-attempts via `fullTcfExamProvider` (FutureProvider.autoDispose.family), affiche 4
  cards d'étape (CO/CE/EE/EO) avec leur état Done/Current/Locked, CTA « Commencer · [épreuve courante] »
  qui push :
  - **CO/CE** → runner QCM standard `/runner/$subAttemptId?from=fullTcf&fullExamId=$parentId`. Le runner
    détecte la query (`runner_screen.dart::_navigateToResult`) et redirige vers ce hub au finish au lieu
    du dialog d'examen.
  - **EE/EO** → briefing existant `/tcf/expression-X/t/0?fullExamId=$parentId&subAttemptId=$subId`. Le
    briefing détecte la query et appelle `EeSessionController.startInFullExam(...)` /
    `EoSessionController.startInFullExam(...)` au lieu de `start(niveau)` — ces variantes REPRENNENT
    l'attempt existant côté backend au lieu d'en créer un nouveau.
- **`TcfFullExamBilanScreen`** (route `/tcf/examen-blanc/:parentId/bilan`) — bilan agrégé. À l'init,
  appelle `POST /api/full-tcf-exams/{id}/finish` (idempotent) puis poll toutes les 4 s jusqu'à
  `status == COMPLETED`. Affiche le niveau CECRL plancher en gros + 4 cards par épreuve avec leur niveau
  individuel.

**Propagation des query params** : utilitaire `core/utils/query_propagation.dart::withCurrentQuery(context, path)`
appelé partout dans le flow EE/EO (briefing → enregistrement → termine → résultats → tâche suivante)
pour que `fullExamId` + `subAttemptId` survivent à toutes les transitions. Sans ça les sous-attempts du
parent seraient perdus.

**Auto-finalisation des sous-attempts EE/EO** : le mobile n'appelle PAS `POST /api/attempts/{id}/finish`
sur les sous-attempts EE/EO. Le backend pose `finishedAt` automatiquement quand la 3ème submission
arrive (`ProductionEvaluationService.finishSubAttemptIfFullExam`). Les sous-attempts CO/CE sont
finalisés normalement par le runner via `/finish`.

**Niveau CECRL** : le mobile lit l'utilisateur dans `auth.user.targetProcedure.tcfLevel` (A2/B1/B2)
pour choisir le niveau des tâches EE/EO du full exam — fallback `B1` si absent. Les pools de tâches
côté backend ne sont pas mixés par niveau ; tout le full exam utilise donc un seul niveau cible.

**Flow utilisateur typique** :
1. Hub TCF → carte sombre "Examen blanc complet" → push `/tcf/examens-blancs` (20 slots)
2. Tap slot → briefing modal → bouton "Lancer" → `POST /api/full-tcf-exams` → push
   `/tcf/examen-blanc/:parentId`
3. CTA "Commencer · Compréhension orale" → runner CO → finish → retour progress
4. CTA "Commencer · Compréhension écrite" → runner CE → finish → retour progress
5. CTA "Commencer · Expression écrite" → EE T1 → T2 → T3 → "Continuer l'examen blanc" → retour progress
6. CTA "Commencer · Expression orale" → EO T1 → T2 → T3 → "Continuer l'examen blanc" → retour progress
7. CTA "Voir mon résultat" → push `/tcf/examen-blanc/:parentId/bilan` (avec polling sur évals IA)

**Reprise** : `fullTcfExamProvider` est autoDispose, mais le state des sous-controllers Riverpod
EE/EO survit entre les écrans du même flow. Si l'utilisateur quitte et revient via la liste des
attempts, l'écran progression repart de l'état serveur — pas de "session" client à reprendre, l'état
canonique vit côté backend.

## Roadmap (ce qui n'est pas encore fait)

- **Chrono global examen blanc** : `time_limit_seconds = 5400` (90 min) est posé sur le parent backend
  mais le mobile ne l'affiche pas encore. Idéalement chrono visible en haut du progress screen + chaque
  étape consomme du quota. Pour l'instant, chaque sous-attempt a son propre chrono (CO 20 min, CE 30 min
  via les `time_limit_seconds` des sous-attempts).
- **Offline-first** : pas de SQLite/Drift pour l'instant, tout passe par le réseau. À ajouter dans
  `core/storage/` quand on aura besoin (questions civiques stables, peuvent être cachées).
- **Notifications push** (rappels d'entraînement) : à ajouter via `firebase_messaging` ou OneSignal.
- **In-app purchase** (Premium) : `in_app_purchase` côté Flutter, validation côté backend.
- **Mode sombre** : la palette est prête (l'identité visuelle marche en dark), mais `buildAppTheme()` ne fait
  que le clair pour l'instant.
- **Tests** : aucun pour l'instant. Quand on en ajoutera, Vitest n'existe pas en Flutter — c'est
  `flutter_test` + `mockito` ou `mocktail` pour les mocks. Tester d'abord les controllers Riverpod, c'est là
  que la logique vit.
- **Accessibilité** : les tailles de police suivent le `MediaQuery.textScaling` (clampé entre 0.9 et 1.2 dans
  `app.dart` pour éviter les layouts cassés). Les Semantics pourraient être ajoutés sur les boutons et tags.
- **Animations** : transitions de routes par défaut. Le runner pourrait bénéficier d'un fade ou slide entre
  questions.

## Pistes d'évolution

- Si tu ajoutes un **nouvel écran** : créer `screens/<feature>/<feature>_screen.dart` + un dossier `widgets/`
  si besoin, déclarer la route dans `AppRoutes`, l'ajouter au router. Ne pas oublier l'entrée dans le
  `MainShell` si tu veux qu'elle apparaisse dans la bottom nav.

- Si tu ajoutes un **nouveau type de média TCF** (PDF, document interactif...) : étendre l'enum `MediaType`
  dans `core/models/enums.dart`, ajouter le widget correspondant dans `screens/question_runner/widgets/`, et
  dispatcher dans `QuestionMediaView`.

- **Mode audio TCF CO** : le backend expose `question.audioMode` (`WRITTEN_QUESTION` | `FULL_AUDIO` | null).
  Pour l'instant le runner mobile rend identique aux deux modes — à terme, en `FULL_AUDIO` il faudra
  n'afficher que `"Réponse A/B/C/D"` (déjà ce qui vient en base) et masquer le statement de la question
  pour forcer l'écoute. Cf `CLAUDE.md` racine pour la spec du pipeline.

- Si tu ajoutes un **nouvel endpoint backend** : créer (ou compléter) le repository dans `core/api/`, exposer
  un provider dans `repositories.dart`, et l'utiliser via `ref.watch(...)` dans l'écran.

- Le `selectedModuleProvider` (Riverpod) est volontairement non persisté — il se réinitialise à chaque
  démarrage à `CIVIQUE`. Si on veut le mémoriser, ajouter une lecture dans `TokenStorage` (ou un service de
  prefs dédié) et le restaurer au boot.

- Pour gérer les **mises à jour forcées** (kill-switch côté serveur), ajouter un endpoint `/api/app-config`
  qui renvoie la version minimum acceptée, et bloquer l'app au splash si la version locale est trop ancienne.