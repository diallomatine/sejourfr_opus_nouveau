# SejourFR Flutter — Spec d'implémentation TCF Expression orale & écrite

> **Pour Claude Code · Mobile Flutter**
>
> Ce document décrit l'implémentation complète des modules **TCF Expression orale (EO)** et **TCF Expression écrite (EE)** dans l'app Flutter existante. Ces deux nouveaux modules s'ajoutent aux modules QCM déjà en place (TCF CO, TCF CE, TCF Structure, Civique) sans les modifier.
>
> **Documents de référence** :
> - Backend : `PRODUCTION_TASKS_SPEC_V2.md` (schéma DB, endpoints, contrats DTOs)
> - Guide de génération de contenu : `PRODUCTION_TASKS_GENERATION_GUIDE.md`
> - Maquettes visuelles : `sejourfr_mobile_v3.html` (référence pixel-perfect)
>
> **Règle d'or** : ne pas modifier le code existant des modules QCM. Toutes les évolutions sont additives. Les widgets partagés existants (Header, BottomNav, ProgressBar) doivent être réutilisés et non dupliqués.

---

## 1. Contexte

### 1.1 État actuel de l'app Flutter

Stack confirmée :
- **Flutter** (version stable)
- **Riverpod 2** pour le state management
- **Dio 5** pour les appels HTTP
- **go_router 14** pour la navigation
- **SharedPreferences** pour les préférences locales
- **just_audio** pour la lecture audio
- 42 fichiers Dart déjà livrés (ExamResultScreen, HistoryScreen, ExamReportScreen, onboarding 3 slides, etc.)

### 1.2 Ce qui change

L'utilisateur arrive aujourd'hui sur un écran "Entraînement TCF" listant 3 cartes (CO, CE, Structure). On y ajoute **2 nouvelles cartes** (EO, EE), et derrière chaque carte un flow d'entraînement complet inspiré du mockup v3.

L'EO et l'EE diffèrent fondamentalement des QCM existants :
- L'utilisateur produit du contenu (audio ou texte libre)
- L'évaluation passe par un appel asynchrone backend (Whisper + Claude)
- Le résultat arrive avec 10-20 secondes de latence
- L'affichage du résultat est riche (critères, points forts, exemples corrigés, transcription)

### 1.3 Ce qui ne change pas

- Le module Civique reste intact
- Les modules TCF QCM (CO, CE, Structure) restent intacts
- Le système d'authentification, de profil et de paywall reste intact
- La charte graphique reste intacte (Bleu France `#1E3A8C`, Rouge France `#E1372F` réservé au critique, etc.)

---

## 2. Dépendances à ajouter

À ajouter dans `pubspec.yaml` :

```yaml
dependencies:
  # Existantes déjà présentes : flutter_riverpod, dio, go_router, shared_preferences, just_audio

  # Nouvelles à ajouter
  record: ^5.1.0              # Capture audio cross-platform
  permission_handler: ^11.3.0  # Demande des permissions micro
  path_provider: ^2.1.4        # Stockage temporaire des audios
  audio_waveforms: ^1.0.5      # Affichage waveform pendant rédaction (ou alternative custom)
  flutter_form_builder: ^9.4.0 # Optionnel pour textarea EE avec validation
```

**Justification** :
- `record` est la lib la plus mature pour l'enregistrement audio en 2026. Fonctionne sur iOS, Android, Web, Desktop.
- `permission_handler` pour la permission micro Android/iOS (NSMicrophoneUsageDescription, RECORD_AUDIO).
- `path_provider` pour stocker l'audio en local avant envoi backend (cache temporaire).
- `audio_waveforms` pour l'affichage visuel pendant l'enregistrement. Si tu préfères ne pas ajouter de dépendance, on peut faire un waveform CSS-like avec `AnimatedContainer` (voir section 7).

### 2.1 Configuration permissions

**iOS — `ios/Runner/Info.plist`** :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>SejourFR a besoin d'accéder au microphone pour vous permettre de vous entraîner à l'expression orale.</string>
```

**Android — `android/app/src/main/AndroidManifest.xml`** :
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 3. Arborescence des fichiers

À créer sous `lib/` (en respectant les conventions du projet existant). Les conventions exactes du projet doivent être vérifiées avant — si l'arborescence diffère, adapter en conservant la logique.

```
lib/
├── features/
│   └── tcf/
│       ├── production/                          # NOUVEAU module commun EO+EE
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── production_task.dart
│       │   │   │   ├── production_submission.dart
│       │   │   │   ├── transcription.dart
│       │   │   │   ├── ai_evaluation.dart
│       │   │   │   └── enums.dart              # EpreuveType, NiveauCecrl, SubmissionStatut
│       │   │   ├── api/
│       │   │   │   └── production_api.dart     # Client Dio
│       │   │   └── repositories/
│       │   │       └── production_repository.dart
│       │   ├── providers/
│       │   │   ├── production_task_provider.dart
│       │   │   ├── submission_provider.dart
│       │   │   ├── recording_provider.dart     # EO : état de l'enregistrement
│       │   │   ├── writing_provider.dart       # EE : état du texte + word count
│       │   │   ├── evaluation_provider.dart    # commun : polling de l'évaluation
│       │   │   └── session_progress_provider.dart  # progression 1/3 → 3/3
│       │   ├── widgets/                         # Widgets partagés EO+EE
│       │   │   ├── task_header.dart            # Header avec retour + Quitter
│       │   │   ├── progress_with_level.dart    # Barre "Tâche 1/3" + pastille niveau
│       │   │   ├── task_briefing_card.dart     # Carte Consigne
│       │   │   ├── tips_card.dart              # Carte Conseils
│       │   │   ├── criteres_card.dart          # Carte Critères d'évaluation
│       │   │   ├── level_pill.dart             # Pastille A2/B1/B2
│       │   │   ├── timer_pill.dart             # Chrono 30:00
│       │   │   ├── results_eval_banner.dart    # "Évaluation terminée !"
│       │   │   ├── score_summary_card.dart     # Score global + niveau + barre CECRL
│       │   │   ├── cecrl_scale.dart            # Barre A1→C2 avec curseur
│       │   │   ├── criterion_row.dart          # Ligne critère avec icône + barre
│       │   │   ├── feedback_block.dart         # Points forts / À améliorer / Suggestions
│       │   │   ├── correction_example.dart     # Original → Correction → Explication
│       │   │   ├── confidential_note.dart      # Note RGPD en bas
│       │   │   ├── donut_chart_score.dart      # Donut violet (EE)
│       │   │   └── task_progress_item.dart     # Ligne dans "Votre progression"
│       │   └── routes.dart                      # Routes go_router communes
│       │
│       ├── expression_orale/                    # NOUVEAU module EO
│       │   ├── screens/
│       │   │   ├── eo_briefing_screen.dart
│       │   │   ├── eo_recording_screen.dart
│       │   │   ├── eo_finished_screen.dart
│       │   │   ├── eo_results_summary_screen.dart
│       │   │   ├── eo_results_detail_screen.dart  # Onglets Analyse/Trans/Conseils
│       │   │   ├── eo_progression_screen.dart
│       │   │   └── eo_global_summary_screen.dart
│       │   ├── widgets/
│       │   │   ├── recording_timer_big.dart    # 02:18 grand format
│       │   │   ├── recording_waveform.dart     # Waveform animée pendant REC
│       │   │   ├── stop_recording_button.dart  # Bouton stop rond rouge
│       │   │   ├── audio_playback_bar.dart     # Mini-lecteur après REC
│       │   │   └── recording_status_pill.dart  # "Enregistrement..." vert
│       │   └── services/
│       │       └── audio_recorder_service.dart # Wrapper autour de `record`
│       │
│       └── expression_ecrite/                   # NOUVEAU module EE
│           ├── screens/
│           │   ├── ee_briefing_writing_screen.dart  # Briefing + zone d'écriture combinés
│           │   ├── ee_validation_screen.dart        # "Rédaction envoyée !"
│           │   ├── ee_results_screen.dart           # Résultats avec donut
│           │   ├── ee_progression_screen.dart
│           │   └── ee_global_summary_screen.dart
│           └── widgets/
│               ├── word_counter_card.dart            # Carte ambre "132 mots"
│               ├── writing_textarea.dart             # Textarea + toolbar BIU
│               └── word_count_indicator.dart         # Indicateur "Dans la plage"
│
└── shared/
    └── widgets/
        └── ...                                  # Réutiliser ce qui existe déjà
