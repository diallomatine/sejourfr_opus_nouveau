# L'audio d'une production de candidat n'est pas conservé

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 3177-3237 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## L'audio d'une production de candidat n'est pas conservé (2026-08-16)

Décision du propriétaire, **motif consentement** : « on ne stocke pas les
enregistrements audio des gens ; l'audio sert **uniquement** à produire la
transcription, et après la transcription on ne le stocke pas ». Ce qui reste
d'une production orale, c'est **son texte**.

- **Aucune production de candidat n'est écrite sur R2.** `ProductionAudioStorageService`
  (préfixe `submissions/`) et `SkillTranscriptionService` sont **supprimés** — pas
  désactivés : il n'existe plus de code capable d'écrire ou de relire un audio de
  candidat. Les trois voies concernées étaient les **productions EE/EO**
  (`production_submissions.media_url`), les **micro-exercices de compétence EO**
  (`user_skill_attempts.audio_object_key`) et l'**oral du diagnostic** (qui passe
  par la même route de production). La session vocale **temps réel** n'a jamais
  rien persisté (flux client ⇄ Gemini, production = transcript).
- 🛑 **Ne touche PAS aux audios ÉDITORIAUX** : consignes du diagnostic, exemples
  EO, audios de compréhension orale, médias de questions. Ils passent par
  `CloudflareR2Client` / `MediaStorageService` et sont du **contenu**, pas de la
  donnée personnelle.
- 🛑 **Rien n'est supprimé rétroactivement** : les objets déjà sur R2 restent, les
  clés déjà en base restent. `media_url` et `audio_object_key` deviennent des
  colonnes **LEGACY, plus jamais écrites**. **Ne jamais écrire de migration de
  purge, de job de suppression ni de `delete` rétroactif.**
- **La transcription est SYNCHRONE**, dans la requête de soumission — seul moment
  où les octets existent. Ordre volontaire : **transcrire PUIS insérer**. Un échec
  Whisper ne laisse alors **aucune ligne**, **aucun quota consommé**, et le
  candidat renvoie depuis son appareil (les 4 fronts gardent le fichier local
  après un envoi raté). L'ordre inverse fabriquerait des productions `FAILED`
  définitivement irrécupérables. Coût mesuré sur la base : audio médian 90 s,
  p90 175 s ⇒ quelques secondes d'attente ajoutées à l'envoi, contre ~0 avant.
- **`AudioEphemere.avecOctets` est le seul endroit qui tient la promesse** : le
  tampon est remis à zéro dans un `finally`, donc **aussi quand la transcription
  échoue**. À utiliser dès qu'on manipule les octets d'une production.
- **`spring.servlet.multipart.file-size-threshold: 26MB`** : au défaut (`0B`)
  Spring écrivait **tout** upload multipart dans un fichier temporaire — l'audio
  touchait le disque à chaque soumission. Ne pas rabaisser.
- **Les runners ne transcrivent plus.** `ProductionPipelineAsyncRunner` et
  `SkillAnalysisAsyncRunner` partent toujours d'une production **écrite** ; une
  production orale sans transcription est un état impossible (sauf ligne
  antérieure) et échoue clairement au lieu de noter du vide.
- **Retries** : le retry d'une **évaluation** repart de la transcription (il ne
  relisait déjà que le texte). Le retry d'une **transcription** n'existe plus —
  un échec est une **réponse HTTP 503** (`GlobalExceptionHandler.handleTranscription`)
  qui dit au candidat de **renvoyer**, pas d'attendre. Le retry **agrégé du
  diagnostic** et `POST /api/skill-attempts/{id}/analyse` sont inchangés, mais
  `analyse` refuse **avant** de consommer le quota une tentative orale LEGACY
  sans transcription.
- **Aucun DTO ne porte plus d'URL audio** : `ProductionSubmissionDto.mediaUrl` et
  `SkillAttemptDto.audioUrl` sont **retirés** du backend et des **trois miroirs**
  (`admin/src/types/api.ts`, `web/lib/types.ts`, `mobile/core/models/*.dart`).
  `mediaDurationSec` / `audioDurationSec` restent : la durée n'est pas l'audio.
- **Écrans** : aucun ne propose plus de réécouter une production **soumise** (web
  `CompetenceResult`, mobile `competence_result_screen`, admin
  `calibration/ProductionView` — les seuls qui le faisaient). ✅ **La réécoute
  LOCALE, avant validation, reste** : le fichier est encore sur l'appareil, rien
  n'est stocké, et elle protège le candidat d'envoyer une prise ratée.
- Contraintes desserrées par **V033** : `chk_prod_sub_audio_or_text` (une
  soumission orale n'a plus ni média ni texte, sa production vit dans
  `transcriptions`, comme le temps réel depuis V017) et
  `chk_user_skill_attempts_has_production` (qui accepte désormais `transcript`).
