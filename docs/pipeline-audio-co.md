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

- `old/audio-question-system-v1.md` (legacy, rangé dans `prompts/old/`, gardé pour traçabilité)
- `audio-question-system-v2.md` (actif par défaut)
- `audio-question-tool-schema.json` (schéma de l'outil Claude)

Bascule via `ANTHROPIC_PROMPT_VERSION` dans l'env.

## Import par lot des questions CO image (2026-10-04)

`CO_IMAGE` (une image affichée, l'audio lit une introduction puis les 4 propositions
« A. … B. … ») ne se crée **que par les brouillons** `audio_question_draft`. L'import par
lot écrit ces brouillons depuis un manifeste JSON + des images ; il ne crée **jamais** de
`questions` : la synthèse batch, la revue (`/audio-questions/review`) et la publication
(`validateDraft`) restent celles des brouillons. Endpoints, format et contrat de réponse :
`docs/api-endpoints.md` § « Admin — Import CO image ».

- **Code** : `controller/AdminQuestionImportController` → `service/questionimport/`
  (`CoImageImportService` orchestre, `CoImageImportValidator` valide sans rien lire ni
  écrire, `CharteImagesCo` charge la charte) → `manager/AudioQuestionDraftManager` (seul
  accès au repository des brouillons hors `audioquestion/`) ; mapping pur dans
  `mapper/CoImageImportMapper`.
- **Ce que le serveur dérive, et que le manifeste ne porte pas** : la consigne
  (« Écoutez les propositions et choisissez celle qui correspond à l'image. »), le code de
  compétence `co_image_proposition`, la voix `fr-FR-DeniseNeural`, `transcript_text` et
  `ssml_text` (utilitaire unique `util/PropositionsLuesCoImage`, au-dessus de `util/Ssml`,
  qui sert aussi les exemples-modèles EE/EO et la consigne orale du diagnostic). Pas de
  champ « texte audio » libre : le texte lu est celui des propositions, saisi une fois.
- **Choix** : `label` = `A`..`D` (seul recopié dans `choices.label` à la publication),
  `text` = la proposition (clé JSONB facultative, absente des brouillons V800+). 🛑 Le
  texte d'une proposition ne va **jamais** dans `Choice.label` : il partirait dans le JSON
  du runner. À la publication, il vit dans `medias.transcript` de l'audio, servi après
  correction.
- **Anti-doublon** : `audio_question_draft.external_id` (V088, index unique, tous statuts
  confondus). Pour réimporter un brouillon rejeté, on change d'identifiant.
- **Tout ou rien** : une erreur sur une question refuse le lot (422, rien d'écrit). L'import
  persiste les N brouillons, envoie les N images sur R2 sous
  `questions/images/drafts/<draftId>/<uuid>.<ext>`, puis flush et commit dans **une seule
  transaction** ; tout échec annule la transaction et supprime au mieux les clés déjà
  envoyées. (L'id du brouillon est tiré par Hibernate à la persistance : `@UuidGenerator`
  n'accepte pas d'id assigné, d'où des envois R2 à l'intérieur de la transaction plutôt
  qu'avant elle. Résidu possible en cas de crash : des clés orphelines sous un `draftId`
  absent de la base, repérables par préfixe.)
- **Charte des images** : `backend_sejourfr/src/main/resources/generation_questions/charte-images-co-v1.json`,
  seule autorité des contraintes techniques (PNG ou WEBP, 4:3 à 2 % près, largeur ≥ 800 px,
  fond opaque) ; elle porte aussi les règles de style (trait noir sur fond blanc, aucun
  texte ni chiffre ni logo, personnages neutres, une action lisible, jamais d'image de
  livret FEI). Changer de version = `sejourfr.question-import.co-image.charte`.
- **Images** : `service/ImageUploadSupport` est l'autorité unique. Partout (remplacement
  d'image d'une question ou d'un brouillon, import), le type est **lu sur les octets**
  (signature) et doit égaler le type déclaré. Dimensions, ratio, largeur et opacité ne sont
  opposés qu'à l'import : le remplacement unitaire de la console reste libre de son cadrage.
  **Opacité** : le critère est le **pixel**, jamais la présence d'un canal alpha — une
  PNG RGBA entièrement opaque passe ; un seul pixel d'alpha < 255 refuse
  (`IMAGE_TRANSPARENTE`). PNG : décodage complet (≤ 16 Mpx, au-delà `IMAGE_ILLISIBLE`).
  Le JDK ne lit pas le WEBP : dimensions et alpha sont lus dans les blocs RIFF, sans
  dépendance — un bloc `ALPH` brut est lu octet par octet, un `ALPH` compressé ou un
  indice alpha VP8L valent transparence (libwebp ne les écrit que si un pixel l'est), un
  drapeau alpha VP8X sans bloc `ALPH` ne compte pas. Un SVG n'est jamais un fichier
  uploadable (ni ici, ni par `/api/admin/media/upload`) : il ne vit qu'en `inline_svg`.
- **Taille** : 20 questions par lot au plus (`max-questions`), 5 Mo par image ;
  `spring.servlet.multipart.max-request-size` est à 110 Mo pour tenir un lot entier.
- **Lot d'essai** : `docs/question-audio/lot-test/` (3 questions A2, images de placeholder
  conformes à la charte).
- **Coût audio** : la synthèse batch prend 10 brouillons par clic — un lot de 20 demande
  deux clics « Générer l'audio ».

## Garde-fou des tirages (2026-10-04)

Une `CO_IMAGE` sans audio n'est **jamais** tirée, ni comptée dans un stock (lots, Plan,
composition d'examen) : le prédicat « servable au candidat » de
`QuestionRepository.SERVABLE_JPQL` / `SERVABLE_SQL` exige `is_active`, `status = ACTIVE`
et, pour une `CO_IMAGE`, `audio_media_id` non nul. La console admin la signale
(`QuestionDto.audioMissing`, filtre `media=AUDIO_MISSING`). Révision, favoris et relecture
de session n'y passent pas : une question déjà vue reste relisible.