```

**Convention de nommage** : `eo_` et `ee_` en préfixe pour bien distinguer les écrans spécifiques. Les widgets partagés EO+EE vont dans `tcf/production/widgets/`.

---

## 4. Intégration dans le module TCF existant

### 4.1 Modifier l'écran d'accueil TCF

L'écran existant qui liste CO / CE / Structure doit afficher **5 cartes au lieu de 3** :

```
┌─────────────────────────────────┐
│   Entraînement TCF              │
├─────────────────────────────────┤
│  📚 Compréhension écrite        │ ← existant
│  🎧 Compréhension orale         │ ← existant
│  🔡 Structure de la langue      │ ← existant
│  🎤 Expression orale  NOUVEAU   │ ← à ajouter
│  ✍️ Expression écrite NOUVEAU   │ ← à ajouter
└─────────────────────────────────┘
```

**Localiser le fichier existant** (probablement `lib/features/tcf/tcf_home_screen.dart` ou similaire) et y ajouter 2 entrées dans la liste des modules. Chaque carte doit :

- Afficher l'icône, le nom du module, une courte description ("3 tâches • ~10 minutes")
- Naviguer vers `/tcf/expression-orale` ou `/tcf/expression-ecrite` au tap
- Afficher un badge "Nouveau" si possible pendant 2 mois après le lancement
- Respecter exactement le style des cartes existantes (même padding, même border-radius, même typo)

**Ne pas modifier** le state management ou la logique des 3 modules existants. Juste ajouter 2 cartes.

### 4.2 Si l'utilisateur n'est pas Premium

Les modules EO et EE sont **réservés Premium**. Si l'utilisateur free tape sur la carte EO ou EE :
- Soit afficher directement le paywall existant
- Soit autoriser une démo limitée (2 submissions à vie, voir spec backend section 11)

À aligner avec la stratégie freemium déjà en place dans l'app. Idéalement, réutiliser le widget `PaywallSheet` existant.

---

## 5. Modèles de données Dart

### 5.1 Enums (`lib/features/tcf/production/data/models/enums.dart`)

```dart
enum EpreuveType {
  civique,
  tcfCo,
  tcfCe,
  tcfStructure,
  tcfEo,
  tcfEe,
  tcfComplet;

  String toJson() => switch (this) {
    EpreuveType.civique => 'CIVIQUE',
    EpreuveType.tcfCo => 'TCF_CO',
    EpreuveType.tcfCe => 'TCF_CE',
    EpreuveType.tcfStructure => 'TCF_STRUCTURE',
    EpreuveType.tcfEo => 'TCF_EO',
    EpreuveType.tcfEe => 'TCF_EE',
    EpreuveType.tcfComplet => 'TCF_COMPLET',
  };

  static EpreuveType fromJson(String value) => switch (value) {
    'CIVIQUE' => EpreuveType.civique,
    'TCF_CO' => EpreuveType.tcfCo,
    'TCF_CE' => EpreuveType.tcfCe,
    'TCF_STRUCTURE' => EpreuveType.tcfStructure,
    'TCF_EO' => EpreuveType.tcfEo,
    'TCF_EE' => EpreuveType.tcfEe,
    'TCF_COMPLET' => EpreuveType.tcfComplet,
    _ => throw FormatException('Unknown EpreuveType: $value'),
  };
}

enum NiveauCecrl {
  a1NonAtteint, a1, a2, b1, b2, c1, c2;

  String get displayName => switch (this) {
    NiveauCecrl.a1NonAtteint => 'A1 non atteint',
    NiveauCecrl.a1 => 'A1',
    NiveauCecrl.a2 => 'A2',
    NiveauCecrl.b1 => 'B1',
    NiveauCecrl.b2 => 'B2',
    NiveauCecrl.c1 => 'C1',
    NiveauCecrl.c2 => 'C2',
  };

  /// Index 0-5 pour positionner le curseur sur la barre CECRL
  int get scaleIndex => switch (this) {
    NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => 0,
    NiveauCecrl.a2 => 1,
    NiveauCecrl.b1 => 2,
    NiveauCecrl.b2 => 3,
    NiveauCecrl.c1 => 4,
    NiveauCecrl.c2 => 5,
  };

  String toJson() => /* idem switch */
  static NiveauCecrl fromJson(String value) => /* idem switch */
}

enum SubmissionStatut {
  submitted, transcribing, evaluating, evaluated, failed;
  // toJson / fromJson équivalents
}
```

### 5.2 ProductionTask

```dart
class ProductionTask {
  final String id;
  final EpreuveType epreuve;
  final int tacheNumero;       // 1, 2 ou 3
  final NiveauCecrl niveauCible;
  final String consigne;
  final String? contexte;
  final int? dureeMaxSec;      // EO uniquement
  final int? motsMin;          // EE uniquement
  final int? motsMax;          // EE uniquement
  final Map<String, dynamic> criteresEvaluation;
  final bool isActive;

  /// Titre court généré côté front pour l'UI
  /// (le backend ne fournit pas ce libellé, il est calculé)
  String get displayTitle => switch ((epreuve, tacheNumero)) {
    (EpreuveType.tcfEo, 1) => 'Entretien dirigé',
    (EpreuveType.tcfEo, 2) => 'Jeu de rôle',
    (EpreuveType.tcfEo, 3) => 'Point de vue',
    (EpreuveType.tcfEe, 1) => 'Message simple',
    (EpreuveType.tcfEe, 2) => 'Récit d\'expérience',
    (EpreuveType.tcfEe, 3) => 'Point de vue argumenté',
    _ => 'Tâche ${tacheNumero}',
  };

  factory ProductionTask.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}
