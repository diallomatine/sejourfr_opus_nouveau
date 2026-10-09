# Rapport final — Corrections de l'examinateur IA

> Brief : `docs/examinateur-ia/spec-corrections-examinateur-ia.md` · Audit :
> `docs/examinateur-ia/AUDIT_examinateur_IA.md` · Décisions : `DECISIONS.md` · Recette :
> `RECETTE.md`. Branche locale `feat/examinateur-ia-v4` (depuis `develop` @ `ed65c6e3`),
> **un commit par lot, rien de poussé, rien de fusionné**. Aucune session Gemini Live
> ouverte, aucun appel payant, aucune donnée de production lue.

---

## Phase 0 — Vérification et plan

### Constats de l'audit sur le HEAD

La branche part du commit même de l'audit : les 20 constats et leurs lignes sont valides
tels quels (D-03). Le plan n'a pas eu à être adapté.

### Comportement actuel sur les langues étrangères (diagnostic seulement, rien corrigé)

Constat §6.4 de l'audit : des lignes `Candidat :` en écriture non latine (arabe,
cyrillique) ou en langue étrangère en alphabet latin (« Ja, het is goed zo. ») arrivent
dans la transcription temps réel. Ce qu'en font les deux services aujourd'hui :

| Étape | Ce qui se passe | Où |
|---|---|---|
| Texte noté | Les lignes restent **telles quelles** dans `transcriptions.texte` : le correcteur Claude les lit. | `ProductionEvaluationService.evaluateRealtimeTranscript:283-288` |
| Contrôle de validité | Mesuré sur les seuls tours `Candidat :`. **> 30 %** de lettres non latines → production `INVALIDE`. Sinon, à partir de 12 mots : moins de 10 % de mots-outils français → `INVALIDE`, moins de 18 % → `AVERTISSEMENT` (confiance plafonnée). Une ou deux lignes étrangères dans un échange français ne déclenchent **rien**. | `ProductionValidityService.evaluer:208-247`, seuils `application.yaml:799-802` |
| Filet de restitution | Retire du **rapport** les reproches « vous êtes passé à une autre langue », mais seulement si la production est mesurable (≥ 40 mots candidat) **et** massivement française (≤ 15 % de lettres non latines, ≤ 6 % de mots étrangers). Au-delà : on considère que la bascule est réelle et on ne purge rien. | `EvaluationOralArtifactFilter.mesurableEtFrancaise:589-602` |
| Note | Le filet ne touche jamais la note : le correcteur peut toujours **noter** sur un passage qu'il n'a pas compris. | même fichier, javadoc « Ce que ce filet ne touche pas » |

**Option proposée (non implémentée)** : un filtre serveur **déterministe**, appliqué au
texte envoyé à la notation seulement (le transcript stocké reste intact), qui remplace dans
les tours `Candidat :` toute séquence en écriture non latine par `[inaudible]`, derrière un
drapeau de configuration (`EVAL_TRANSCRIPT_NON_LATIN_MASK_ENABLED`, faux par défaut), avec
mesure au banc avant allumage. Il ne traite pas le latin étranger (« Ja, het is goed zo. »),
indiscernable d'un français mal transcrit sans lexique — c'est la limite assumée du filet
existant. Avantage : c'est une contrainte dure (rang 3), pas une consigne. Risque : masquer
une vraie bascule de langue en écriture non latine ; atténué en ne masquant que sous le seuil
`INVALIDE` (30 %), au-dessus duquel la production reste invalide comme aujourd'hui.

### Plan par lot

**Lot M — Mesure (F11, F19, F20)**
- Migration `V090__realtime_mesure_examinateur.sql` : colonnes `end_cause`,
  `persona_version`, `client_platform`, `conduct_config_version`, `vad_silence_ms` sur
  `realtime_sessions` ; tables `realtime_session_turns`, `realtime_session_events`,
  `realtime_fallbacks`.
- Backend : `RealtimeSessionService` (traçage à l'ouverture, au relais, à la reprise, à la
  clôture), `RealtimeMesureManager`, entités/dépôts, `AppendTranscriptRequest` (+ temps),
  `FinishRealtimeSessionRequest` (nouveau, corps optionnel), `RealtimeEoController`
  (plateforme lue sur `X-Sejourfr-Client`).
