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
    │   └── main_shell.dart        Bottom nav 5 onglets
    ├── training/                  Entraînement libre (thème + niveau + nb questions)
    │   └── widgets/production_entry_tile.dart  Tiles EO/EE en bas de la liste TCF
    ├── exam/                      Examen blanc (CSP/CR/NAT ou A2/B1/B2)
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
    │   ├── ee_session_controller.dart   Session EE (3 tâches, attempt parent partagé)
    │   ├── eo_session_controller.dart   Session EO (idem)
    │   ├── session_view.dart            Vue abstraite EE+EO pour écrans communs
    │   ├── ee_briefing_writing_screen.dart  Briefing + zone d'écriture combinés
    │   ├── eo_briefing_screen.dart      + recording + finished + results screens
    │   ├── session_progress_screen.dart Entre les tâches (X/3 + liste)
    │   ├── session_bilan_screen.dart    Après T3 : hero bleu CECRL + détail
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

**Entry par hub d'entraînement libre.** L'utilisateur n'est plus forcé d'enchaîner T1 → T2 → T3 : il
arrive sur un hub avec 3 cards (T1, T2, T3), choisit la tâche qu'il veut travailler, fait son
entraînement, revient au hub. La session 3-tâches chaînée existe toujours dans le code mais est mise au
frigo en attendant l'examen blanc (cf. roadmap).

**Routes EO** (idem EE en remplaçant `expression-orale` par `expression-ecrite`) :
- `/tcf/expression-orale` → **hub** d'entraînement (`ProductionHubScreen`)
- `/tcf/expression-orale/historique` → liste des sessions passées (`ProductionHistoryScreen`)
- `/tcf/expression-orale/sessions/:attemptId` → bilan d'une session passée (lecture seule)
- `/tcf/expression-orale/t/:idx` → briefing T(idx+1) (single-task ou exam blanc selon `totalTasks` du SessionController)
- `/tcf/expression-orale/t/:idx/enregistrement` → capture audio (EO uniquement)
- `/tcf/expression-orale/t/:idx/termine` → écoute + soumission (EO uniquement)
- `/tcf/expression-orale/resultats/:id?taskIndex=N&history=1` → résultats live ou history
- `/tcf/expression-orale/nouvelle`, `/progression`, `/bilan` → **legacy session 3-tâches**, conservés pour le futur examen blanc

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
   Whisper**. En single-task (`session.totalTasks == 1`), bouton "Retour aux tâches" qui reset la session
   et go vers le hub. En 3-tâches : "Passer à la tâche N+1" entre T1/T2 et "Voir mon bilan" sur T3.

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
les tasks (1 en single-task, 3 en exam blanc) + l'attempt parent + la map des submissions. Deux points
d'entrée :
- `start(niveau:...)` → mode 3-tâches (chargé tasks + crée attempt). Réservé à l'examen blanc futur.
- `startSingle(task:...)` → mode entraînement libre (1 tâche pickée par le hub + crée attempt).
Reset manuel après "Retour aux tâches" ou abandon.

**Écrans communs EE + EO** (`session_progress_screen.dart`, `session_bilan_screen.dart`) paramétrés par
`EpreuveType`, lisent la session via `readSessionView(ref, epreuve)` (helper dans `session_view.dart` qui
abstrait `EeSessionState` et `EoSessionState`). **Inutilisés en mode single-task**, vivent pour l'examen
blanc futur.

**Gotchas iOS** :
- `record_ios 1.2.0` produit un fichier vide (28 B) sur **iOS 26 en AAC-LC**. Workaround : `AudioEncoder.wav`
  (PCM 16 kHz mono, ~32 KB/s). Repasser à AAC dès qu'une version récente sort.
- **AVAudioSession** doit être configurée explicitement en `playAndRecord` avant chaque
  `_recorder.start()`, sinon le micro est muet si `just_audio` a précédemment saisi la session en
  `.playback`. `AudioRecorderService.start()` le fait via le package `audio_session`.
- `NSMicrophoneUsageDescription` dans `ios/Runner/Info.plist` + `RECORD_AUDIO` dans le manifest Android.

**Backend gotcha relayé** : le DTO `Attempt` du backend renvoie `totalQuestions=null` pour les attempts de
type production. `core/models/attempt_models.dart` coerce `null → 0` pour ne pas casser le parsing existant.

## Roadmap (ce qui n'est pas encore fait)

- **Examen blanc EO/EE** : flow 3-tâches chaîné avec chrono. Stratégie validée = **Option 3 fire-and-forget** :
  chaque submit part en async pendant que l'utilisateur attaque la tâche suivante (gain de ~15 s × 3 d'attente
  perçue), résultats agrégés dans un bilan unique à la fin. Les briques existent déjà : `EoSessionController.start(niveau)`
  charge 3 tasks + crée l'attempt, les écrans `session_progress_screen.dart` / `session_bilan_screen.dart` sont
  prêts. À faire : un orchestrateur qui `Future.wait` les 3 submissions en arrière-plan + un chrono global +
  un nouveau point d'entrée distinct du hub (probablement un CTA "Mode examen blanc" en bas du hub).
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