```

### 5.3 ProductionSubmission, Transcription, AiEvaluation

Mapping direct des DTOs backend décrits dans `PRODUCTION_TASKS_SPEC_V2.md` section 8. Reproduire les mêmes noms de champs avec conversion camelCase Dart.

`AiEvaluation.feedbackJson` est typé `Map<String, dynamic>`. On crée un sous-modèle `EvaluationFeedback` pour le parser :

```dart
class EvaluationFeedback {
  final double noteGlobale;
  final NiveauCecrl niveauCecrl;
  final List<CriterionScore> scoresCriteres;
  final List<String> pointsForts;
  final List<String> pointsAAmeliorer;
  final List<String> suggestions;
  final List<CorrectionExample> exemplesCorriges;

  factory EvaluationFeedback.fromJson(Map<String, dynamic> json) => ...
}

class CriterionScore {
  final String code;
  final double noteSurVingt;
  final String commentaire;
  // ...
}

class CorrectionExample {
  final String original;
  final String corrige;
  final String explication;
  // ...
}
```

---

## 6. State management Riverpod

### 6.1 Providers d'API

```dart
@riverpod
ProductionApi productionApi(ProductionApiRef ref) {
  final dio = ref.watch(dioProvider);  // dioProvider existant
  return ProductionApi(dio);
}

@riverpod
ProductionRepository productionRepository(ProductionRepositoryRef ref) {
  return ProductionRepository(ref.watch(productionApiProvider));
}
```

### 6.2 Catalogue de tâches

```dart
@riverpod
Future<List<ProductionTask>> productionTasks(
  ProductionTasksRef ref, {
  required EpreuveType epreuve,
  required NiveauCecrl niveau,
}) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.fetchTasks(epreuve: epreuve, niveau: niveau);
}
```

### 6.3 Session d'entraînement (3 tâches consécutives)

C'est le state central. L'utilisateur fait les 3 tâches d'affilée, on garde la trace de ce qu'il a fait.

```dart
class TcfSessionState {
  final EpreuveType epreuve;            // TCF_EO ou TCF_EE
  final List<ProductionTask> tasks;     // 3 tâches tirées
  final int currentTaskIndex;           // 0, 1 ou 2
  final List<ProductionSubmission?> submissions;  // [sub0, sub1, sub2]
  final bool isCompleted;               // toutes les tâches finies + évaluées

  ProductionTask get currentTask => tasks[currentTaskIndex];
  int get progressNumerator => currentTaskIndex + 1;
  int get progressDenominator => tasks.length;
  double get progressFraction => progressNumerator / progressDenominator;
}

@riverpod
class TcfSession extends _$TcfSession {
  @override
  TcfSessionState build(EpreuveType epreuve) {
    // Charge 3 tasks (une par niveau si "examen blanc", ou 3 du niveau choisi)
    return _initialState(epreuve);
  }

  void submitCurrentTask(ProductionSubmission submission) { ... }
  void nextTask() { ... }
  void abortSession() { ... }
}
```

### 6.4 État de l'enregistrement (EO)

```dart
class RecordingState {
  final RecordingPhase phase;
  // idle / countdown / recording / paused / finished / failed
  final Duration elapsed;
  final Duration maxDuration;
  final String? filePath;
  final double? lastAmplitude;   // pour la waveform live
}

enum RecordingPhase { idle, countdown, recording, paused, finished, failed }

@riverpod
class Recording extends _$Recording {
  late final AudioRecorderService _service;
  Timer? _ticker;
  StreamSubscription? _amplitudeSub;

  @override
  RecordingState build() {
    _service = ref.watch(audioRecorderServiceProvider);
    ref.onDispose(() => _ticker?.cancel());
    return RecordingState(phase: RecordingPhase.idle, ...);
  }

  Future<void> start({required Duration maxDuration}) async { ... }
  Future<void> stop() async { ... }
  void reset() { ... }
}
```

### 6.5 État de la rédaction (EE)

```dart
class WritingState {
  final String text;
  final int wordCount;
  final int wordsMin;
  final int wordsMax;
  final WritingStatus status;
  // empty / tooShort / inRange / tooLong / submitting / submitted
}

enum WritingStatus { empty, tooShort, inRange, tooLong, submitting, submitted }

@riverpod
class Writing extends _$Writing {
  @override
  WritingState build({required int wordsMin, required int wordsMax}) { ... }

  void updateText(String newText) {
    final count = _countWords(newText);
    state = state.copyWith(
      text: newText,
      wordCount: count,
      status: _computeStatus(count),
    );
  }

  static int _countWords(String text) =>
    text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}
```

### 6.6 Évaluation (polling ou attente synchrone)

Le backend est en synchrone court terme (voir `PRODUCTION_TASKS_SPEC_V2.md` section 2.2). La requête HTTP attend 10-20 secondes, puis renvoie la submission avec son évaluation. Mais on prévoit l'asynchrone pour plus tard.

```dart
@riverpod
class SubmissionEvaluation extends _$SubmissionEvaluation {
  @override
  Future<ProductionSubmission> build(String submissionId) async {
    final repo = ref.watch(productionRepositoryProvider);
    final initial = await repo.getSubmission(submissionId);
    if (initial.statut == SubmissionStatut.evaluated ||
        initial.statut == SubmissionStatut.failed) {
      return initial;
    }
    // Si async un jour : poll toutes les 2s jusqu'à evaluated/failed
    // (pour l'instant, le submit synchrone renvoie déjà l'état final)
    return initial;
  }

  Future<void> retry() async {
    final repo = ref.read(productionRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.retrySubmission(/* id */));
  }
}
```

### 6.7 Pendant l'évaluation : UX d'étapes simulées

Même si l'appel HTTP est synchrone (10-20s), on affiche côté front 4 étapes textuelles qui défilent automatiquement (cf. spec backend section 9). C'est un provider local qui tourne sur des timers, indépendant du backend.

```dart
@riverpod
class EvaluationProgress extends _$EvaluationProgress {
  Timer? _timer;

  @override
  int build() {  // index de l'étape courante 0..3
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  void start() {
    // Étapes : 0=envoi, 1=transcription, 2=analyse, 3=préparation bilan
    // Durées : 2s, 6s, 6s, 4s (= 18s total)
    final durations = [2, 6, 6, 4];
    int i = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      // logique d'avancement
    });
  }
}
```

---

## 7. Routes go_router

À ajouter à la config go_router existante :

```dart
GoRoute(
  path: '/tcf/expression-orale',
  builder: (context, state) =>
    EoBriefingScreen(taskIndex: 0),
  routes: [
    GoRoute(
      path: 'enregistrement',
      builder: (c, s) => EoRecordingScreen(),
    ),
    GoRoute(
      path: 'termine',
      builder: (c, s) => EoFinishedScreen(),
    ),
    GoRoute(
      path: 'resultats',
      builder: (c, s) => EoResultsSummaryScreen(
        submissionId: s.pathParameters['submissionId']!,
      ),
    ),
    GoRoute(
      path: 'resultats/detail',
      builder: (c, s) => EoResultsDetailScreen(
        submissionId: s.pathParameters['submissionId']!,
        initialTab: EoResultTab.analyse,
      ),
    ),
    GoRoute(
      path: 'progression',
      builder: (c, s) => EoProgressionScreen(),
    ),
    GoRoute(
      path: 'bilan',
      builder: (c, s) => EoGlobalSummaryScreen(),
    ),
  ],
),