- Web : `lib/realtime/geminiLive.ts` (horodatage), `RealtimeEoRunner.tsx` (segments horodatés,
  cause de fin, clôture sur erreur), `lib/api.ts`, `lib/types.ts`.
- Mobile : `gemini_live_client.dart`, `realtime_eo_controller.dart`, `realtime_repository.dart`,
  `realtime_models.dart` (+ adaptation du faux dépôt de `test/realtime_finish_test.dart`).
- `docs/examinateur-ia/indicateurs.sql`.
- Tests : `RealtimeSessionServiceTest` (+13), `RealtimeMesureIT` (nouveau : bout en bout,
  client sans horodatage, repli comptable, exécution d'`indicateurs.sql`).

**Lot 1 — Persona v4 et configuration (F01, F05, F06, F08, F09, F10, F15, F16)**
- `prompts/realtime-personas-v4.json` (nouveau), `prompts/realtime-conduct-v1.json` (nouveau,
  JSON de conduite) et `realtime-conduct-v0.json` (comportement d'avant, pour le retour
  arrière) ; `RealtimePersonaBuilder` (mode examen, placeholder `{enteteExamen}`),
  `RealtimePersonaTemplates`, chargeur du JSON de conduite, `RealtimeProperties` +
  `application.yaml` (1 500 ms, v4, température par env, version de conduite),
  `RealtimeSessionDescriptor` (+ `conduct`), `RealtimeSessionService`.
- Web et mobile : lecture du bloc `conduct` (repli local identique au JSON v1 si absent) pour
  l'amorce, la garde d'accueil, la tenue micro, le message de fin et la clôture.
- Tests : `RealtimePersonaV4Test` (assemblage, mode, longueurs), `RealtimePersonaV4SujetsIT`
  (20 sujets T2 réels), `GeminiTokenBrokerTest` / `RealtimeSessionServiceTest` (config).
- Docs : `docs/notation-ia-eo-ee.md` (comportement de l'examinateur vocal),
  `docs/regles/notation-ia.md`.

**Lot 2 — Orchestration (F02, F03, F13)**
- Web : `lib/realtime/conduct.ts` (logique de conduite pure : échéance, grâce, relance,
  reprise), détection locale de voix dans `geminiLive.ts`, branchement dans
  `RealtimeEoRunner.tsx`.
- Mobile : `lib/core/realtime/realtime_conduct.dart` (miroir), détection de voix dans
  `gemini_live_client.dart`, branchement dans `realtime_eo_controller.dart` et l'écran.
- Backend : `RealtimeSessionDescriptor.contextRestored` à la reprise.
- Vérification : les 9 cas du §4.4 sur les deux modules purs — hors dépôt au lot 2, versionnés depuis la revue (D-02).

---

## Lot M — Mesure (F11, F19, F20) · commit `40ae67e5`

### Ce qui a été fait

| Constat | Correction | Fichiers |
|---|---|---|
| **F11** — aucun horodatage par tour | Chaque segment relayé porte `startedAtMs` / `endedAtMs` (ms depuis `setupComplete` côté client ; examinateur = lecture audio réelle, candidat = premier → dernier fragment de transcription) et est conservé dans `realtime_session_turns`, sous le même contrôle d'idempotence que le transcript. Le format texte noté ne change pas. | `V090__realtime_mesure_examinateur.sql`, `RealtimeSessionTurn`, `RealtimeMesureManager`, `AppendTranscriptRequest`, `RealtimeSessionService.appendTranscript` ; `geminiLive.ts`, `RealtimeEoRunner.tsx` ; `gemini_live_client.dart`, `realtime_eo_controller.dart`, `realtime_repository.dart` |
| **F19** — aucune cause de fin | `end_cause` (`TIME_UP` / `USER_FINISH` / `CONNECTION_LOST` / `ERROR`) via un corps facultatif sur `finish` ; une erreur fatale clôt désormais la session (`FAILED`, sans notation) au lieu de la laisser ouverte. | `FinishRealtimeSessionRequest`, `RealtimeEndCause`, `RealtimeEoController`, `RealtimeSessionService.finish` ; runner web, contrôleur mobile |
| **F20** — ni persona, ni plateforme, ni repli tracés | `persona_version`, `client_platform` (lu sur `X-Sejourfr-Client`, aucun changement client), `vad_silence_ms`, `conduct_config_version` sur `realtime_sessions` ; table `realtime_fallbacks` pour chaque repli asynchrone ; `realtime_session_events` pour les relances, la grâce de fin de temps et les reprises (avec / sans handle, tracées par le serveur). | `RealtimeSession`, `RealtimeFallback`, `RealtimeSessionEvent`, `RealtimeSessionService.start/resume` |
| Indicateurs | `docs/examinateur-ia/indicateurs.sql` : 9 requêtes, ventilées par tâche × persona × plateforme (parole en secondes et en mots, longueur des répliques, délai de reprise de parole, relances, causes de fin, durée effective, termes interdits, replis, reprises). | — |

### Écarts au brief

D-04 (table dédiée), D-05 (plateforme lue sur l'en-tête existant, valeurs `MOBILE`/`UNKNOWN` en plus), D-06 (zéro = `setupComplete`), D-07 (temps candidat = transcription, gardé après le lot 2 pour la comparabilité), D-08 (événements transmis à la clôture), D-09 (`ERROR` ⇒ `FAILED` sans notation), D-10 (table des replis), D-11 (documents versionnés).

### Tests

- `RealtimeSessionServiceTest` : +13 (traçage à l'ouverture, replis × 3 raisons, segment horodaté, client sans horodatage, rejeu sans doublon, reprises avec / sans handle, repli de reprise, cause + événements, sans corps, `ERROR`, clôture rejouée) — **vert**.
- `RealtimeMesureIT` (nouveau, Postgres embarqué + vraies migrations) : session de bout en bout avec doubles, client sans horodatage, repli comptable, **exécution de toutes les requêtes d'`indicateurs.sql`** avec contrôle de deux résultats — **vert**.
- `indicateurs.sql` exécuté sur la **base locale** dans une transaction annulée (migration V090 appliquée puis retirée) : **sans erreur**.
- Mobile : faux dépôt de `test/realtime_finish_test.dart` adapté aux nouvelles signatures (aucun test ajouté) — **vert** (13).
- `flutter analyze` propre, `npx tsc --noEmit` propre.

### Aucun changement visible pour le candidat

Oui : seuls des champs facultatifs voyagent en plus ; un ancien client est accepté tel quel (vérifié par test).

---

## Lot 1 — Persona v4 et configuration (F01, F05, F06, F08, F09, F10, F15, F16) · commit `5cce4577`

### Ce qui a été fait

| Constat | Correction | Fichiers |
|---|---|---|
| **F01** | `silenceDurationMs` 500 → **1 500** (yaml **et** POJO), trace par session | `application.yaml`, `RealtimeProperties` |
| **F05** | T2 non passive : une aide par blocage, dans le rôle, sans jamais nommer une information non demandée | `realtime-personas-v4.json` |
| **F06** | Ouvertures courtes : T1 « Bonjour. Nous commençons la première partie. Pouvez-vous vous présenter, s'il vous plaît ? » ; T2 = (en-tête en examen blanc) + réplique d'entrée + « Je vous écoute. », situation non relue | `realtime-personas-v4.json`, `RealtimePersonaBuilder` |
| **F08** | Neutralité : acquiescements neutres seuls, liste d'interdits | idem |
| **F09** | Température surchargeable (`REALTIME_GEMINI_TEMPERATURE`) ; `maxOutputTokens` reste absent (tronquerait en plein mot) | `application.yaml` |
| **F10** | Cas prévus avec leur phrase ; contradiction « n'adapte pas son niveau » levée (D-12, D-13) | `realtime-personas-v4.json` |
| **F15** | Une seule phrase de clôture (`[FIN]` ⇒ « Merci, nous allons nous arrêter ici. ») ; « Voici la deuxième partie » en examen blanc seulement (D-14, D-15) | persona, `RealtimeSessionService.examenBlanc` |
| **F16** | POJO aligné sur le yaml (v4) ; javadoc VAD-par-niveau corrigée | `RealtimeProperties`, `RealtimePersonaBuilder` |
| JSON de conduite | `realtime-conduct-v1.json` (valeurs du brief) servi dans `RealtimeSessionDescriptor.conduct`, lu par les deux fronts (repli local identique si absent) ; `realtime-conduct-v0.json` = comportement d'avant pour les personas v1-v3 ; paire contrôlée au boot (D-16) | `RealtimeConductConfig`, descripteur ; `conduct-config.ts`, `realtime_models.dart`, `geminiLive.ts`, `gemini_live_client.dart`, runner, contrôleur |

### Écarts au brief

D-12 (ligne 7 du verrou de langue), D-13 (précision sur « En français, s'il vous plaît », titre de section), D-14 (formulation de l'en-tête), D-15 (examen blanc = `isExamSession`), D-16 (champ `personas` + conduite v0), D-17 (plafond de clôture 12 → 15 s).

### Tests

- `RealtimePersonaV4Test` (7) : aucun placeholder (T1/T2, examen/entraînement, avec/sans fiche), ouverture T1 ≤ 25 mots, en-tête T2 en examen seulement, T2 non passive, règles et cas prévus présents et anciennes formules absentes, verrou de langue v3 repris au caractère près, v1-v3 inchangées — **vert**.
- `RealtimePersonaV4SujetsIT` : les **20 sujets T2 actifs** seedés, en examen et en entraînement, sans placeholder et ouverture ≤ 35 mots — **vert**.
- `RealtimeConductConfigTest` (5) : défauts livrés, valeurs v1 du brief, v0 = comportement d'avant, mélange persona/conduite refusé au boot, version inconnue refusée — **vert**.
- `RealtimeSessionServiceTest` : +3 (conduite servie et tracée, mode examen / entraînement transmis au builder) — **vert**.
- Mis à jour : `GeminiTokenBrokerTest` (1 500 ms), `RealtimePersonaBuilderTest` (persona v1 explicite).
- `flutter analyze` propre, `npx tsc --noEmit` propre.

### Sujets T2 dont l'ouverture dépasse 35 mots

**Aucun.** Ouverture en examen blanc (en-tête + réplique d'entrée + « Je vous écoute. ») de 12 à 25 mots sur les 20 sujets actifs (D-18). 5 répliques d'entrée finissaient déjà par « je vous écoute » / « je réponds à vos questions » : la redite est traitée dans la persona à la revue (cf. « Revue des décisions »).

---

## Lot 2 — Orchestration (F02, F03, F13) · commit du lot 2

### Ce qui a été fait

| Constat | Correction | Fichiers |
|---|---|---|
| **F03** — micro coupé net à 0:00 | Fin de temps douce : l'examinateur finit sa lecture (≤ 10 s, D-19), le candidat finit sa phrase (≤ `graceMaxMs` 10 s, écran « Temps écoulé — terminez votre phrase »), puis micro coupé + `[FIN]`, clôture après 1,2 s de silence de l'examinateur, au plus 15 s ; grâce tracée (`TIMEUP_GRACE`) | `lib/realtime/conduct.ts` ⇄ `core/realtime/realtime_conduct.dart` ; runner, contrôleur, écran |
| **F02** — aucune relance sur silence | Minuteur armé à la fin de lecture de l'examinateur, annulé dès que le candidat parle ; `[SILENCE]` à 7 s ; 2 relances au plus sans parole entre elles ; aucune dans les 15 dernières secondes, pendant la fin de temps ni pendant une coupure ; course gérée (D-21, D-22, D-24) ; chaque relance tracée | idem |
| Signal « le candidat parle » | Détection locale d'énergie du micro, après annulation d'écho, sur ce qui serait émis seulement (D-23) ; un seul détecteur par front | `VoiceActivityDetector`, `geminiLive.ts`, `gemini_live_client.dart` |
| **F13** — reprise sans contexte | Le serveur dit si un handle a été verrouillé (`contextRestored`, D-25) ; sinon le client envoie `[REPRISE]` + les 3 derniers tours au nouveau socket, à la place de l'amorce (D-26) ; chrono en pause pendant la coupure (inchangé) | `RealtimeSessionDescriptor`, `RealtimeSessionService.resume` ; `resumePrimer`, `reconnect(next, primer)` |

`notifyTimeUp` est supprimé des deux clients (remplacé par `muteInput` + `sendTextTurn`), ainsi que les minuteurs de clôture ad hoc du runner web et du contrôleur mobile.

### Parité web ⇄ mobile

| Comportement | Web | Mobile |
|---|---|---|
| Module de conduite pur | `lib/realtime/conduct.ts` | `core/realtime/realtime_conduct.dart` |
| Détection de voix | `VoiceActivityDetector` sur paquets Float32 (40 ms) | `VoiceActivityDetector` sur paquets PCM16 (`rmsOfPcm16`) |
| Fin de temps douce | ✅ | ✅ |
| Relance sur silence | ✅ | ✅ |
| Reprise sans contexte | ✅ (`reconnect(next, primer)`) | ✅ (`reconnect(next, primer:)`) |
| Libellés de fin | `RT_TIMEUP_GRACE_STATUS` / `RT_TIMEUP_CLOSING_STATUS` | `kRtTimeUpGraceStatus` / `kRtTimeUpClosingStatus` |
| Valeurs | `RealtimeConductConfig` servi | `RealtimeConductConfig` servi |

### Vérification

Les 9 cas du §4.4, plus 3 cas complémentaires (suspension pendant une coupure, aucune relance pendant la fin de temps, détection locale), exécutés **hors dépôt** sur les deux modules purs, horloge simulée (depuis la revue, les 9 cas sont **versionnés**, cf. « Revue des décisions ») :

| Cas | TypeScript | Dart |
|---|---|---|
| Échéance, candidat silencieux → `[FIN]` immédiat, clôture `TIME_UP` | ✅ | ✅ |
| Échéance, candidat parle, finit en 4 s → micro ouvert 4 s puis `[FIN]` (grâce 4 000 ms tracée) | ✅ | ✅ |
| Échéance, candidat parle > 10 s → coupure à 10 s puis `[FIN]` | ✅ | ✅ |
| Échéance pendant que l'examinateur parle → `[FIN]` après sa lecture | ✅ | ✅ |
| 7 s de silence → une relance `[SILENCE]` (tracée) | ✅ | ✅ |
| Silence prolongé → deux relances au maximum, puis le compteur repart après une prise de parole | ✅ | ✅ |
| Le candidat parle à 6,9 s → aucune relance | ✅ | ✅ |
| Course : énergie au seuil à l'expiration → aucune relance | ✅ | ✅ |
| Silence dans les 15 dernières secondes → aucune relance (+ témoin à 23 s) | ✅ | ✅ |
| Coupure en cours / fin de temps → aucune relance | ✅ | ✅ |
| Reconnexion sans handle → `[REPRISE]` + 3 derniers tours, sans l'ouverture | ✅ | ✅ |
| Détection : début après 200 ms, fin après 600 ms ; RMS | ✅ | ✅ |

Backend : `RealtimeSessionServiceTest` étendu (`contextRestored` vrai / faux). **Suite backend complète** (`./mvnw verify`, 5 389 tests unitaires et d'intégration) : un seul échec, dans `RealtimePersonaV4SujetsIT` (lot 1) — il lisait tous les sujets T2 actifs de la base partagée, où un autre test laisse un sujet sans fiche ; il ne mesure plus que les sujets seedés (avec fiche). Correctif dans le commit du lot 2, test repassé au vert. `flutter analyze` propre, `npx tsc --noEmit` propre, `npm run build` **réussi** (serveur de dev web arrêté pendant le build).

---

## Revue des décisions (2026-10-09)

Validées telles quelles : D-01, D-03 à D-17, D-19 à D-26. Tranchées par toi : D-02, D-07, D-18. D-27 et D-28 : pris en charge par toi. Statuts à jour dans `DECISIONS.md`.

| Décision | Ce qui change | Fichiers |
|---|---|---|
| **D-02** — exception aux tests front pour ce chantier | Les 9 cas du §4.4 sont versionnés, mêmes cas et mêmes noms des deux côtés, sur horloge simulée. Exception notée dans le `CLAUDE.md` racine (décompte des tests front recompté : 18 TS, 25 Dart) et dans ceux des deux fronts. | `web_sejoufr/lib/realtime-conduct.test.ts`, `mobile_sejourfr/test/realtime_conduct_test.dart` |
| **D-07** — A reste la référence, B s'ajoute | V091 : `started_at_ms_vad` / `ended_at_ms_vad` (nullables) sur `realtime_session_turns`. `AppendTranscriptRequest` gagne `startedAtMsVad` / `endedAtMsVad`, facultatifs, **ignorés sur un tour examinateur**. Les fronts les mesurent avec le détecteur local, ramenés à l'instant réel de la transition (le détecteur rend désormais `sinceMs` : 200 ms de confirmation au début, 600 ms d'attente à la fin) ; premier début et dernière fin du tour, fin = instant de clôture du tour si le candidat parle encore. Segments fusionnés : premier début, dernière fin. Nouvel indicateur 9 (`indicateurs.sql`) : délai fin de parole au micro → reprise de l'examinateur (médiane, p90, part < 1,5 s, nombre de reprises mesurées), à lire à côté de l'indicateur 3. | `V091__realtime_temps_candidat_vad.sql`, `RealtimeSessionTurn`, `RealtimeMesureManager`, `AppendTranscriptRequest`, `RealtimeSessionService` ; `conduct.ts`, `geminiLive.ts`, `RealtimeEoRunner.tsx`, `api.ts` ; `realtime_conduct.dart`, `gemini_live_client.dart`, `realtime_eo_controller.dart`, `realtime_repository.dart` |
| **D-18** — redite « je vous écoute » | t2 de la persona v4 : « …puis « Je vous écoute. », sauf si ta réplique d'entrée invite déjà le candidat à parler. » (v4 n'est pas livrée : modifiée en place, pas de v5). Test mis à jour, `notation-ia-eo-ee.md` aussi. | `realtime-personas-v4.json`, `RealtimePersonaV4Test`, `docs/notation-ia-eo-ee.md` |

**Vérification** : `RealtimeSessionServiceTest` 52 (+2 : temps micro conservés sur un tour candidat, ignorés sur un tour examinateur), `RealtimeMesureIT` 4 (temps micro persistés, indicateur 9 contrôlé, client sans mesure ⇒ colonnes nulles), `RealtimePersonaV4Test` 7, `RealtimePersonaV4SujetsIT` 1 — **verts**. `indicateurs.sql` sur la base locale, V090 + V091 appliquées dans une transaction annulée : **sans erreur**. Web : `realtime-conduct.test.ts` 9/9, `npx tsc --noEmit` et `eslint` propres. Mobile : `realtime_conduct_test.dart` 9/9, `realtime_finish_test.dart` vert (faux dépôt aligné), `flutter analyze` propre.

À vérifier en recette : les temps micro dépendent du seuil d'énergie (L2-13) ; si le seuil est recalibré, l'indicateur 9 se lit par `conduct_config_version`.

---

## À vérifier en conditions réelles

Tout ce qui dépend du modèle et de l'audio réel : `RECETTE.md` (parties 1 et 2), en particulier la perception de la reprise de parole à 1,5 s (L1-5), le respect des ouvertures et des phrases prévues, la non-lecture des messages entre crochets, et le **calibrage du seuil d'énergie** (0,02) sur web, Android et iOS (L2-13). Rien de cela n'a été joué (D-27).

## Variables d'environnement à poser ou vérifier sur le VPS

| Variable | Valeur cible | Remarque |
|---|---|---|
| `REALTIME_PERSONA_VERSION` | `v4` (ou absente) | 🛑 Si elle vaut `v3` en prod, le serveur **refuse de démarrer** avec la conduite v1 par défaut : la retirer, ou poser `REALTIME_CONDUCT_VERSION=v0` en même temps. |
| `REALTIME_CONDUCT_VERSION` | `v1` (ou absente) | Retour arrière : `v0` **avec** `REALTIME_PERSONA_VERSION=v3`. |
| `REALTIME_GEMINI_VAD_SILENCE_DURATION_MS` | `1500` (ou absente) | Si elle est posée à `500` en prod, elle annule F01. |
| `REALTIME_GEMINI_TEMPERATURE` | `0.7` (ou absente) | Nouvelle, facultative. |
| `REALTIME_GEMINI_MODEL` | à vérifier | Dev : `gemini-2.5-flash-native-audio-latest` ; défaut du dépôt : `gemini-live-2.5-flash-native-audio`. |
| `REALTIME_GEMINI_VAD_START/END_SENSITIVITY`, `…PREFIX_PADDING_MS`, `REALTIME_SESSION_*`, `REALTIME_CONTEXT_COMPRESSION_*`, `REALTIME_GEMINI_TOKEN_USES` | inchangées | — |

Les migrations V090 et V091 s'appliquent au démarrage (additives, aucune donnée réécrite).

## Résumé

**Décisions** : toutes revues le 2026-10-09 (cf. « Revue des décisions »). D-02, D-07 et D-18 appliquées selon ton arbitrage ; aucune décision en attente.

**À ta charge** : D-27 (recette réelle Gemini et mesures avant/après, `RECETTE.md`), D-28 (push, merge, variables de production).

**Diagnostic langue (phase 0)** : option de masquage déterministe des passages non latins dans le texte noté, non implémentée (hors périmètre), décrite en tête de ce rapport.
