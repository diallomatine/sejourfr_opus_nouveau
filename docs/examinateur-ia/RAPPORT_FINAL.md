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
- Vérification : les 9 cas du §4.4 exécutés hors dépôt sur les deux modules purs (D-02).

---