GoRoute(
  path: '/tcf/expression-ecrite',
  builder: (c, s) => EeBriefingWritingScreen(taskIndex: 0),
  routes: [
    GoRoute(path: 'validation', builder: (c, s) => EeValidationScreen()),
    GoRoute(path: 'resultats', builder: (c, s) => EeResultsScreen(...)),
    GoRoute(path: 'progression', builder: (c, s) => EeProgressionScreen()),
    GoRoute(path: 'bilan', builder: (c, s) => EeGlobalSummaryScreen()),
  ],
),
```

**Logique de transition** :

EO :
```
briefing (T1) → recording → finished → results (summary) → progression
            ↑                                                   ↓
            └────────────────── (T2 puis T3) ──────────────────┘
                          fin T3 → bilan global
```

EE :
```
briefing+writing (T1) → validation → results → progression
                  ↑                                ↓
                  └───────── (T2 puis T3) ────────┘
                        fin T3 → bilan global
```

---

## 8. Écrans EO — Spécifications détaillées

Pour chaque écran, je donne : le nom du fichier, les providers utilisés, les widgets composés, les transitions.

### 8.1 EoBriefingScreen (`eo_briefing_screen.dart`)

**Référence visuelle** : écran 01 du mockup v3.

**Providers** :
- `tcfSessionProvider(EpreuveType.tcfEo)` pour récupérer la tâche courante
- `currentTaskProvider` (computed à partir de la session)

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Expression orale', showQuit: true),
  body: Column([
    ProgressWithLevel(
      current: session.progressNumerator,
      total: session.progressDenominator,
      level: task.niveauCible,
    ),
    Expanded(child: SingleChildScrollView(child: Column([
      TaskBriefingCard(
        title: task.displayTitle,
        durationLabel: 'Durée attendue : 2 à 3 minutes',
        body: task.consigne,
      ),
      TipsCard(tips: _extractTipsFromCriteres(task)),
    ]))),
    BottomActionBar(
      primaryAction: PrimaryButton(
        label: 'Commencer',
        icon: Icons.mic,
        onPressed: () => context.push('/tcf/expression-orale/enregistrement'),
      ),
    ),
  ]),
)
```

**Demande de permission micro** : vérifier au tap de "Commencer". Si refusée, afficher un dialog explicatif et un bouton vers les paramètres système.

### 8.2 EoRecordingScreen (`eo_recording_screen.dart`)

**Référence visuelle** : écran 02 du mockup v3.

**Providers** :
- `recordingProvider` pour l'état d'enregistrement
- `tcfSessionProvider(EpreuveType.tcfEo)` pour la tâche

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Expression orale', showQuit: true),
  body: Column([
    ProgressWithLevel(...),
    Expanded(child: Column([
      Text('Enregistrement en cours', style: ...),
      RecordingTimerBig(
        elapsed: recording.elapsed,
        maxDuration: recording.maxDuration,
      ),
      RecordingWaveform(amplitude: recording.lastAmplitude),
      RecordingStatusPill(text: 'Enregistrement...'),
      ConseilCallout(text: 'Prenez votre temps, respirez et parlez naturellement.'),
      StopRecordingButton(
        onPressed: () async {
          final filePath = await ref.read(recordingProvider.notifier).stop();
          // navigate to finished
        },
      ),
      Text('Terminer'),
    ])),
  ]),
)
```

**Auto-stop** : quand `recording.elapsed >= recording.maxDuration`, déclencher automatiquement le stop et passer à l'écran suivant.

**Empêcher le pop** : utiliser `WillPopScope` ou `PopScope` pour confirmer avant de quitter (sinon perte d'enregistrement). Bouton "Quitter" → dialog "Voulez-vous arrêter l'enregistrement ? Votre progression sera perdue."

### 8.3 EoFinishedScreen (`eo_finished_screen.dart`)

**Référence visuelle** : écran 03 du mockup v3.

**Providers** :
- `recordingProvider` pour le chemin du fichier audio
- `productionRepositoryProvider` pour soumettre

**Comportement** :
- Affichage immédiat avec l'icône ✓, la durée, et le lecteur audio
- L'utilisateur peut écouter sa production
- Bouton "Voir mon évaluation" → lance la submission backend → navigue vers l'écran d'évaluation en cours qui devient l'écran de résultats

**Soumission** :
```dart
Future<void> _submit() async {
  final task = ref.read(currentTaskProvider);
  final filePath = ref.read(recordingProvider).filePath;
  final session = ref.read(tcfSessionProvider(EpreuveType.tcfEo));

  // Naviguer vers un écran "Évaluation en cours"
  context.push('/tcf/expression-orale/evaluation-en-cours');

  // Lancer la soumission en parallèle
  try {
    final submission = await ref.read(productionRepositoryProvider).submitAudio(
      taskId: task.id,
      attemptId: session.parentAttemptId,
      audioFile: File(filePath),
    );
    ref.read(tcfSessionProvider(EpreuveType.tcfEo).notifier)
       .submitCurrentTask(submission);
    context.pushReplacement('/tcf/expression-orale/resultats/${submission.id}');
  } catch (e) {
    // afficher écran d'erreur avec bouton retry
  }
}
```

### 8.4 EoResultsSummaryScreen (`eo_results_summary_screen.dart`)

**Référence visuelle** : écran 04 du mockup v3.

**Providers** :
- `submissionEvaluationProvider(submissionId)` pour récupérer la submission + son évaluation

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Résultats', trailing: ShareButton()),
  body: ListView([
    ResultsEvalBanner(
      title: 'Évaluation terminée',
      subtitle: 'Tâche 1 sur 3 · Entretien dirigé · 2 min 27 s',
    ),
    ScoreSummaryCard(
      note: evaluation.noteSurVingt,
      niveauEstime: evaluation.niveauCecrl,
      cecrlScale: CecrlScale(activeLevel: evaluation.niveauCecrl),
    ),
    SectionTitle('Scores par critère'),
    ...evaluation.feedback.scoresCriteres.map((c) =>
      CriterionRow(
        icon: _iconForCriterion(c.code),
        name: c.label,
        score: c.noteSurVingt,
      ),
    ),
  ]),
  bottomNavigationBar: BottomActionBar(
    primary: PrimaryButton(
      label: 'Voir le détail de mon évaluation',
      onPressed: () => context.push(
        '/tcf/expression-orale/resultats/detail',
      ),
    ),
  ),
)
```

### 8.5 EoResultsDetailScreen (`eo_results_detail_screen.dart`)

**Référence visuelle** : écrans 05, 06, 07 du mockup v3 (3 onglets).

**Particularité** : écran à 3 onglets (TabBar Flutter standard ou implémentation custom). Onglets : **Analyse / Transcription / Conseils**.

