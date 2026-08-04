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
│   │   ├── api_config.dart        Base URL via .env (Env.read)
│   │   ├── api_exception.dart     ApiException typée
│   │   ├── auth_repository.dart
│   │   ├── themes_repository.dart
│   │   ├── attempts_repository.dart
│   │   ├── user_content_repository.dart
│   │   └── repositories.dart      Providers Riverpod
│   ├── auth/
│   │   ├── token_storage.dart     Persistance sécurisée des tokens
│   │   └── auth_controller.dart   AuthState + StateNotifier
│   ├── config/
│   │   └── env.dart               Wrapper flutter_dotenv (Env.init / Env.read)
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
    │   └── widgets/hub_home_widgets.dart  Widgets partagés des 2 home hubs
    │                                     (HubHomeHeader, ExamBlancHero, EpreuveCard, SectionLabel/Counter/Link)
    ├── civique/
    │   ├── civique_screen.dart                Home Civique (single scroll : header + hero + thèmes + maîtrise)
    │   └── widgets/civique_mastery_card.dart  Carte maîtrise globale civique (% justes + couverture)
    ├── tcf/
    │   ├── tcf_screen.dart                    Home TCF (single scroll : header + hero + 5 épreuves + CECRL + stats)
    │   └── widgets/
    │       ├── cecrl_progress_card.dart       Niveau global estimé + objectif + barre 6 segments A1→C2
    │       └── stats_row.dart                 3 mini-cards stats (Séances / Pratique / Jours actifs)
    ├── module_detail/             Écran détail intermédiaire entre hub et runner / sujets de tâche
    │   ├── civique_theme_detail_screen.dart   Hub d'un thème civique (single scroll, pattern QCM)
    │   ├── civique_theme_exams_screen.dart    Page « Examens blancs » d'un thème (10 slots 20 Q)
    │   ├── civique_hub_data.dart              Providers partagés hub thème + page examens civique
    │   ├── tcf_qcm_detail_screen.dart         Détail TCF CO/CE/Structure (enum TcfQcmModule) — onglet Séries = cards niveau
    │   ├── tcf_level_lots_screen.dart         Liste des lots pour un (module CO/CE/Structure, niveau A2/B1/B2)
    │   ├── tcf_lot_result_screen.dart         Bilan affiché à la fin d'un lot (score circle + résumé + CTAs)
    │   ├── production_exam_briefing_sheet.dart  Briefing modal examen 3-tâches EE/EO (enum vit dans tcf_production/)
    │   └── widgets/module_detail_widgets.dart Layout partagé (topbar, hero, stats, score card)
    │   (NB : TCF EE/EO n'a plus d'écran "détail" ni "sujets" ici — remplacés par
    │    tcf_production/tcf_expression_screen.dart, cf. plus bas)
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
    │   ├── tcf_expression_screen.dart   2 écrans : TcfExpressionScreen (hub /tcf/eo|ee :
    │   │                                carte examen blanc + 3 tâches + historique) et
    │   │                                TcfTaskTrainingScreen (/tcf/{eo,ee}/tache/:n : toggle
    │   │                                Sujets/Exemples + liste ; tap sujet → fiche consigne+plan
    │   │                                → Enregistrer/Rédiger ou Refaire/Voir le rapport).
    │   ├── tcf_production_module.dart   Enum TcfProductionModule (EO/EE) partagé écran + briefing
    │   ├── audio_recorder_service.dart  record 6 + permission_handler + audio_session
    │   ├── draft_service.dart           Brouillon EE en SharedPreferences
    │   ├── ee_session_controller.dart   Session EE (1 ou 3 tâches, attempt parent partagé)
    │   ├── eo_session_controller.dart   Session EO (idem)
    │   ├── ee_briefing_writing_screen.dart  Briefing + zone d'écriture combinés
    │   ├── eo_briefing_screen.dart      briefing + enregistrement fusionnés (+ finished + results)
    │   ├── history_session_screen.dart  Bilan détaillé d'une session (live ou historique) :
    │   │                                hero CECRL + détail par tâche tappable, polling
    │   │                                automatique sur les évals IA quand `?live=1`
    │   └── widgets/                     production_app_header, donut_chart_score,
    │                                    consigne_card, writing_zone, criterion_row,
    │                                    feedback_block, transcription_section,
    │                                    evaluation_report (corps partagé EE/EO),
    │                                    accomplishment_card, niveau_observe_card, etc.
    ├── review/                    Favoris + erreurs récentes (tabs)
    └── profile/                   Compte + paramètres + logout + suppression de compte
```

**Règle simple** : si une feature a son domaine métier (login, training, exam, runner...), elle a son dossier
dans `screens/`. Les widgets vraiment génériques (boutons, tags, cards) montent dans `core/widgets/`. Les
widgets locaux à une feature restent dans `screens/<feature>/widgets/`.

## Identité visuelle — refonte 2026 (maquette `SejourFR_Mobile_Autonome.html`)

L'app suit la maquette mobile autonome (design « bleu-blanc-rouge discret »). Couleurs
(toutes dans `core/theme/app_theme.dart`) :

- **Bleu France** : `#1E3A8C` (`AppColors.blue`, foncé `blueDark`, teinté `blueLight`/`blueSoft`)
- **Rouge France** : `#E1372F` (`AppColors.red`, foncé `redDark`, teinté `redLight`)
- **Neutres calmes** : `ink` / `inkSoft` / `inkFaint`, fonds `bg` < `surface2` < `surface3`,
  bordures `line` / `lineSoft`
- Sémantique parcours : **TCF = rouge, Civique = bleu** (toggles, héros, icônes de parcours)
- `masteryColor(0-100)` : rampe rouge → corail → ardoise → bleu → Bleu France pour les barres
  de maîtrise ; `masteryLabel()` pour le libellé qualitatif. `CecrlColor` inchangé (jamais de
  rouge pour un niveau).
- Rayons standard : `AppRadii.sm/md/lg/xl/pill` (8/12/18/26/999). Ombres : `AppShadows.card` (douce) / `.md`.

Typographies :

- **Bricolage Grotesque** (`AppFonts.display`) — titres, gros chiffres, tracking -0.02em
- **Hanken Grotesk** (`AppFonts.ui`) — corps, boutons, navigation ; `AppFonts.label` pour les
  petits labels bold
- `jakarta`/`fraunces` ont été **supprimés** (migration faite partout). `mono` reste en
  délégué **@Deprecated** vers du Hanken bold — à résorber au fil de l'eau, ne plus l'utiliser.

**Icônes** : `lucide_icons_flutter` (`LucideIcons.*`, trait fin géométrique comme la maquette).
Migration globale faite — ne plus introduire de `Icons.*` Material (seule exception :
`Icons.apple` du bouton Sign in with Apple).

**Primitives maquette** (`core/widgets/`) : `ScreenHeader` (en-tête fixe flouté, hors scroll),
`ListGroup`/`ListRow`/`SectionTitle` (listes encartées), `SegmentedTabs` + `parcoursSegments()`
(toggle TCF rouge / Civique bleu), `ProgressRing`, `ProgressTrack`, `StatValueCard`,
`showAppSheet` (bottom sheet à poignée), `AppButton` (pill — variants primary/accent/soft/
outline/ghost/danger), `AppCard` (r=18), `AppTag` (badge pill, tones).

**Le logo** reste le lockup `core/widgets/sejourfr_logo.dart` (Cocarde + Wordmark + Tagline).

**Ne jamais hardcoder une couleur** ailleurs que dans `app_theme.dart` — toujours `AppColors.*`,
`AppFonts.display/ui/label`, `AppRadii.*`.

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
- **Échec de démarrage d'un attempt** (série, examen blanc QCM, session EE/EO) : passer par
  `core/utils/start_failure.dart` — `showPaywallOrError(context, e)` ouvre le paywall sur un **403**
  (verrou freemium appliqué par le backend : statut premium en cache périmé, abonnement expiré en
  cours de session) et affiche le message backend sinon. `onForbidden:` sert à fermer un briefing
  avant d'empiler le paywall. **Ne pas réécrire ce `if (isForbidden)` dans un écran** : la règle vit à
  un seul endroit, et `classifyStartFailure` la verrouille en test.

**Formulaires**

- `Form` + `GlobalKey<FormState>` + `TextFormField` avec validators inline.
- Pour les erreurs serveur sur champs précis, le backend renvoie `fieldErrors: [{field, message}]` et
  `ApiException` les expose en `Map<String, String>`. Les afficher inline sous le champ correspondant.

