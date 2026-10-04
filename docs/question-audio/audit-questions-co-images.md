# Audit — questions TCF CO avec image (import par lot)

> Audit du 2026-10-04, lecture seule (code + migrations + SELECT sur la base locale `sejourfr_db`).
> Brief : `docs/question-audio/audit-questions-co-images-spec.md`. Aucune implémentation.

Abréviations de chemins :
- `J/` = `backend_sejourfr/src/main/java/com/sejourfr/app/`
- `AQ/` = `J/audioquestion/`
- `M/` = `backend_sejourfr/src/main/resources/db/migration/`
- `R/` = `backend_sejourfr/src/main/resources/`
- `ADM/` = `admin_sejourfr/src/`
- `WEB/` = `web_sejoufr/`
- `MOB/` = `mobile_sejourfr/lib/`

---

## 1. Résumé exécutif

🔑 **Le format `IMAGE_PROPOSITIONS` existe déjà : c'est `QuestionType.CO_IMAGE`** (`J/enums/QuestionType.java:7`).
- Il est branché de bout en bout : backend, web, mobile, admin.
- Base locale : 70 questions `CO_IMAGE` A2, toutes actives, toutes avec audio, toutes en SVG inline, aucune en R2.
- Leur seule voie de création est le **pipeline des brouillons audio** (`audio_question_draft`), alimenté par des migrations SQL écrites à la main (`M/300_tcf/co_comprehension_orale/audio_drafts/a2/V802…V814`).

Le besoin se résume donc à **un importeur qui écrit des brouillons**. Ni nouveau modèle, ni nouveau player, ni nouveau pipeline.

| # | Question | Réponse courte |
|---|---|---|
| 1 | Une CO peut-elle déjà porter une image R2 ? Migration nécessaire ? | **Oui, sans migration.** `medias.url` de type IMAGE (`J/entity/Media.java:22-43`). Upload R2 déjà en place pour une question (`J/controller/AdminQuestionController.java:77-82` → `J/service/QuestionImageService.java:36-63`) et pour un brouillon (`AQ/controller/AudioDraftAdminController.java:67`). Une seule migration est utile, pour l'**anti-doublon** : `external_id` (§4.5). |
| 2 | Choix mélangés ? Textes visibles ? | **Jamais mélangés en `CO_IMAGE`** : `QuestionMapper.choicesAreReadAloud` renvoie vrai (`J/mapper/QuestionMapper.java:311`), donc `ordreAffiche` ne mélange pas (`:209-224`). Aucun front ne mélange (`WEB/app/_components/QuestionRunner.tsx:706-711`, `MOB/screens/question_runner/runner_screen.dart:320-322`). **Textes** : les libellés stockés valent `A/B/C/D`, donc rien n'est affiché. ⚠️ Divergence : le web masque pour tout `CO_IMAGE` (`QuestionRunner.tsx:715`) ; le mobile ne masque que si tous les libellés sont une lettre seule (`MOB/core/models/question_models.dart:89,146-149`). |
| 3 | Inactive / sans audio exclue partout ? | **Inactive : oui** dans tous les tirages TCF (`J/repository/QuestionRepository.java:45-377`, filtre `is_active`). **Non** en révision et favoris (`J/service/MeService.java:137-143,169-189`, `findById`/`findAllById`), ce qui est acceptable (déjà vue). ⚠️ `status` n'est **pas** filtré dans les tirages TCF (seulement en civique, `:410-511`). **Sans audio : rien ne l'exclut**, aucune requête ne teste `audio_media_id` ni `media_id`. Aujourd'hui sans effet (0 cas), car seul `validateDraft` crée des `CO_IMAGE`, et il exige l'audio. |
| 4 | Filtre « avec image » | **Ni A ni B tels quels.** A existe déjà : filtre « Type » = `CO_IMAGE` (« CO image », `ADM/features/questions/QuestionsPage.tsx:255-266`). L'esprit de B existe aussi : filtre « Média : Audio / Image / Vidéo / Sans » côté serveur (`:278-290`, `J/.../QuestionSpecifications.java:37-54`). **Recommandation :** étendre ce filtre « Média » avec « Image fichier » (`url` non nulle) et « Image SVG » (`inline_svg` non nul). Sans cela, on ne repère pas les CO encore en SVG à remplacer. |
| 5 | Le pipeline audio sait-il lire les 4 propositions ? | **Le moteur oui, la dérivation non.** Le batch des brouillons synthétise `ssml_text` tel quel (`AQ/service/AudioDraftService.java:173-174`), et les SSML V802+ lisent déjà « A. … B. … » (`V802:39`). Mais le texte des propositions n'existe **que** dans ce SSML écrit à la main (choix stockés `A/B/C/D`). **Adaptation minimale :** stocker le texte dans le JSONB `choices` du brouillon (clé `text`, pas de migration), puis construire `transcript_text` et `ssml_text` côté serveur à l'import, par un utilitaire unique. Le batch existant reste inchangé. |
| 6 | R2 réutilisable ? Chemin ? | **Oui, tel quel** (`AQ/service/CloudflareR2Client.java:89-121`, `J/service/ImageUploadSupport.java`). Chemin : **`questions/images/drafts/<draftId>/<uuid>.<ext>`**, convention existante du brouillon (`AudioDraftService.java:312`). |
| 7 | Où placer l'importeur ? Tout ou rien ? | Dans **`J/service/questionimport/`** (sur le modèle de `service/adminuser/`), endpoint admin dédié, écriture des brouillons via un manager. **Tout ou rien** : une seule transaction DB, R2 compensé en cas d'échec (§4.4). |
| 8 | Briques IA réutilisables (phase 3) | Patron `AQ/service/AnthropicClient.java:151-235` : tool forcé, schéma versionné, Bean Validation. Plus `PromptLoader`, `CoutAppelLlm` et `GenerationRateLimiter`. **Absents :** appel multimodal (image en entrée) et générateur d'images. Tout est à écrire. |