**Composition** :
```dart
DefaultTabController(
  length: 3,
  initialIndex: widget.initialTab.index,
  child: Scaffold(
    appBar: TaskHeader(
      title: 'Détail de l\'évaluation',
      bottom: TabBar(
        tabs: [
          Tab(text: 'Analyse'),
          Tab(text: 'Transcription'),
          Tab(text: 'Conseils'),
        ],
        labelColor: ColorsTokens.bleuFrance,
        unselectedLabelColor: ColorsTokens.encreMute,
        indicatorColor: ColorsTokens.bleuFrance,
      ),
    ),
    body: TabBarView(
      children: [
        _AnalyseTab(submission: submission, evaluation: evaluation),
        _TranscriptionTab(submission: submission),
        _ConseilsTab(evaluation: evaluation),
      ],
    ),
  ),
)
```

**Tab 1 - Analyse** :
- Analyse globale (texte libre depuis `feedback.commentaireGlobal` si fourni)
- Liste des critères avec leur note + commentaire détaillé
- Footer fixe : "Note globale 14,5/20 · Niveau estimé B1"

**Tab 2 - Transcription** :
- `TranscriptionInfoBanner` ("Transcription générée par IA, des erreurs peuvent subsister")
- Carte texte avec la transcription complète
- `AudioPlaybackBar` (just_audio) en bas pour réécouter en lisant

**Tab 3 - Conseils** :
- `FeedbackBlock(type: positive)` avec `evaluation.feedback.pointsForts`
- `FeedbackBlock(type: improve)` avec `evaluation.feedback.pointsAAmeliorer`
- `FeedbackBlock(type: violet)` avec `evaluation.feedback.suggestions` ("Suggestions pour progresser")

**Bouton bas** : "Passer à la tâche 2" (ou "Voir mon bilan global" si T3).

### 8.6 EoProgressionScreen (`eo_progression_screen.dart`)

**Référence visuelle** : écran 08 du mockup v3.

Affiche entre les tâches : "Vous avez fait 1/3, passons à la tâche 2."

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Expression orale'),
  body: Column([
    Text('Votre progression'),
    ProgressionSummary(completed: 1, total: 3),
    ...session.tasks.asMap().entries.map((entry) {
      final i = entry.key;
      final task = entry.value;
      final sub = session.submissions[i];
      return TaskProgressItem(
        number: i + 1,
        name: task.displayTitle,
        level: task.niveauCible,
        score: sub?.evaluation?.noteSurVingt,
        levelObtenu: sub?.evaluation?.niveauCecrl,
        status: sub != null ? TaskStatus.done : TaskStatus.todo,
      );
    }),
  ]),
  bottomNavigationBar: BottomActionBar(
    primary: PrimaryButton(label: 'Continuer l\'entraînement', ...),
    secondary: GhostButton(label: 'Revoir mes résultats', ...),
  ),
)
```

### 8.7 EoGlobalSummaryScreen (`eo_global_summary_screen.dart`)

**Référence visuelle** : écran 09 du mockup v3.

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Résultats — Expression orale', trailing: CalendarButton()),
  body: ListView([
    BilanHero(
      score: 15.2,
      niveauGlobal: NiveauCecrl.b1,
      cecrlScale: CecrlScale(activeLevel: NiveauCecrl.b1),
    ),
    SectionTitle('Détail par tâche'),
    TacheBilanRow(name: 'Tâche 1 — Entretien dirigé', niveauTask: NiveauCecrl.a2, score: 14.5, levelObtenu: NiveauCecrl.b1),
    TacheBilanRow(name: 'Tâche 2 — Jeu de rôle', niveauTask: NiveauCecrl.b1, score: 15.8, levelObtenu: NiveauCecrl.b1),
    TacheBilanRow(name: 'Tâche 3 — Point de vue', niveauTask: NiveauCecrl.b2, score: 15.3, levelObtenu: NiveauCecrl.b1),
    FeedbackBlock(
      type: FeedbackType.violet,
      title: 'Vos prochaines étapes',
      icon: Icons.info_outline,
      body: 'Continuez à vous entraîner régulièrement pour atteindre le niveau B2 requis pour vos démarches.',
    ),
  ]),
  bottomNavigationBar: AppBottomNav(active: BottomNavTab.exercices),
)
```

---

## 9. Écrans EE — Spécifications détaillées

### 9.1 EeBriefingWritingScreen (`ee_briefing_writing_screen.dart`)

**Référence visuelle** : écran EE·01 du mockup v3.

Particularité importante : **le briefing et la zone d'écriture sont sur le même écran**, en scroll vertical. Contrairement à l'EO où on a 2 écrans (briefing puis enregistrement), l'EE combine tout dans une seule longue page scrollable.

**Providers** :
- `tcfSessionProvider(EpreuveType.tcfEe)` pour la tâche courante
- `writingProvider(wordsMin: task.motsMin, wordsMax: task.motsMax)`

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Expression écrite', infoIcon: true),
  body: Column([
    ProgressWithLevel(
      current: session.progressNumerator,
      total: session.progressDenominator,
      level: task.niveauCible,
      trailing: TimerPill(time: countdown.formatted),  // 30:00 décompte
    ),
    Expanded(child: SingleChildScrollView(child: Column([
      TaskBriefingCard(
        title: 'Consigne',
        body: task.consigne,
      ),
      TipsCard(title: 'Conseils pour réussir', tips: [...]),
      WordCounterCard(
        currentWords: writing.wordCount,
        minWords: task.motsMin!,
        maxWords: task.motsMax!,
        status: writing.status,
      ),
      WritingTextarea(
        controller: _textController,
        onChanged: (text) => ref.read(writingProvider(...).notifier).updateText(text),
      ),
      WordCountIndicator(  // "Dans la plage recommandée"
        status: writing.status,
        currentWords: writing.wordCount,
      ),
      CriteresCard(criteres: [
        'Pertinence et développement du contenu',
        'Organisation et cohérence du texte',
        'Richesse et précision du vocabulaire',
        'Correction grammaticale',
        'Orthographe et ponctuation',
      ]),
    ]))),
    BottomActionBar(
      primary: PrimaryButton(
        label: 'Valider ma rédaction',
        onPressed: writing.status == WritingStatus.inRange ? _submit : null,
      ),
      secondary: SecondaryButton(
        label: 'Enregistrer le brouillon',
        onPressed: _saveDraft,
      ),
      confidentialNote: ConfidentialNote(
        text: 'Votre rédaction est confidentielle et sera analysée par notre IA pour vous fournir un feedback détaillé.',
      ),
    ),
  ]),
)
```

**Compteur de mots** : recalculé à chaque `onChanged` du textarea. Utiliser un `debouncer` (200ms) pour éviter de stresser le state à chaque caractère.

**Brouillon local** : sauvegarder en SharedPreferences toutes les 5 secondes (`key: 'ee_draft_${task.id}'`). Si l'utilisateur revient sur la tâche, restaurer le brouillon.

**Chrono 30:00** : décompte total des 30 minutes de l'épreuve EE complète, pas par tâche. Géré par un provider `eeTimerProvider`. À la fin du chrono, soumettre automatiquement ce qui a été écrit (ou marquer comme expiré).

### 9.2 EeValidationScreen (`ee_validation_screen.dart`)

**Référence visuelle** : équivalent EE de l'écran "Enregistrement terminé". À reproduire fidèlement mais pour l'écrit.

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Expression écrite'),
  body: Column([
    ProgressWithLevel(...),
    Expanded(child: Center(child: Column([
      FinishedIcon(),  // ✓ vert grand
      Text('Rédaction envoyée !', style: ...),
      Text('Votre rédaction a bien été enregistrée.', style: ...),
      NextInfoCard(
        title: 'Et maintenant ?',
        body: 'Votre rédaction va être analysée par notre IA. Vous recevrez une évaluation détaillée dans quelques secondes.',
      ),
    ]))),
    BottomActionBar(
      primary: PrimaryButton(
        label: 'Voir mon évaluation',
        onPressed: () => context.push('/tcf/expression-ecrite/resultats/${submissionId}'),
      ),
    ),
  ]),
)
```

