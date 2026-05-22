# Roadmap commune (qui n'existe pas encore)

- **Paiement Stripe** : front prêt (web `paiement/page.tsx`), endpoint
  `POST /api/billing/create-checkout-session` **à créer côté Java** (dep
  `com.stripe:stripe-java`, Price IDs en `application.yaml`).
- **Refresh JWT côté web** : l'intercepteur n'est pas encore branché dans
  `web_sejoufr/lib/api.ts` (admin et mobile l'ont déjà).
- **Middleware Next** pour protéger les routes auth via cookie `sejourfr.accessToken`.
- **Dashboard utilisateur, entraînement libre, révision, succès post-paiement** côté web.
- **Clients / abonnements / stats par user** côté admin (entités existent, pas d'endpoints
  encore).
- **EO/EE TCF côté web + admin** : mobile livré (hub d'entraînement single-task, recording
  WAV, écrans complets) ; reste à coder le miroir web (entraînement EO/EE en navigateur via
  `MediaRecorder` API) et l'écran admin de calibration humaine consommant
  `/api/admin/calibration/*`.
- **Examen blanc TCF complet — orchestration mobile** : backend livré (cf. `exams-tcf.md`,
  `POST /api/full-tcf-exams` atomique + 4 sous-attempts + CECRL plancher). Reste à brancher
  le mobile : orchestrateur Riverpod qui enchaîne les sub-attemptIds CO/CE (runner QCM
  existant en mode strict examen module) puis EE/EO (réutiliser `EeSessionController.start()`
  / `EoSessionController.start()` qui sont déjà en mode 3-tâches mais à passer le
  `subAttemptId` du parent au lieu de créer un attempt isolé). Stratégie validée :
  fire-and-forget pour les évaluations IA EE/EO — chaque submit part en async pendant que
  l'utilisateur enchaîne. Écran progression "Étape X/4" + écran bilan agrégé CECRL plancher
  reposant sur `GET /api/full-tcf-exams/{id}`.
- **Rate limiting global EO/EE** : la spec demandait 10/h et 50/jour, pas branché
  (mériterait un filter Spring dédié type Bucket4j).
- **AAC pour EO mobile** : `record_ios 1.2.0` produit un fichier vide sur iOS 26 en AAC-LC
  → workaround WAV (32 KB/s = ~6 Mo pour 3 min). Repasser à AAC dès qu'une version
  `record_ios` iOS 26-compatible sort, pour économiser ~5x sur l'upload.
- **Offline-first mobile** (SQLite/Drift dans `core/storage/`) — non commencé.
- **In-app purchase** mobile : **volontairement reporté**, on pousse l'utilisateur à payer
  sur le web.
- **Tests** : aucun sur les 4 projets. Cibles à venir : Vitest+RTL (admin/web),
  `flutter_test`+`mocktail` (mobile, prioriser les controllers Riverpod), JUnit (backend,
  prioriser l'orchestration EO/EE qui n'a que des mocks à brancher).
