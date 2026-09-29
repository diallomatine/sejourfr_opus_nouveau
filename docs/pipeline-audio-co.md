# Pipeline de génération audio TCF (Compréhension Orale)

Le backend a un pipeline **Claude (Anthropic) → Azure Speech → Cloudflare R2 → Postgres**
dans `backend_sejourfr/src/main/java/com/sejourfr/app/audioquestion/`. Côté admin React,
c'est dans `admin_sejourfr/src/features/audioQuestions/`. Endpoints sous
`/api/admin/audio-questions/*`.

> Le sous-dossier `docs/audio-pipeline/` contient la spec exhaustive (00-OVERVIEW.md à
> 08-OBSERVABILITY-SECURITY.md).

## Deux modes d'audio

Colonne `questions.audio_mode`, enum `AudioMode` :

- `WRITTEN_QUESTION` : document sonore lu, question et 4 choix écrits à l'écran (défaut).
- `FULL_AUDIO` : document + question + 4 choix tous lus dans l'audio ; labels en base =
  `"Réponse A/B/C/D"`.

## Amorce standardisée

Toute question audio commence par **« Écoutez le document sonore, puis répondez à la
question. »** (vérifiée strictement côté serveur, sinon rejet 422). Pour les questions non
audio (CE/STRUCTURE), `audio_mode` reste `NULL`.

## Prompts

Dans `backend_sejourfr/src/main/resources/prompts/` :

- `audio-question-system-v1.md` (legacy, gardé pour traçabilité)
- `audio-question-system-v2.md` (actif par défaut)
- `audio-question-tool-schema.json` (schéma de l'outil Claude)

Bascule via `ANTHROPIC_PROMPT_VERSION` dans l'env.