### 9.3 EeResultsScreen (`ee_results_screen.dart`)

**Référence visuelle** : écran EE·02 du mockup v3 (long scroll).

**Composition** :
```dart
Scaffold(
  appBar: TaskHeader(title: 'Résultats'),
  body: ListView([
    ResultsEvalBanner(title: 'Évaluation terminée !', subtitle: 'Voici votre correction détaillée.'),

    ScoreSummaryCard(
      title: 'Score global',
      child: DonutChartScore(
        note: 15,
        percent: 75,
        niveau: NiveauCecrl.b1,
      ),
    ),

    ScoreSummaryCard(
      title: 'Détail par critères',
      child: Column(children: [...criterion rows]),
    ),

    FeedbackBlock(type: positive, title: 'Points forts', items: [...]),
    FeedbackBlock(type: improve, title: 'Points à améliorer', items: [...]),

    ScoreSummaryCard(
      title: 'Exemples et corrections',
      titleIcon: Icons.lightbulb_outline,
      child: Column(children: [
        ...evaluation.feedback.exemplesCorriges.map((ex) =>
          CorrectionExample(
            original: ex.original,
            corrige: ex.corrige,
            explication: ex.explication,
          ),
        ),
      ]),
    ),

    FeedbackBlock(type: violet, title: 'Suggestion globale', body: '...'),
  ]),

  // Footer fixe avec lien vers la rédaction
  persistentFooterButtons: null,
  bottomSheet: Column([
    ResultFooterLink(
      icon: Icons.visibility,
      label: 'Votre rédaction',
      subLabel: 'Relire ma rédaction',
      onTap: () => _showRedactionSheet(),
    ),
    BottomActionBar(
      primary: PrimaryButton(label: 'Passer à la tâche 3'),
      secondary: GhostButton(label: 'Voir les tâches'),
    ),
  ]),
)
```

### 9.4 EeProgressionScreen et EeGlobalSummaryScreen

Identiques en structure aux écrans EO équivalents (sections 8.6 et 8.7), mais pour l'écrit.

---

## 10. Widgets partagés EO + EE

Détails d'implémentation des widgets critiques.

### 10.1 LevelPill

```dart
class LevelPill extends StatelessWidget {
  final NiveauCecrl level;
  final bool small;

  Color get _bgColor => switch (level) {
    NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 || NiveauCecrl.a2
      => ColorsTokens.succesLight,
    NiveauCecrl.b1 => ColorsTokens.bleuFranceLight,
    NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2
      => ColorsTokens.violetLight,
  };
  Color get _textColor => /* idem */ ;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          color: _textColor,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

### 10.2 CecrlScale

Barre horizontale multicolore avec un curseur qui pointe le niveau atteint.

```dart
class CecrlScale extends StatelessWidget {
  final NiveauCecrl activeLevel;
  final bool dark;  // pour le hero bleu