---

## 2. Existant

### 2.1 Modèle

| Donnée | Question publiée | Brouillon (`audio_question_draft`, `M/00_schema/V009`) |
|---|---|---|
| Format | `questions.question_type` = `CO_IMAGE`, varchar sans CHECK (`M/00_schema/V004:20`) | Implicite : `inline_svg`/`image_url` non nul ⇒ publié en `CO_IMAGE` (`AudioDraftService.java:239`) |
| Niveau | `questions.difficulty` A2/B1/B2 (`J/entity/Question.java:70`) | `difficulty`, CHECK A2/B1/B2 (`V009:11,33`) |
| Choix et ordre | table `choices(label, is_correct, display_order)`, `@OrderBy displayOrder` (`V004:50-57`, `Question.java:121-122`) ; **pas d'unicité** `(question_id, display_order)` | JSONB `[{label, is_correct, display_order}]` (`V009:18,41`, `AQ/entity/AudioQuestionDraft.java:123-127`) |
| Bonne réponse | booléen par choix ; correction par UUID de choix (`J/service/AttemptInteractionService.java:208-224`) | `is_correct` dans le JSONB |
| Texte source audio | `medias.transcript` du média audio (`Media.java:45-46`) ; servi **après correction** seulement (`QuestionMapper.java:263-284`) | `transcript_text` + `ssml_text`, NOT NULL (`V009:14-15`) |
| Audio | `questions.audio_media_id` → `medias(url, storage_key = audio/<uuid>.mp3)` (`V004:18,44-45`) | `audio_url` (`V009:24`) |
| Image | `questions.media_id` → `medias(type IMAGE, url \| inline_svg, alt_text)` ; l'URL prime | `inline_svg`, `image_url`, `image_alt_text` (`V009:20-22`) |
| Actif | `is_active` **et** `status` DRAFT/ACTIVE/ARCHIVED (`V004:23,30`) | `status` TEXT_VALIDATED → AUDIO_GENERATING → AUDIO_PENDING_REVIEW → PUBLISHED / REJECTED (`V009:34`) |
| Identifiant externe | **aucun**, UUID seul ; aucune contrainte UNIQUE (`V004:12-32`) | **aucun** |

- **Discriminant de format :** il existe déjà (`CO_IMAGE`). **Aucune évolution n'est nécessaire.**
- `audio_mode` reste NULL pour `CO_IMAGE`, sans conséquence : le type suffit (`QuestionMapper.java:311`).

### 2.2 Images et SVG

- **Origine des SVG :** écrits à la main dans les migrations de brouillons, colonne `inline_svg` (V802 : 10 SVG ; V803–V814 : 5 chacune ; B1/B2 : aucun).
- **Publication :** recopiés dans `medias.inline_svg` par `validateDraft` (`AudioDraftService.java:255-263`). Il n'existe ni générateur, ni fichier, ni asset front.
- **Exposition API :** `QuestionPublicResponse.media.inlineSvg` et `audioMedia` (`J/dto/QuestionPublicResponse.java:28-32`, `J/dto/MediaResponse.java:14-21`).
- **PNG/JPG/WEBP sur R2 :** supportés **sans migration ni code front**.
  - Les deux fronts préfèrent l'URL au SVG : `WEB/app/_components/MediaView.tsx:35-36,69` (balise `<img>`, pas `next/image`) et `MOB/screens/question_runner/widgets/question_media_view.dart:45-50,133-148` (`Image.network`).
  - Un upload R2 vide `inline_svg` (`QuestionImageService.java:55`, `AudioDraftService.java:317`).
