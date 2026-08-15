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
│   │   ├── diagnostic_repository.dart  Reprise/démarrage/polling du diagnostic TCF
│   │   ├── learning_plan_repository.dart  Plan adaptatif de l'utilisateur
│   │   ├── audience_repository.dart  Événements agrégés publics (sans donnée perso)
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
│   │   ├── diagnostic_models.dart Diagnostic, observations et plan (miroirs serveur)
│   │   └── attempt_models.dart
│   ├── router/
│   │   └── app_router.dart        Routes + redirects auth
│   ├── theme/
│   │   └── app_theme.dart         Couleurs, typographies, Material theme
│   ├── utils/
│   │   └── selected_module.dart   Provider du module actif (CIVIQUE/TCF)
│   └── widgets/                   Primitives UI réutilisables
│       ├── audio_player.dart      SejourAudioPlayer (just_audio, source distante)
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
    │   └── main_shell.dart        Bottom nav 5 onglets : Accueil · Réviser · Examens · Plan · Profil
    ├── diagnostic/               Parcours initial EE + EO, reprise serveur et résultat léger
    │   ├── diagnostic_controller.dart  StateNotifier + soumissions standard + polling
    │   ├── diagnostic_screen.dart
    │   └── widgets/              Présentation, écrit, oral, analyse, résultat
    ├── plan/                     Priorité immédiate + séance recommandée + observations
    │   ├── learning_plan_provider.dart
    │   └── plan_screen.dart
    ├── hub/
    │   └── widgets/hub_home_widgets.dart  Widgets partagés des 2 home hubs
    │                                     (HubHomeHeader, ExamBlancHero, EpreuveCard, SectionLabel/Counter/Link)
    ├── civique/
    │   ├── civique_screen.dart                Home Civique (single scroll : header + hero + thèmes + maîtrise)
    │   └── widgets/civique_mastery_card.dart  Carte maîtrise globale civique (% justes + couverture)
    ├── tcf/
    │   ├── tcf_screen.dart                    Home TCF (single scroll : header + hero + 5 épreuves + CECRL + stats)
    │   └── widgets/
    │       ├── cecrl_progress_card.dart       Niveau global estimé + objectif (hors production)
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
    │    le parcours tcf_production/, cf. plus bas)
    ├── exam/                      Écrans de résultat et rapport d'examen blanc (le setup a été supprimé,
    │                              le tirage d'examen blanc se fera depuis la carte sombre des hubs)
    ├── question_runner/           Le runner partagé (le cœur de l'app)
    │   ├── runner_controller.dart Riverpod controller avec state d'attempt
    │   ├── runner_screen.dart
    │   └── widgets/
    │       ├── question_media_view.dart Dispatch image/audio/vidéo
    │       │                      (le player vit dans core/widgets/audio_player.dart)
    │       ├── choice_tile.dart   4 états visuels
    │       ├── exam_timer.dart    Chrono décompte
    │       └── explanation_box.dart Bloc correction post-réponse
    ├── tcf_production/            EO + EE (productions évaluées par IA)
    │   ├── production_parcours_screen.dart  ProductionParcoursScreen — **l'écran
    │   │                                unique du parcours** : en-tête, barre du module,
    │   │                                tâche courante, et les 3 modes en IndexedStack.
    │   │                                Toutes les routes de mode le construisent.
    │   ├── production_subjects_tab_view.dart  mode « Sujets » (corps seul) :
    │   │                                pastilles T1/T2/T3 + liste ; tap sujet →
    │   │                                fiche consigne+plan → Enregistrer/Rédiger
    │   │                                ou Refaire/Voir le rapport.
    │   ├── production_exams_tab_view.dart  mode « Examens » (corps seul).
    │   ├── production_result_labels.dart  règles PURES du rapport de tâche :
    │   │                                niveau affirmé, portée du niveau, rappel
    │   │                                d'enjeu (miroir web production-feedback.ts).
    │   ├── production_catalog.dart      catalogue d'une épreuve (sujets +
    │   │                                productions), mis en cache pour la session.
    │   ├── competences/                 Module « Compétences TCF » : 4 écrans (liste,
    │   │                                détail, petit sujet, résultat) + providers + widgets.
    │   │                                Cf. § dédié plus bas.
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
    │   └── widgets/                     production_app_header, consigne_card,
    │                                    writing_zone, criterion_row, feedback_block,
    │                                    transcript_dialogue (transcription EO,
    │                                    ouverte en `showAppSheet`),
    │                                    evaluation_report (corps partagé EE/EO) +
    │                                    ses 6 sections : results_hero /
    │                                    tcf_note_scale, results_quick_row,
    │                                    criteria_overview, priority_card,
    │                                    production_text_card, results_section_head,
    │                                    evaluation_notice, etc.
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
  de maîtrise ; `masteryLabel()` pour le libellé qualitatif. `CecrlColor` (jamais de rouge
  pour un niveau) est la **seule** table qui décide de la teinte d'un niveau : le badge
  `CecrlTagTone` (`core/widgets/app_tag.dart`, `niveau.tagTone`) en **dérive** via
  `tagToneForAccent(Color)`. Ne pas réécrire un second `switch` sur `NiveauCecrl`.
  Même règle pour le **libellé** : `NiveauCecrl.shortName` (`core/models/enums.dart`)
  est la seule forme courte — « A1 non atteint » s'y rend **`<A1`**, jamais tronqué
  en « A1 ». Une teinte de niveau vient **toujours** de `CecrlColor` : le vert dit
  « B2 », pas « terminé » (une pastille d'état reste neutre).
  **Une note de production se colore par son palier TCF** (`TcfNoteScale.bandFor(note)`,
  `null` si la note n'est pas un nombre → pas de palier inventé), jamais par
  un seuil scolaire sur 20 : 12/20 vaut B2, le palier le plus haut de l'examen. Un critère
  d'évaluation antérieur au contrat v4 (sans `bande`) relit sa note avec la même table
  (`TcfNoteScale.bandeFor`, mêmes correspondances que `BandeCritere.of` côté serveur) et se
  rend comme un critère moderne — aucun critère ne s'affiche plus en chiffres.
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
outline/ghost/danger), `AppCard` (r=18), `AppTag` (badge pill, tones),
`PressableCard` + `CardChevron` (`pressable_card.dart` — carte cliquable à retour au toucher,
promue de `tcf_production/widgets/production_blocks.dart` quand le Plan a repris l'anatomie de
la carte de compétence ; `ProductionChevron` s'appelle désormais `CardChevron`),
`GradientHero` (`gradient_hero.dart` — bloc dégradé + anneau décoratif des maquettes
Diagnostic / Plan).

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
- **Exception assumée : le contenu de catalogue d'un parcours qu'on parcourt par onglets.**
  Un `autoDispose` jette ses données dès qu'on quitte l'écran, donc refetche au retour — ce
  qui rendait le parcours TCF EE/EO lourd (une bascule = un appel). Le remède est
  `ref.keepAlive()` **dans** le provider (l'erreur, elle, n'est jamais cachée :
  `link.close()` dans le `catch`), et une **invalidation explicite** aux points où la
  donnée du candidat change (soumission, analyse). Cf. `production_catalog.dart` et
  `competences_providers.dart`. Ne pas cacher ce qui mesure la progression sans poser en
  même temps son point d'invalidation.
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
  sheet ne déclenche pas de refetch. Pattern utilisé par `ProductionParcoursScreen` (parcours
  EE/EO), qui n'invalide **que** la donnée du mode actif. Combiner avec
  `async.when(skipLoadingOnReload: true)` pour éviter un spinner plein écran au retour.

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
Plan · Profil** (cf. maquette) :

- **Accueil** (`screens/home/`) : carte « À travailler en priorité » (catégorie la plus faible),
  3 stat cards (maîtrise/streak/niveau TCF), « Mes parcours », bloc IA EE/EO, raccourci examens.
- **Réviser** (`screens/reviser/`) : fusion des hubs Civique/TCF derrière `SegmentedTabs`
  (provider partagé `reviserParcoursProvider` — l'Accueil le présélectionne avant `goTab`).
  Liste des catégories avec anneau de maîtrise → écrans détail existants.
- **Examens** (`screens/examens/`) : examens blancs complets des 2 parcours derrière un toggle
  (`examensParcoursProvider`). Embarque `TcfFullExamsView` et `CiviqueFullExamsView` (corps
  extraits des écrans pleine page, qui restent pour les push profonds).
- **Plan** (`screens/plan/`, route `/plan`) : priorité serveur immédiate, exercice de compétence
  recommandé, deux priorités suivantes au maximum et huit compétences observées au maximum.
  L'écran **Progrès** (`screens/progres/`, route `/progress`) reste fonctionnel mais secondaire,
  via « Voir ma progression » ; `RecoScreen` reste sur `/progress/recommandations`.
- **Profil** (`screens/profile/`) : carte identité, 3 stats, carte « Mon pass » →
  `ManageSubscriptionScreen` (carte gradient maquette + détails + inclusions, paywall pour
  prolonger), objectif, groupes compte/aide, déconnexion + suppression via `showAppSheet`.

**Données** : `GET /api/me/dashboard` (miroir `core/models/dashboard_models.dart`, provider
`core/providers/dashboard_provider.dart`) alimente Accueil/Réviser/Progrès en un appel —
streak, `globalSuccessPercent`, `estimatedTcfLevel`, stats par catégorie (codes `TCF_*` /
`CIV_*`, mapping icône/route partagé dans `core/utils/dashboard_targets.dart`).

**`estimatedTcfLevel` = niveau TCF *estimé* du candidat**, dérivé serveur
(`TcfProfileService`) : plancher des 4 épreuves, chacune retenant son **meilleur** résultat,
une épreuve abandonnée sans rien rendre étant **exclue** (cf. CLAUDE.md racine). Null =
inconnu, jamais « < A1 ». **Ne jamais le recalculer côté app**, et **toujours dire
« estimé »** dans le libellé — Accueil « Niveau TCF estimé », Profil « Niveau estimé »,
mêmes chaînes que le web. L'endpoint `GET /api/tcf/profile/level` et le client
`tcfLevelProfile()` ont été supprimés (jamais appelés).

**Le périmètre part avec le niveau.** `estimatedTcfLevelEpreuvesCounted` /
`…EpreuvesExpected` / `…Partial` (même contrat que `epreuvesCountedInFinalLevel` /
`epreuvesExpected` / `finalLevelPartial` d'un examen complet) disent sur **combien
d'épreuves sur 4** le niveau porte — sans eux, un candidat qui n'avait passé que
l'expression écrite lisait « Niveau TCF estimé : B1 » sans le moindre signal. Dérivé
serveur : **ne jamais recompter côté app**. Le rendu passe par
`estimatedTcfLevelScopeLabel` (`core/models/dashboard_models.dart`), **une seule
chaîne** — « D'après 1 épreuve sur 4 » — rendue dans le nouveau `hint` de
`StatValueCard` (3ᵉ ligne, absente sans périmètre à annoncer) sur l'Accueil **et** le
Profil, gelée en miroir du web par `test/estimated_tcf_level_test.dart`. Elle
**constate un périmètre**, elle ne reproche pas un inachèvement, et ne porte aucun
chiffre de barème. 4/4 ⇒ rien ; 0/4 ⇒ le niveau vaut déjà « — », donc rien non plus.

## Diagnostic TCF initial et Plan personnalisé

- `/diagnostic` est hors shell **et publique** (allowlist `isOnPublicPage` du redirect global,
  à côté de `/about` ; elle échappe aussi à l'onboarding pour qu'un lien profond n'atterrisse
  pas sur `/login`). `/plan` reste authentifié.
- **Le visiteur produit AVANT d'avoir un compte.** `DiagnosticController` a deux régimes,
  choisis par `authControllerProvider.select((s) => s is AuthAuthenticated)` :
  - **invité** : sujets lus sur `GET /api/public/diagnostics/current` (`PublicDiagnostic` /
    `PublicDiagnosticExercise`, **sans `attemptId` ni `submissionId`** — ils n'existent
    qu'après la session), étape courante déduite de la production locale
    (`DiagnosticGuestStep`), puis écran de demande de compte ;
  - **connecté** : parcours serveur **inchangé** (`GET /api/diagnostics/current`,
    `POST /api/diagnostics`, `GET /api/diagnostics/{sessionId}`, `…/retry-analysis`).
- **La production n'est jamais gardée seulement en mémoire** — `diagnosticControllerProvider`
  est `autoDispose` et l'arbre est reconstruit au moment précis de l'inscription.
  `DiagnosticDraftStore` (`screens/diagnostic/diagnostic_draft_service.dart`, patron
  d'`EeDraftService`) écrit le texte dans `SharedPreferences` (autosave 2 s + à la validation)
  et **recopie l'audio dans le dossier de l'application** — on persiste le **nom** du fichier,
  jamais son chemin absolu (le conteneur iOS change d'identifiant). Survit au kill de l'app, au
  détour par Google/Apple sign-in et à la bascule d'`AuthState`. À la relecture, un audio
  disparu n'est pas annoncé.
- **Ordre d'envoi post-inscription, à ne pas relâcher** : `POST /api/diagnostics` → écrit →
  attente de l'accusé de réception → oral → attente du sien → **et seulement là**
  `DiagnosticDraftStore.clear()`. Un envoi partiel ou en échec **garde tout** et propose de
  réessayer (`canRetrySync`). Un compte qui a **déjà** un diagnostic est détecté avant toute
  soumission (statut non `IN_PROGRESS`, ou deux `submissionId` déjà posés) : on le dit
  (`noticeMessage`, `DiagnosticAlreadyDoneView`) au lieu de boucler sur une erreur, et la copie
  locale n'est effacée que sur confirmation explicite.
- **Aucune attente n'est un rond gris muet** (`widgets/diagnostic_wait.dart`, partagé transfert
  ⇄ analyse) : étapes franchies + compteur de temps écoulé (`Stopwatch`, jamais `DateTime.now()`)
  + réassurance qui bascule sur « c'est plus long que d'habitude » à 2 min **sans annoncer
  d'échec** (l'échec, c'est `FAILED`, qui a son propre écran). `DiagnosticSyncStage` n'existe que
  pour nommer l'étape d'envoi en cours. `_content` fait passer `isSyncing`/`canRetrySync`
  **avant** le loader générique : un transfert ne doit jamais se rendre en spinner anonyme.
- **Le marqueur « déjà démarré » vit dans l'état du contrôleur, jamais dans un drapeau qui
  survit au démontage** — c'est ce qui distingue le mobile du bug web de blocage éternel. Le
  provider est `autoDispose` : tout chemin d'abandon (`if (!mounted) return`) emporte le
  marqueur, et l'exactement-une-fois du transfert est tenu par le **serveur**
  (`POST /api/diagnostics` idempotent + gardes `submissionId == null`), pas par un booléen
  local. Corollaire à ne pas casser : **toute sortie d'une méthode du contrôleur résout son
  `isLoading`/`isSubmitting`/`isSyncing`** — sinon le bouton tourne sans fin, `PopScope` refuse
  le retour et `ScreenHeader` masque sa flèche : le candidat est enfermé.
- L'écran de demande de compte (`DiagnosticAccountGate`) **n'affiche aucun résultat réel** —
  l'analyse coûte deux appels LLM. Il montre un **exemple** étiqueté comme tel (badge
  « EXEMPLE » + phrase « ce ne sont pas vos réponses ») et ouvre l'inscription **ou** la
  connexion avec `redirect=/diagnostic`.
- Les réponses utilisent le pipeline de production existant : EE en JSON et EO en multipart via
  `ProductionRepository`. La zone écrite réutilise `WritingZone` avec les bornes du DTO ; l'oral
  réutilise `AudioRecorderService`, `RecordingWaveform` et `SejourAudioPlayer`. Les permissions
  micro restent centralisées dans le service existant.
- `GET /api/me/plan` est la seule source de hiérarchie du Plan. L'app ne déduit ni statut, ni
  priorité, ni faux score vers l'objectif. Après une production EE/EO, un micro-exercice ou une
  mutation du diagnostic, `learningPlanRevisionProvider` est incrémenté : un Plan ou un Accueil
  qui l'observe est rechargé, sans provoquer de requête réseau si aucun écran ne l'observe. Le
  retour d'un entraînement poussé au-dessus de Plan force aussi une relecture
  (`RouteAware.didPopNext`).
- **Le Plan se lit comme un chemin**, pas comme une pile de cartes : héros (« niveau estimé →
  objectif » + 3 compteurs réels), « À faire maintenant », puis **« Votre parcours » — des
  étapes numérotées, verticales et reliées** (étape 1 = `currentPriority` marquée EN COURS,
  étapes suivantes = `nextPriorities` marquées À VENIR, étape finale = la réévaluation). Le
  niveau estimé du héros vient **exclusivement** de `dashboardProvider`
  (`estimatedTcfLevel`) et dégrade sur le seul objectif quand il manque — jamais de recalcul.
- **Compteurs de sujets sur les DTO du Plan — DEUX jeux, à ne jamais confondre.**
  `promptCount` / `attemptedCount` / `validatedCount` (sur `LearningPlanPriority` **et**
  `LearningPlanSkill`, mêmes champs que `SkillDto`) décrivent la **compétence entière**
  (15 sujets) : ils alimentent les cartes « Mes compétences observées », qui reprennent
  l'anatomie de `CompetenceCard` (Réviser → Compétences) et le **libellé partagé**
  `skillProgressLabel` (`core/utils/skill_progress.dart`, dont `competenceProgressLabel`
  n'est plus qu'une application au `SkillDto`). `stepPromptCount` /
  `stepAttemptedCount` / `stepValidatedCount` / `stepCompleted` (priorités seulement)
  décrivent l'**étape** — les **5 premiers** sujets de la compétence : c'est ce couple que
  l'anneau d'une étape du parcours affiche (« 2/5 », jamais « 2/15 »). Tout est dérivé
  serveur, y compris `stepCompleted` : l'écran ne compare plus rien lui-même.
- **L'étape SUIT le candidat jusque dans la fiche de compétence** (2026-08-15).
  Une compétence ouverte **depuis le Plan** (`CompetenceDetailScreen.planStep`)
  n'affiche plus que les **sujets de l'étape** et compte « 2/5 » ; par
  « Réviser → épreuve → Compétences », la fiche complète (les 15 sujets,
  « x/15 ») est **strictement inchangée**. Deux vues d'une même compétence selon
  la porte d'entrée : c'est **assumé** (décision propriétaire, prise sur maquette).
  - **Le périmètre est servi** : `LearningPlanPriority.stepPromptIds` (jamais
    `null`, éventuellement vide, `length == stepPromptCount`). On ne rejoue
    **jamais** la règle « les 5 premiers par rang d'affichage », qui vit côté
    serveur.
  - **Aucun identifiant ne voyage dans la route** : un simple marqueur
    `?etape=1`, posé par `competenceDetailPath(..., planStep: true)` depuis
    `_openSkill` du Plan (la seule navigation Plan → compétence des deux
    fronts), lu par le router (`isPlanStepQuery`). Règle + libellés **gelés**
    dans `screens/plan/plan_step_labels.dart`, **miroir mot pour mot de
    `web_sejoufr/lib/plan-step.ts`**. Rien à propager plus loin : le retour d'un
    petit sujet est un `pop`, il ramène naturellement dans l'étape.
  - **Zéro appel réseau de plus** : `learningPlanProvider` est **déjà vivant**
    (l'écran Plan reste monté sous celui-ci), on ne fait que le lire.
  - **Repli silencieux, obligatoire** : Plan pas chargé, `stepPromptIds` vide,
    ou compétence **sortie des priorités** (cas **normal** — le serveur l'en
    sort dès qu'une vérification en situation a réussi) ⇒ on retombe sur la
    fiche complète. Ni message, ni écran vide, ni spinner. Le repli se lit à
    l'**identité** de la liste rendue par `_prompts`, pas à un compteur.
  - **Compteurs servis, jamais recomptés** : `_SummaryCard` reçoit
    `attempted`/`total`/`validated` (les `step*Count` en mode étape). Les
    filtres (Tous / À faire / Traités / Verrouillés) portent sur les **5** et
    leur somme reste juste, comme sur les 15 ; la `FixedActionBar` vise un sujet
    **de l'étape**.
  - 🛑 **Aucun second parcours de vérification ici.** Étape terminée
    (`stepCompleted`) ⇒ un `ProductionNotice` « Étape terminée » + « Revenir à
    mon plan ». « Vérifier ma progression » vit **sur le Plan**, qui seul
    connaît la deuxième condition (moteur de maîtrise prêt) : une étape peut
    donc afficher « 5/5 » sans que la vérification s'ouvre — **c'est voulu**, ne
    pas l'expliquer par un message ni contourner la règle.
- **Une étape peut être TERMINÉE, et elle reste affichée** : badge `EN COURS` →
  `TERMINÉE`, plus la ligne « Réévaluée à ta prochaine production. » sous le titre
  (`_StepDoneLines`, miroir mot pour mot de `LearningPlanView` côté web). Les priorités ne
  changent qu'à l'arrivée d'une nouvelle observation — sans cette phrase, un candidat qui a
  fini son étape et la voit toujours là croit à un bug. Quand elle est terminée sans être
  toute validée, une seconde ligne discrète dit « N validés sur M » : terminer n'est pas
  tout réussir. Rien de tout ça quand l'étape n'est pas terminée.
- **L'état de maîtrise remplace le compteur sur une carte de compétence**
  (décision propriétaire) : `SkillDto.masteryState` (« Priorité » / « À renforcer » /
  « En consolidation » / « Solide », libellés **gelés**, miroir de
  `SKILL_MASTERY_STATE_LABEL` côté web) prend la place de `competenceProgressLabel`
  dans `CompetenceCard`, et celle de `status.label` sur les cartes « Mes compétences
  observées » du Plan. **`null` (aucune observation) est le seul cas où le compteur
  reste.** Teinte et pilule vivent à **un seul endroit** :
  `core/widgets/skill_mastery_tag.dart` (`SkillMasteryTag` + extension
  `SkillMasteryStateStyle`), qui reprend les teintes de `LearningPlanSkillStatus.color`
  — jamais une couleur nouvelle. L'anneau garde ses compteurs.
- **La trajectoire d'une compétence vit dans SA fiche** (`CompetenceDetailScreen`),
  pas dans le Plan ni dans un écran de plus : `SkillDetail.trajectory` →
  `SkillTrajectorySection` (`competences/widgets/skill_trajectory.dart`), frise du
  **plus ancien au plus récent** (ordre serveur), une ligne = source
  (`LearningPlanSourceType.label`, gelé) + verdict + date, explication en second plan.
  **Vide ⇒ `SizedBox.shrink`**, pas d'encart d'excuse. `confidence` n'est **jamais**
  montrée au candidat.
- **Une étape du Plan peut devenir une VÉRIFICATION** —
  `recommendedExercise.kind == PlanExerciseKind.reassessment` : **même carte, même
  emplacement**, badge `VÉRIFICATION` (là où s'affiche `EN COURS`), bouton
  « Vérifier ma progression » sur `_NowCard` comme sur `_CurrentStepCard`. Jamais une
  seconde carte. **Le routage vit à un seul endroit**,
  `tcf_production/recommended_exercise_launcher.dart` (partagé avec le résultat du
  diagnostic) : micro-sujet → `competencePromptPath` ; vérification → on charge le
  sujet (`getTask`), on démarre la session (`startSingle`) puis on ouvre
  `productionSessionPath` (`…/t/0`) — exactement le chemin du mode « Sujets », **le
  `productionTaskId` ne voyage jamais dans l'URL**. `locked` ⇒ paywall, l'exercice
  reste désigné.
- **Le Plan porte un JALON, à côté des étapes** — `LearningPlan.milestone`
  (`PlanMilestone`) → `PlanMilestoneCard` (`screens/plan/plan_milestone_card.dart`),
  **sous** « Votre parcours » et au-dessus des compétences observées. Un jalon
  n'est pas une étape : il désigne un **examen blanc déjà existant** par son
  `epreuve` + `slotNumber`, et `PlanExerciseKind` gagne pour cela
  `epreuveMockExam` / `fullTcfMockExam`. **`milestone == null` est le cas
  NORMAL** (même sursis que `PlanChange`) : rien ne s'affiche, aucun indicateur.
  ⚠️ **Un jalon n'a ni titre, ni compétence, ni section** — d'où une **classe à
  part** (`PlanMilestone`), jamais un `PlanRecommendedExercise` aux champs
  rendus nullables : aucun écran ne peut lire ici un titre qui n'existe pas.
  `recommendedExercise` reste une **étape**, et
  `recommended_exercise_launcher.dart` n'a donc rien à connaître des jalons.
  **Le serveur ne fournit AUCUN libellé** (il expose des faits) : les phrases
  vivent dans `screens/plan/plan_milestone_labels.dart` (`kPlanMilestone*`,
  extension `PlanMilestoneLabels`), **miroir mot pour mot** de
  `web_sejoufr/lib/diagnostic.ts` (section « jalons »). La durée vient
  d'`estimatedMinutes`, jamais d'un nombre écrit ici.
  **Aucune route ni aucun appel n'est créé** : `epreuveMockExam` réutilise
  `Ee/EoSessionNotifier.startExam(slotNumber:)` puis `productionSessionPath`
  (le chemin de l'onglet « Examens »), `fullTcfMockExam` réutilise
  `FullTcfExamRepository.start(slotNumber:)` puis `AppRoutes.tcfFullExamProgress`
  (celui de `TcfFullExamsView`), 403 → `showPaywallOrError`. `locked` :
  `PremiumLockTag` + `showTcfLockPaywall`, **sans rien masquer**.
- **« Ce que ça change dans le Plan » sur le rapport d'une tâche** :
  `ProductionSubmissionDto.planChange` → `PlanChangeLine`
  (`tcf_production/widgets/`), **une ligne** en fin de `EvaluationReport`
  (« X confirmée » / « Nouvelle priorité : Y. » + « Voir » vers `/plan`), les deux
  moitiés indépendamment nullables. **`null` est un cas NORMAL** : rien ne s'affiche,
  aucun indicateur. Les observations arrivant **après** le plan d'action,
  `ProductionResultPollGuard` prolonge la **même** boucle dans le **même** sursis
  (`kActionPlanGrace`, même échéance) — pas de seconde boucle, et `awaitsActionPlan`
  reste réservé au plan d'action.
- **Le Plan reste visible en entier même verrouillé** (freemium Compétences, cf. § dédié) :
  `locked` sur `LearningPlanPriority` / `LearningPlanSkill` / `PlanRecommendedExercise`
  n'ôte **aucune** information — ni une priorité, ni une compétence observée, ni un
  compteur, ni l'anneau. Il ajoute la pilule « Premium » et remplace le CTA (« Commencer » /
  « Continuer cette étape ») par « Débloquer cet exercice » / « Débloquer cette étape », qui
  ouvre `showTcfLockPaywall`. `_ExerciseRow` annonce l'exercice recommandé **à l'identique**,
  verrouillé ou non. **Ne pas coder « l'étape 1 est toujours ouverte »** : le serveur
  déverrouille la priorité n°1, l'app lit `locked`, toujours.
- **Libellés de `LearningPlanSkillStatus` gelés** sur ceux du web (« Non observée /
  Prioritaire / À renforcer / Solide », `web_sejoufr/lib/diagnostic.ts`), verrouillés par
  `test/diagnostic_models_test.dart`. Leur **teinte** vit à un seul endroit :
  `LearningPlanSkillStatus.color` (`core/theme/app_theme.dart`), partagée Plan ⇄ Diagnostic.
- **Le résultat du diagnostic affiche enfin `summary`, `taskCompletion`, `communicationStatus`
  et `weaknesses`** (deux cartes « Vos productions »), en plus des compétences observées et de
  la priorité n°1. **Aucun pourcentage de progression vers un palier**, ni sur le Plan ni sur
  le diagnostic : le brief l'interdit et le serveur n'en publie aucun.
- L'Accueil suit trois états serveur : invitation dismissible avant diagnostic, reprise de la
  session interrompue, puis priorité du jour après résultat. Il ne réaffiche jamais l'invitation
  générique une fois le diagnostic terminé.
- Les liens profonds protégés conservent leur destination dans `redirect` jusqu'à la connexion,
  y compris lors d'un démarrage à froid tant que `AuthLoading` n'a pas encore résolu le token ;
  `safePostLoginDestination` refuse tout schéma/hôte externe et toute boucle vers l'auth.
- L'audience agrégée utilise uniquement `POST /api/public/page-views` avec `{path, source:
  "direct", event}` : `direct` est la seule source backend compatible avec une ouverture native.
  Aucun identifiant ni contenu de production n'est envoyé et un échec analytics ne bloque jamais
  le parcours. La route étant publique (`skipAuth`), **le funnel reste mesurable en invité** ;
  `DIAGNOSTIC_ACCOUNT_REQUIRED` (émis une fois, à l'affichage de l'écran de demande de compte)
  est la mesure de conversion du parcours.

- **Écran de présentation (2026-08-14) — « 5 minutes », pas un examen.**
  `DiagnosticIntro` annonce le budget **en tête** (pilule dans le hero, avant le titre)
  puis les **deux exercices séparément**, chacun avec sa mesure — « Écrit · 100 à 120
  mots · environ 3 min », « Oral · environ 2 minutes ». 🛑 **Aucun chiffre en dur** :
  tout se dérive des sujets servis (`wordsMin/Max`, `durationMin/MaxSeconds`) par les
  règles **pures** de `diagnostic_intro_labels.dart` (`diagnosticBudgetLabel`,
  `diagnosticWrittenMeasureLabel`, `diagnosticOralMeasureLabel`,
  `kDiagnosticWritingWordsPerMinute = 40`, valable **pour cet écran seulement**) —
  miroir mot pour mot de `web_sejoufr/lib/diagnostic.ts`. Le budget est la **somme**
  des deux : raccourcir un sujet en base raccourcit la promesse. Sans borne
  exploitable, on annonce « Diagnostic express · 2 exercices » et « un court texte » /
  « un court enregistrement » — jamais un chiffre inventé, et « ~5 min » reste un
  **ordre de grandeur**, jamais un chrono. ⚠️ Un compte **sans session** ne reçoit
  aucun sujet (le serveur ne les attache qu'à `POST /api/diagnostics`) :
  `DiagnosticController._loadSubjectsForPresentation` relit alors `publicCurrent()`
  en best-effort — sans lui, l'invité voyait ses mesures et le compte connecté non.

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
  `targetProcedure`). Cette carte de profil général est distincte de la notation
  production TCF IRN, dont l'échelle de bilan s'arrête à B2.
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

**Périmètre du niveau final (examen complet)** : le plancher `finalCecrlLevel` ne porte que
sur les épreuves **réellement passées** — une EE/EO verrouillée par le freemium n'a plus de
niveau du tout (`cecrlLevel` null + cadenas), et une évaluation en échec est écartée. Le
backend publie le périmètre : `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
`finalLevelPartial` (résumé d'historique : `finalLevelPartial` seul). Conséquences côté
mobile, à ne pas défaire : le bilan **ne dit jamais « tes 4 épreuves » en dur** (phrase
dérivée du décompte, et sans chiffre si le champ manque), et un examen partiel n'alimente
pas « meilleur niveau » / « dernier examen » — il est annoté « partiel ».

**Score d'une sous-épreuve QCM : TOUJOURS sur 499, jamais le pondéré.**
`FullTcfExamSubAttempt.calibratedScore` (100-499, dérivé serveur par
`TcfLevelEstimatorService`) est ce qu'affichent le hub de progression et le bilan —
`score`/`maxScore` reste servi mais c'est le score **pondéré interne** (A2=1, B1=2,
B2=3) et « 23/50 » ne correspond à rien sur le relevé d'un candidat. La règle vit à
**un seul endroit**, `FullTcfExamSubAttempt.qcmScoreLabel` (`core/models/full_tcf_exam.dart`,
miroir de `qcmScoreLabel` dans `web_sejoufr/lib/exam-levels.ts`) : calibré présent ⇒
`x/499`, sinon repli sur `x/maxScore`, `null` quand il n'y a rien (EE/EO, épreuve
verrouillée, pas encore notée). **Ne jamais dériver un /499 d'un pondéré côté app**, et
ne pas remplacer par un tiret une donnée qu'on possède. Mêmes barèmes que les examens
**module** CO/CE (`tcf_qcm_exams_screen`, `qcm_history_section`), qui étaient déjà en
/499 — c'est cette cohérence-là qu'on rétablit. Le **civique** n'est pas concerné (/40
ou /20 selon l'examen).

**Modules affichés :**
- **Civique** = les 5 thèmes officiels chargés via `/api/themes?module=CIVIQUE` (Principes &
  symboles, Institutions, Droits & devoirs, Histoire-Géo, Société). Tap → push
  `/civique/theme/:themeId` (écran détail).
- **TCF** = 4 modules officiels IRN + 1 bonus, **tous** avec un écran détail :
  - CO → `/tcf/co`, CE → `/tcf/ce` → `TcfQcmDetailScreen` → CTA "Commencer l'entraînement"
    → `POST /api/attempts` + push runner.
  - EE / EO → **pas de hub d'épreuve** : on entre directement sur l'écran d'accueil du
    parcours, `/tcf/{ee,eo}/tache/1/competences` (`AppRoutes.tcf{Ee,Eo}Entry`), et la
    tâche se change par les pastilles T1/T2/T3. `/tcf/ee` et `/tcf/eo` restent déclarés
    comme **alias en redirect**. Cf. § TCF Expression plus bas.
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
- `/tcf/eo` et `/tcf/ee` → alias en redirect vers l'entrée du parcours ;
  `/tcf/{eo,ee}/tache/:n` → `ProductionParcoursScreen` (mode Sujets). Enum
  `TcfProductionModule.{eo,ee}` dans
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
répondue, sinon dernière. ⚠️ **Cela ne vaut plus pour un examen blanc** — cf. juste en dessous.

### 🛑 Quitter un examen blanc QCM joué seul (2026-08-15)

> **Quitter un examen, c'est le terminer.** La croix — et le retour système —
> n'est pas un « je reviendrai » : l'attempt est finalisé, donc définitif et non
> reprenable, et le candidat arrive **directement sur son résultat**.

Périmètre : civique global (40 Q), civique **par thème** (20 Q), examens TCF par
épreuve (CO / CE / STRUCTURE) et examens issus d'un `ExamTemplate`. **Hors
périmètre** : les séries (`AttemptType.training`), où quitter n'a jamais rien
coûté (comportement inchangé : entraînement infini → on finalise le batch,
sinon on pop et la session se reprend), et les sous-épreuves d'un examen complet
(`from=fullTcf`), qui gardent les libellés de
`screens/tcf_full_exam/full_exam_exit_labels.dart` : là, quitter **clôt
l'épreuve sans ouvrir de bilan**.

- **C'était le vrai écart avec le web** : `_confirmQuit` ne finalisait que
  l'entraînement infini — en examen module il **poppait sans finaliser**, donc
  l'examen restait reprenable, alors que le web le clôturait déjà.
  `_RunnerView._confirmQuit` appelle désormais `finish()` puis
  `_navigateToResult` (qui pousse `AppRoutes.examResult` en `pushReplacement` et
  invalide les 4 historiques). Une finalisation en échec (réseau) **laisse le
  candidat sur sa question**, avec le message d'erreur : on ne sort jamais en
  lui faisant croire que c'est fait.
- **Le back système et le geste de retour iOS suivent EXACTEMENT la croix** :
  `PopScope(canPop: !isExam)` (c'était `!isFullExamEpreuve`) → `_confirmQuit`.
  Sans ça on sortait par le bas sans rien clore. Le runner est **hors
  `ShellRoute`** : aucune bottom nav par laquelle s'échapper.
- **Libellés déclarés une seule fois** dans
  `screens/question_runner/mock_exam_exit_labels.dart` (`kMockExamQuitTitle` /
  `…Message` / `…Confirm` / `…Cancel`), **miroir mot pour mot** de
  `web_sejoufr/lib/mock-exam-exit.ts`. Le message dit les **trois**
  conséquences avant l'action : plus de reprise ; un résultat sur ce qui a été
  répondu ; les questions restantes comptées **non répondues**. Le bouton de
  confirmation **nomme l'issue** — « Quitter et voir mon résultat », jamais un
  « Confirmer » neutre : la croix devient destructrice sur un simple appui, la
  confirmation est la seule protection.
- **Annuler ne coûte rien… sauf le temps** : on revient à la question, aucune
  réponse n'est perdue, mais le chrono a continué de courir.
- **Ce qui ne finalise RIEN** : mettre l'app en arrière-plan, la tuer. Un examen
  n'est **jamais** finalisé sans confirmation — ne pas ajouter de `finish` dans
  un `dispose` ou un `AppLifecycleState.paused`.
- **Ce qui finalise sans confirmation, et c'est normal** : l'expiration du
  chrono (`ExamTimer.onElapsed` → `_autoFinish`) et le **422** « hors délai »
  sur une réponse (`_handleTimeExpired`). Ce ne sont pas des gestes de sortie :
  c'est la règle de l'examen.

**Médias** : le `QuestionDto.media` est un `MediaDto` optionnel avec un `type` (AUDIO/IMAGE/VIDEO) + une
`url`. Le `QuestionMediaView` dispatche vers le bon widget. Pour l'instant, les questions du seed ne
contiennent que du texte, mais l'architecture est prête pour le TCF complet.

## TCF Expression orale + écrite (`screens/tcf_production/`)

Module distinct du runner QCM : l'utilisateur **produit** un audio (EO) ou un texte (EE), envoyé au backend
qui le transcrit (Whisper) + le note via le correcteur unique configuré dans
`sejourfr.production-evaluation` (DeepSeek par défaut) en 10-15 s. Cf. `CLAUDE.md` racine.

**Deux écrans**, un par fichier (`production_subjects_tab_view.dart`,
`tcf_task_examples_screen.dart`) — le troisième, le hub d'épreuve
(`tcf_expression_screen.dart`), est **supprimé** (cf. plus bas).

### ⚠️ Les DEUX épreuves sont BLEUES (décision client 2026-08-09)

L'expression orale n'est plus rouge. `TcfProductionModule.accent` /
`.accentDark` valent le **bleu pour EE comme pour EO**, et le rouge redevient
ce que `docs/identite-visuelle.md` prévoit : CTA critiques et signaux
d'urgence, rien d'autre. Deux épreuves du même module qui se peignent
différemment se lisent comme deux produits.

**Ce qui distingue l'écrit de l'oral, maintenant** — déclaré une seule fois
dans `TcfProductionModule`, jamais recopié :

1. le **titre** et le sous-titre d'épreuve (`epreuveMeta` :
   « TCF IRN · 3 tâches · 30 min » à l'écrit, « 15 min » à l'oral) ;
2. le **pictogramme** (`icon` : stylo / micro), rendu sur la carte
   « Prochain entraînement », le bouton d'action d'un sujet et les liens
   d'appoint ;
3. le **verbe** (`actionVerb` : « Rédiger » / « Enregistrer »).

Endroits repris dans la même passe, à ne pas réintroduire en rouge :
`eo_briefing_screen` (carte de consigne, spinner, forme d'onde),
`eo_finished_screen` (carte de consigne), `production_exam_briefing_sheet`
(héros du briefing, carte « CONSEIL » passée en ambre) et l'entrée Réviser
(`reviser_screen`, où l'alternance décorative bleu/rouge **saute les deux
épreuves de production** — sinon l'écrit s'annonçait en rouge à l'entrée d'un
parcours entièrement bleu). Restent rouges, et c'est voulu : le bouton
d'enregistrement et sa pastille « Enregistrement… », le décompte des 30
dernières secondes, les erreurs et le « Quitter » destructeur.

### Structure du parcours — maquettes client (passe 2026-08-09)

Les trois onglets (Compétences · Sujets · Examens) partagent désormais une
**tête commune**, reprise des trois maquettes fournies par le propriétaire :

1. **en-tête constant** (`ScreenHeader`) : retour, nom de l'épreuve,
   `epreuveMeta`, et à droite le badge `ProductionLevelBadge` — « NIVEAU VISÉ »
   + le palier de la démarche (`userTargetLevelProvider`). L'eyebrow dit
   « visé » en toutes lettres : le repo interdit d'afficher un niveau sans le
   qualifier, et ce n'est **pas** le niveau estimé du candidat ;
2. **`ProductionParcoursHero`** (`widgets/production_parcours_top.dart`) :
   anneau + trois colonnes chiffrées (Score moyen `/20`, Examens blancs `/10`,
   Sujets traités `/N`) + « Progression du parcours » ;
3. **`ProductionNextCard`** : la prochaine compétence non terminée de
   l'épreuve, « Tâche N · <titre> » + « Continuer ». Rien à faire ⇒ **aucune
   carte**, jamais une invitation vide ;
4. **`ProductionModeTabs`** (`widgets/production_mode_tabs.dart`) : barre
   segmentée **dans le flux**. L'ancienne `ProductionModuleBar` flottante en
   bas est **supprimée** (elle masquait le dernier élément de chaque liste) ;
5. **`ProductionTaskCards`** : trois cartes « 1 · Message · 30-60 mots ». Elles
   remplacent `ProductionTaskPills` (**supprimé**), qui ne disait que
   « Tâche 2 » alors que le format et la contrainte sont précisément ce qui
   distingue les trois tâches. Absentes du mode Examens, porté par l'épreuve.

Chaque mode rend cette tête **en tête de sa propre liste** (`top:` passé par
`ProductionParcoursScreen`) : l'`IndexedStack` garde donc le défilement de
chacun. Elle est rendue **quel que soit l'état** de la liste — sans elle, une
erreur de chargement enfermait le candidat dans un mode.

⚠️ **Conséquence assumée sur les appels** : le héros compte les sujets et les
examens de l'épreuve, la carte « Prochain entraînement » lit les compétences —
donc `productionCatalogProvider` **et** `skillsSectionProvider` sont chargés dès
l'entrée, quel que soit le mode. Ce qui reste vrai, et ce que
`test/production_parcours_caching_test.dart` verrouille : **aucune bascule de
mode ou de tâche ne coûte un appel de plus**.

`ProductionHero` (+ `ProgressTrackOnDark`) est **supprimé** :
`ProgressTrack(trackColor:)` faisait déjà le travail. `ProgressRing` accepte
maintenant `trackColor` / `textColor` / `subColor` pour se poser sur un fond
sombre.

**Libellés gelés partagés avec le web** (chaque front en tient une copie écrite
à la main, un test par couche sur les mêmes chaînes) :
`productionTaskShortTitle`, `productionTaskConstraint` et
`productionSubjectTitle` (`widgets/production_common.dart` ⇄ `lib/types.ts`),
`competenceProgressLabel` (`competences/widgets/competence_card.dart` ⇄
`lib/skill-progress.ts`).

**Le titre d'une carte de sujet vient de la base** : `ProductionTaskDto.titre`
(colonne `production_tasks.titre`, V028, contenu V754), éditable en console
admin. Il est **nullable** — contenu antérieur, sujet créé sans titre — et le
repli est `productionSubjectTitle(titre, ordre)` → « Sujet N », **jamais** un
titre vide ni un placeholder ; la consigne reste affichée dessous dans les deux
cas. Ne pas y remettre `displayTitle` (l'intitulé de la **tâche**) : il est le
même pour les vingt sujets d'une tâche, donc il ne distingue rien. `displayTitle`
reste employé là où c'est bien la tâche qu'on nomme (briefings, temps réel,
historique).

**Une ligne de compétence** porte un `ProgressRing` « 2/5 » + l'état en clair
(« 2 réussis · 3 restants »), plus une pastille de numéro et une barre fine.
**Une carte de sujet** porte son rang sur deux chiffres (`01`), sa contrainte et
sa tâche — le palier a quitté la carte, il est annoncé une fois par le badge de
l'en-tête. La grille des examens ouvre sur `ProductionExamTrail`
(« Parcours examens blancs · 1/10 ») à la place des trois cartes de statistiques,
devenues une redite du héros.

### Reprise sur la maquette client (passe 2026-08-06)

Le parcours entier suit `docs/skills/sejourfr_expression_ecrite_v3_competences.html`,
comme le module Compétences avant lui — **c'est la même maquette, donc les mêmes
briques**. Elles ont été **promues** de `competences/widgets/` vers
`tcf_production/widgets/` et renommées `Production*` :

- `production_parcours_top.dart` (**2026-08-09**) — `ProductionParcoursHero`,
  `ProductionParcoursStats`, `ProductionNextCard`, `ProductionTaskCards`,
  `ProductionLevelBadge`, `ProductionSideLink`, `ProductionExamTrail`
- `production_mode_tabs.dart` (**2026-08-09**) — `ProductionModuleTab` (l'enum
  a déménagé ici) + `ProductionModeTabs`
- `production_blocks.dart` — `ProductionSectionHead`, `ProductionNotice`,
  `ProductionTipline`, `ProductionIndexChip` (48×48 r16), `ProductionChevron`
  (30×30), `PressableCard` (r23), `DashedBox`
- `production_state_views.dart` — `ProductionErrorView`, `ProductionEmptyView`
- `production_cards.dart` (**nouveau**) — `ProductionSubjectCard` (`.topic-card` +
  liseré de statut). `ProductionTaskCard` (`.skill-card`, les 3 cartes de tâche du
  hub) y vivait : supprimée avec le hub.
- `production_common.dart` (**nouveau**) — `productionTaskMeta`, `SheetHandle`,
  `BusyOverlay`, `MutedHint`, `ShowMoreButton`
- `production_examples.dart` (**nouveau**) — `FeaturedExampleCard`, `StrategyCard`,
  `ExampleDetailSheet`, `PlanSheet`

⚠ **Ne pas recopier ces briques dans un écran** : elles sont partagées avec le module
Compétences, une divergence se verrait au premier retouche.

**Écrit et oral suivent exactement les mêmes écrans** : la maquette ne couvre que
l'écrit, l'oral n'en diffère que par le pictogramme et par la zone de production
(enregistreur au lieu de la saisie). Aucun écran, aucune section, aucun bloc
supplémentaire d'un côté.

**Navigation du module — `ProductionModeTabs`** (`widgets/production_mode_tabs.dart`,
depuis le 2026-08-09) : barre segmentée **dans le flux**, sous la carte
« Prochain entraînement », mode actif en pilule pleine. Trois entrées :
**Compétences · Sujets · Examens**, portées par `ProductionModuleTab`. Les
chemins vivent dans `production_nav.dart` ; **une bascule ne navigue plus** — cf.
« Un seul écran pour les trois modes » plus bas.
⚠ **Aucune double barre** : les écrans du parcours TCF EE/EO sont déclarés **hors
du `ShellRoute`** (cf. `app_router.dart`), la bottom nav globale n'y est pas rendue.

⚠ **Il n'y a plus rien au-dessus des trois modes.** Le hub d'épreuve est
supprimé : les trois modes sont des **frères**, donc « retour » depuis l'un
d'eux veut dire **quitter le parcours**, jamais sauter latéralement sur un
autre mode. La règle vit à un seul endroit, `leaveProductionParcours`
(`production_nav.dart`), appelé par le seul `ProductionParcoursScreen` : on
dépile si on peut, sinon `/reviser`. Ne pas réécrire un `if (canPop)` local,
et surtout ne pas y remettre `/tcf/{ee,eo}` en repli (ce path redirige vers le
mode Compétences : le retour deviendrait une boucle).

### Un seul écran pour les trois modes (passe fluidité 2026-08-06)

Constat client : « changer de Compétences / Sujets / Examens, ou de Tâche 1/2/3,
donne l'impression d'un appel au back et d'un changement d'écran lourd ». Deux
causes, corrigées ensemble.

1. **Chaque mode était une route**, et chaque bascule un `pushReplacement` :
   l'arbre entier était démonté puis reconstruit (défilement perdu, animation de
   page pour un déplacement latéral). Désormais **`ProductionParcoursScreen`**
   (`production_parcours_screen.dart`) porte l'en-tête, la barre du module, la
   tâche courante et le voile d'attente, et rend les trois corps
   (`CompetencesTabView`, `ProductionSubjectsTabView`, `ProductionExamsTabView`)
   dans un **`IndexedStack`**. Un mode quitté **reste monté** : filtres, « Voir
   plus » et position de défilement survivent. Un mode **jamais ouvert n'est pas
   construit** — on ne paie pas les appels d'un mode que le candidat n'a pas
   demandé.
   - Les chemins `/tcf/{ee,eo}/tache/:n{,/competences}` et
     `/tcf/expression-{orale,ecrite}/examens?tache=N` **restent servis** (liens
     profonds, retour arrière) : ils construisent tous cet écran avec le bon mode
     de départ. En revanche **une bascule ne change plus l'URL** — c'est le prix
     assumé, et c'est ce qui rend le retour arrière exact (une seule route à
     dépiler = quitter le parcours).
2. **Tous les providers étaient `autoDispose`**, donc quitter un mode jetait ses
   données. Le cache est maintenant porté par **l'épreuve**, jamais par la tâche :
   - `skillsSectionProvider` (`competences_providers.dart`) charge les **24
     compétences de l'épreuve en un appel** (`GET /api/skills?section=EE|EO`) ;
     `skillsListProvider` n'est plus qu'un **filtre local synchrone** par
     `taskCode`. Les pastilles T1/T2/T3 ne touchent plus au réseau. **Repli**
     conservé tant que le filtre `section` n'est pas déployé : les trois
     `taskCode` en **une** passe parallèle, jamais un appel par bascule.
   - `productionCatalogProvider` (`production_catalog.dart`) charge les sujets et
     les productions de l'épreuve (`listTasks` + `listMine`, tous deux déjà portés
     par l'épreuve — ils étaient redemandés à chaque tâche). `taskTrainingProvider`
     et `expressionHubProvider` en **dérivent sans réseau** : arriver sur
     « Examens » depuis « Sujets » ne coûte plus rien. Seuls les **modèles**
     (`taskExamplesProvider`) restent portés par la tâche — l'endpoint exige
     `tacheNumero`.
   - **Ce qui reste frais.** Le cache ne doit jamais faire mentir la progression :
     `productionCatalogProvider` et `skillsSectionProvider` sont invalidés
     explicitement après une **soumission** ou une **analyse**
     (`competence_prompt_screen`, `competence_result_screen`), au **retour d'un
     flux poussé** (`ProductionParcoursScreen.didPopNext`, qui ne recharge que la
     donnée du **mode actif** — un micro-sujet de compétence ne touche pas au
     catalogue TCF), et au tiré-pour-rafraîchir. Le **quota d'analyses**
     (`skillAnalysisQuotaProvider`) et les providers de détail
     (`skillDetailProvider`, `skillPromptProvider`, `skillAttemptProvider`)
     restent **`autoDispose`** : ils portent l'état du candidat sur un sujet
     précis, on les veut frais à chaque ouverture.
   - Les **bilans d'examen** (`examBilansProvider`) dépendent de la *liste d'ids*
     des sessions, pas du catalogue entier : recharger le catalogue parce que le
     candidat vient de produire un sujet ne relance pas N appels de bilan.
   - Coût réseau, aller-retour T1 → T2 → T1 : **9 appels → 1** en Compétences,
     **9 → 4** en Sujets (2 d'épreuve + 1 modèle par tâche visitée) ; tour des
     trois modes : **7 → 2 + les bilans**. Verrouillé par
     `test/production_parcours_caching_test.dart` (faux repositories qui
     **comptent** les appels + test de widget prouvant que le mode quitté reste
     monté).

**« Exemples » n'est pas un mode** (la barre n'a que trois entrées) : c'est une
ressource d'appoint, atteinte par un **bouton discret en tête de la liste des
sujets** (`_ExamplesLink`) qui pousse `TcfTaskExamplesScreen`. Ne pas le
réintroduire dans un toggle.

1. **Le hub d'épreuve est SUPPRIMÉ** (passe 2026-08-06, demande client : « dès
   qu'on vient du menu Réviser → EO ou EE, on arrive directement sur l'écran comme
   celui du template »). `TcfExpressionScreen` — hero + 3 `ProductionTaskCard` +
   historique récent + `FixedActionBar` « Examens blancs » — n'existe plus, parce
   que la maquette n'a pas ce niveau : elle ouvre sur son écran d'accueil et change
   de tâche par les **pastilles T1/T2/T3**.
   - **Entrée du parcours** = le mode « Compétences » de la tâche 1
     (`AppRoutes.tcf{Ee,Eo}Entry` = `/tcf/{ee,eo}/tache/1/competences`), le mode
     actif par défaut de la maquette. Utilisée par Réviser
     (`dashboardCategoryRoute`), l'Accueil (bloc IA) et les recommandations.
   - **`/tcf/ee` et `/tcf/eo` restent des alias en redirect**, pas du code mort :
     les écrans de résultats, de bilan de session et d'historique s'en servent
     encore comme « racine de l'épreuve » quand la pile est vide.
   - Ce que portait le hub : les **examens blancs** sont la 3ᵉ entrée de la barre
     fixe du bas (`ProductionModuleTab.examens`) ; l'**historique récent** est
     abandonné (« on l'oublie pour l'instant »), l'historique complet restant
     atteignable par Profil → Mon entraînement → Mes historiques → EE/EO.
   - `HubData` / `expressionHubProvider` (`expression_hub_data.dart`) **survivent** :
     la page « Examens blancs » les consomme. La progression y reste calculée côté
     client depuis les soumissions **déjà servies** par `listMine` (aucun endpoint
     ajouté) : on repart des `tasks` publiées, donc un sujet retiré du catalogue ne
     gonfle ni le numérateur ni le dénominateur, et un sujet repris deux fois ne
     compte qu'une fois. Verrouillé par `test/production_parcours_test.dart`.

2. **`ProductionSubjectsTabView`** (`/tcf/{eo,ee}/tache/:n`) — le mode « Sujets » :
   la tête commune du parcours (cf. § « Structure du parcours »), puis
   `ExamFilterChips` **Tous / À faire / Traités** avec compteurs,
   `ProductionSectionHead` « Sujets d'entraînement » portant à droite le lien
   discret **« N exemples corrigés »** (`ProductionSideLink`), puis les
   **`ProductionSubjectCard`**.
   **Tap un sujet non fait → l'entraînement démarre directement** (`startSingle` +
   briefing `/tcf/expression-{orale,ecrite}/t/0`) ; sujet fait → sheet Voir le
   détail / Refaire. Freemium inchangé : 1er sujet offert, suivants → paywall, le
   verrou suit **l'index d'origine**, jamais l'index filtré.
   - **Info one-time « Un essai gratuit par épreuve »** (`showAppSheet`, posée en
     `initState` + post-frame) : 1 essai d'entraînement offert **par épreuve** +
     1 examen blanc de production offert (règle backend
     `ProductionAccessService.enforceQuota`). Mémorisée par épreuve dans
     `SharedPreferences` sous **la même clé que le web**
     (`sejourfr.prodQuotaInfo.TCF_{EE,EO}`, `prodQuotaInfoKey`), **jamais montrée
     à un abonné TCF**. Le mobile ne l'avait **jamais eue** (elle n'existait que
     sur le web, sur le hub d'épreuve supprimé) — ajoutée ici par parité.
     ⚠️ Elle vit sur **cet écran et nulle part ailleurs** : c'est le seul de
     l'épreuve où la règle s'applique, et il précède l'écran qui consomme
     l'essai. **Surtout pas sur l'écran d'entrée** (mode « Compétences ») : les
     micro-exercices ne verrouillent aucun sujet et ont leur **propre** quota
     (analyses IA offertes) — l'y afficher annoncerait une règle fausse.
   - Données : `taskTrainingProvider` (`task_training_data.dart`), **dérivé sans
     réseau** de `productionCatalogProvider`. L'écran des exemples lit directement
     `taskExamplesProvider` : il n'a que faire des productions du candidat.

3. **`TcfTaskExamplesScreen`** (`/tcf/{eo,ee}/tache/:n/exemples`) — les **modèles**
   (`GET /api/production-examples?…`, appel inchangé) : `FeaturedExampleCard` (lecteur
   inline en oral, bouton corrigé à l'écrit), `StrategyCard` → `PlanSheet`,
   `ProductionNotice`. 1er modèle offert, suivants → paywall.

**Carte d'exercice** (`widgets/consigne_card.dart`, partagée EE + EO + écran de fin) :
c'est le `.exercise` de la maquette — carte blanche r28, padding 18, pastille de
critère teintée de l'accent + repère « Tâche i/N » à droite, titre d'intention,
consigne, encadré de contexte, chips de contraintes. Les paramètres ajoutés
(`step`, `contexte`, `requirements`) sont **optionnels** : les appelants historiques
(variantes compactes `maxLines` des écrans d'enregistrement et de fin) sont
inchangés.

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

**Correction IA affichée (profil TCF IRN, rubriques v8 / schéma v5, maximum B2)** — le corps des deux écrans de
résultats (EE + EO) est le widget partagé `widgets/evaluation_report.dart` : un seul endroit
décide de l'ordre et de la forme de la correction, **y compris la note**. Le rapport prend un
`isOral` (et plus un titre de corrections) : c'est lui qui en déduit le wording des exemples
**et** la limite de l'évaluation orale.

**Passe « rapport express » (2026-08-08)** — verdict client : *« le contenu est bon, mais trop
verbeux, un candidat ne lira pas tout ça »*. **Aucune information n'a été retirée** : ce qui
disait deux fois la même chose a été **fusionné**, ce qui se consulte a été **replié**.
Structure de référence : maquette « Résultats TCF — Rapport express », **couleurs de l'app**
(zéro hex, `AppColors.*` / `AppFonts.*` / `LucideIcons.*`). **4 sections, dans cet ordre** :

1. **Hero** (`results_hero.dart`) — le `.hero` de la maquette : dégradé de marque +
   **halo clair** en haut à droite, eyebrow « Expression écrite · Tâche 1 », **verdict
   d'objectif** en gros, `objectif_resume`, puis le panneau `.level`
   **translucide** (blanc 13 %, bordure blanc 18 %) : niveau estimé + pastille + barre des
   cinq paliers, et enfin le **rappel d'enjeu**. Les trois cartes d'avant (bandeau « Évaluation terminée », `objective_card.dart`,
   `production_score_hero.dart`) n'en font plus qu'une, et les trois fichiers sont
   **supprimés**. Pas d'objectif (≈ 100 évaluations legacy) → titre neutre « Votre
   correction », le hero tient quand même. **Aucune pastille d'icône devant le verdict** :
   la maquette n'en a pas, et « Objectif non atteint » se lit en toutes lettres.
2. **Deux bandeaux pleine largeur, empilés et repliés** (`results_summary_tiles.dart`) :
   **« Ce qui marche »** (vert — `N/M points traités`, **obligatoires seulement** des deux
   côtés ; repli sur le compte de points forts sans check-list) et **« À corriger en
   priorité »** (**rouge** — `N priorité(s)`). Chacun tient sur **une ligne** : titre, chiffre,
   chevron. Appuyer ouvre le détail **dans le même encart, juste en dessous** — points traités
   puis points **oubliés** (intertitre rouge, depuis v15/v9) puis points forts d'un côté
   (ces derniers séparés par un filet, deux natures différentes), la ou les
   priorités **complètes** de l'autre (`PriorityCard(embedded: true)` : ni carte ambre ni
   étiquette, le bandeau les porte déjà). Un bandeau sans contenu ne s'affiche pas.
   ⚠️ **La priorité vit désormais à UN SEUL endroit.** Elle était résumée en tête puis répétée
   en entier plus bas : c'était la dernière redite du rapport. Le rouge est assumé ici — c'est
   le seul bloc qui dit « à refaire », et il ne peint aucun niveau CECRL (la règle « jamais de
   rouge sur un niveau » n'est pas en cause).
3. **Profil par critère** (`criteria_overview.dart`) — **une carte par critère**
   (`.criterion` de la maquette : pastille 40×40, nom, barre 6 px, bande à droite), **sortie
   du repli** (elle y était, donc personne ne la voyait). Commentaire, preuve **et définition
   complète** se déplient carte par carte via le bouton **« Voir pourquoi » / « Masquer le
   détail »** (`CriterionRow.showDetail` + `onToggle`). Quatre lignes serrées dans une seule
   carte se lisaient comme un tableau, pas comme quatre choses sur lesquelles appuyer.
4. **Votre rédaction** (`production_text_card.dart`) — le texte rendu, **et rien d'autre** :
   la bascule « Voir la version améliorée » a été **retirée le 2026-08-08** (cf. la règle
   dédiée plus bas), et `improved_version_card.dart` est **supprimé**. La phrase visée par la
   priorité n° 1 y est **surlignée** (`highlight`, première occurrence **exacte** ; aucune
   correspondance ⇒ aucun repère, jamais un repère faux), avec pour seule action « Masquer
   les repères » (douce). Puis, juste en dessous, le **plan d'action** :
   `production_action_plan.dart`.
5. **Le plan d'action** (`ProductionActionPlan`, `version_ciblee`) — les mêmes blocs que le
   retour d'un micro-exercice de compétence, via les widgets **partagés**
   `widgets/action_plan.dart` : « Pour viser {niveau} » (leviers action / exemple), puis
   « Une version plus aboutie » à l'écrit (texte réécrit, extraits surlignés, puce par
   segment) ou « Des versions plus abouties » à l'oral (une ligne par reformulation :
   `original` atténué, `reformule` en accent, pastille `apport`), puis « À retenir ».
   ⚠️ **Le titre n'étiquette plus un texte d'un palier** : l'ancien bloc « La marche
   au-dessus » / « Au niveau B2, votre réponse pourrait ressembler à ceci » est
   **supprimé** (`target_level_version_card.dart` avec lui), parce que rien ne vérifie
   qu'un texte atteint le palier annoncé — un candidat a recopié un exemple étiqueté B2 et
   l'analyse l'a noté B1. Seul l'**objectif** est nommé. Chaque section se masque
   indépendamment ; bloc absent ⇒ rien du tout.

### Le sursis du plan d'action (2026-08-11)

Le plan d'action vient d'un **second appel LLM**, lancé côté serveur **après**
que la correction est persistée et la soumission passée à `EVALUATED` — hors
transaction, pour qu'il ne puisse jamais retarder ni faire échouer la
correction. **Ce comportement serveur est volontaire et ne change pas** : le
correctif est entièrement côté app. L'écran s'affichait sans plan alors qu'il
arrivait dix à quinze secondes plus tard, et le candidat devait sortir puis
revenir pour le voir.

- **Le polling existant est prolongé**, pas doublé. Les deux écrans de résultat
  (`ee_results_screen` / `eo_results_screen`) recopiaient la même boucle : elle
  est désormais arbitrée par **`ProductionResultPollGuard`**
  (`production_result_polling.dart`, avec `kProductionPollInterval` 3 s et
  `kProductionPollMaxDuration` 90 s = borne dure). Après `EVALUATED`, il
  prolonge **15 s au maximum** tant que le feedback ne porte ni `versionCiblee`
  ni `niveauViseAtteint`.
- **Durée, libellé et indicateur vivent à un seul endroit**, dans
  `widgets/action_plan.dart` — déjà partagé avec le résultat d'un
  micro-exercice, qui attend exactement le même bloc : `kActionPlanGrace`
  (**15 s**, miroir de `ACTION_PLAN_GRACE_MS` côté web ; l'ancien
  `_niveauViseGrace` à 10 s des Compétences est **supprimé**),
  `kActionPlanPendingLabel` (**« On prépare tes conseils… »**, contrat gelé) et
  le widget `ActionPlanPending` (le petit `CircularProgressIndicator` déjà
  employé par `EvaluationLoadingView`, pas un composant de plus).
- **Ce que voit le candidat** : un petit spinner et une ligne, à l'emplacement
  du bloc. **Non bloquant** (le rapport reste entièrement lisible et
  défilable), et il **disparaît en silence** à la fin du sursis — pas de message
  d'échec, pas de « indisponible » : un plan absent est un cas normal.
- ⚠️ **Jamais sur un rapport rouvert plus tard.** Le garde et
  `_awaitsNiveauVise` (Compétences) exigent tous deux d'avoir **vu la correction
  en vol** depuis l'ouverture de l'écran. Une correction de trois jours ne poll
  donc pas et n'annonce aucun conseil. Ne pas relâcher cette condition.

⚠️ **« Voir l'analyse complète » n'existe plus (contrat v15 / tool-schema v9, 2026-08-11).**
Le correcteur ne produit plus `exemples_corriges` ni `suggestions`, et ce repli — que
personne n'ouvrait — part avec eux : `_FullAnalysis`, `_CorrectionsCard`,
`accomplishment_card.dart` et `avertissements_card.dart` sont **supprimés**. Les deux champs
restent **décodés** dans `production_models.dart` (une centaine d'évaluations en base les
portent) et **aucun écran candidat ne les lit**. Ce qui vivait dans le repli sans venir du LLM
a été **remonté**, pas perdu :
- **« À savoir sur cette évaluation »** (`avertissements`, écrit par le **serveur** : limite
  de l'oral, purges automatiques) devient une **note discrète sous le hero**
  (`widgets/evaluation_notice.dart`) — ni accordéon, ni carte pleine, et rien du tout quand
  la liste est vide ;
- **la check-list de la consigne** vit désormais dans le dépliant du bandeau **« Ce qui
  marche »**, qui montrait déjà les points **traités** et montre aussi les points
  **oubliés** (intertitre rouge « Points oubliés ») : sans eux, le candidat lisait « 2/3
  points traités » sans jamais savoir lequel manquait. Les **pistes non abordées**, qui ne
  coûtent aucun point, ne sont plus rendues.
La transcription EO reste dans sa feuille (dialogue en bulles).

**Trois arbitrages de la passe, à ne pas défaire sans raison :**
- **Les points forts ne sont plus en clair.** Deux phrases entières = cinq lignes de prose
  entre le résumé et le profil, pour une information que « Ce qui marche » donne déjà en un
  chiffre. Ils vivent dans le dépliant de ce bandeau — **et nulle part ailleurs**.
- **La technique d'une priorité (`comment`) est bornée à 2 lignes** + « Comment faire » /
  « Réduire ». Le correcteur y écrit jusqu'à huit lignes de consignes imbriquées : à plat,
  c'était le plus gros bloc du rapport, et il chassait hors écran la seule chose vraiment
  actionnable — la phrase réécrite, qui elle **ne se replie jamais**.
- **Un critère se lit sous son NOM COURT** (`CriterionRow._shortLabelForCode` : Communiquer ·
  Interagir · Vocabulaire · Grammaire). Le `label` du serveur est une **définition**
  (« Communiquer : accomplir la tâche et enchaîner les idées ») : sur deux lignes, il pousse
  la bande hors de vue. La définition réapparaît au déplié — elle n'est jamais perdue.

Le fond des deux écrans de résultats passe de `white` à **`AppColors.bg`** : les cartes
blanches du rapport ne se détachaient pas sur du blanc pur.

`BeforeAfterLines` (`widgets/before_after_lines.dart`, promu depuis
`correction_example.dart` **supprimé**) rend l'avant/après **sans étiquettes** : l'ancienne
phrase barrée en rouge, la nouvelle en vert. Deux lignes au lieu de quatre — la rature dit
« avant » mieux que le mot « avant ». La forme étiquetée est partie avec les exemples
corrigés (v15/v9), son seul appelant.

Les intertitres sortent des cartes (`results_section_head.dart`) : chaque bloc portait son
titre dans un encadré coloré, ce qui faisait lire le rapport comme une suite d'alertes.

### ⚠️ Pas de note /20 sur le résultat d'une TÂCHE (décision 2026-08-08)

Au TCF, un correcteur attribue **un niveau par tâche, jamais une note** : le /20 ne porte que
sur l'**épreuve entière** (3 tâches). Et comme 10/20 y vaut déjà B2, un A2 parfaitement normal
s'affichait « 3,5/20 », qu'un francophone lit comme une catastrophe scolaire. À ne pas défaire :

- **`results_hero.dart` n'affiche aucune note** — ni en gros, ni en petit, ni dans un repli —
  et **aucune borne chiffrée de barème** (« 2-5 → A2 ») : la table des paliers de la feuille
  et `TcfNoteBand.rangeLabel` ont été supprimées avec elle. `TcfNoteScale` **n'est plus un
  widget** : il ne reste que `kTcfNoteBands` + `bandIndexFor` / `bandFor` / `bandeFor`, qui
  servent à **teinter** un résultat et à relire la bande d'un critère legacy.
- **La note reste affichée dès qu'on agrège les 3 tâches** : bilan d'épreuve EE/EO (`BilanHero`,
  `CecrlScale`) et bilan d'examen blanc TCF complet. Le critère est « 3 productions agrégées »,
  pas « examen complet ».
- **La règle vaut PARTOUT, pas seulement sur l'écran de résultat** (passe du 2026-08-08, second
  lot) : `TacheBilanRow` (détail par tâche du bilan de session), `ProductionSubjectCard` (badge
  d'un sujet traité), la feuille « sujet déjà traité » de `production_subjects_tab_view` et
  `HistorySessionCard` **quand la session ne compte qu'une tâche** (entraînement libre) rendent
  le **niveau**. Une session d'examen (≥ 2 soumissions) garde sa moyenne /20, comme
  `ProductionExamDoneResult` et `ProductionExamsStatsRow`.
  ⚠️ Le commentaire « Aucun niveau CECRL par tâche » de `tache_bilan_row.dart` datait du
  2026-06-11, quand le backend avait retiré le niveau par tâche de son DTO. Il l'y a remis
  (`EvaluationResult.niveauObserve`, contrat v4) : la décision est **inversée**, le commentaire
  est supprimé.
- **Deux helpers partagés dans `production_result_labels.dart`** : `tacheNiveau(evaluation)`
  (le niveau affichable, `null` sans confiance ou sur une éval antérieure au contrat v4 — on
  n'invente rien, on écrit « Évaluée » / « Fait ») et `tacheNiveauLabel(niveau)` (**libellé
  gelé** : « Niveau B2 » …, et « A1 non atteint » pour le plancher, qui se contredirait en
  « Niveau A1 non atteint » — miroir mot pour mot du web, verrouillé par test des deux côtés).
- **Le niveau s'affirme** : `niveauAtteintLabel` rend « Votre production est au niveau A2 »,
  plus jamais « Proche du niveau A2 » — « proche de » veut dire « pas encore » en français
  courant, alors que le niveau EST A2. Le plancher a sa propre formulation (« n'atteint pas
  encore le niveau A1 »). Sans confiance, le panneau écrit « Niveau indisponible pour cette
  production » et ne rend ni pastille ni barre.
- **Rappel d'enjeu** (`demarcheRappel`, bloc `VOTRE DÉMARCHE` du hero) : le niveau obtenu mis
  en face de la démarche du candidat (A2 → carte de séjour pluriannuelle · B1 → carte de
  résident · B2 → naturalisation, seuils du 1ᵉʳ janvier 2026). C'est le vrai
  anti-découragement — un A2 qui vise la carte de séjour **est** au niveau demandé. Le palier
  visé vient de `userTargetLevelProvider` (`core/providers/`), dérivé de `targetProcedure` :
  parcours inconnu ⇒ **rien** ne s'affiche, jamais un message générique.
- **Règles pures dans `production_result_labels.dart`** (sans Flutter, testées) :
  `niveauAtteintLabel`, `tacheNiveau`, `tacheNiveauLabel`, `kNiveauPorteeTache`,
  `kConfianceSansRaison`, `demarcheRappel`. Miroir web : `lib/production-feedback.ts`.

- **La barre des cinq paliers** (`<A1 · A1 · A2 · B1 · B2`) est à **largeur égale** (pas
  proportionnelle) : sur le dégradé bleu les teintes de `CecrlColor` ne se voient plus, donc le
  palier atteint passe en **blanc plein** et c'est la **pastille — blanche, texte teinté** —
  qui porte la couleur du niveau. `donut_chart_score.dart`, `niveau_observe_card.dart` et
  `production_score_hero.dart` restent **supprimés**, fusionnés dans `ProductionResultsHero`.
- **La règle de lecture du NIVEAU se consulte, elle ne s'impose pas** : `avertissementNiveau`
  (ou son repli `kNiveauPorteeTache`) vit dans une feuille, ouverte en **appuyant sur le
  panneau de niveau** (la pastille ⓘ à côté du sur-titre en est le repère). Elle explique le
  niveau, **jamais une note invisible**.
- **La confiance ne s'affiche QUE si elle n'est pas `HAUTE`** (avec ses `confianceRaisons`) :
  une confiance haute est le cas normal, l'annoncer n'apprend rien et inquiète.
- **Limite de l'évaluation orale** : le correcteur la renvoie normalement dans
  `avertissements` ; quand la liste arrive **vide sur une tâche orale**, le rapport affiche le
  repli `kOralEvaluationLimitNotice` (texte mot pour mot de `docs/notation-ia-eo-ee.md` §9,
  même repli que le web). Jamais à l'écrit.
- **Une priorité ENSEIGNE** : `points_a_ameliorer[]` est un **objet**
  `{constat, comment?, exemple?{avant, apres}}` (`PointAAmeliorer`), rendu par
  `priority_card.dart` — `comment` = la technique réutilisable, **bornée à 2 lignes** avec
  « Comment faire » ; `exemple` = la démonstration avant/après sur la phrase du candidat,
  **toujours visible**.
  ⚠ **Les deux formes coexistent en base** : les évaluations antérieures portent de simples
  **chaînes** — `PointAAmeliorer.fromJsonNullable` les accepte et les rend comme un `constat`
  seul (aucun encadré vide, aucun bouton mort). Ne jamais retirer cette tolérance.
- `exemplesCorriges` et `suggestions` restent **décodés** (rétrocompatibilité) mais ne sont
  **plus affichés nulle part** : le contrat v15 / tool-schema v9 ne les produit plus.
- **Par critère on affiche la bande, pas la note** : `CriterionScore.bande` (`BandeCritere`,
  calculée côté serveur) → **« Niveau B2 / Niveau B1 / Niveau A2 / Niveau A1 / Non
  évaluable »**, plus la `preuve` (citation littérale) sous le commentaire — **dépliés à la
  demande** dans la section 4. ⚠️ Ces libellés **nomment le palier atteint, pas un déficit** :
  les bornes des bandes (10 / 6 / 2) sont exactement celles des paliers du TCF, donc
  « En cours d'acquisition » couvrait TOUTE la bande A2 et un candidat A2 ne pouvait voir que
  ça, quoi qu'il produise. Ces chaînes ne transitent pas par le réseau : **miroir mot pour mot
  de `bandeCritereLabel` côté web** (`lib/types.ts`), gelé par test des deux côtés (même
  technique que le module Compétences). Une note qui s'affiche encore (bilans) passe toujours
  par `formatScore` (`core/utils/format_date.dart`), jamais par un arrondi local. La grille
  active n'a que **4 codes équipondérés** (`communiquer`, `interagir`,
  `lexique`, `morphosyntaxe`), mais la table icône↔libellé de `criterion_row.dart` garde
  **tous** les codes des grilles précédentes (`realisation_consigne`,
  `adequation_destinataire`, `chronologie_recit`, `developpement_reponses`, `prise_position`,
  `argumentation`, `conduite_echange`, `coherence`, `pertinence`) — sinon l'historique
  retombe sur l'icône et le libellé par défaut. Un test le verrouille.
- **Garde-fou non négociable** : jamais de niveau sans sa confiance
  (`EvaluationResult.hasNiveauObserve`). Le **bilan d'épreuve** reste le seul niveau qui fait
  foi.
- **La note /20 suit l'échelle TCF IRN** : 0 = A1 non atteint, 1 = A1, 2-5 = A2,
  6-9 = B1 et 10-20 = B2 (plafond du profil, jamais C1/C2) — table jamais affichée au
  candidat. Une tâche isolée n'a ni note ni correspondance de bilan. La
  correspondance (`ProductionBilan.correspondanceTcf` → `CorrespondanceTcf.phrase`) ne
  s'affiche qu'au **bilan d'épreuve** (`BilanHero`), au même wording que le web.
  Cf. `docs/notation-ia-eo-ee.md` §6.6.
- `CecrlScale` affiche uniquement les quatre paliers du profil A1→B2. Les valeurs
  C1/C2 restent décodables pour l'historique mais sont rabattues visuellement sur B2.
- **Rétrocompatibilité (une centaine d'évaluations en base)** : `niveauObserve` / `confiance` /
  `avertissementNiveau` / `bande` / `accomplissement` / `objectif` / `objectif_resume` /
  `version_amelioree` / `preuve` / `gain` absents, et
  `points_a_ameliorer` en chaînes = cas **normal** → les blocs concernés disparaissent et
  l'écran reste cohérent. Couvert par `test/production_models_test.dart` +
  `test/evaluation_report_test.dart`.

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
- La correction IA réutilise le pipeline existant (Whisper + correcteur configuré).

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
   `EvaluationLoadingView(includeTranscription: true)` pendant l'upload R2 + Whisper + correcteur
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
auto-soumission du texte courant **s'il est recevable** (mots ∈ [motsMin, motsMax],
bornes strictes TCF IRN : 30–60 / 40–90 / 40–90), sinon rien ;
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

### Situation dans le palier + version au niveau visé (2026-08-08, 3ᵉ lot)

Deux champs backend nouveaux, câblés dans la même passe (miroirs :
`core/models/production_models.dart`, `web_sejoufr/lib/types.ts`,
`admin_sejourfr/src/types/api.ts`).

- **`EvaluationResult.situationDansNiveau` / `situationDansNiveauLabel`** — le
  cran de progression **dans** la bande (enum `SituationDansNiveau` dans
  `core/models/enums.dart`), qui remplace la note disparue du résultat d'une
  tâche. Lu par `situationView` (`production_result_labels.dart`) et rendu en
  pastille discrète sous le niveau du hero, à la forme **composée**
  (« A2 solide ») — celle qu'annonce `docs/notation-ia-eo-ee.md` §6.3 bis.
  ⚠️ **Jamais « presque B1 »** : aucun cran ne nomme un manque, c'est la
  contrepartie de la note masquée. Deux gardes : rien sans niveau affichable
  (donc rien sans confiance), rien quand le backend n'envoie pas de cran (évals
  antérieures, `A1_NON_ATTEINT`, C1/C2). Libellés gelés par test des deux côtés
  (`situationLibelle` / `situationQualificatif`).
- **`feedback.version_ciblee`** (`VersionCiblee`) → `ProductionActionPlan`,
  rendu **juste sous** `ProductionTextCard`. **EE ET EO** depuis le contrat v2
  (le `isOral` qui l'annulait a été retiré). **Trois formes, une seule clé**,
  distinguées à la présence de `exempleCible` ou de `reformulations` :
  - **v2, écrit** : `leviers[2..3]{action, exemple}` + `exempleCible{texte,
    segments[2..3]{extrait, apport}}` + `aRetenir{formule, explication}` ;
  - **v2, oral** : idem, mais `reformulations[2..3]{original, reformule,
    apport}` **à la place de** `exempleCible`. **Aucun texte modèle complet à
    l'oral** — la production n'est jamais réécrite en entier ;
  - **v1** (une centaine d'évaluations en base) : `texte` + `ceQuiManque`, écrit
    seulement. Rendu comme avant, **sans l'étiquette de palier** sur le texte.
  Ces formes vivent dans `core/models/action_plan.dart` (`ActionPlanLevier`,
  `ActionPlanSegment`, `ActionPlanExempleCible`, `ActionPlanReformulation`,
  `ActionPlanMemo`) — **partagées avec `SkillNiveauViseDto`**, qui portait des
  jumelles `SkillNiveauVise*` : elles sont supprimées, pas dupliquées. Chaque
  `extrait` est **garanti sous-chaîne exacte** du texte : on surligne par
  recherche de chaîne, un extrait introuvable ⇒ texte brut. L'ordre des leviers
  vient du backend (du plus rentable au moins rentable) : **ne jamais le
  retrier**. Bloc absent ⇒ **rien n'est rendu** (éval antérieure, second appel en
  échec, oral dégradé, niveau visé déjà atteint) — pas de squelette, pas de
  « non disponible ». Chaque sous-bloc se masque **indépendamment**.
- ⚠️ **`versionAmelioree` N'EST PLUS AFFICHÉE NULLE PART (2026-08-08).** Elle
  réécrit la production au niveau **déjà constaté** et vivait en bascule sous la
  rédaction, sans mention de niveau : c'était le texte le plus visible et le
  plus copiable du rapport, et il ne fait pas monter d'un palier. Mesuré : le
  propriétaire l'a recopiée telle quelle, resoumise, et a obtenu **la même note
  et le même niveau au dixième près** (4,5/20, A2). Le champ **reste dans le
  contrat serveur et décodé dans `production_models.dart`** — le retirer
  imposerait une version de tool-schema sur la grille de notation — mais **aucun
  widget ne le lit**. Sont morts et supprimés : `improved_version_card.dart`, la
  prop `versionAmelioree` de `ProductionTextCard`, sa bascule et le libellé
  « Comparez en 10 secondes ». `test/evaluation_report_test.dart` a **retourné**
  ses tests d'affichage (ils vérifient l'absence) et couvre le cas « aucun texte
  modèle ». Même retrait, même passe côté web.
- **Libellés partagés** : `kTacheTraiteeLabel` vaut désormais **« Traité »**
  (c'était « Fait », le web disait « Traité » pour le même état) et
  `kTacheEvalueeLabel` « Évaluée » — tous deux dans
  `production_result_labels.dart`, gelés en miroir du web. Le « Fait » des slots
  d'examen (`exam_slot/`) et de `SkillPromptStatus.treated` est un **autre**
  contrat, inchangé. **« Évaluée » est le repli, partout** : une production
  corrigée sans niveau affichable l'affiche aussi bien dans `TacheBilanRow` que
  dans `HistorySessionCard` (qui écrivait « — ») et dans la feuille « sujet déjà
  traité » (qui ne disait plus rien du tout).
- **Le conseil de fin de bilan est partagé** : `kBilanProchainesEtapesTitle`
  (« Vos prochaines étapes ») + `bilanProchainesEtapesMessage(niveau)`
  (`production_result_labels.dart`). Il vivait **en double**, écrit à la main de
  chaque côté, et les copies avaient divergé — **ici on tutoyait**, le web
  vouvoyait, et le reste de la restitution vouvoie. Surtout, chacune recopiait
  la table **démarche → palier**, donnée légale que `TargetProcedure` interdit de
  réécrire dans un écran : elle vient désormais de `TargetLevel.demarcheLabel`.
- **`kProductionExamMinSubmissions = 2`** (`expression_hub_data.dart`) : le
  seuil qui distingue une session d'examen d'un entraînement libre. Il valait
  **3** — un examen abandonné après 2 tâches n'apparaissait nulle part côté
  mobile alors qu'il figurait dans la grille web et que le backend avait bien
  consommé le slot. `HistorySessionCard` en tenait **trois copies en dur**
  (`>= 2`) : elles sont remplacées par la constante. `HubData.singles`, sans
  consommateur depuis la refonte du parcours, est **supprimé**.
- **Une pastille de niveau porte la forme COURTE** (`NiveauCecrl.shortName`,
  « <A1 ») : `LevelPill` affichait `displayName`.

## Compétences TCF (`screens/tcf_production/competences/`)

Espace **voisin** des sujets TCF complets, jamais un remplacement : on y travaille **un
critère à la fois** sur de petits sujets de production ouverte. 6 tâches × 8 compétences ×
15 petits sujets, chacun avec 3 références comparatives écrites en base.

**Les 5 niveaux** : épreuve → tâche → *deux espaces* (Sujets | **Compétences** | Exemples)
→ une compétence → un petit sujet → son résultat.


### Fidélité au prototype client (passe de reprise)

Le module suit **la maquette du client**
(`docs/skills/sejourfr_expression_ecrite_v3_competences.html`) : structure,
hiérarchie, géométrie **et navigation**. Trois règles qui ne se négocient pas :

1. **On reproduit le prototype**, y compris son accueil (hero, pastilles de
   tâche, encart pédagogique) et sa carte d'exercice.
2. **Les couleurs restent celles de l'app** : `AppColors.*` / `AppFonts.*` /
   `LucideIcons.*` exclusivement. Il manque une teinte ⇒ on **ajoute une entrée
   au thème**, jamais un `Color(0xFF…)` dans un écran. Le module est à **zéro
   hex** et doit le rester.
3. **On ne reproduit PAS la barre d'onglets du haut** du prototype
   (« Compétences | Sujets TCF | Examens blancs ») : cette navigation existe
   déjà en bas de l'app.

Ajouts au thème faits pour ça (`core/theme/app_theme.dart`) :
- **`AppColors.amberDark`** — l'ambre **de texte**. `AppColors.amber` est un
  ambre de *remplissage*, illisible en lettres : c'est lui qui avait produit le
  hex en dur de `core/widgets/app_tag.dart`. Toute mention ambre écrite (badge
  « À renforcer », tipline) passe par `amberDark`.
- **`AppGradients.hero(from, to)`** + **`AppGradients.premium`** — un hero se
  peint avec l'accent de son module, pas avec un dégradé écrit dans l'écran.

Et deux conventions transverses :
- **`TcfProductionModule.accent` / `.accentDark`** portent l'accent du module
  (EO rouge, EE bleu). Les quatre écrans recopiaient le même ternaire :
  ne pas le réintroduire.
- **L'accent descend en paramètre optionnel** (bleu par défaut) dans les
  widgets partagés utilisés par le module — `AppTag.compact`,
  `ExamFilterChips.accent`, `WritingZone.accent`. La valeur par défaut préserve **au pixel près**
  le rendu des appelants historiques : ne jamais la changer pour arranger un
  seul écran.

Briques de la maquette, dans `competences/widgets/` :
`competences_hero.dart` (hero en dégradé + progression globale),
`competences_task_pills.dart` (T1/T2/T3, filtre local — cf. la passe fluidité),
`competences_blocks.dart` (intertitre, encart « notice », tipline ambre,
pastille de numéro **48×48 r16 — une seule forme partout**, chevron 30×30,
`PressableCard` = ombre douce + enfoncement au toucher, `DashedBox` = la
bordure pointillée que Flutter n'a pas nativement).

### L'écran d'un petit sujet — il fait produire, il n'explique pas

Refonte 2026-08-06 (verdict client sur la version précédente : « beaucoup trop
verbeux et pas du tout intuitif »). Référence :
`~/Downloads/saisi_ee-competence.png`.

**Le critère de réussite est mesurable et verrouillé par des tests** : la zone
de production doit être **visible sans défiler** sur un téléphone standard
(`test/competence_prompt_layout_test.dart`, qui pompe le vrai écran à 390×844
et 375×812 et compare la position du champ au haut du `FixedActionBar`). Tout
ce qu'on ajoute au-dessus de la carte « Ta réponse » se paie en défilement
et fera tomber ces tests — c'est le but, ne pas les assouplir. Ce qu'on ajoute
**sous** la zone (lecteur de réécoute, avertissement de transcription) ne les
concerne pas : c'est là qu'on met la matière nouvelle.

Structure, de haut en bas (`competence_prompt_screen.dart`) :
1. en-tête (`ScreenHeader`) ;
2. `_PromptMetaRow` — `Sujet i/N` à gauche, pilule de palier à droite ;
3. `_SkillProgressBar` — libellé réduit à **« Progression »** ;
4. `SkillChecklistCard` « Ce qu'il faut faire » ;
5. `SkillSituationCard` « Situation » ;
6. `SkillConstraintRow` — puce de longueur **puis** étiquettes de contrainte ;
7. `SkillAnswerCard` « Ta réponse » — icône **crayon à l'écrit, micro à
   l'oral** — zone de production + pied de carte (astuce à gauche,
   compteur/durée à droite) ;
8. à l'oral seulement : `SkillTranscriptNotice`, **sous** l'enregistreur ;
9. **sous** la zone : le reste d'analyses offertes (compte gratuit uniquement),
   tipline ;
10. `FixedActionBar` : `Valider et comparer` · `Effacer`.

**Ont été supprimés** (et leurs widgets avec — `criterion_highlight.dart`,
`self_evaluation_picker.dart` et `analysis_toggle.dart` n'existent plus) : le
fil d'Ariane sur deux lignes, les badges « Une compétence · un critère » et
« Petit sujet i/N », le titre « Produis ta propre réponse. », le paragraphe
d'objectif, l'encart « Compétence évaluée », l'encart « Pourquoi cet
exercice ? », les puces méta « Accessible » / « Un seul critère »,
**l'auto-évaluation** et **la bascule d'analyse IA**.

**Parité écrit ⇄ oral par construction** : `SkillAnswerCard` est **une seule
coque** pour les deux épreuves. Seuls changent le `child` (champ de saisie ⇄
`SkillRecorderPanel`) et le `meta` (compteur de mots ⇄ durée). Ne pas refaire
un écran oral à part.

**Les 4 champs de guidage** (`SkillPromptDto.checklist`, `constraintTags`,
`answerStarter`, `tip`, backend V026 + V306-311) sont **tous facultatifs** — un
sujet créé depuis la console d'administration peut naître sans guidage. La
dégradation est un contrat, pas un cas limite : pas de check-list ⇒ la carte
retombe sur la **consigne** ; pas d'étiquette ⇒ seule la puce de longueur ; pas
d'amorce ⇒ texte grisé neutre ; pas d'astuce ⇒ pied de carte réduit au
compteur. **Jamais de carte vide, jamais de « null » à l'écran.**

- La **puce de longueur** est générée par le front depuis les bornes en base
  (`skillLengthHint`) — `≈ 15–35 mots` à l'écrit, `≈ 45 secondes` à l'oral.
  Une étiquette de contrainte ne doit **jamais** la dupliquer. Règles alignées
  au mot près sur le web (`lib/skill-guidance.ts`) : **au-delà de 60 s on écrit
  en minutes** (`≈ 1 min 30`, jamais « 90 secondes »), et **une seule borne de
  mots reste une consigne** (`≈ 15 mots minimum` / `≈ 35 mots maximum`) au lieu
  de disparaître.
- **Plafonds de guidage appliqués à l'affichage** : `skillChecklist` (4 gestes)
  et `skillConstraintTags` (3 étiquettes), mêmes valeurs que le web. Le DTO
  reste fidèle au serveur ; c'est le rendu qui tronque, pour qu'une saisie
  d'administration trop généreuse déborde en base et non à l'écran (une 2ᵉ ligne
  d'étiquettes coûte la ligne de flottaison).
- La table **icône ↔ code d'étiquette** est unique et exhaustive
  (`skillConstraintIcon`, `prompt_guidance.dart`), avec
  `SkillConstraintIcon.unknown` comme repli d'un code non prévu. Ne pas
  disperser un second `switch`.
- Le **corps des cartes de guidage prend toute la largeur** : la référence
  l'aligne sous le titre, mais sur un téléphone étroit ce retrait de 40 px
  coûtait une ligne de repli par paragraphe — donc la zone de production sous la
  ligne de flottaison. Adaptation responsive assumée.
- `SkillRecorderPanel` **ne porte pas son propre cadre** : il vit dans
  `SkillAnswerCard`, là où l'écrit met son champ. Lui rendre une bordure
  blanche referait une carte dans une carte.
- **Réécoute AVANT de valider** (parité web) : capture terminée ⇒ le panneau
  monte le `SejourAudioPlayer` partagé sur le fichier **local** (rien n'est
  encore parti sur le réseau) + l'invite « Réécoute ta réponse, refais-la ou
  envoie-la à l'évaluation. ». Une coche et « Réenregistrer » faisaient envoyer
  à l'évaluation une production que le candidat n'avait pas entendue. Le lecteur
  partagé accepte désormais une URL `http(s)`, une URI `file://` **ou un chemin
  brut** (`_setSource` route vers `setFilePath`) — c'est ce qui évite un second
  lecteur pour trois lignes d'écart.
- **Compteur du pied de carte** : format du web (`0:12 / 0:45` à l'oral —
  écoulé / durée conseillée ; `20 / 35 mots` à l'écrit) et **trois teintes**
  (`SkillMetaTone`) — neutre tant que rien n'est produit, **vert dans la
  cible**, `amberDark` au-delà. Sans le vert, le candidat n'a que « rien » ou
  « trop » et n'apprend jamais qu'il est bon.
- **`SkillTranscriptNotice` (spec §15)** : la note se fonde sur la
  transcription ; prononciation, accent et intonation ne sont **pas** évalués.
  C'est le garde-fou central de l'oral — rendu sous l'enregistreur, jamais
  au-dessus (le micro ne recule pas).
- `SkillWritingField` est volontairement **distinct de `WritingZone`** (le gros
  éditeur des sujets TCF complets, avec stats, barre de progression et
  confirmation d'effacement) : ici le compteur et l'astuce vivent dans le pied
  de la carte. Ne pas rebrancher `WritingZone` sur cet écran.

Points de comportement à ne pas défaire :
- **La consigne est traduite en gestes AVANT la production** : la check-list
  remplace le critère abstrait, et l'ordre reste guidage → situation →
  contraintes → saisie. Le critère brut du sujet n'est plus montré tel quel.
- **La fourchette de longueur avertit, elle ne bloque pas** (règle 15). Le
  plafond de 400 mots est un garde-fou **serveur** : il s'affiche en avertissement
  et ne désactive plus le bouton de validation.
- **L'analyse IA n'est pas une option, et elle ne se déverrouille pas.** L'écran
  de saisie n'a plus de bascule : l'analyse est demandée dès que le compte y a
  droit (abonné, ou analyses offertes restantes). Quand il n'y a plus droit, la
  soumission part **sans** analyse au lieu d'échouer en 403 — c'est l'écran de
  résultat qui invite à s'abonner. Reste, sous la zone de production et pour un
  compte gratuit seulement, une **information** : « Ta réponse sera analysée par
  l'IA. Il te reste N analyses offertes. » La retirer ferait consommer un quota
  à l'insu du candidat ; la retransformer en interrupteur redonnerait une
  décision à prendre au pire moment.
- **Au résultat, l'analyse s'affiche dépliée** — c'est le retour qui vient
  d'être mérité. Le bandeau « Analyse IA du critère » et son bouton « Voir » ne
  subsistent **que** quand il n'y a rien à montrer (quota épuisé, production
  sans analyse, analyse en échec) : son action ouvre alors `showPaywallSheet`.
  Symétriquement, **les références comparatives sont repliées par défaut** dès
  qu'une analyse est affichée (intertitre tappable, « Comparer » ⇄ « Masquer »),
  et **ouvertes** quand il n'y a pas d'analyse — elles sont alors le seul retour
  de l'écran. Replier ne coupe aucun appel : la liste est chargée de toute
  façon, c'est elle qui décide si la section existe.
  Verrouillé par `test/competence_result_screen_test.dart` et
  `test/competence_prompt_analysis_test.dart`.
- **Ordre de l'écran de résultat (contrat v3, commun au web)** : bandeau
  « Production analysée / Progression mise à jour » → verdict du critère →
  **carte NIVEAU** → « Pour viser X » → « Une version plus aboutie » → « À retenir »
  → **`Ta production`, repliée** → références → deux actions (« Sujet suivant »
  puis « S'entraîner sur ce point », qui refait le sujet courant ; le retour en
  arrière reste la flèche d'en-tête). La production quitte la vue principale
  mais **reste à un tap** : à l'oral, se réécouter en lisant le retour fait la
  moitié de la valeur de l'exercice.
  - **Les trois blocs du plan d'action sont PARTAGÉS** avec le rapport de
    correction EE/EO : ils vivent dans `tcf_production/widgets/action_plan.dart`
    (`ActionPlanLeviers`, `ActionPlanExempleCard`,
    `ActionPlanReformulationsList`, `ActionPlanMemoCard` + les libellés gelés
    `pourViserTitle` / `kActionPlanExempleTitle` /
    `kActionPlanReformulationsTitle`), promus depuis `competences/widgets/` à
    leur deuxième consommateur. Ils rendent le **corps seul** — chaque écran pose
    son propre intertitre (`SectionTitle` ici, `ResultsSectionHead` dans le
    rapport). Ne pas les recopier.
  - **Tout est dérivé serveur** : `SkillLevelProgressDto` porte le niveau
    démontré, le palier visé, la situation, **son libellé prêt à afficher**,
    les 3 crans de la jauge et l'index du curseur. `SkillLevelCard` /
    `_LevelGauge` (`competences/widgets/skill_level_card.dart`) ne recalculent
    aucune position, ne réordonnent rien et ne recomposent jamais
    `situationLabel` — seul un **garde-fou de rendu** borne l'index.
  - **`analysis.niveauVise == null` est un cas NORMAL**, jamais une erreur : le
    bloc vient d'un **second appel LLM best-effort**, absent quand l'objectif
    est atteint. Ni message d'échec, ni spinner, ni encart d'excuse — les trois
    sections disparaissent, la carte de niveau se suffit.
  - **Course de l'appel 2** : quand la tentative passe `EVALUATED` avec un
    niveau, un objectif non atteint, pas de `niveauVise` **et que l'analyse a
    été vue en vol**, le polling continue **15 s de plus au maximum**
    (`kActionPlanGrace`, `widgets/action_plan.dart` — cf. « Le sursis du plan
    d'action » plus bas) — sinon l'écran s'arrête une seconde avant l'arrivée
    des leviers. Le budget global de 120 s reste la borne dure, et pendant le
    sursis la place du bloc porte `ActionPlanPending`.
  - **Deux générations d'analyses cohabitent sans migration** : `levelProgress`
    absent ⇒ contrat v1/v2 ⇒ on retombe **intégralement** sur l'affichage
    historique (point réussi / priorité / proposition améliorée), chaque bloc
    rendu seulement s'il porte du texte. Aucune régression sur ce qui est déjà
    en base.
  - **Surlignage de l'exemple** : le serveur garantit chaque `extrait`
    sous-chaîne exacte du texte, on découpe donc par recherche de chaîne. Un
    extrait introuvable est **ignoré** (texte brut) — on n'invente jamais un
    surlignage et on ne plante jamais.
- **La barre « Progression · X/N »** de l'écran d'un petit sujet est **calculée
  côté client** depuis `skillDetailProvider` (déjà en cache : l'écran est poussé
  depuis le détail). Aucun endpoint n'a été inventé ; en deep link direct la
  barre disparaît plutôt que d'afficher un chiffre faux.
- **Le liseré vertical d'une carte de sujet n'existe QUE si le sujet est traité**
  (3 px, en retrait de 17 px haut et bas) — un liseré gris permanent ne repère
  plus rien.
- **Couleurs des références** : `Insuffisant` rouge, `Attendu` vert,
  `Très réussi` bleu (`skillReferenceColor`, `skill_references_tabs.dart`).
  Ce n'est **pas** un niveau CECRL : la règle « jamais de rouge sur un niveau »
  ne s'y applique pas, le rouge y dit « contre-exemple ». Le verdict `PARTIEL`,
  lui, prend **`amberDark`** (`skillCriterionColor`) : cette couleur habille
  aussi le **libellé**, et `amber` est un ambre de remplissage illisible en
  lettres.
- **Le titre des références part avec son contenu** (`_ReferencesSection`) :
  aucune référence ⇒ ni intertitre « Compare avec les niveaux de référence », ni
  widget vide dessous. Il reste pendant le chargement et sur erreur — là, il y a
  bien quelque chose à annoncer.
- **La validation reste dans un `FixedActionBar`** (§13.10), désormais avec le
  bouton secondaire « Effacer » à côté.

**Routes** (`AppRoutes`, `moduleKey ∈ {ee, eo}`) :
- `/tcf/:moduleKey/tache/:tacheNumero/competences` → `ProductionParcoursScreen`
  (mode Compétences ; le corps est `CompetencesTabView`)
- `/tcf/:moduleKey/competences/:skillId` → `CompetenceDetailScreen`
- `/tcf/:moduleKey/competences/:skillId/sujet/:promptId` → `CompetencePromptScreen`
- `/tcf/:moduleKey/competences/resultat/:attemptId` → `CompetenceResultScreen`

Les quatre patterns ont des longueurs de chemin différentes (`resultat` est un littéral) :
aucune ambiguïté go_router, l'ordre de déclaration n'a pas d'effet.

**Modèle / réseau** : `core/models/skill_models.dart` + `core/api/skill_repository.dart`
(provider dans `core/api/repositories.dart`). ⚠ Le `Difficulty` de `core/models/enums.dart`
porte les paliers CSP/CR/NAT/A2/B1/B2 et **n'est pas** le `Difficulty` EASY/MEDIUM/HARD du
backend : ce dernier vit sous le nom `SkillDifficulty` dans `skill_models.dart`. Ne pas les
fusionner.

**State** (`competences_providers.dart`) : `skillsSectionProvider` charge **l'épreuve
entière en un appel** et est **gardé en vie pour la session** (`ref.keepAlive`, erreur non
cachée) ; `skillsListProvider` est un `Provider` **synchrone** qui filtre par `taskCode`
(clé value-object `SkillsKey`) — changer de pastille ne coûte rien. Les lectures **par
sujet** restent `FutureProvider.autoDispose.family` (`skillDetailProvider` /
`skillPromptProvider` / `skillReferencesProvider` / `skillAttemptProvider` /
`skillAnalysisQuotaProvider`) : elles portent l'état du candidat sur un sujet précis, on
les veut fraîches. La soumission passe par un `StateNotifierProvider.autoDispose.family`
(`skillSubmissionProvider`), après quoi `invalidateSkillsSection` **doit** être appelé —
sans ça la liste afficherait un « X/N sujets traités » périmé. Les chemins se construisent
dans `competences_nav.dart`, jamais recollés à la main.

**Statuts d'un petit sujet** (dérivés **côté serveur**, jamais recalculés ici) :
`TODO` « À faire » · `TREATED` « Fait » · `VALIDATED` « Validé » · `TO_REINFORCE`
« À renforcer ». `TREATED` est l'état d'une production **sans** analyse IA : sans verdict de
critère, l'afficher « Validé » ou « À renforcer » serait faux. `skill_status_badge.dart` est
le **seul** endroit qui décide de la teinte d'un statut — badge, liseré vertical de carte et
pastille de numéro en dérivent tous.

**Deux textes de compétence, deux endroits** : `skill.generalCriterion` (« le critère
général travaillé ») reste **toujours visible** dans l'encart **« Critère travaillé »** de la
carte de résumé ; `skill.description` (« une courte explication ») n'est **plus dans le corps
de la carte** — six lignes y repoussaient le critère et la liste des sujets (verdict client :
« elle prend trop de place »). Elle vit derrière la **pastille d'information** en haut à
droite de la carte (`_SkillInfoButton`, `competence_detail_screen.dart`) : dessin 30×30, zone
tactile 44×44, libellé « À quoi sert cette compétence ? » en `Semantics` **et** en `Tooltip`,
tap → `showAppSheet` (titre = nom de la compétence, corps = l'explication). **Description
vide ou absente ⇒ pas de pastille du tout** — jamais un bouton qui ouvre une feuille vide.
Verrouillé par `test/competence_detail_summary_test.dart` ; même geste côté web. Ne pas les
rendre au même endroit, et ne confondre ni l'un ni l'autre avec `SkillPromptDto.uniqueCriterion`, le
critère précis d'UN petit sujet. L'écran de sujet lit `skillDescription`,
`skillGeneralCriterion`, `skillPromptCount` et `skillTargetLevel` **portés par le sujet
lui-même** : le fil d'Ariane « Sujet i/N », le palier et l'encart n'entraînent **aucun**
appel à `GET /api/skills/{id}`. ⚠ Supprimer un appel réseau ne doit jamais coûter un
affichage : le palier est exigé sur l'écran d'un petit sujet (spec §3 niveau 5).

**Réécoute de l'oral** (spec §15 : « l'oral conserve l'audio ») : l'écran de résultat d'une
tentative EO monte `SejourAudioPlayer` (`core/widgets/audio_player.dart`, déplacé là depuis
`question_runner/` le jour où un 3ᵉ domaine en a eu besoin) sur `attempt.audioUrl` — URL R2
présignée 15 min. Le lecteur s'habille via `label`/`icon`/`accent`/`background` ; on ne le
forke pas. La durée seule ne suffit pas : se réécouter en lisant l'analyse fait la moitié de
la valeur pédagogique de l'oral. **Le même lecteur sert la réécoute d'avant validation** sur
l'écran de saisie, monté sur le fichier local — deux lecteurs pour un même geste finiraient
par diverger.

**Libellés du bandeau « Sujet déjà traité »** (identiques au web, mot pour mot) : EE →
**« Reprendre ma réponse »** (recharge la dernière production dans la zone d'écriture via
`lastAttemptId`) ; EO → **« Écouter ma dernière réponse »** (ouvre l'écran de résultat de
`lastAttemptId`). **Une seule action par section**, jamais deux. Le bandeau est
**tenu sur une ligne** (toute la carte est tappable) : en pavé — pastille, deux
lignes de méta, bouton pleine largeur — il suffisait à repousser la zone de
production sous la ligne de flottaison dès la deuxième visite d'un sujet.

**Règles UX à ne pas défaire** (spec §13) : la consigne est traduite en gestes **avant** la
production ; les références n'apparaissent **jamais** avant qu'une tentative existe (garde
serveur : 403) ; le statut se met à jour immédiatement au retour (`RouteAware.didPopNext` →
`ref.invalidate` sur la liste et le détail) ; le retour IA est **au-dessus** des
références ; l'accès au sujet suivant n'est jamais bloqué (`nextPromptId` nul ⇒ bouton
désactivé, pas de verrou) ; le bouton de validation vit dans un `FixedActionBar`.

**Jamais de note /20 ni de niveau CECRL sur un micro-exercice** (interdit par §9 de la
spec) : l'analyse rend 4 champs courts — verdict, point réussi, priorité, reformulation —
plus un verdict de critère `VALIDATED | PARTIAL | NOT_VALIDATED`. C'est une voie
**parallèle** à la notation des productions complètes (rubriques v8), pas une réutilisation.

**Freemium (refonte 2026-08-10) — le module n'est plus gratuit et illimité.** Sans
abonnement TCF, le serveur n'ouvre qu'**une compétence par tâche** (plus celle de la
priorité n°1 du Plan) et, dans une compétence ouverte, **ses 2 premiers sujets**. Un abonné
TCF n'a aucun verrou. ⚠ **Ces règles ne sont écrites nulle part dans l'app** : le serveur
les calcule et publie un booléen **`locked`** sur `SkillDto`, `SkillPromptSummary`,
`SkillPromptDto` et, côté Plan, `LearningPlanPriority` / `LearningPlanSkill` /
`PlanRecommendedExercise` (défaut `false` si le champ manque). L'app **reflète** ce
booléen — jamais un « si l'index dépasse N alors cadenas », et le 403 serveur reste
l'arbitre final.
- **Rien n'est masqué, tout est annoncé** : une compétence, un sujet, une étape du Plan ou
  une compétence observée verrouillés restent **affichés et lisibles** (titre, état,
  compteurs). Masquer priverait le candidat du résultat de sa propre production. Ce qui
  change : le cadenas (`PremiumLockTile`) prend la place de l'anneau de progression ou du
  numéro de sujet — un anneau à zéro n'a rien à raconter —, la pilule `PremiumLockTag`
  s'ajoute au statut, et le tap ouvre `showTcfLockPaywall` (le paywall existant, pré-réglé
  sur Intégral, **jamais un second parcours d'achat**). Le chevron, lui, reste.
- **Un seul jeu de libellés**, dans `core/widgets/premium_lock.dart`, **miroir mot pour mot
  du web** (`app/_components/skill-ui/SkillLayout.tsx`) : `kPremiumLockTagLabel`
  « **Premium** » et `kPremiumLockCta` « **Voir l'abonnement Intégral** » (wording neutre,
  guidelines Apple 3.1.1). Côté Plan, les deux CTA sont ceux de `LearningPlanView` :
  « **Débloquer cet exercice** » (À faire maintenant) et « **Débloquer cette étape** »
  (étape 1), plus la note « Cet exercice fait partie de l'abonnement Intégral. Votre plan,
  lui, reste entier. »
- **Les compteurs ne mentent pas** (`CompetenceDetailScreen`) : un sujet verrouillé sort du
  filtre « À faire » (il n'est pas à faire, il n'est pas ouvert), reste dans « Tous » et
  dans « Traités » s'il a déjà été produit — un abonnement échu ne réécrit pas l'historique.
  Un **4ᵉ filtre « Verrouillés · N »** apparaît quand il y en a, et c'est lui qui rend la
  somme juste (`Tous = À faire + Traités + Verrouillés`) ; il disparaît avec le dernier
  sujet verrouillé et l'écran retombe alors sur « Tous ». L'action de la `FixedActionBar`
  vise toujours un sujet **ouvert**, et devient « Voir l'abonnement Intégral » quand il n'en
  reste aucun.
- **Lien profond sur un sujet verrouillé** : `CompetencePromptScreen` rend
  `_LockedPromptView` — on garde le repère « Sujet i/N » + palier et **rien d'autre** : ni
  consigne, ni situation, ni zone de production, ni barre de validation. Le contenu du sujet
  fait partie de ce qui s'achète, et laisser produire ferait perdre la réponse sur le 403.

Les **3 analyses IA offertes à vie** ne changent pas (`GET /api/skills/analysis-quota`) :
elles restent la seule chose que le quota décompte. L'écran de sujet ne demande plus rien :
il demande l'analyse quand `canAnalyse`, s'en passe sinon (aucun 403 provoqué), et se
contente d'annoncer le reste du quota. `remaining == -1` signifie **illimité** et ne doit
jamais s'afficher tel quel. Un 403 à la soumission passe quand même par
`showPaywallOrError` — le serveur reste l'arbitre.

**Oral** : la capture réutilise `AudioRecorderService` / `recordingControllerProvider`
(panneau `SkillRecorderPanel`). Le plafond de capture est **180 s**, aligné sur la borne
serveur — la durée conseillée du sujet reste indicative et ne coupe jamais la parole. La
**transcription n'est produite que si une analyse IA est demandée** (on ne paie pas Whisper
pour rien) : une tentative EO `RECORDED` n'a donc pas de texte à relire, et l'écran de
résultat le dit au lieu d'afficher un vide.

**Polling du résultat** : 3 s, arrêt sur `statut.isFinal` ou au bout de **120 s**.
`RECORDED` et `FAILED` sont des statuts **finaux** : on saute le bloc IA et on va droit aux
références. ⚠ **Le plafond est partagé avec le web** (`CompetenceResult`) et vaut désormais
120 s des deux côtés : les deux fronts avaient suivi des contrats différents (90 s ici,
40 tirages là-bas), donc une analyse aboutissant en 100 s réussissait sur le web et échouait
sur mobile. On retient la plus généreuse — échouer une analyse qui allait aboutir est le pire
des deux défauts. Le changer d'un seul côté rouvre l'écart.

**Libellés figés par le contrat sur l'écran de résultat** (mot pour mot avec le web) :
**« Ce qui est réussi »** / **« À travailler en priorité »** pour les deux blocs de retour, et
**« Retour aux petits sujets »** pour l'action de sortie — « Retour aux sujets » se confondait
avec le mode « Sujets » TCF, qui est un tout autre écran (spec §4).

## Examen blanc TCF complet (orchestration des 4 épreuves)

Backend : cf. `CLAUDE.md` racine section « Examen blanc TCF complet ». Côté mobile, l'orchestration vit
dans `screens/tcf_full_exam/` :

### 🛑 Le temps d'un examen TCF — refonte 2026-08-15

- **Le chrono global de 90 min est SUPPRIMÉ.** Le temps d'une épreuve ne se transfère jamais à la
  suivante et la reprise **entre** épreuves est officiellement supportée (cf. § *Suspendre un
  examen* : on reprend aux épreuves **jamais commencées**, jamais celle qui est en cours) : un
  décompte global n'a plus de sens. Les 4 durées font **~95 min**, annoncé comme **indicatif**. Ne pas réintroduire
  `_fullExamTotal` ni un timer ancré sur `FullTcfExamResponse.timerStartedAt` (qui n'est plus qu'une
  trace du début, servant au statut de continuité).
- **Chaque épreuve a son chrono propre, servi par le DTO** :
  `FullTcfExamSubAttempt.timeLimitSeconds` (CO 1200, CE 2100, EE 1800, **null pour l'EO**) +
  `deadlineAt`, **l'unique source du compte à rebours**. On ne recompose jamais une échéance côté app,
  et le tick se lit sur `DateTime.now()` face à une échéance **absolue** — donc juste au retour
  d'arrière-plan, où le temps a couru.
- **CE = 35 min PARTOUT**, y compris dans l'examen complet (elle y était raccourcie à 30 min pour tenir
  dans les 90 min, qui n'existent plus). C'est exactement là que web et mobile avaient divergé.
- **`core/utils/epreuve_duration.dart` est la SEULE table de durées de l'app** (miroir de `DureeEpreuve`
  côté backend). Elle ne sert **que** aux écrans de catalogue et de briefing, qui annoncent une durée
  **avant** qu'aucune session n'existe : dès que la donnée serveur est là (`timeLimitSeconds`), c'est
  elle qui fait foi. `TcfQcmModule` et `TcfProductionModule` y lisent leur `durationLabel` via leur
  `epreuve` — aucun « 20 min » / « 35 min » recopié dans un écran.
- **L'expression orale se chronomètre PAR TÂCHE, et seulement quand la tâche est lancée** — calqué sur
  le vrai TCF : la consigne s'affiche **sans aucun décompte**, le candidat presse « Je suis prêt ·
  Commencer la tâche », et c'est **à cet instant** que part le chrono sur `dureeMaxSec`
  (180 / 210 / 210 s). Auto-stop à zéro, puis tâche suivante. **L'épreuve EO n'a plus de chrono global
  de 15 min** (`AttemptResponse.timeLimitSeconds` est désormais `null` pour une session EO — il valait
  900). L'auto-stop passe par le **flux d'état du service** d'enregistrement, jamais par un `stop()`
  posé dans `start()` : c'est ce câblage qui évite une fuite du wake lock écran. Vaut pour l'EO d'un
  examen complet **comme** pour l'épreuve EO jouée seule.
- **EE : temps conseillé par tâche, indicatif et JAMAIS bloquant** (≈ 7 / 10 / 13 min,
  `eeTempsConseilleMinutes`) — affiché sous la consigne, **à côté** du chrono réel de 30 min, qui porte
  sur les **3 tâches ensemble**. Rien ne se ferme quand ce repère est dépassé. Ces 3 valeurs sont
  éditoriales : elles ne se dérivent d'aucune donnée serveur et aucun endpoint ne les publie.
- **Quitter ne suspend rien** (sauf à l'oral, où le temps ne court que pendant une tâche lancée) : le
  chrono continue pendant l'absence, on reprend avec le temps réellement restant, et une épreuve dont
  l'échéance est passée est **clôturée automatiquement par le serveur** (`GET /api/attempts/{id}` et
  `GET /api/full-tcf-exams/{id}` le font avant de répondre). Il n'existe **aucun** flux « recommencer
  une épreuve interrompue » — n'en construis pas. Le progress screen relit l'état à l'expiration et au
  retour au premier plan ; il ne finalise **pas** l'examen entier.
- **`POST /api/attempts/{id}/answers` renvoie 422 après l'échéance + 60 s.** Le refus porte sur **une**
  réponse, pas sur la session : `RunnerState.timeExpired` le porte, `RunnerScreen` affiche le message du
  serveur puis bascule sur l'écran de fin. Le runner ne plante pas et ne perd rien.
- **Statut de simulation** : `FullTcfExamResponse.continuite` (`ContinuiteSimulation`, **nullable** —
  `null` tant que l'examen n'est pas terminé, cas normal). Libellés **gelés** et miroirs du backend :
  « Simulation complète — conditions examen » / « Simulation complétée en plusieurs sessions », portés
  par le `label` de l'enum, jamais par une chaîne d'écran. Affiché sous le hero du bilan.
  ⚠️ **Ne pas y ajouter un 3ᵉ cas** « pas de résultat global définitif » : il existe déjà, c'est
  `finalLevelPartial` / `epreuvesCountedInFinalLevel`, qui répondent à une autre question (sur combien
  d'épreuves porte le niveau).

### 🛑 Suspendre un examen — la règle de sortie (2026-08-15)

> **Une épreuve COMMENCÉE ne se reprend jamais. Une épreuve JAMAIS COMMENCÉE
> attend le candidat aussi longtemps qu'il faut.**

Arbitrage propriétaire, appliqué à l'identique sur le web. Il **révoque** « quitter =
abandonner » et **revient en partie** sur le correctif de la veille (`markSubDone` retiré du
« quitter » des épreuves EE/EO) : la règle produit a changé, c'est voulu.

- 🛑 **Aucun résultat tant que les 4 épreuves ne sont pas terminées.** Le hub
  (`TcfFullExamProgressScreen`) n'a plus d'action menant au bilan depuis sa feuille de sortie :
  le bouton du bas est **« Suspendre l'examen »**, et la feuille ne propose que **« Suspendre et
  reprendre plus tard »** / **« Continuer l'examen »**. Plus aucun `finish` du parent depuis cet
  écran.
- **Suspendre clôture l'épreuve commencée, épargne les autres**, puis **sort de l'écran**. Un
  examen suspendu **reste « en cours » indéfiniment**, sans résultat, reprenable, et **garde son
  slot** dans la grille : c'est **voulu**, ne pas le clôturer automatiquement pour libérer la
  place.
- **« Commencée » = `FullTcfExamSubAttempt.commencee`** (`timerStartedAt != null`, l'ancre posée
  par `POST /begin`) — le discriminant dont `jamaisOuverte` est la lecture « close sans avoir été
  ouverte ». **Ne pas en inventer un second.**
- **Règle et libellés déclarés une seule fois** :
  `screens/tcf_full_exam/full_exam_exit_labels.dart` (`epreuvesAClore`, `fullExamSuspendMessage`,
  `epreuveExitMessage`, `kFullExamSuspend*`, `kEpreuveExit*`), **miroir mot pour mot** de
  `web_sejoufr/lib/full-exam-exit.ts`. La feuille **nomme l'épreuve** qui va être close ;
  **sans** épreuve commencée elle dit simplement que la progression est conservée — on ne fait
  pas peur pour rien.
- **Quitter une épreuve la clôture aussi**, sur les trois écrans d'épreuve :
  `runner_screen` (CO/CE lancé avec `from=fullTcf` → `finish()` puis retour au hub),
  `ee_briefing_writing_screen` et `eo_briefing_screen` (→ `markSubDone`). Le `PopScope`/back
  système passe par le même chemin : back = quitter = clôturer.
- **Ce qui ne clôture RIEN** : la **flèche retour du hub** (elle sort de l'écran, point), la mise
  en arrière-plan, la fermeture de l'app. Et **aucune** épreuve jamais commencée n'est fermée par
  un geste de sortie.
- **La grille dit déjà « En cours · Reprendre »** (`tcf_full_exams_screen`) et ouvre le hub, pas
  le bilan — c'est le web qui s'est aligné dessus.
- **Un examen dont les 4 épreuves sont closes reste finissable** : le hub réaffiche « Voir mon
  résultat », et c'est l'écran de bilan qui appelle `finish`.
- **Backend inchangé** : `finish` refuse tant qu'un sous-attempt n'est pas terminé, `beginEpreuve`
  ne ré-ancre jamais une épreuve terminée, et un attempt fini refuse toute réponse comme toute
  soumission.

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
    côté backend (sans `niveau`), le **relisent** via `GET /api/attempts/{id}` (jamais un `Attempt`
    fabriqué : c'est lui qui porte `startedAt` recalé et `timeLimitSeconds`) et chargent ses 3 tâches
    via `getExamTasks`.
  - **`POST /begin?epreuve=…` est appelé pour les 4 épreuves**, juste avant d'ouvrir leur écran :
    tant qu'il ne l'est pas, l'épreuve **n'a pas d'échéance** (les 4 sous-attempts sont créés d'un bloc
    au lancement de l'examen, leur `startedAt` ne dit rien du moment où le candidat les ouvre). Il est
    **obligatoire pour l'EE**.
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

- ~~**Chrono d'examen blanc**~~ ✅ fait, puis **refondu le 2026-08-15** : le chrono global de 90 min a
  été **supprimé**, chaque épreuve porte le sien (`FullTcfExamSubAttempt.timeLimitSeconds` +
  `deadlineAt`) et l'oral se chronomètre par tâche. Détail complet et invariants : § « Le temps d'un
  examen TCF » de la section *Examen blanc TCF complet*. ⚠️ Ne pas se fier à la description qui vivait
  ici (`_GlobalTimer`, 90:00 figé, double chrono) : elle est **révoquée**.
- **Offline-first** : pas de SQLite/Drift pour l'instant, tout passe par le réseau. À ajouter dans
  `core/storage/` quand on aura besoin (questions civiques stables, peuvent être cachées).
- **Notifications push** (rappels d'entraînement) : à ajouter via `firebase_messaging` ou OneSignal.
- ~~**In-app purchase** (Premium)~~ ✅ fait au lot 4d (cf. section dédiée plus bas).
- **Mode sombre** : la palette est prête (l'identité visuelle marche en dark), mais `buildAppTheme()` ne fait
  que le clair pour l'instant.
- 🛑 **Tests : on n'en écrit PLUS sur ce sous-projet** (règle posée le 2026-08-09, cf. § Tests du
  `CLAUDE.md` racine). Aucun nouveau `*_test.dart` — ni test de widget, ni test de modèle, ni gel de
  libellé, ni test de layout. La vérification d'un changement mobile, c'est `flutter analyze` (zéro
  warning nouveau), et le propriétaire teste lui-même à l'écran. Les tests déjà présents dans `test/`
  restent en place et doivent rester verts : un test qui devient rouge à cause d'un changement voulu
  se **met à jour ou se supprime**, il ne bloque jamais le changement. Toute la couverture de règles
  métier vit côté backend.
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