  @override
  Widget build(BuildContext context) {
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return Column([
      // Labels
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: levels.asMap().entries.map((e) {
          final isActive = e.key == activeLevel.scaleIndex;
          return Text(e.value, style: TextStyle(
            color: isActive
              ? (dark ? Colors.white : ColorsTokens.bleuFrance)
              : (dark ? Colors.white60 : ColorsTokens.encreMute),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ));
        }).toList(),
      ),
      SizedBox(height: 6),
      // Track avec gradient
      LayoutBuilder(builder: (context, constraints) {
        final cursorLeft = (activeLevel.scaleIndex / 5) * constraints.maxWidth;
        return Stack([
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF87171), Color(0xFFFB923C), Color(0xFFFBBF24),
                         Color(0xFF34D399), Color(0xFF60A5FA), Color(0xFFA78BFA)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Positioned(
            left: cursorLeft - 7,
            top: -4,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: dark ? ColorsTokens.bleuFrance : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? Colors.white : ColorsTokens.bleuFrance,
                  width: 3,
                ),
              ),
            ),
          ),
        ]);
      }),
    ]);
  }
}
```

### 10.3 RecordingWaveform

Choix simple : utiliser `audio_waveforms` pour la version live. Si on évite la dépendance, on génère 30 `AnimatedContainer` avec des hauteurs aléatoires basées sur l'amplitude réelle ou simulée.

```dart
class RecordingWaveform extends StatelessWidget {
  final double? amplitude;  // 0..1
  static const int bars = 31;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(bars, (i) {
          // Hauteur basée sur l'amplitude réelle + variation par index
          final base = 10.0;
          final dynamicHeight = (amplitude ?? 0.5) * 40;
          final variation = sin((i + DateTime.now().millisecond / 200) * 0.5).abs() * 10;
          final height = base + dynamicHeight + variation;
          return AnimatedContainer(
            duration: Duration(milliseconds: 100),
            margin: EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: ColorsTokens.bleuFrance,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
```

### 10.4 DonutChartScore (EE)

Cercle avec arc coloré pour le pourcentage + texte central.

```dart
class DonutChartScore extends StatelessWidget {
  final double percent;  // 0..100
  final String label;    // "Bon niveau"

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, height: 100,
      child: Stack(children: [
        // Cercle de fond
        CustomPaint(
          size: Size(100, 100),
          painter: _DonutPainter(
            percent: percent,
            background: ColorsTokens.bleuFranceLight,
            foreground: ColorsTokens.violet,
          ),
        ),
        Center(child: Column([
          Text('${percent.toInt()}%', style: TextStyle(
            color: ColorsTokens.violet,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )),
          Text(label, style: TextStyle(
            color: ColorsTokens.encreSoft,
            fontSize: 10,
          )),
        ])),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  // Dessin avec drawArc, stroke 10, strokeCap.round
}
```

### 10.5 Autres widgets

Pour les autres (TaskBriefingCard, TipsCard, CriteresCard, FeedbackBlock, CorrectionExample, etc.), reproduire fidèlement le HTML/CSS du mockup v3 en widgets Flutter. Pas de subtilité particulière, ce sont des layouts statiques.

**Recommandation** : avant de coder, ouvrir `sejourfr_mobile_v3.html` dans un navigateur côte à côte avec l'IDE. Le pixel-perfect compte ici.

---

## 11. Service d'enregistrement audio

```dart
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<double>? _amplitudeController;
  Timer? _amplitudeTimer;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/eo_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,  // suffisant pour Whisper
      ),
      path: filePath,
    );

    _startAmplitudeStream();
    return filePath;
  }

  Stream<double> get amplitudeStream {
    _amplitudeController ??= StreamController<double>.broadcast();
    return _amplitudeController!.stream;
  }

  void _startAmplitudeStream() {
    _amplitudeTimer = Timer.periodic(Duration(milliseconds: 100), (_) async {
      final amplitude = await _recorder.getAmplitude();
      _amplitudeController?.add(amplitude.current);
    });
  }

  Future<String?> stop() async {
    _amplitudeTimer?.cancel();
    return await _recorder.stop();
  }

  Future<void> dispose() async {
    _amplitudeTimer?.cancel();
    await _amplitudeController?.close();
    await _recorder.dispose();
  }
}
```

**Encodage** : AAC-LC à 16 kHz / 64 kbps = ~480 Ko/minute. Pour 3 min = ~1,5 Mo. Acceptable pour un upload mobile. Whisper accepte ce format sans souci.

---

## 12. Mapping écran ↔ endpoint backend

| Écran | Endpoint backend | Méthode | Notes |
|---|---|---|---|
| EoBriefingScreen (chargement) | `GET /api/production-tasks?epreuve=TCF_EO&niveau=B1` | GET | Charge le catalogue |
| EoFinishedScreen → submit | `POST /api/production-submissions` (multipart) | POST | Envoie audio + metadata |
| EoResultsSummaryScreen | `GET /api/production-submissions/{id}` | GET | Récupère submission + eval |
| Retry depuis écran erreur | `POST /api/production-submissions/{id}/retry` | POST | Relance le pipeline |
| EeBriefingWritingScreen → submit | `POST /api/production-submissions` (JSON) | POST | Envoie texte + metadata |
| EeResultsScreen | `GET /api/production-submissions/{id}` | GET | Idem EO |
| EoGlobalSummaryScreen | `GET /api/users/me/production-submissions?epreuve=TCF_EO&attemptId={parent}` | GET | Tous les sub-attempts |

### 12.1 Format multipart pour EO

```dart
Future<ProductionSubmission> submitAudio({
  required String taskId,
  required String attemptId,
  required File audioFile,
}) async {
  final formData = FormData.fromMap({
    'audio': await MultipartFile.fromFile(
      audioFile.path,
      filename: 'recording.m4a',
      contentType: MediaType('audio', 'mp4'),
    ),
    'metadata': jsonEncode({
      'productionTaskId': taskId,
      'attemptId': attemptId,
    }),
  });

  final response = await _dio.post(
    '/api/production-submissions',
    data: formData,
    options: Options(
      sendTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 90),  // > backend timeout
    ),
  );

  return ProductionSubmission.fromJson(response.data);
}
```

### 12.2 Format JSON pour EE

```dart
Future<ProductionSubmission> submitText({
  required String taskId,
  required String attemptId,
  required String text,
}) async {
  final response = await _dio.post(
    '/api/production-submissions',
    data: {
      'productionTaskId': taskId,
      'attemptId': attemptId,
      'texte': text,
    },
    options: Options(
      contentType: 'application/json',
      receiveTimeout: Duration(seconds: 90),
    ),
  );
  return ProductionSubmission.fromJson(response.data);
}
```

### 12.3 Gestion des erreurs HTTP

| Code | Comportement Flutter |
|---|---|
| 200 / 201 | Succès, parser la réponse, passer à l'écran suivant |
| 400 | Erreur de validation, afficher le message du backend |
| 401 | Token expiré, rediriger vers login (logique existante) |
| 403 | Pas Premium ou quota atteint, afficher le paywall |
| 422 | Submission invalide (audio trop court, texte trop court, etc.), message dédié |
| 429 | Rate limit, message "Trop de tentatives, réessayez dans X minutes" |
| 5xx | Erreur serveur, écran d'erreur avec bouton retry |
| Timeout | Idem 5xx, le bouton retry appelle `/retry` |

---

## 13. UX de latence pendant l'évaluation

Quand l'utilisateur soumet, le backend met 10 à 20 secondes à répondre. Pendant ce temps, on affiche un **écran d'évaluation animé** avec 4 étapes textuelles qui défilent.

**Écran intermédiaire** (pas dans le mockup v3, à créer) : `EvaluationLoadingScreen`.

```dart
class EvaluationLoadingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepIndex = ref.watch(evaluationProgressProvider);
    final steps = [
      'Envoi de votre production',
      'Transcription',  // skip pour EE
      'Analyse pédagogique',
      'Préparation de votre bilan',
    ];

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CocardeRotating(size: 110),  // cocarde tricolore animée
            SizedBox(height: 32),
            Text('Analyse en cours', style: TextStyles.fraunces22Bold),
            SizedBox(height: 6),
            Text('Encore quelques secondes…', style: TextStyles.body13Soft),
            SizedBox(height: 32),
            ...steps.asMap().entries.map((e) => EvalStep(
              text: e.value,
              status: e.key < stepIndex ? EvalStepStatus.done
                : e.key == stepIndex ? EvalStepStatus.active
                : EvalStepStatus.pending,
            )),
          ],
        ),
      ),
    );
  }
}
```

**Bouclage du timer** : si l'appel backend dépasse 20s, l'écran reste sur "Préparation de votre bilan" jusqu'à la réponse. Si dépasse 60s, afficher l'écran d'erreur avec retry.

---

## 14. Brouillon local (EE uniquement)

Pour ne pas perdre la rédaction en cas de fermeture de l'app ou de crash.

```dart
class WritingDraftService {
  static const _prefix = 'ee_draft_';

  Future<void> save(String taskId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$taskId', text);
    await prefs.setString('${_prefix}${taskId}_savedAt',
                          DateTime.now().toIso8601String());
  }

  Future<String?> load(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$taskId');
  }