**Navigation**

- Toujours utiliser `context.go(...)` ou `context.push(...)` de go_router. Pas de `Navigator.push` direct.
- Les routes sont centralisées dans `AppRoutes` (`core/router/app_router.dart`).
- Le router redirige automatiquement vers `/login` quand non authentifié, et vers `/` quand authentifié. **Pas
  besoin de gérer la redirection dans les écrans.**
- **Rafraîchir une liste au retour d'un flux poussé** : `core/router/route_observer.dart`
  expose `appRouteObserver` (branché sur `GoRouter.observers`). Un écran qui doit se
  ré-hydrater quand on **revient** dessus (un flux poussé au-dessus a modifié les données)
  mixe `RouteAware` : `appRouteObserver.subscribe(this, ModalRoute.of(context)!)` en
  `didChangeDependencies`, `unsubscribe` en `dispose`, et invalide son provider dans
  `didPopNext()`. ⚠ Ne pas se fier au `Future` d'un `context.push` pour ça : un flux qui fait
  des `pushReplacement` (briefing → résultats EE/EO) résout le push d'origine trop tôt, avant
  que la donnée (note d'évaluation) existe. L'observer est typé `PageRoute` → fermer un bottom
  sheet ne déclenche pas de refetch. Pattern utilisé par `TcfTaskTrainingScreen` (liste des
  sujets EE/EO). Combiner avec `async.when(skipLoadingOnReload: true)` pour éviter un spinner
  plein écran au retour.

**UI**

- Couleurs : **toujours** via `AppColors`, jamais en littéral hex.
- Polices : **toujours** via `AppFonts.jakarta()`, `AppFonts.fraunces()`, `AppFonts.mono()`.
- Spacing standardisé : 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32. Pas de 17 ou 23.
- Border radius : 4 (badges), 8 (boutons petits/chips), 10 (cards intérieures), 12 (boutons/inputs), 14 (
  cards), 16 (cards), 20 (modals).
- `withValues(alpha: 0.x)` pour la transparence (Flutter 3.27+) — pas `withOpacity` qui est déprécié.

**Hygiène (rappel transverse, cf. CLAUDE.md racine)**

- **Parité web ⇄ mobile (impératif)** : le mobile et le web partagent le même backend et doivent offrir
  **le même fonctionnement et le même rôle**. Tout **bug corrigé**, **changement** ou **ajout de
  fonctionnalité** sur une surface partagée (freemium, paywall, runner, examens, productions EE/EO, EO
  temps réel, chrono…) doit être **répercuté et vérifié sur l'autre front DANS LA MÊME PASSE** : aucune
  **régression** de l'autre côté, et les deux fronts restent **synchronisés au maximum**. Avant de fermer
  une tâche, se poser explicitement la question : « web et mobile font-ils exactement pareil, sans
  régression ? ». Détail complet : `CLAUDE.md` racine (Hygiène d'architecture).
- Si un widget apparaît 2 fois dans 2 écrans, **l'extraire** dans `core/widgets/` (générique) ou
  `screens/<area>/widgets/` (local à un domaine). Ex: `screens/hub/widgets/hub_home_widgets.dart` et
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

La config runtime (URL backend + Client IDs Google) vit dans `mobile_sejourfr/.env`
(non commité, gitignoré au niveau racine). Charge via `flutter_dotenv` au boot dans
`main.dart` → `Env.init()`, puis lue par `ApiConfig.baseUrl` et `SocialAuthConfig.*`
via le helper `core/config/env.dart`. `.env.example` est commité comme template :
`cp .env.example .env` puis remplir.

Cles attendues :

| Cle                       | Usage                                                                                    |
|---------------------------|------------------------------------------------------------------------------------------|
| `API_BASE_URL`            | Backend Spring. iOS sim = `http://localhost:8080`, Android emu = `http://10.0.2.2:8080`. |
| `GOOGLE_SERVER_CLIENT_ID` | Web client Google (passe en `serverClientId` au plugin). Vide → bouton Google masque.    |
| `GOOGLE_IOS_CLIENT_ID`    | iOS client Google (scheme natif inverse declare dans `Info.plist`).                      |

```bash
# Installer les dépendances + créer le .env local
flutter pub get
cp .env.example .env   # puis remplir les valeurs

# Lancer (les valeurs viennent de .env, plus besoin de --dart-define)
flutter run
```

Anciennement la conf passait par `--dart-define=API_BASE_URL=...` ; ces flags
sont desormais ignores (les getters ne lisent plus `String.fromEnvironment`).

Compte de test en dev (créé par le seed Flyway du backend) :

- `user@sejourfr.fr` / `User123!`
- `karim.test@sejourfr.fr` / `User123!`

Pour avoir des permissions natives (audio en arrière-plan, par exemple), penser à éditer
`ios/Runner/Info.plist` et `android/app/src/main/AndroidManifest.xml` selon les besoins. Pour l'instant, juste
internet suffit, c'est l'autorisation par défaut.

## Social sign-in (Google + Apple)

Activation : Google partout, Apple uniquement iOS. Cf. `CLAUDE.md` racine section
« Social sign-in » pour la vue d'ensemble + la sémantique de la colonne `auth_provider` côté
backend.

**Code mobile** :
- `core/auth/social_auth_config.dart` lit les Client IDs via `Env.read(...)`
  (cf. `core/config/env.dart` qui wrappe `flutter_dotenv`) :
  `GOOGLE_SERVER_CLIENT_ID` (le **Web client ID**, à passer en `serverClientId` à
  `google_sign_in` pour avoir un id_token consommable cote backend) et `GOOGLE_IOS_CLIENT_ID`
  (le iOS client, pour le URL scheme natif). Tant que vide dans `.env`, les boutons ne s'affichent pas.
- `core/auth/social_sign_in_service.dart` (provider `socialSignInServiceProvider`) encapsule
  `google_sign_in` + `sign_in_with_apple` et retourne un `SocialSignInResult { provider,
  idToken, firstName?, lastName? }`. Lève `SocialSignInException` (avec `cancelled: true` quand
  c'est une annulation user — à ne PAS afficher comme erreur dans le formulaire).
- `core/auth/auth_controller.dart::loginWithGoogle() / loginWithApple()` orchestre :
  service natif → `AuthRepository.loginWithGoogle/Apple` → store tokens via `TokenStorage` →
  passe en `AuthAuthenticated`. Le `logout()` appelle aussi `signOutAll()` Google pour vider la
  session native (sinon le prochain `signIn()` réutilise silencieusement le dernier compte).
- `screens/auth/widgets/social_auth_buttons.dart` : widget réutilisable rendu en haut des écrans
  `login_screen.dart` et `register_screen.dart`, avec un divider `OU` au-dessus du formulaire
  email/mdp.

**Config native iOS** (à compléter avec les vraies valeurs) :
- `ios/Runner/Info.plist` contient un `CFBundleURLTypes` avec
  `com.googleusercontent.apps.REVERSED_GOOGLE_IOS_CLIENT_ID` — remplacer par le scheme inverse
  du iOS Client ID Google.
- `ios/Runner/Runner.entitlements` contient `com.apple.developer.applesignin`. Ouvrir Xcode →
  cible Runner → Signing & Capabilities → "+ Capability" → "Sign in with Apple" pour que Xcode
  référence ce fichier. Activer aussi la capability sur l'App ID dans Apple Developer Portal.

**Config native Android** : rien à modifier dans le code. La config se fait dans Google Cloud
Console : ajouter un OAuth Client Android avec le package name + **3 SHA-1** : keystore debug,
keystore release (upload), **et la clé Play App Signing** (Play Console → Intégrité de l'app →
certificat de la clé de signature). ⚠ Avec un `.aab`, Google re-signe l'app → le build installé
depuis Play a le SHA-1 Play App Signing, pas celui de ta clé release : sans lui, Google Sign-In
échoue (`DEVELOPER_ERROR`/code 10) en test interne alors que ça marche en local. Le package
`google_sign_in` détecte tout via le `serverClientId` qu'on lui passe.

**Activer le social sign-in** : remplir `GOOGLE_SERVER_CLIENT_ID` (et `GOOGLE_IOS_CLIENT_ID`
sur iOS) dans `mobile_sejourfr/.env` (cf. § Démarrage local). Sans valeurs, les boutons
Google ne sont pas affichés. Apple s'affiche toujours sur iOS dès que l'entitlement est
activé (pas de clé à fournir).

## Connexion & inscription — « Se souvenir » + consentement CGU

- **« Enregistrer mes identifiants »** (`login_screen.dart`) : `AppCheckbox`
  (`core/widgets/app_checkbox.dart`). Cochée + login OK → email/mot de passe
  chiffrés dans le Keychain/EncryptedSharedPreferences via
  `TokenStorage.saveCredentials` ; au boot du login on prefill + on coche.
  Décochée → `clearCredentials`. Stockés **à part de la session** : un `logout`
  vide les tokens mais conserve les identifiants enregistrés.
- **Acceptation CGU + confidentialité à l'inscription** (`register_screen.dart`) :
  `AppCheckbox` (`labelTappable: false`) avec liens `Text.rich`
  (`TapGestureRecognizer`) ouvrant `${webBaseUrl}/{cgu,confidentialite}` dans la
  WebView (`AppRoutes.helpWebview`, mêmes URLs que le Centre d'aide). Case
  **obligatoire** : `_ensureAccepted()` garde le bouton « Créer mon compte » ET
  le social sign-in (`SocialAuthButtons.canProceed`).
- **Mention passive sous les boutons sociaux** (`social_auth_buttons.dart`,
  visible login + inscription) : « En continuant avec Google ou Apple, vous
  acceptez les CGU et la Politique de confidentialité » (liens WebView). Couvre
  la création de compte via social depuis l'écran de connexion (non gardée par
  la case d'inscription). Ne liste que les providers réellement affichés.

## Bottom nav et hubs Civique / TCF

**Refonte 2026 — nouvelle nav** : la bottom nav a 5 onglets **Accueil · Réviser · Examens ·
Progrès · Profil** (cf. maquette) :

- **Accueil** (`screens/home/`) : carte « À travailler en priorité » (catégorie la plus faible),
  3 stat cards (maîtrise/streak/niveau TCF), « Mes parcours », bloc IA EE/EO, raccourci examens.
- **Réviser** (`screens/reviser/`) : fusion des hubs Civique/TCF derrière `SegmentedTabs`
  (provider partagé `reviserParcoursProvider` — l'Accueil le présélectionne avant `goTab`).
  Liste des catégories avec anneau de maîtrise → écrans détail existants.
- **Examens** (`screens/examens/`) : examens blancs complets des 2 parcours derrière un toggle
  (`examensParcoursProvider`). Embarque `TcfFullExamsView` et `CiviqueFullExamsView` (corps
  extraits des écrans pleine page, qui restent pour les push profonds).
- **Progrès** (`screens/progres/`) : 3 anneaux de synthèse + listes encartées par parcours +
  `RecoScreen` (route `/progress/recommandations`). L'ancien `screens/stats/` est **supprimé**.
- **Profil** (`screens/profile/`) : carte identité, 3 stats, carte « Mon pass » →
  `ManageSubscriptionScreen` (carte gradient maquette + détails + inclusions, paywall pour
  prolonger), objectif, groupes compte/aide, déconnexion + suppression via `showAppSheet`.

**Données** : `GET /api/me/dashboard` (miroir `core/models/dashboard_models.dart`, provider
`core/providers/dashboard_provider.dart`) alimente Accueil/Réviser/Progrès en un appel —
streak, `globalSuccessPercent`, `estimatedTcfLevel`, stats par catégorie (codes `TCF_*` /
`CIV_*`, mapping icône/route partagé dans `core/utils/dashboard_targets.dart`).

**Les anciens hubs sont supprimés** : `screens/tcf/`, `screens/hub/`, `civique_screen.dart`
et leurs widgets n'existent plus. `/civique` et `/tcf` sont des **redirects** vers `/reviser`
(gardés pour les fallbacks et deep links).

**Pattern détail d'épreuve (refonte 2026)** — cf. `MLevels`/`MSeries` maquette :
- TCF QCM (`/tcf/{co,ce,structure}` → `TcfQcmDetailScreen`) : 3 cartes niveau A2/B1/B2
  (compteur « X/N séries faites » via `lotsProvider`) + historique des examens du module
  en dessous + bouton **« Examens blancs » fixé en bas** (`FixedActionBar`) → page des
  examens du module. Tap niveau → `TcfLevelLotsScreen` (« Séries » = les lots, cartes
  `SerieCard` partagées avec badge « Dernier X/Y » — `LotDto.lastScore` est le
  **dernier** score, pas le meilleur) + même bouton fixe.
- Civique (`/civique/theme/:themeId` → `CiviqueThemeDetailScreen`) : pas de niveaux —
  séries directes (cap 6 + « Voir plus ») + historique + bouton fixe → 10 examens du thème.
- `widgets/serie_card.dart` est la carte série partagée TCF/Civique ;
  `core/widgets/fixed_action_bar.dart` la barre fixe à fondu.
- Les cartes de slot d'examen partagées (`tcf_production/widgets/exam_slot/`) sont au
  style maquette : numéro Bricolage, pill « Fait » teinté accent, boutons pill.

Le quota démo (`kDemoBatchSize = 20`) et premium (`kInitialBatchSize = 30`)
vivent dans `core/widgets/paywall_sheet.dart` avec le bottom sheet `PaywallSheet` réutilisable.

Les 2 hubs (`screens/civique/civique_screen.dart` et `screens/tcf/tcf_screen.dart`) partagent une
structure visuelle identique implémentée dans `screens/hub/widgets/hub_home_widgets.dart`. Chaque hub
est un `ConsumerWidget` en **single scroll** (plus d'onglets internes : les anciens segments
*Entraînement / Examens blancs* ont été refondus pour matcher la maquette
`tcf_modules_home_screen.html` — home unique avec hero examen blanc + liste verticale des épreuves
+ bloc progression).

Sections successives (mêmes briques sur les 2 hubs) :

- `HubHomeHeader` : titre + sous-titre dynamiques (ex. « Préparer le TCF » + « IRN · 5 modules ·
  objectif B1 »). Bouton menu à gauche + cloche notifications à droite (placeholders, pas d'action
  branchée).
- `ExamBlancHero` : carte rouge teintée (`redLight` + `redDark`), eyebrow mono « EXAMEN BLANC
  COMPLET · 1H 35 », titre, description, CTA filled rouge. Tap → push la route examens du module.
  - TCF : push `AppRoutes.tcfFullExams` (`TcfFullExamsScreen` → 20 slots).
  - Civique : ouvre `showCiviqueExamBriefingSheet` puis POST `/api/attempts {type:MOCK_EXAM,
    module:CIVIQUE}` → runner. Pour les non-abonnés on resume l'attempt en cours ou on tombe
    sur le paywall si l'examen gratuit a été consommé.
- `SectionLabel` (« S'entraîner par épreuve / par thème ») + `SectionCounter` (« 5 modules »).
- Liste verticale d'`EpreuveCard` : icône colorée 44×44, titre + pill niveau (CSP/CR/NAT ou
  A2/B1/B2 selon `user.targetProcedure`), sous-titre court, **barre 3 px** + % à droite, chevron.
  - TCF : 5 cartes (CO bleu, CE vert, Structure ambre — pill « BONUS », EE gris neutre, EO rouge).
    Barre = **maîtrise** user `correct/total` du thème côté backend (`/api/me/stats`).
    EE/EO ont `progress: 0.0` en attendant que l'API expose un compte de submissions terminées
    par tâche (TODO inline).
  - Civique : N thèmes chargés via `/api/themes?module=CIVIQUE`, couleurs alternées
    (bleu/rouge/ambre/vert selon `displayOrder`).
- `SectionLabel('Ma progression')` + `SectionLink('Détails')` → push `/progress`.
- TCF : `CecrlProgressCard` (niveau actuel = `progression.lastFullExam.finalLevel` du dernier
  examen blanc complet ; objectif = `progression.tcf.targetLevel`, fallback dérivé de
  `targetProcedure`). Barre 6 segments A1→C2 colorée jusqu'au niveau courant.
- TCF uniquement : `StatsRow` (3 mini-cards). Seules les Séances sont branchées
  (`stats.attemptsTotal`) — Pratique (minutes) et Jours actifs sont en `—` tant que le backend
  ne les expose pas (TODO).
- Civique : `CiviqueMasteryCard` à la place du CECRL (Civique n'a pas de niveau CECRL) — affiche
  % de bonnes réponses sur questions tentées + couverture brute `answered/total`. Pas de stats row.

**Lien examen blanc complet TCF** : `TcfFullExamsScreen` (route `/tcf/examens-blancs`) reste
l'écran unique des 20 slots, atteint depuis le hero du hub TCF, le hero Progression, l'historique
et le bilan. `TcfFullExamsView` est le corps réutilisable qu'il enveloppe avec une topbar back.
L'ancien `civique_exam_blanc_view.dart` a été **supprimé** (plus utilisé après la refonte sans
onglets) ; pour Civique, le tap du hero démarre directement un MOCK_EXAM via le briefing modal.

**Modules affichés :**
- **Civique** = les 5 thèmes officiels chargés via `/api/themes?module=CIVIQUE` (Principes &
  symboles, Institutions, Droits & devoirs, Histoire-Géo, Société). Tap → push
  `/civique/theme/:themeId` (écran détail).
- **TCF** = 4 modules officiels IRN + 1 bonus, **tous** avec un écran détail :
  - CO → `/tcf/co`, CE → `/tcf/ce` → `TcfQcmDetailScreen` → CTA "Commencer l'entraînement"
    → `POST /api/attempts` + push runner.
  - EE → `/tcf/ee`, EO → `/tcf/eo` → `TcfExpressionScreen` : hub d'épreuve (carte examen
    blanc + 3 tâches + historique). Tap une tâche → `TcfTaskTrainingScreen` (sujets +
    exemples). Cf. § TCF Expression plus bas.
  - **Structure de la langue** → `/tcf/structure` → `TcfQcmDetailScreen` avec
    `TcfQcmModule.structure` (`questionType = STRUCTURE`). Bannière `_ModuleNoticeBanner`
    rendue sous le titre pour rappeler que le module n'est pas évalué au TCF IRN. Mêmes
    onglets Séries / Examens / Erreurs que CO/CE. Briefing examen rendu par
    `_BriefingCopy.forModule(...)` (durée 20 min, hero "Prêt à analyser ?", `_NoticeCard`
    sous le hero). Backend : `startModuleExam` accepte CO/CE/STRUCTURE, mais
    `startModuleExamSubAttempt` reste restreint à CO/CE (STRUCTURE jamais sous-attempt
    d'un examen blanc complet IRN).

**Écran détail (lot 3 + 3 bis)** — vit dans `screens/module_detail/`. Routes hors shell (pas de
bottom nav) :
- `/civique/theme/:themeId` → `CiviqueThemeDetailScreen` — **refondu** au pattern TCF QCM
  (single scroll, plus d'onglets segmentés). Header + hero rouge « Lancer un examen blanc »
  + section « S'entraîner par lot » + historique des 3 derniers examens du thème.
  Sous-widgets dans `widgets/civique_hub/` (civique_exam_hero / civique_lot_row /
  civique_history_section). Providers partagés dans `civique_hub_data.dart`
  (`civiqueThemesProvider`, `civiqueStatsProvider`, `civiqueThemeExamsHistoryProvider`),
  miroir de `qcm_hub_data.dart`. Civique n'a pas la notion de niveau (vs TCF A2/B1/B2) →
  les lots sont rendus inline avec un cap de 6 + "Voir plus" pour les thèmes copieux.
  L'onglet Erreurs a été supprimé (alignement sur le pattern QCM ; les erreurs restent
  accessibles via `/review`). Tap lot → `POST /api/attempts {type:TRAINING,
  module:CIVIQUE, themeId, lotNumero}` puis push runner (backend trace via `lot_theme_id`
  + `lot_numero`, cf. migration V089 + CLAUDE.md racine § Lots). Lot 1 = découverte
  gratuite du thème, lots 2+ paywall non-abonné.
- `/civique/theme/:themeId/examens` → `CiviqueThemeExamsScreen` — page « Examens
  blancs » d'un thème calquée sur `TcfQcmExamsScreen`. Header + drapeau France + 3 stats
  (Terminés / Score moyen / Meilleur score) + barre progression + chips filtre + 10 slots
  numérotés (20 Q du thème, 20 min, seuil 16/20). Slot 1 = découverte gratuite, slots 2-10
  = premium. Réutilise les widgets partagés `ExamSlotCard`, `ExamProgressCard`,
  `ExamFilterChips`, `FlagBadge`, `ModuleScreenHeader`, `ExamsErrorView` (dossier
  `tcf_production/widgets/`), + le builder local `CiviqueExamSlotBuilder` extrait pour
  rester sous 400 lignes. Distinct de l'examen blanc complet civique (40 Q tous thèmes,
  45 min, seuil 32) qui vit sur l'onglet Examens du hub.
- `/tcf/co` et `/tcf/ce` → `TcfQcmDetailScreen` avec l'enum `TcfQcmModule.{co,ce}` qui porte
  l'intitulé, l'icône, le `QuestionType` et le label de durée.
- `/tcf/eo` et `/tcf/ee` → `TcfExpressionScreen` (hub) ; `/tcf/{eo,ee}/tache/:n` →
  `TcfTaskTrainingScreen`. Enum `TcfProductionModule.{eo,ee}` dans
  `tcf_production/tcf_production_module.dart` (cf. § TCF Expression).

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
   - EE/EO : "Voir les tâches" → raccourci vers T1 = push
     `TcfProductionTaskSubjectsScreen(tacheNumero: 1)` (paywall si non-premium).
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
      `ExplanationBox`, on bloque les choix, puis le bouton "Question suivante" apparaît. Le bouton
      "Valider" appelle `submitCurrent`.
    - En **examen blanc** : pas de "Valider" — la réponse est soumise par les boutons "Suivant" /
      "Terminer" juste avant de naviguer. `submitCurrent()` renvoie un `bool` : en examen blanc, si
      la soumission échoue (réseau), on **n'avance pas** et on **ne finalise pas** (l'`errorMessage`
      reste affiché) — sinon la réponse de la question serait perdue silencieusement. Pas de
      correction immédiate (le backend renvoie `correct/correctChoiceIds = null`, que
      `AnswerResult.fromJson` coerce en valeurs neutres).
5. **Chrono** : pour les examens blancs, `ExamTimer` décompte depuis `attempt.startedAt` jusqu'à
   `timeLimitSeconds`. Quand ça atteint 0, finalisation automatique.
6. **Finalisation** : `POST /api/attempts/{id}/finish`, dialog de résultat avec score / seuil / passé-échoué.

**Ordre des choix** : le backend shuffle les choix (seedé par `AttemptQuestion.id`, donc stable
runner ↔ rapport pour un même attempt). Le mapping réponse cliquée → enregistrée → affichée se fait
**toujours par ID de choix réel**, jamais par position. Le tri d'affichage est centralisé dans
`orderedDisplayChoices()` (`core/models/question_models.dart`), partagé par le runner et le rapport
(`question_detail_sheet.dart`) : pour les questions TCF CO `FULL_AUDIO` (labels mono-lettre A/B/C/D),
on re-trie A→D ; les autres gardent l'ordre shuffle. À réutiliser partout où on rend des choix pour
garder runner et rapport cohérents.

**Reprise d'un attempt** : si l'utilisateur quitte le runner avant de finir, l'attempt reste en cours côté
backend. À la reprise, `RunnerController._load()` recalcule l'index de départ : première question non
répondue, sinon dernière.

**Médias** : le `QuestionDto.media` est un `MediaDto` optionnel avec un `type` (AUDIO/IMAGE/VIDEO) + une
`url`. Le `QuestionMediaView` dispatche vers le bon widget. Pour l'instant, les questions du seed ne
contiennent que du texte, mais l'architecture est prête pour le TCF complet.

## TCF Expression orale + écrite (`screens/tcf_production/`)

Module distinct du runner QCM : l'utilisateur **produit** un audio (EO) ou un texte (EE), envoyé au backend
qui le transcrit (Whisper) + le note (Claude) en 10-15 s. Cf. `CLAUDE.md` racine pour le pipeline backend.

**Deux écrans** (`tcf_expression_screen.dart`, remplacent l'ancien couple
`TcfProductionDetailScreen` + `TcfProductionTaskSubjectsScreen` supprimés). Accents refonte
2026 : **EO = rouge, EE = bleu** (cf. bloc IA de l'Accueil maquette).

1. **`TcfExpressionScreen`** — hub d'épreuve (`/tcf/eo`, `/tcf/ee`), même pattern que les
   détails CO/CE : `ScreenHeader` + **3 cartes tâche** (`_TaskCard` maquette `MTasks` : chip
   numéro 50, T1 EO badge « Présentation » rouge, description + nb de sujets) → push
   `/tcf/{eo,ee}/tache/N` ; **historique en dessous** (stats, dernier examen blanc →
   `…/sessions/{id}`, dernier entraînement → `…/resultats/{id}`, via `expressionHubProvider`) ;
   bouton **« Examens blancs » fixé en bas** (`FixedActionBar`, accent du module) →
   `ProductionExamsScreen` (10 slots).

2. **`TcfTaskTrainingScreen`** (`/tcf/{eo,ee}/tache/:n`) — entraînement d'une tâche :
   `SegmentedTabs` **Sujets / Exemples**. Les **sujets** = lignes `production_tasks` du
   (épreuve, tâche), marquées faite/non-faite (`listMine` → map
   `production_task_id → dernière submission`), rendues en cartes maquette `MTask`
   (`_ExerciseRow` : pastille mic/pen, énoncé, pill niveau + note /20, play/refaire).
   **Tap un sujet non fait → l'entraînement démarre directement** (`startSingle(task)` +
   briefing `/tcf/expression-{orale,ecrite}/t/0`) ; sujet fait → sheet Reprendre / Voir le
   détail. La bannière de consigne (`_IntroCard`/`ConsigneCard`) est teintée accent module
   avec liseré gauche 3 px. Segment **Exemples** = les **modèles**
   (`GET /api/production-examples?…`) ; tap → modal texte + `explications` + audio EO.

L'**examen blanc** (session 3 tâches enchaînées) reste fidèle au vrai TCF : **aucune correction
entre T1/T2/T3** ; après T3 → bilan détaillé (`HistorySessionScreen` `?live=1`, polling IA).

**Routes EO** (idem EE en remplaçant `expression-orale` par `expression-ecrite`) :
- `/tcf/expression-orale` → **redirige** vers `/tcf/eo` (l'ancien `ProductionHubScreen` est
  supprimé ; la sélection T1/T2/T3 vit sur le détail module). Le path est gardé en redirect
  côté router pour absorber les anciens liens et conserver le préfixe pour les sous-routes.
- `/tcf/expression-orale/historique` → liste des sessions passées (`ProductionHistoryScreen`)
- `/tcf/expression-orale/sessions/:attemptId[?live=1]` → bilan détaillé d'une session,
  `HistorySessionScreen`. En mode `live=1` (juste après T3) il poll les évaluations IA. Sinon
  (depuis historique) il lit la donnée déjà figée. Chaque ligne de tâche est tappable → push
  l'écran `resultats/:submissionId` du detail complet.
- `/tcf/expression-orale/t/:idx` → briefing **+ capture audio sur place** T(idx+1) (EO uniquement ;
  l'ancienne sous-route `/enregistrement` a été supprimée, cf. flow EO plus bas)
- `/tcf/expression-orale/t/:idx/termine` → écoute + soumission (EO uniquement)
- `/tcf/expression-orale/resultats/:id?taskIndex=N&history=1` → résultats détaillés d'une
  submission (correction IA complète) — push en single-task après soumission, ou depuis le
  bilan en tap d'une ligne.

**Correction IA affichée (contrat de notation v4)** — le corps des deux écrans de résultats
(EE + EO) est le widget partagé `widgets/evaluation_report.dart` : un seul endroit décide de
l'ordre et de la forme de la correction. Ordre imposé : **niveau observé** sur la tâche
(`niveau_observe_card.dart`) → **avertissements** (dont la limite « évaluation fondée sur la
transcription » à l'oral, jamais enterrée en bas d'écran) → **accomplissement**
(`accomplishment_card.dart`, check-list de la consigne, **avant** la langue) → détail par
critère → points forts → **priorités** (`points_a_ameliorer`, 2 max côté backend) →
corrections → suggestion.

- **Par critère on affiche la bande, pas la note** : `CriterionScore.bande` (`BandeCritere`,
  calculée côté serveur) → « Très bonne maîtrise / Satisfaisant / En cours d'acquisition /
  Fragile / Non évaluable », plus la `preuve` (citation littérale) sous le commentaire. La
  **note globale /20 reste affichée** (donut). La table icône↔code de `criterion_row.dart`
  couvre les 10 codes v4 (`realisation_consigne`, `adequation_destinataire`,
  `chronologie_recit`, `developpement_reponses`, `prise_position`, `argumentation`,
  `conduite_echange`, `lexique`, `morphosyntaxe`, `coherence`) **et** les codes v3 encore en
  base — un test verrouille qu'aucun ne retombe sur l'icône par défaut.
- **Garde-fou non négociable** : jamais de niveau sans sa confiance
  (`EvaluationResult.hasNiveauObserve`). Le **bilan d'épreuve** reste le seul niveau qui fait
  foi.
- **La note /20 est PÉDAGOGIQUE, pas une note de TCF** (notre échelle : 16-20 = B2,
  11-15 = B1… ; au TCF IRN 10/20 vaut déjà B2). `DonutChartScore` le dit et n'affiche
  **aucune** correspondance TCF — une tâche isolée n'a pas de note officielle. La
  correspondance (`ProductionBilan.correspondanceTcf` → `CorrespondanceTcf.phrase`) ne
  s'affiche qu'au **bilan d'épreuve** (`BilanHero`), au même wording que le web.
  Cf. `docs/notation-ia-eo-ee.md` §6.6.
- **Rétrocompatibilité v3** : `niveauObserve` / `confiance` / `avertissementNiveau` / `bande` /
  `accomplissement` / `preuve` absents = cas **normal** (évaluations déjà en base) → les blocs
  concernés disparaissent et l'écran redevient celui d'avant. Couvert par
  `test/production_models_test.dart` + `test/evaluation_report_test.dart`.

**Modélisation (sémantique clé)** : `production_tasks` = les **SUJETS** d'entraînement —
plusieurs lignes par (épreuve, tacheNumero), chacune un sujet concret (ex. « Vous êtes
mécanicien, présentez-vous »). Le candidat en choisit un et produit sa réponse, corrigée par
l'IA. `production_examples` = des **MODÈLES** illustratifs rattachés à la tâche (`task_id`)
+ un champ `explications` (commentaire pédagogique) ; ils se listent par (épreuve,
tacheNumero) et ne dépendent **pas** du sujet choisi. **Les situations ont été supprimées**
(plus de `production_situations` / `_situation_medias` / supports visuels ni plan d'aide
`etapes`/`declencheur`).

**Adaptation assumée** : le panneau de production ne réenregistre/ré-rédige pas inline — il
réutilise le flux briefing → enregistrement (EO) / `ee_briefing_writing_screen` (EE) déjà
éprouvé, sur le sujet (task) sélectionné. L'ancien `ProductionHubScreen`,
`TcfProductionDetailScreen` et `TcfProductionTaskSubjectsScreen` sont **supprimés**.

**Backend du contenu d'entraînement** (cf. CLAUDE.md racine) :
- `V107`→`V109` (historiques) : avaient créé `production_situations` + supports + colonnes
  audio sur `production_examples`.
- `V135` : **supprime** `production_situations` + `production_situation_medias` + la colonne
  `production_submissions.situation_id`, et ajoute `production_examples.explications`.
- Seed : `V133`/`V134` (situations historiques, droppées) puis `V136` (sujets EO T1 variés +
  ré-seed des exemples avec `explications`, rattachés par catégorie).
- Audio EO des exemples : batch admin (Azure Speech + R2) ; le candidat ne voit `audioUrl`
  que `PUBLISHED` (bouton « ▶ Écouter » dans le modal exemple).
- Endpoints lecture : `GET /api/production-tasks?epreuve=…&tacheNumero=…` (sujets),
  `GET /api/production-tasks/{id}` (détail sujet), `GET /api/production-examples?epreuve=…&tacheNumero=…` (modèles).
- La correction IA réutilise le pipeline existant (Whisper + Claude).

**Flow EO (2 écrans + résultats)** — single-task : le SessionController a juste 1 tâche. Les écrans
suivent le « studio » du template `SejourFR_Mobile_Autonome.html` : **consigne épinglée en haut,
action en bas, UI épurée** (cf. `clicktcf-web/src/features/speaking`). ⚠️ **Briefing et
enregistrement sont fusionnés sur un seul écran** (`eo_briefing_screen.dart`) : on n'ouvre plus de
page intermédiaire pour capturer — le tap sur le micro lance la capture sur place. La route
`/t/:idx/enregistrement` et l'ancien `eo_recording_screen.dart` ont été **supprimés**.
1. **Briefing + enregistrement** (`eo_briefing_screen.dart`, écran unique à 2 phases pilotées par
   `recordingControllerProvider.phase`) :
   - **idle** : `ConsigneCard` rouge (consigne complète) en haut + panneau bas `_MicStartButton`
     (gros micro rond style « idle » du template + invite à parler). Tap → permission micro via
     `recorder.requestPermission()` (le package `record` — ✋ **ne pas utiliser `permission_handler`
     seul** : il court-circuite l'auth iOS dans certains cas et ne déclenche pas le dialog) →
     `recorder.start(maxDuration: dureeMaxSec)` **sans navigation**.
   - **recording** (`_RecordingView`) : `ConsigneCard` rouge compacte (`maxLines: 3`) en haut, puis
     bloc centré REC pill + timer big + waveform animée rouge (33 barres calées sur l'amplitude
     réelle + sinusoïde, param `color`) + bouton stop rond rouge. Stop manuel ou auto-stop à
     `dureeMaxSec` → le service passe en `finished` → un `ref.listen` pousse `…/t/:idx/termine`
     (garde `_navigated` anti-double-push). `initState` appelle `recorder.cancel()` pour repartir
     d'un état au repos (sinon un `finished` résiduel d'une tâche précédente naviguerait aussitôt).
     `PopScope`/flèche retour passent par une confirmation d'abandon pendant la capture.
2. **Finished** (`eo_finished_screen.dart`) : `ConsigneCard` rouge compacte (`maxLines: 2`) +
   check vert + mini-player just_audio sur le fichier local + CTA "Voir mon évaluation" → swap vers
   `EvaluationLoadingView(includeTranscription: true)` pendant l'upload R2 + Whisper + Claude
   (~15 s), puis push résultats.
4. **Résultats** (`eo_results_screen.dart`) : score donut (couleur = rampe `masteryColor`,
   plus de violet hors palette) + critères + feedback + **transcription
   Whisper**. Atteint en single-task après soumission, ou depuis le bilan en tap d'une ligne, ou
   depuis l'historique des sessions passées (mode `isHistory`). En 3-tâches, `eo_finished_screen`
   **bypasse** ce screen entre les tâches : il push direct le briefing suivant, et après T3 le
   bilan détaillé. CTAs : "Retour aux sujets" (single-task) ou "Continuer l'examen blanc" (full
   TCF exam) ou "Retour" (history).

**Flow EE** : 1 seul écran combiné `ee_briefing_writing_screen.dart`, épuré sur le modèle du
template (`clicktcf-web/src/features/writing`) : **consigne en haut, saisie en bas**. La ListView
ne contient plus que `ConsigneCard` (bleue, consigne + « Longueur attendue : X à Y mots ») +
`WritingZone` (textarea avec compteur de mots, barre de progression et statut intégrés dans son
en-tête). Les ex-cartes `MotsCard` / `CriteresCard` / `PreparationCard` ont été **supprimées** du
flow (le compteur de `WritingZone` rend `MotsCard` redondant ; les critères réapparaissent dans le
feedback). Brouillon auto-save 3 s dans `SharedPreferences` via `EeDraftService`.
- Textarea avec `FocusNode` partagé entre le screen state et `WritingZone` → quand le clavier ouvre,
  les 2 boutons du bas (Valider / Brouillon) disparaissent → le textarea grandit (`minLines: 12`).
  `keyboardDismissBehavior: onDrag` sur la ListView. **Important** : ne pas conditionner les enfants
  de la ListView sur le focus avec `if (!isWriting) ...[ConsigneCard, ...]` — ça change les indices
  et Flutter recrée le State de `WritingZone` → focus perdu, clavier se ferme immédiatement. Garder
  tous les enfants présents + ValueKey stable sur chacun.
- `TextField.onTapOutside: (_) => focusNode.unfocus()` pour dismiss le clavier au tap hors champ (API
  officielle Flutter 3.10+). **Ne pas** wrapper le body dans un `GestureDetector(onTap: unfocus)` : ça
  rentre en compétition avec le tap de focus du TextField → "il faut 2 taps pour ouvrir le clavier".
- Bordure bleue 1.5px + fond `blueSoft` + ombre douce au focus, `AnimatedContainer` 150ms.
- Info button (`ProductionAppHeaderInfo`) du header ouvre une `showModalBottomSheet` avec le texte de
  confidentialité (cf. `_ConfidentialitySheet` privé dans le screen).

**Sessions** : `EeSessionController` / `EoSessionController` (StateNotifier **non-autoDispose**) portent
les tasks (1 en single-task, 3 en session examens) + l'attempt parent + la map des submissions + un
flag `isExam` + le `slotNumber`. Points d'entrée :
- `startExam(slotNumber:N)` → **session d'examen blanc module** : `POST /api/attempts/production
  {exam:true, slotNumber:N}` (l'AttemptResponse porte `timeLimitSeconds` = **1800** pour l'EE, null
  pour l'EO, + `startedAt`) puis `GET /api/attempts/{id}/production-exam-tasks` → **3 tâches
  déterministes** (slots 1-3 = A2, 4-6 = B1, 7-10 = B2). **Plus de paramètre `niveau`** : le niveau
  user ne pilote plus la composition. 10 examens par épreuve.
- `startSingle(task:...)` → mode entraînement libre (1 tâche pickée par le hub), `isExam=false`.
- `startInFullExam(subAttemptId:...)` → reprend le sous-attempt EE/EO d'un examen TCF complet et charge
  ses 3 tâches via `getExamTasks` (composition gérée backend selon le slot du parent + niveau cible).
- `finishAttemptIfExam()` → `POST /finish` sur l'attempt courant (no-op hors examen module). Appelé
  après la 3e soumission acquittée, à l'expiration du chrono et à l'abandon confirmé.
- `refreshSubmission(taskIndex)` permet au bilan d'aller chercher la dernière version d'une
  submission (utilisé par le polling mode `live=1` de `HistorySessionScreen`).

`production_repository.dart` : `startProductionAttempt` gagne `exam`/`slotNumber` ; nouvelle méthode
`getExamTasks(attemptId)` (3 tâches) ; `finishAttempt(attemptId)`. `ProductionBilan` (models) gagne
`slotNumber` (mapping session → slot dans la grille) + `finished` (l'examen a `finishedAt` posé).

**Chrono d'examen EE (30:00)** : `ee_briefing_writing_screen` affiche un `ExamTimer`
(`screens/question_runner/widgets/exam_timer.dart`, réutilisé) dans le `trailing` du
`ProductionProgressStrip`, ancré sur `attempt.startedAt` + `timeLimitSeconds` (module ; survit à un
kill/reprise) ou 1800 s côté front (examen complet, pas de `timeLimitSeconds` backend). À 0:00 :
auto-soumission du texte courant **s'il est recevable** (mots ∈ [motsMin, motsMax×1.2]), sinon rien ;
puis `finish` (module) / `markSubDone` (complet) ; puis bilan.

**Chrono d'examen EO (15:00)** : `eo_briefing_screen` rend le même `ExamTimer` dans le `trailing` du
`ProductionProgressStrip` **dès que l'attempt porte un `timeLimitSeconds`** (900 s posées par le
backend sur une session d'examen module EO). Ancré sur `startedAt`, il court à travers les 3 tâches et
survit à un kill/reprise. À 0:00 : `_handleExamTimeout` pose `_navigated` **avant** de stopper la
capture (sinon `_onCaptureFinished` enchaînerait la tâche suivante en parallèle), soumet l'audio
capturé en best-effort, puis `finish` + bilan. Absent en entraînement libre et sur le sous-attempt EO
d'un examen complet (attempt fabriqué côté client, sans `timeLimitSeconds` — le temps global y est
tenu par le `_GlobalTimer` du hub). En plus de ce chrono global, `_TimerBig` passe en **décompte**
(`countdown:true`, `dureeMaxSec` → 0) pendant l'enregistrement en mode examen.

**EO en examen** : au stop (manuel OU auto-stop), pas d'écran `eo_finished_screen` entre les tâches —
le briefing soumet immédiatement (`_submitExamAndAdvance`) et enchaîne la tâche suivante (ou le bilan
après T3). L'entraînement libre garde le flux réécoute + soumission manuelle.

**Auto-soumission de fin de temps (EO examen)** : l'arrêt à `dureeMaxSec` est garanti par un
`Timer` **possédé par l'écran** (`_examAutoStop` dans `eo_briefing_screen`, armé à
`_startRecording`) qui appelle `_forceExamSubmit` → stop + `_onCaptureFinished`. On ne se fie plus
au seul ticker interne de `AudioRecorderService` relayé par `ref.listen` (éphémère, lié au build) :
ça ratait l'auto-soumission de la 3e tâche EO en examen complet. Le ticker du service auto-stoppe
toujours en parallèle (entraînement libre + redondance) ; les deux chemins convergent sur
`_onCaptureFinished`, idempotent via `_navigated`. Le service expose désormais le vrai
`maxDuration` dans le flux d'amplitude (avant : 3 min codé en dur → « temps restant » qui oscillait).

**Abandon en examen** (PopScope/back EE+EO) → confirmation → `finish`/`markSubDone` (copie ramassée :
tâches manquantes comptées 0) puis sortie. **Fin normale** (3 tâches) → `finish` AVANT le bilan.

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

**Freemium (parité web/backend)** : l'examen complet n'est plus 100 % premium.
`TcfFullExamsView` ouvre le **slot 1 aux comptes gratuits** (examen offert,
EE/EO évaluées une fois) ; les slots 2-20 affichent un cadenas → `showPaywallSheet`
(`_ExamSlotCard.locked = !isPremium && slot > 1`). Le briefing
(`TcfFullExamBriefingSheet isFreeAccount`) rappelle que l'EE/EO n'est offerte
qu'une fois. Au refaire de l'examen 1, le backend renvoie les sous-attempts EE/EO
avec `FullTcfExamSubAttempt.locked=true` (pré-terminés) : le progress screen et
le bilan les rendent « Réservé à l'abonnement Intégral » + cadenas (jamais badge
niveau ni check vert ni lien). Miroir `locked` dans `core/models/full_tcf_exam.dart`.

- **`TcfFullExamProgressScreen`** (route `/tcf/examen-blanc/:parentId`) — hub de progression. Charge le
  parent + ses 4 sous-attempts via `fullTcfExamProvider` (FutureProvider.autoDispose.family), affiche 4
  cards d'étape (CO/CE/EE/EO) avec leur état Done/Current/Locked, CTA « Commencer · [épreuve courante] »
  qui push :
  - **CO/CE** → runner QCM standard `/runner/$subAttemptId?from=fullTcf&fullExamId=$parentId`. Le runner
    détecte la query (`runner_screen.dart::_navigateToResult`) et redirige vers ce hub au finish au lieu
    du dialog d'examen.
  - **EE/EO** → briefing existant `/tcf/expression-X/t/0?fullExamId=$parentId&subAttemptId=$subId`. Le
    briefing détecte la query et appelle `EeSessionController.startInFullExam(subAttemptId:)` /
    `EoSessionController.startInFullExam(subAttemptId:)` — ces variantes REPRENNENT l'attempt existant
    côté backend (sans `niveau`) et chargent ses 3 tâches via `getExamTasks`. L'EE complet a un chrono
    30:00 front-side ; l'EO complet enchaîne tâche par tâche comme le module.
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

**Niveau CECRL** : le mobile ne choisit plus le niveau des tâches EE/EO — la composition des 3 tâches
du sous-attempt est **déterministe côté backend** (selon le slot du parent + niveau cible du user),
récupérée telle quelle via `getExamTasks(subAttemptId)`. Le bilan agrégé reste en CECRL plancher.

**Flow utilisateur typique** :
1. Hub TCF → onglet "Examens" (`TcfFullExamsView`, 20 slots)
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

## In-App Purchase (lot 4d) — Apple StoreKit + Google Play Billing

Depuis le **lot 4d**, le mobile vend les abonnements via **IAP natif**, plus
par redirection web (obligatoire d'après les guidelines Apple/Google quand on
vend du contenu digital). L'ancien `openSubscriptionWeb()` est supprimé.

**Architecture** :
- `core/models/billing_models.dart` — DTOs miroirs `/api/billing/*`
  (`PlanPublicResponse`, `SubscriptionStatusResponse`, `VerifyReceiptRequest`)
  + enums `PlanPeriodicity` (monthly/quarterly/yearly), `PlanModuleTarget`
  (CIVIQUE/INTEGRAL), helper `planCodeFor(module, periodicity)`.
- `core/api/billing_repository.dart` — 3 endpoints :
  - `listPlans()` (public)
  - `getSubscriptionStatus()` (authentifié, source de vérité Premium)
  - `verifyReceipt(req)` (authentifié)
- `core/billing/iap_service.dart` — wrapper sur `in_app_purchase` 3.x :
  `init`, `loadProducts(skuIds)`, `purchase(product)`, `restorePurchases`,
  `completePurchase`, `purchaseStream`. `IapService.currentSource` détecte
  iOS→Apple / Android→Google. `IapService.receiptFor(purchase)` extrait le
  bon format selon la plateforme (JWS Apple ou purchaseToken Google).
- `core/billing/billing_controller.dart` — `StateNotifier<BillingState>`
  s'abonne au `purchaseStream`, charge plans backend × SKUs store, déclenche
  `verify-receipt` sur PURCHASED/RESTORED puis acquitte le store et refresh
  `AuthUser` via `AuthController.refreshSubscriptionStatus()`.
- `screens/paywall/paywall_screen.dart` — UI plein écran avec toggle
  périodicité (mensuel/trimestriel/annuel) + 2 cards Civique/Intégral.
  Prix lus depuis le store en devise locale. Bouton « Restaurer mes achats »
  obligatoire pour validation Apple. **Guideline 2.3.10** : tout texte de store
  est conditionné par plateforme via le helper `_storeName` (`Platform.isIOS`) —
  on n'affiche JAMAIS « Google Play » sur iOS ni « App Store » sur Android
  (`_TrustRow`, `_LegalLinks`). Le reste du billing passe déjà par
  `IapService.currentSource`.

**Flow d'achat** :
1. User tap CTA premium → `showPaywallSheet(context)` push l'écran.
2. `BillingController.load()` appelle `listPlans()` puis
   `IapService.loadProducts({skus})` qui retourne `ProductDetails` (prix,
   devise, titre, description) depuis le store.
3. User choisit périodicité + tap card → `BillingController.startPurchase()`
   → `iap.buyNonConsumable()` ouvre l'UI native (sheet Apple / dialog Google).
4. User confirme → `purchaseStream` émet `pending` puis `purchased`.
5. Sur `purchased` → `verify-receipt` au backend (qui re-valide auprès du
   store, source de vérité unique) → renvoie `SubscriptionStatusResponse`.
6. `AuthController.refreshSubscriptionStatus(status)` met à jour
   `hasCivique/hasTcf/premiumEndsAt` sur le user → l'app sort du mode démo.
7. `iap.completePurchase()` acquitte au store (sinon retentatives en boucle).

**Sécurité** :
- L'app NE décide JAMAIS du statut Premium — c'est le backend après vérif
  store qui tranche. `AuthUser.hasCivique/hasTcf` est rafraîchi à 3
  moments : (a) au boot via `/subscription-status`, (b) après login,
  (c) après chaque `verify-receipt` OK.
- Si le backend échoue après un achat store réussi (network down), on
  N'ACQUITTE PAS le store. Au prochain démarrage le `purchaseStream`
  re-livre l'achat → retry automatique. Le user n'a pas payé deux fois.

**Affichage des prix d'un pass** (`_PassRow`) : le **prix réellement débité**
en gros, l'équivalent mensuel en sous-texte (« soit 13,33 €/mois »). Un pass
se paie une fois — un « /mois » en principal laisserait croire à un
abonnement. Même hiérarchie côté web (`/paiement`, `/tarifs`) : ne pas
réinverser d'un seul côté.

**Restore purchases** : bouton **« Restaurer mes achats »** (variante secondary,
sous les cartes du paywall).

⚠ **Un consommable ne se restaure PAS.** En mode passes one-time (catalogue
100 % consommable, cf. `state.products.every(isOneTime)`), `restorePurchases()`
**ne déclenche AUCUN sync StoreKit** : l'accès vit côté backend
(`user_subscriptions`, durée posée par `plan.durationDays`), pas dans le store.
Le bouton relit donc `GET /api/billing/subscription-status` + refresh
`AuthUser`, puis réutilise le chemin d'affichage de l'achat (snackbar d'issue
via `_outcomeFor`, fermeture si Premium ; sinon « Aucun achat à restaurer pour
ce compte. »). C'est LE vrai restore pour un compte qui a déjà payé
(réinstallation, nouvel appareil, pass en cours).
**Pourquoi** : Apple ne restaure jamais un consommable, et StoreKit 2 (plugin
`in_app_purchase`) **re-livre des transactions consommables périmées en boucle
en `PurchaseStatus.restored`** (flutter/flutter#180046, #85529) — passer
`restorePurchases()` sur un catalogue de passes faisait remonter « Achat validé
côté store, mais nous n'avons pas pu activer votre accès » à chaque restauration.
En **mode abonnement** (dormant), on garde le vrai sync StoreKit + le
**garde-fou anti-spinner-infini** : `_restoreInFlight` + `Timer`
(`_restoreTimeout`, 8 s) qui débloque l'UI si le store n'émet aucun event,
désarmé (`_endRestore`) dès qu'un event arrive.

**Défense en profondeur** : toute transaction `PurchaseStatus.restored` qui
échoue à `verify-receipt` est **acquittée en silence** (jamais de bannière
d'erreur) — l'utilisateur ne l'a pas déclenchée, c'est un consommable périmé
re-livré par StoreKit au boot / à l'ouverture du paywall. Cf.
`_verifyAndAcknowledge` (branche `restored` après le 409).

**SKUs** : le mobile lit les Product IDs store **directement depuis le backend**
(`PlanPublicResponse.appleProductId` / `googleProductId`, exposés par
`/api/billing/plans`). `_skuFor()` retourne l'ID de la plateforme courante
(Apple ou Google) tel quel — **plus de dérivation depuis `Plan.code`**. Un plan
dont l'ID store de la plateforme est `null` est filtré (non vendable ici, ex.
plan FREE ou web-only Stripe → il n'apparaît pas au paywall).

⚠ Conséquence : les colonnes `plans.apple_product_id` / `plans.google_product_id`
**doivent être renseignées** (admin → Plans, ou seed dev) avec les Product IDs
EXACTS créés dans App Store Connect / Play Console — sinon `loadProducts` ne les
trouve pas (`notFoundIDs`) et les cards ne s'affichent pas. Les IDs Apple et
Google peuvent **diverger de `Plan.code`** : c'est nécessaire car un Product ID
Apple supprimé **n'est jamais réutilisable**, donc une recréation impose un ID
neuf. (Google impose des IDs en minuscules ; Apple tolère les majuscules — mais
l'app n'impose plus aucune casse, elle envoie ce que dit le backend.)

⚠ Type de produit Apple : les passes one-time **doivent être des Consommables**
(ré-achetables à l'infini, Apple ré-affiche la sheet à chaque achat). Un
Non-Consommable est « possédé à vie » → Apple refuse le rachat et restaure la
transaction d'origine (même `transactionId`) → le backend la traite en *replay*,
aucune prolongation. La durée d'accès est posée par le backend
(`plan.durationDays`), pas par Apple.

**Setup natif requis** (à faire avant les tests sandbox) :
- iOS : Xcode → Runner → Signing & Capabilities → +In-App Purchase.
  App Store Connect → Subscriptions → créer le Subscription Group + les 6
  SKUs. TestFlight pour le sandbox.
- Android : Play Console → Monetisation → Subscriptions → créer les 6
  Base Plans (un par SKU avec billing period correspondant). Testing track
  + comptes Google de test.

**Ancien comportement (avant lot 4d)** : `openSubscriptionWeb()` redirigeait
vers `https://sejourfr.fr/paiement`. Supprimé — Apple aurait rejeté l'app
au review (3.1.1). Si on a besoin de référencer une URL web pour les CGV,
utiliser `url_launcher` ponctuellement, jamais pour le paiement.

**Résiliation** : écran `screens/profile/manage_subscription_screen.dart`
accessible via tap sur la `_PlanCard` du profil quand l'user est Premium
(route `AppRoutes.manageSubscription = /profile/abonnement`). Affiche
plan + source + date de renouvellement + CTA rouge « Résilier mon
abonnement » avec confirmation. Appelle directement `BillingRepository.cancel()`
(pas via `BillingController`, dont l'état est dédié aux achats IAP) puis
gère la réponse :
- `action=DONE` (Stripe) : `AuthController.refreshSubscriptionStatus()`
  pour propager `autoRenew=false` + status CANCELED sur la PlanCard,
  SnackBar de confirmation.
- `action=REDIRECT` (Apple/Google) : ouvre `redirectUrl` via `url_launcher`
  en `LaunchMode.externalApplication`. Sur iOS l'URL
  `https://apps.apple.com/account/subscriptions` ouvre directement les
  Settings → Subscriptions ; sur Android, redirige vers la fiche Play.
  Le statut local ne bascule QUE quand le webhook du store confirme.

## Page « À propos » (conformité stores — Misleading Claims)

`screens/help/about_screen.dart`, route publique `AppRoutes.about = /about` (exemptée du
redirect login comme la WebView légale). Écran **natif** (consultable offline) exigé par la
Misleading Claims policy Google Play : encart disclaimer de non-affiliation (fond `blueLight`,
texte `ink` — **jamais de rouge** dans cet encart) + 4 liens sources officielles
(service-public.fr, immigration.interieur.gouv.fr, france-education-international.fr, ofii.fr)
ouverts via `url_launcher` en `LaunchMode.externalApplication` (snackbar si échec hors ligne).
Trois points d'entrée : tile « À propos de SejourFR » du profil (section Aide & informations
légales), tile du Centre d'aide, et la note `_IndependenceNote` en bas du home (« Outil
indépendant — non affilié à l'État français · En savoir plus »). **Ne pas reformuler le
disclaimer d'une manière qui affaiblirait la non-affiliation.** Pas de référence cross-store
dans cet écran. Équivalent web : `/a-propos`.

## Suppression de compte (App Store 5.1.1(v))

Entrée « Supprimer mon compte » dans `profile_screen.dart` (section Compte, tile
rouge `_confirmDeleteAccount`). Flow : dialog de confirmation → `AuthController.
deleteAccount()` (`DELETE /api/account`, **n'altère PAS la session**) → si un
abonnement Apple/Google reste à résilier, dialog « Compte supprimé » avec le
`manualActionMessage` du backend (affiché tant que l'écran est monté) → puis
`AuthController.logout()` vide la session et le router redirige vers `/login`.
On sépare volontairement l'appel réseau de la déconnexion pour que le message
d'action manuelle s'affiche avant la redirection. Modèle `core/models/
account_models.dart` (`AccountDeletionResult`), miroir de `AccountDeletionResponse`.
Backend : anonymisation (cf. CLAUDE.md racine + `docs/api-endpoints.md`).

## Roadmap (ce qui n'est pas encore fait)

- ~~**Chrono global examen blanc**~~ ✅ fait. Le chrono global 90 min est affiché en haut du
  progress screen (`_GlobalTimer`), ancré sur `FullTcfExamResponse.timerStartedAt` (lancement réel de
  la CO), pas sur `startedAt` (création) — figé à 90:00 tant qu'aucune épreuve n'a démarré. Chaque
  épreuve garde **en plus** son chrono propre (CO 20 / CE 30 via `time_limit_seconds` du sous-attempt) :
  `_startStep` appelle `POST /api/full-tcf-exams/{id}/begin?epreuve=…` (`beginEpreuve`) AVANT d'ouvrir le
  runner, ce qui recale `started_at` du sous-attempt sur le lancement réel. Sans ce recalage, la CE —
  créée en même temps que la CO — héritait du temps déjà écoulé et démarrait amputée (bug « la CE
  n'avait que 10 min »). Les deux chronos coexistent : le premier à 0 force la suite (auto-finish
  sous-attempt côté runner / auto-finalisation de l'examen côté hub).
- **Offline-first** : pas de SQLite/Drift pour l'instant, tout passe par le réseau. À ajouter dans
  `core/storage/` quand on aura besoin (questions civiques stables, peuvent être cachées).
- **Notifications push** (rappels d'entraînement) : à ajouter via `firebase_messaging` ou OneSignal.
- ~~**In-app purchase** (Premium)~~ ✅ fait au lot 4d (cf. section dédiée plus bas).
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