- `alt_text` est stocké mais **non servi** au candidat (`MediaResponse` ne l'a pas). Le web met `alt="Document"` en dur (`MediaView.tsx:69`).

### 2.3 Player

| Sujet | Web | Mobile |
|---|---|---|
| Rendu `CO_IMAGE` | image, puis audio, consigne, lecture auto (`QuestionRunner.tsx:539,683-701`) | idem (`runner_screen.dart:282-318`) |
| Texte des choix masqué | toujours en `CO_IMAGE` (`:715,742`) | seulement si les libellés sont des lettres seules (`question_models.dart:146-149`, `choice_tile.dart:129-130`) |
| Rapport / révision | lettres, texte masqué si libellé = lettre (`WEB/app/_components/ExamReport.tsx:527`) | libellé brut (`MOB/core/widgets/question_detail_sheet.dart:143-149`) |
| Mélange local | aucun | aucun |
| Cache image | navigateur | **mémoire seule**, sans `cached_network_image` (`mobile_sejourfr/pubspec.yaml:31`) : re-téléchargement à chaque lancement |
| Hors ligne | — | aucun (audio en streaming : `MOB/core/widgets/audio_player.dart:126-137`) |
| SVG inline contre URL | SVG dans le JSON (~1 Ko), sans requête supplémentaire | URL : un aller-retour réseau en plus et un état « Image indisponible » (`question_media_view.dart:144-147`) |
| Thème sombre | **inexistant** (aucun `prefers-color-scheme`) | **inexistant** (`MOB/app.dart:29`, pas de `darkTheme`) |
| Fond de l'image | SVG : carte `#fff` en dur (`MediaView.tsx:91-98`) ; `<img>` : fond de page clair | cadre blanc ; ⚠️ **zoom plein écran sur fond noir** (`question_media_view.dart:329`) |

**Conséquence pour le gris et le noir & blanc :** l'affichage est lisible partout, **sauf un PNG transparent à traits noirs dans le zoom mobile**, où il devient invisible. La charte impose donc un **fond blanc opaque**.

### 2.4 Activation (côté candidat)

| Parcours | Requête | Inactive exclue | Sans audio exclue |
|---|---|---|---|
| Entraînement (abonné / gratuit / lots / invité) | `findRandom`, `findOrdered(Excluding)` (`QuestionRepository.java:45-191`) | Oui | Non |
| Séries de compétence et étapes du Plan | `findLeastRecentlySeen(InBand)` (`:221-282`) | Oui | Non |
| Examen blanc module CO, `TCF_COMPLET`, gabarit, démo invité | `AttemptCompositionService.composeModuleExam:87-109`, `findDemoPool:119-128` | Oui | Non |
| Diagnostic TCF 4 épreuves (backend conservé) | `composeModuleExam` | Oui | Non |
| Révision, favoris, relecture de session | `findById` / `findAllById` / `attempt_questions` | **Non** (voulu : déjà vue) | Non |

- **Aucun tirage TCF ne filtre `status`.**
- ⚠️ **Faille existante :** la génération unitaire crée `active=false, status=DRAFT` (`AQ/service/AudioQuestionPersistenceService.java:94-95`). Or `PATCH /api/admin/questions/{id}/status` ne bascule que `active` (`J/service/QuestionService.java:92-100`). Résultat : une question peut être tirée alors que son `status` vaut encore `DRAFT`.

### 2.5 Admin

- **`/questions/tcf`** : `ADM/features/questions/QuestionsPage.tsx`.
  - Filtres serveur : Thématique, Niveau, Type (`CO`, `CO_IMAGE`, `CE`, `STRUCTURE`), Statut, Média (l.228-301).
  - Recherche sur l'énoncé, avec debounce de 350 ms (l.86, `QuestionSpecifications.java:56-61`).
  - Pagination serveur, `size=20`, tri `createdAt` décroissant (l.51,100-118 ; `AdminQuestionController.java:54`).
  - Activation via `PATCH …/status` (l.121-130).
- **Statut audio :** ni affiché ni filtrable. `audioMediaUrl` est servi mais lu par aucun composant.
- **Formulaire :** `QuestionFormModal.tsx`, générique, 2 à 6 choix.
  - Il ne sait pas éditer `audioMedia` (`QuestionWriteRequest`, `J/dto/QuestionWriteRequest.java:13-40`).
  - Son upload (`MediaPicker` → `POST /api/admin/media/upload`) écrit sur **disque local**, pas sur R2 (`J/service/MediaService.java:33-47`, `LocalFileStorageService`).
  - `POST /api/admin/questions/{id}/image` (R2) n'a **aucun appelant** dans l'admin.
- **Revue des brouillons :** `/audio-questions/review`, `ADM/features/audioQuestions/AudioDraftReviewPage.tsx`.
  - Bouton « batch » (l.51-52), aperçu image ou SVG (l.345-367), remplacement d'image (l.290), puis validation ou rejet.
  - **C'est déjà l'écran de « relecture → activation » demandé.**
- Aucun import de questions n'existe : « insérés manuellement en base par script SQL externe (pas d'API d'import) » (`AudioDraftService.java:48`).

### 2.6 R2

| Élément | Existant |
|---|---|
| Config | `sejourfr.r2.*` (`R/application.yaml:311-317`), `AQ/config/CloudflareR2Properties.java:5-25` ; bucket par défaut `sejourfr-audio`, `.env` = `sejourfr` |
| Client | `S3Client` path-style, région `auto` (`AQ/config/CloudflareR2Config.java:23-42`) ; `S3Presigner` déclaré mais **inutilisé** (:49-67) |
| Service | `CloudflareR2Client` : `uploadAudio`, `uploadImage(key, bytes, contentType)`, `deleteObject` au mieux, `audioExists` (l.42-190) ; `@Retryable` ×3 |
| Bucket / URL | **un seul bucket public**, URL `publicUrlBase/key`, `Cache-Control: immutable` (l.31,111) ; aucune URL signée |
| Préfixes | `audio/<uuid>.mp3`, `questions/images/<questionId>/<uuid>.<ext>`, `questions/images/drafts/<draftId>/<uuid>.<ext>` |
| Suppression | ancienne clé supprimée au remplacement (`QuestionImageService.java:61-63`), **dans** la transaction ⇒ orphelins ou clés mortes possibles en cas de rollback |
| Permissions | `/api/admin/**` = ADMIN (`J/config/SecurityConfig.java:101`) ; jeton R2 en lecture/écriture |
| Validation MIME | liste blanche jpeg/png/webp, mais **sur le Content-Type déclaré** et non sur les octets (`J/service/ImageUploadSupport.java:19-23`) |
| Poids | 5 Mo (`ImageUploadSupport.java:17`) ; multipart global 25 Mo (`R/application.yaml:35-44`) ⚠️ trop juste pour 10 images d'un coup |
| Dimensions / ratio | **aucune** validation |
| Resize / WEBP | **aucun**, aucune bibliothèque d'image dans le `pom.xml` |

**Chemin recommandé :** `questions/images/drafts/<draftId>/<uuid>.<ext>`. C'est la convention existante, et l'image suit le brouillon jusqu'à la publication (`validateDraft` reprend `image_url`).

### 2.7 Audio (Azure TTS)

- **Pipeline réel = batch des brouillons.**
  - `POST /api/admin/audio-drafts/batch-generate?difficulty=` (`AudioDraftAdminController.java:43`).
  - Synchrone, prend les **10** brouillons `TEXT_VALIDATED` les plus anciens, une transaction par brouillon, retour à `TEXT_VALIDATED` en cas d'échec (`AudioDraftService.java:145-207`).
- **Voie unitaire générée par Claude** (`AQ/service/AudioQuestionGenerationService.java:74-241`) : **inadaptée**. Elle refuse le mode « propositions lues » (l.211-219) et impose l'amorce « Écoutez le document sonore… » (l.232).
- **Synthèse :** toujours en SSML (`AQ/service/AzureSpeechClient.java:53-73`), format `audio-24khz-48kbitrate-mono-mp3` (`R/application.yaml:305-310`).
  - 14 voix fr-FR en liste blanche (`AzureVoices.java:8-28`).
  - `SsmlValidator.cleanForAzure` retire les `<break/>` hors `<voice>` (l.158-176).
- **Gabarit `CO_IMAGE` observé (`V802:39`) :** voix Denise, débit 0.95, intro, `<break 1500ms>`, puis `A.<break 300ms/>texte<break 700ms/>B.…`.
- **Critère « sans audio » :** brouillon `TEXT_VALIDATED` avec `audio_url` NULL. Sur `questions`, il n'existe aucun statut audio.
- **Stockage :** `audio/<uuid>.mp3` sur R2, puis à la validation un `Media` AUDIO est relié par `audio_media_id` (`AudioDraftService.java:214-298`).
- **Constructeurs « texte → SSML » côté serveur déjà écrits deux fois :**
  - `J/service/ProductionExampleAudioService.java:181-188` ;
  - `J/service/diagnostic/DiagnosticInstructionAudioService.java:104-110`.

  Un troisième usage oblige à **extraire** un utilitaire commun (règle de duplication).

### 2.8 IA

| Brique | Existant | Réutilisable phase 3 |
|---|---|---|
| Client Claude, tool forcé + schéma | `AQ/service/AnthropicClient.java:151-235`, `R/prompts/audio-question-tool-schema.json` | **Patron** à reprendre, avec un nouveau schéma versionné |
| Prompts versionnés | `PromptLoader.java:24-40`, `R/prompts/*-vN.*` | Oui |
| Guides de rédaction CO | `R/generation_questions/GUIDE_CO_comprehension_orale.md:30-140` (hors ligne, jamais chargé par le code) | Base du prompt |
| Coût | `util/CoutAppelLlm` + `config/TarifsLlm` (autorité) ; `CostCalculator.java:24-28` (copie en dur, à ne pas réutiliser) | `CoutAppelLlm` |
| Suivi des coûts | `v_ai_usage` (`M/…V048:46-138`), 4 sources, **sans la génération CO** | Ajout versionné à la vue |
| Rate-limit admin | `GenerationRateLimiter` (10/min) | Oui |
| Appel multimodal (image en entrée) | **aucun** | À écrire |
| Génération d'image | **aucune** | À écrire |

---

## 3. Écarts avec le format `IMAGE_PROPOSITIONS`

| # | Écart | Gravité |
|---|---|---|
| E1 | Le texte des propositions n'existe que dans un SSML écrit à la main ; il n'est pas **dérivé** des choix | Bloquant pour l'import |
| E2 | Aucun import : les brouillons ne s'insèrent que par migration SQL | Bloquant |
| E3 | Aucun identifiant externe : un ré-import crée des doublons | Bloquant |
| E4 | Mobile : masquage des textes conditionné aux libellés `A–D`, pas au type (≠ web) | Latent, tant que les libellés restent `A–D` |
| E5 | Zoom mobile sur fond noir : un PNG transparent devient invisible | Charte : fond opaque |
| E6 | Tirages TCF sans filtre `status` ni présence d'audio | Latent (garde-fou absent) |
| E7 | Pas de cache disque des images sur mobile | Confort / data |
| E8 | Pas de validation par les octets, ni des dimensions | Qualité |
| E9 | `alt_text` non servi au candidat | Accessibilité |
| E10 | Filtre admin incapable de distinguer une image fichier d'un SVG | Confort de suivi |

---

## 4. Import

### 4.1 Architecture

**Décision structurante :** l'importeur **écrit des brouillons** (`audio_question_draft`, statut `TEXT_VALIDATED`), **pas des questions**.

Ce choix réutilise sans rien changer :
- la synthèse batch ;
- l'écran de revue (écoute, image, rejet) ;
- `validateDraft`, qui crée la question `CO_IMAGE` avec ses médias.

La règle « inactive jusqu'à audio + relecture » est tenue par construction : **aucune question n'existe avant la validation du brouillon**. La validation dans l'écran de revue *est* l'activation manuelle (`AudioDraftService.java:248-249` pose `active=true, status=ACTIVE`).

| Élément | Emplacement |
|---|---|
| Endpoints | `J/controller/AdminQuestionImportController.java` : `POST /api/admin/question-imports/co-image/analyze` et `…/import` (multipart : `manifest` JSON + N fichiers) |
| DTO | `J/dto/` (paquet plat) : manifeste, question, rapport d'analyse |
| Validateur + orchestration | `J/service/questionimport/` (validation pure + service d'import) |
| Mapper | `J/mapper/` : DTO d'import → `AudioQuestionDraft` (pur, sans lookup) |
| Construction transcript/SSML | **utilitaire unique** extrait des 2 `buildSsml` existants, appelé par l'import |
| Écriture | via un manager. `AudioQuestionDraftRepository` vit dans `audioquestion/` (exception d'architecture) : soit un `AudioQuestionDraftManager` dans `J/manager/`, soit l'appel au service du module. **À arbitrer**, sans étendre l'exception. |

### 4.2 Format JSON ajusté

```json
{
  "version": "1",
  "format": "CO_IMAGE",
  "questions": [
    {
      "externalId": "co-a2-001",
      "level": "A2",
      "themeCode": "…",
      "image": "co-a2-001.png",
      "sceneDescription": "Un couple descend l'allée d'un cinéma…",
      "choices": ["…", "…", "Viens, on va s'asseoir là.", "…"],
      "correctAnswer": "C",
      "explanation": "…"
    }
  ]
}
```

Ajustements par rapport au brief :
- **`format` = `CO_IMAGE`**, nom réel en base. `type: TCF_CO` est redondant et retiré.
- **`themeCode` ajouté**, car `theme_id` est NOT NULL (`V009:13`). Optionnel si l'on fixe un thème CO par défaut. **À arbitrer.**
- **`explanation` ajouté**, optionnel : la correction l'affiche, et le formulaire admin l'exige.
- **`sceneDescription`** devient `image_alt_text` (colonne existante). Il sert aussi à une régénération future.
- **`correctAnswer` en lettre** : confirmé, cohérent avec les libellés `A–D` stockés.
- **Hors manifeste, côté serveur :** `statement` (consigne par défaut du player), voix (Denise par défaut, cf. V802), `transcript_text` et `ssml_text` dérivés de `choices`.

Mapping vers le brouillon :
- `choices[i]` → `{label: "A"…"D", text: choices[i], is_correct, display_order: i+1}`. La clé `text` s'ajoute au JSONB, **sans migration**.
- Sur la question publiée, les libellés restent `A–D` et le texte part dans `medias.transcript`, servi après correction. **Ne jamais mettre le texte dans `Choice.label`** : la réponse fuirait dans le JSON, et le mobile l'afficherait (E4).

### 4.3 Validations (phase « Analyser », sans écriture)

| Niveau | Règle |
|---|---|
| Manifeste | `version` connue, `format` = `CO_IMAGE`, 1 ≤ N ≤ 20 questions |
| Question | `externalId` : motif `[a-z0-9-]{3,64}`, unique dans le lot **et** absent en base (brouillons, tous statuts) |
| | `level` ∈ A2/B1/B2 ; `themeCode` existant et de module TCF |
| | exactement 4 `choices`, non vides après trim, **distincts** sans tenir compte de la casse, longueur bornée (ex. ≤ 120 caractères) |
| | `correctAnswer` ∈ A–D |
| | `sceneDescription` non vide, bornée |
| Image | référencée une seule fois ; fichier présent ; aucun fichier en trop dans le dépôt |
| | type jpeg/png/webp **vérifié sur les octets** (signature), ≤ 5 Mo |
| | dimensions lisibles, ratio 4:3 ± tolérance, largeur minimale (ex. ≥ 800 px), via `ImageIO` du JDK, sans dépendance |
| Lot | rapport par question (OK / erreurs), aperçu côté admin à partir des fichiers locaux, sans aucun envoi |

**Le bouton « Importer » rejoue les mêmes validations côté serveur** : l'analyse n'est jamais crue sur parole.

### 4.4 Transaction et cohérence R2

**Tout ou rien.** Un lot de 10 se corrige et se renvoie. Un import partiel crée des trous et des situations de doublon.

Séquence :
1. Valider tout (§4.3). Au moindre échec : 422 et rapport, rien n'est écrit.
2. Tirer les UUID des brouillons en mémoire, puis **envoyer les N images** sur `questions/images/drafts/<draftId>/<uuid>.<ext>` en **conservant la liste des clés**.
3. **Une seule transaction DB** insère les N brouillons.
4. Si l'étape 2 ou 3 échoue : **compensation**, avec suppression au mieux des clés déjà envoyées (`deleteObject` existe), puis erreur.

Les orphelins résiduels (crash entre l'envoi et le commit) sont bornés à un lot. Ils sont repérables par préfixe, car leur `draftId` n'existe pas en base. Un balayage n'est pas nécessaire au MVP.

L'unicité `external_id` en base ferme la course entre deux imports concurrents : le second échoue au commit et compense.

### 4.5 Doublons

**Stratégie la plus simple :** une colonne `audio_question_draft.external_id varchar(64)` avec index UNIQUE (**une** migration).
- Un `externalId` déjà connu en base, **quel que soit le statut**, refuse la question. Pour réimporter un brouillon rejeté, on change d'identifiant.
- Pas de mise à jour par ré-import. Elle n'est pas souhaitable : `QuestionService.update` recrée les choix (`J/service/QuestionService.java:87-88`), ce qui casse `answers.selected_choice_ids`.
- Aucune colonne n'est nécessaire sur `questions` : la traçabilité s'arrête au brouillon `PUBLISHED`. L'ajouter serait spéculatif.

### 4.6 Avis sur le ZIP (phase 2)

**Pas au MVP.**
- Le glisser-déposer JSON + images couvre le besoin.
- Le ZIP ajoute un risque (zip-bomb, traversée de chemins) et un paquet de décompression.
- Il ne devient utile que si la phase 3 produit un lot téléchargeable hors admin.
- S'il arrive, il se **décompresse en (manifeste, fichiers)** puis appelle **le même service d'import**.

---

## 5. Architecture cible

```text
Admin « Importer des CO image »  (nouvelle page, features/questionImport/)
  ├─ JSON collé  +  N images (drag & drop)
  ▼
POST …/co-image/analyze  ── validateur pur ──► rapport (aucune écriture)
  ▼  (aperçu image / choix / bonne réponse / erreurs)
POST …/co-image/import
  ├─ re-validation
  ├─ R2 : questions/images/drafts/<draftId>/<uuid>.<ext>   (compensé si échec)
  └─ DB (1 transaction) : audio_question_draft × N
        choices JSONB {label A–D, text, is_correct, display_order}
        transcript_text + ssml_text  ◄── utilitaire SSML unique (dérivé des choices)
        image_url, image_alt_text (= sceneDescription), external_id
        status = TEXT_VALIDATED
  ▼
/audio-questions/review  (EXISTANT)
  ├─ « Générer l'audio » → batch-generate (EXISTANT, Azure → R2 audio/<uuid>.mp3)
  ├─ écoute + image + rejet
  └─ Valider → validateDraft (EXISTANT) → questions CO_IMAGE active
        media_id = IMAGE(url R2), audio_media_id = AUDIO, choices A–D

Phase 3 (plus tard) : LLM → manifeste JSON → (générateur d'images) → MÊME POST …/import
```

---

## 6. Évolutions

| Évolution | Classement | Motif |
|---|---|---|
| Endpoint et service d'import → brouillons | **Nécessaire** | Cœur du besoin (E2) |
| Clé `text` dans le JSONB `choices` + transcript/SSML dérivés par un utilitaire unique (extraction des 2 `buildSsml`) | **Nécessaire** | E1 et règle de duplication |
| Migration `audio_question_draft.external_id` UNIQUE | **Nécessaire** | E3 |
| Page admin d'import (analyse, aperçu, import) | **Nécessaire** | Workflow phase 1 |
| Validation des octets et des dimensions (ImageIO) dans `ImageUploadSupport` (autorité unique) | **Nécessaire** | E8 ; profite aussi aux uploads existants |
| Hausse de `spring.servlet.multipart.max-request-size` pour 10 × 5 Mo | **Nécessaire** | 25 Mo actuels insuffisants |
| Charte d'images versionnée (JSON) | **Nécessaire** | Référence de génération (§6.1) |
| Mobile : masquer les textes sur `questionType == CO_IMAGE` comme le web (+ révision / favoris des deux côtés) | Optionnel (parité) | E4 ; à faire si un jour `label` ≠ lettre |
| Filtre « Média » : valeurs Image fichier / Image SVG + indicateur « audio manquant » | Optionnel | E10 |
| Garde-fou serveur des tirages TCF : `status = ACTIVE` et `audio_media_id` non nul pour `CO_IMAGE` | Optionnel, recommandé | E6 + faille `setActive` (§2.4) |
| Fond blanc au zoom mobile | Optionnel | E5, si la charte n'est pas respectée |
| Servir `altText` au candidat | Optionnel | E9 |
| `cached_network_image` sur mobile | Optionnel | E7 |
| Upload ZIP | À éviter au MVP | §4.6 |
| Nouveau `QuestionType` / colonne `format` | **À éviter** | `CO_IMAGE` existe |
| Champ `audioText` libre | **À éviter** | Divergence garantie |
| Écrire directement dans `questions` (contournement des brouillons) | **À éviter** | Second chemin, pas de revue audio |
| Réutiliser la voie unitaire `AudioQuestionGenerationService` | **À éviter** | Refuse ce mode et impose l'amorce |
| Resize / conversion WEBP serveur | À éviter au MVP | Bibliothèque à ajouter ; exporter en WEBP à la source suffit |
| Champs `batchId`, `generationModel` | À éviter | Spéculatif (`batch_id` existe d'ailleurs déjà pour la synthèse) |

### 6.1 Charte visuelle

Emplacement proposé : `backend_sejourfr/src/main/resources/generation_questions/charte-images-co-v1.json`, à côté de `GUIDE_CO_comprehension_orale.md`. Versionnée `-vN` comme `R/prompts/`.

Contenu minimal :
- dessin au trait noir sur **fond blanc opaque** ;
- ratio 4:3 et largeur minimale ;
- format WEBP ou PNG ;
- **aucun texte, chiffre ni logo** dans l'image ;
- personnages neutres (âge, genre, origine variés, sans stéréotype) ;
- une seule action lisible par scène, cadrage sur l'action ;
- interdit : reproduction d'images des livrets FEI.

Le validateur d'import lit le ratio et la largeur depuis ce fichier : **une seule autorité**.

---

## 7. Risques et points de vigilance

1. **Fuite de la réponse :** si le texte des propositions passe dans `Choice.label`, il part dans le JSON du runner, et le mobile l'affiche (E4). Le texte reste dans le brouillon et dans le transcript, jamais dans `label`.
2. **Cohérence image ↔ propositions :** aucune vérification automatique. La revue humaine (écran existant) est le seul contrôle avant la phase 3.
3. **Distracteurs trop faciles ou ambigus :** deux propositions plausibles pour la scène. Ce risque est éditorial ; la revue doit écouter avec l'image.
4. **Orphelins R2 :** compensation au mieux, résidu borné. Accepté.
5. **Course `external_id` :** fermée par l'index UNIQUE.
6. **Batch de 10 synchrone :** un import de 20 demande deux clics « Générer » et facture deux fois des appels Azure (coût faible, à surveiller).
7. **Faille existante `setActive` / `status DRAFT`** (§2.4), hors périmètre mais réelle.
8. **Taille des requêtes :** multipart à 25 Mo et chargement entièrement en mémoire (`file-size-threshold: 26MB`). Plafonner la taille du lot.
9. **Bucket public :** les images sont publiques, au même titre que les audios. Rien de sensible, mais aucune image de livret FEI n'est jamais envoyée.
10. **Aucun mode sombre aujourd'hui :** si un mode sombre arrive, les images à fond blanc resteront des cartes claires, ce qui est voulu.

---

## 8. Plan d'implémentation

**Phase 1a — backend**
- migration `external_id` ;
- utilitaire SSML unique (extraction + 3ᵉ appelant) ;
- `text` dans `DraftChoice` ;
- validation par les octets et les dimensions dans `ImageUploadSupport` ;
- charte JSON ;
- validateur, service d'import (analyse + import, compensation R2), mapper, endpoint ;
- taille multipart ;
- **tests** : validateur (unitaires), import tout ou rien et doublon `external_id` (IT Zonky), dérivation SSML (unitaires).

**⛔ STOP — revue du contrat d'endpoint et du format JSON.**

**Phase 1b — admin**
- page d'import (zone JSON, glisser-déposer, aperçu local, rapport d'analyse, import, lien vers `/audio-questions/review`) ;
- miroir `ADM/types/api.ts` ;
- vérification par `npx tsc --noEmit`.

**⛔ STOP — import réel d'un lot de test, génération audio, revue, validation.**

**Phase 1c — parité et garde-fous** (optionnels, à arbitrer)
- masquage mobile par `questionType` ;
- filtre « Média » enrichi ;
- garde-fou des tirages (`status`, audio) ;
- fond blanc au zoom mobile.

**⛔ STOP.**

**Phase 2 — ZIP** : seulement si le besoin se confirme. Décompression vers le même service.

**⛔ STOP.**

**Phase 3 — génération IA**
- LLM, tool-schema `co-image-questions-tool-schema-v1.json` + prompt versionné → manifeste ;
- générateur d'images (fournisseur à choisir, **coût à présenter avant toute mesure**) → fichiers ;
- **même endpoint d'import**.

Variante image fournie : client multimodal (bloc image à ajouter), qui propose les choix et la bonne réponse, édités puis importés.

Coûts via `CoutAppelLlm`, ajout versionné à `v_ai_usage`, `GenerationRateLimiter`.

**⛔ STOP.**

---

## 9. Fichiers modifiés ou créés (phase 1)

**Backend**

| Fichier | Action |
|---|---|
| `M/…/V0xx__audio_draft_external_id.sql` (numéro selon `docs/migrations-flyway.md`) | créer |
| `AQ/entity/AudioQuestionDraft.java` (`externalId`, `DraftChoice.text`) | modifier |
| `J/util/` utilitaire SSML (nom à fixer) | créer |
| `J/service/ProductionExampleAudioService.java`, `J/service/diagnostic/DiagnosticInstructionAudioService.java` | modifier (appellent l'utilitaire) |
| `J/service/ImageUploadSupport.java` (octets, dimensions) | modifier |
| `J/controller/AdminQuestionImportController.java` | créer |
| `J/dto/CoImageImport*.java` (manifeste, question, rapport) | créer |
| `J/service/questionimport/CoImageImportValidator.java`, `CoImageImportService.java` | créer |
| `J/mapper/CoImageImportMapper.java` | créer |
| `J/manager/AudioQuestionDraftManager.java` (selon l'arbitrage §4.1) | créer |
| `AQ/repository/AudioQuestionDraftRepository.java` (`existsByExternalIdIn`) | modifier |
| `R/generation_questions/charte-images-co-v1.json` | créer |
| `R/application.yaml` (multipart) | modifier |
| tests `*Test` / `*IT` correspondants | créer |

**Admin**

| Fichier | Action |
|---|---|
| `ADM/features/questionImport/` (page + CSS Module) | créer |
| `ADM/api/questionImportApi.ts` | créer |
| `ADM/types/api.ts` | modifier |
| `ADM/App.tsx` (route) + entrée de navigation | modifier |

**Docs**

| Fichier | Action |
|---|---|
| `docs/pipeline-audio-co.md` (section import ; corriger le chemin `prompts/old/`) | modifier |
| `backend_sejourfr/CLAUDE.md` / `admin_sejourfr/CLAUDE.md` (nouvelle feature) | modifier |

**Phase 1c, si retenue**

| Fichier |
|---|
| `MOB/core/models/question_models.dart`, `MOB/screens/question_runner/widgets/choice_tile.dart`, `MOB/core/widgets/question_detail_sheet.dart` |
| `WEB/app/_components/ExamReport.tsx` |
| `J/repository/QuestionRepository.java` |
| `J/enums/QuestionMediaFilter.java`, `J/.../QuestionSpecifications.java`, miroir `ADM/types/api.ts` |
| `MOB/screens/question_runner/widgets/question_media_view.dart` |

---

**Arbitrages attendus avant le GO :**
1. L'import écrit des **brouillons** (recommandé), et non des questions inactives.
2. `themeCode` dans le JSON, ou thème CO par défaut.
3. Écriture des brouillons hors `audioquestion/` : manager dédié, ou appel au service du module.
4. Phase 1c : quels optionnels retenir.