  Future<void> clear(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$taskId');
    await prefs.remove('${_prefix}${taskId}_savedAt');
  }
}
```

**Déclenchement** : auto-save toutes les 5 secondes pendant que l'utilisateur tape, et au moment du `dispose` du textarea.

**Restauration** : au mount de `EeBriefingWritingScreen`, vérifier si un brouillon existe pour `task.id` et le pré-remplir.

**Nettoyage** : après une soumission réussie, supprimer le brouillon.

---

## 15. Tests à écrire

### 15.1 Tests unitaires (`test/`)

- `enums_test.dart` : `EpreuveType.fromJson()`, `NiveauCecrl.scaleIndex`
- `production_task_test.dart` : `displayTitle` pour chaque combinaison épreuve × tâche
- `writing_provider_test.dart` : transitions d'état (empty → tooShort → inRange → tooLong)
- `recording_provider_test.dart` : start/stop/elapsed avec un AudioRecorderService mocké
- `evaluation_progress_test.dart` : avancement des étapes sur les timers

### 15.2 Tests de widgets (`test/widget/`)

- `level_pill_test.dart` : couleurs selon le niveau
- `cecrl_scale_test.dart` : position du curseur selon `activeLevel`
- `criterion_row_test.dart` : couleur de la barre selon le score (high/mid/low)
- `donut_chart_test.dart` : rendu pour 0%, 50%, 100%

### 15.3 Tests d'intégration (`integration_test/`)

- Flow EO complet de bout en bout (briefing → enregistrement simulé → soumission mockée → résultat)
- Flow EE complet (briefing → écriture → validation → résultat)
- Cas d'erreur : timeout → retry → succès
- Restauration de brouillon EE après réouverture de l'app

### 15.4 Mocks

Utiliser `mocktail` (déjà dans le projet probablement) pour mocker `ProductionRepository` dans les tests.

---

## 16. Charte graphique — Rappel des tokens

À centraliser dans `lib/shared/theme/colors_tokens.dart` (probablement déjà fait pour les modules existants).

```dart
class ColorsTokens {
  static const bleuFrance = Color(0xFF1E3A8C);
  static const bleuFranceDark = Color(0xFF15296B);
  static const bleuFranceLight = Color(0xFFE8ECF8);
  static const bleuSoft = Color(0xFFF1F4FB);

  static const rougeFrance = Color(0xFFE1372F);
  static const rougeFranceLight = Color(0xFFFDECEB);

  static const encre = Color(0xFF0F1839);
  static const encreSoft = Color(0xFF4A5479);
  static const encreMute = Color(0xFF7D87A8);

  static const succes = Color(0xFF168F5B);
  static const succesLight = Color(0xFFE5F4ED);

  static const ambre = Color(0xFFE8A317);
  static const ambreLight = Color(0xFFFDF3DC);

  static const violet = Color(0xFF7C3AED);     // NOUVEAU pour EE
  static const violetLight = Color(0xFFF3EEFE); // NOUVEAU

  static const background = Color(0xFFF8F9FC);
  static const border = Color(0xFFE1E4F0);
  static const borderSoft = Color(0xFFEEF1F8);
}
```

**Règle d'utilisation du rouge** : `rougeFrance` n'apparaît que dans des moments critiques (REC actif, bouton stop, erreur). Jamais en décoration.

---

## 17. Polices

Charger via `pubspec.yaml` :
- **Plus Jakarta Sans** (corps) — déjà présent probablement
- **JetBrains Mono** (labels techniques) — déjà présent
- **Fraunces** (moments éditoriaux : titres résultats, hero) — déjà présent

Si pas déjà fait, les ajouter avec leurs weights : Jakarta 400/500/600/700/800, Fraunces 500/700, JetBrains Mono 500.

```dart
class TextStyles {
  static const fraunces22Bold = TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const fraunces28Bold = TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  static const body14 = TextStyle(fontSize: 14, height: 1.55);
  static const body13Soft = TextStyle(
    fontSize: 13,
    color: ColorsTokens.encreSoft,
    height: 1.45,
  );
  // ...
}
```

---

## 18. Ordre de livraison suggéré pour Claude Code

1. **Modèles + enums + DTOs** (1h)
2. **Repository + API client + erreurs** (2h)
3. **Providers Riverpod** principaux (2h)
4. **Widgets partagés** (LevelPill, CecrlScale, CriterionRow, FeedbackBlock, etc.) (4h)
5. **Service audio + waveform** (3h)
6. **Écrans EO** dans l'ordre du flow (briefing → recording → finished → results summary → results detail → progression → global summary) (6h)
7. **Écrans EE** dans l'ordre du flow (briefing+writing → validation → results → progression → global summary) (5h)
8. **Intégration dans le hub TCF** (ajout des 2 cartes) (30min)
9. **Routes go_router** (30min)
10. **Tests unitaires** des providers et widgets clés (3h)
11. **Tests d'intégration** des 2 flows complets (2h)

**Total estimé** : 29 heures de dev, à étaler sur 2 sprints d'une semaine.

---

## 19. Points d'attention

### 19.1 Performance

- Le textarea EE peut contenir 200 mots et plus. Utiliser un `TextField` standard avec `maxLines: null` et `keyboardType: TextInputType.multiline`. Ne pas mettre de validation lourde sur chaque caractère, juste un debounce.
- La waveform pendant l'enregistrement tourne à 10 fps (100ms). Ça suffit largement. Ne pas monter à 60 fps inutilement.
- Le donut chart est dessiné avec `CustomPainter`, donc très peu coûteux. Pas de souci de perf.

### 19.2 Accessibilité

- Tous les boutons ont un `tooltip` ou un `semantics label`.
- Les couleurs respectent un contraste minimum WCAG AA. Particulièrement pour le ambre sur fond clair (utiliser `#B5780E` pour le texte sur fond ambre).
- La taille de police suit le `MediaQuery.textScaleFactor` du système.
- L'enregistrement audio doit annoncer son état aux lecteurs d'écran (`semanticLabel: 'Enregistrement en cours, 2 minutes 18 secondes'`).

### 19.3 Hors-périmètre de ce lot

- ❌ Examen blanc TCF complet (4 épreuves enchaînées) — sera fait dans un lot suivant
- ❌ Comparaison de progressions historiques (graphique de l'évolution dans le temps)
- ❌ Partage des résultats sur les réseaux sociaux
- ❌ Téléchargement PDF du bilan
- ❌ Annotation par un professeur humain

### 19.4 Erreurs courantes à éviter

- Ne pas appeler `submit` deux fois si l'utilisateur double-tape. Désactiver le bouton pendant l'appel et utiliser un header `X-Idempotency-Key`.
- Ne pas perdre le fichier audio en cas de crash. L'écrire d'abord dans le cache, puis envoyer.
- Ne pas effacer le brouillon EE avant confirmation de réception backend (statut `SUBMITTED` au minimum).
- Bien libérer les ressources audio (`recorder.dispose()`, `player.dispose()`) à la fermeture des écrans.
- Vérifier le `mounted` avant chaque `setState` ou navigation après un `await`.

---

## 20. Glossaire

- **EO** : Expression Orale (TCF IRN)
- **EE** : Expression Écrite (TCF IRN)
- **CECRL** : Cadre Européen Commun de Référence pour les Langues
- **Tâche 1/2/3** : les 3 exercices au sein d'une épreuve d'expression
- **Submission** : une production envoyée par l'utilisateur (audio ou texte)
- **Evaluation** : le résultat de l'analyse IA (note + niveau + feedback)
- **Briefing** : écran qui affiche la consigne avant le début de l'exercice
- **Hero** : grande carte en haut de l'écran de résultat avec la note principale

---

**Fin du spec.**
À donner à Claude Code avec, en pièces jointes :
- `PRODUCTION_TASKS_SPEC_V2.md` (le quoi côté backend)
- `sejourfr_mobile_v3.html` (le rendu visuel cible)
- Le présent fichier (le comment côté Flutter)
