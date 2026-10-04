# Décisions — import des questions CO image (phase 1)

> Journal des décisions prises en cours d'implémentation (GO du 2026-10-04, phases 1a + 1b + 1c).
> Référence : `docs/question-audio/audit-questions-co-images.md`.

| # | Phase | Contexte | Options envisagées | Décision | Fichiers impactés |
|---|---|---|---|---|---|
| D-01 | 1c | Règle impérative : compter `is_active = true AND status <> 'ACTIVE'` avant d'ajouter le filtre `status = ACTIVE` aux tirages TCF | Appliquer le filtre ; migration d'alignement ; ne pas filtrer | Base locale : **0** ligne, tous modules et types confondus (SELECT du 2026-10-04). Le filtre est appliqué. Une **migration d'alignement idempotente** est ajoutée en plus (`status='ACTIVE'` là où `is_active = true`), pour qu'une base de prod qui aurait des questions activées par l'ancien `PATCH` (statut resté `DRAFT`) ne perde aucun contenu en silence. | `QuestionRepository.java`, nouvelle migration |
| D-02 | 1c | Le masquage des textes de choix (E4) diverge entre web et mobile | Copier `isCoImage` dans chaque écran ; une règle par front | **Une règle par front** : `web_sejoufr/lib/choice-key-letters.ts` ⇄ `QuestionDto.isLetterKeyQuestion` / `choiceKeyLetter(i)` sur mobile. Elle est utilisée par le runner, le rapport et les favoris. | `lib/choice-key-letters.ts`, `QuestionRunner.tsx`, `ExamReport.tsx`, `FavoriDetailSheet.tsx`, `question_models.dart`, `choice_tile.dart`, `runner_screen.dart`, `question_detail_sheet.dart` |
| D-03 | 1c | **Bug web découvert** : la règle « libellé = lettre ⇒ texte masqué » s'appliquait à tous les types. Quatre questions STRUCTURE ont un choix « a » (verbe *avoir*), affiché comme une lettre sans texte. | Conserver ; limiter à CO/CO_IMAGE comme le mobile | Limitée à **CO / CO_IMAGE**, évaluée sur la question entière (tous les libellés). CO_IMAGE ⇒ toujours en lettres (lettre du libellé, sinon position). | idem D-02 |
| D-04 | 1c | Motif de reconnaissance d'une lettre différent : mobile `[A-Za-z]`, web `(réponse )?[A-D]` | Garder les deux ; aligner | Aligné sur le web, insensible à la casse | `question_models.dart` |
| D-05 | 1c | `ChoiceTile` mobile décidait lui-même du mode lettre | Booléen et recalcul dans le widget ; lettre fournie par l'appelant | `String? keyLetter` fourni par le modèle : le widget ne décide plus rien | `choice_tile.dart`, `runner_screen.dart` |
| D-06 | 1c | Zoom mobile sur fond noir : une image transparente à traits noirs y devient invisible (E5) | Écran entièrement clair ; panneau blanc dans un écran sombre | **Panneau blanc opaque** dans un écran `AppColors.ink`. Couleurs en dur passées en tokens. L'indicateur de chargement et l'icône d'erreur, blancs, sont recolorés pour rester visibles sur le panneau. | `question_media_view.dart` |
| D-07 | 1a | Thème par défaut | Valeur en dur ; configuration | `default-theme-code: TCF_CO` en configuration. Un `themeCode` fourni doit exister et appartenir au module TCF, sinon `THEME_INCONNU` / `THEME_HORS_TCF`. | `config/QuestionImportProperties`, `application.yaml` |
| D-08 | 1a | Écriture des brouillons hors `audioquestion/` | Service du module ; manager dédié | `manager/AudioQuestionDraftManager` (`findExistingExternalIds`, `persistAll`, `flush`). L'exception d'architecture n'est pas étendue. | manager, `AudioQuestionDraftRepository` |
| D-09 | 1a | Clé `text` sur les choix du brouillon | Obligatoire ; facultative | Facultative et jamais écrite à `null` : les brouillons V800+ se lisent à l'identique (testé sur V802) | `AudioQuestionDraft` |
| D-10 | 1a | Utilitaire SSML (3ᵉ occurrence) | Une classe ; deux | `util/Ssml` (générique ; sortie des 2 appelants existants identique à l'octet) + `util/PropositionsLuesCoImage` (gabarit CO image) | util, `ProductionExampleAudioService`, `DiagnosticInstructionAudioService` |
| D-11 | 1a | **Écart avec V802** : la pause de 1500 ms y est placée entre deux `<voice>`, et `cleanForAzure` la supprime en silence | Copier V802 ; garder la pause dans la voix | Pause **dans** la voix : elle est réellement jouée | `PropositionsLuesCoImage` |
| D-12 | 1a | Consigne, compétence, voix | Dans le manifeste ; dérivées par le serveur | Dérivées, comme dans V802 : consigne V802, `co_image_proposition`, voix Denise | `CoImageImportMapper` |
| D-13 | 1a | Portée des contrôles d'image | Partout ; import seulement | **Signature des octets partout** (les envois existants aussi : un fichier dont le type déclaré ment est désormais refusé). Dimensions, ratio, largeur et **opacité** à l'import seulement. | `ImageUploadSupport`, validateur |
| D-14 | 1a | Dimensions d'un WEBP sans dépendance | Nouvelle bibliothèque ; lecture de l'en-tête | Lecture de l'en-tête RIFF (VP8 / VP8L / VP8X). Aucune dépendance ajoutée. | `ImageUploadSupport` |
| D-15 | 1a | Charte | Valeurs en dur ; JSON | `generation_questions/charte-images-co-v1.json`, chargé et vérifié au démarrage : PNG/WEBP, 4:3 ± 2 %, largeur ≥ 800 px, opaque. **JPEG exclu à l'import** (l'audit §4.3 l'autorisait). | resources, `CharteImagesCo` |
| D-16 | 1a | Limites du manifeste | En dur ; configuration | Configuration : 20 questions, choix ≤ 120, scène ≤ 500, explication ≤ 2000 caractères | `QuestionImportProperties` |
| D-17 | 1a | Taille des requêtes multipart | Relever le seuil mémoire ; ne relever que le plafond | `max-request-size` à 110MB, seuil mémoire inchangé | `application.yaml` |
| D-18 | 1a | Forme des réponses | Format d'erreur global ; rapport | Le même rapport pour 200 (analyse), 201 (import) et 422 (refus). Un manifeste illisible donne l'erreur de lot `MANIFESTE_ILLISIBLE`, pas un 400. | contrôleur, DTO, validateur |
| D-19 | 1a | **Écart avec l'audit §4.4** : Hibernate génère l'id du brouillon et refuse un id tiré à l'avance | Upload avant la transaction ; upload dans la transaction | Persistance, **upload R2 avec l'id réel dans la transaction**, puis commit. Tout échec (y compris un conflit `external_id` concurrent) annule la transaction et supprime au mieux les clés déjà envoyées. Le résultat reste du tout ou rien. | `CoImageImportService` |
| D-20 | 1c | Prédicat « question servable » | Le recopier dans chaque requête ; une constante | `SERVABLE_JPQL` / `SERVABLE_SQL` (`status = ACTIVE`, et audio présent pour `CO_IMAGE`), concaténés dans tous les tirages, les comptages, le pool d'un thème et l'export de calibration. Ajouté aussi aux tirages civiques, sans effet puisqu'ils filtraient déjà `status`. | `QuestionRepository`, `QuestionManager` |
| D-21 | 1c | Migration d'alignement (D-01) | Modifier une migration appliquée ; en créer une | Nouvelle **V089**, idempotente, vérifiée par un test | V089, `QuestionStatusAlignementIT` |
| D-22 | 1c | Sémantique de la désactivation | DRAFT ; ARCHIVED | ACTIVE → **ARCHIVED** (une question DRAFT peut être supprimée par l'endpoint de la voie unitaire : une question qui a un historique de réponses ne doit jamais redevenir DRAFT). DRAFT et ARCHIVED inchangés. Activation ⇒ ACTIVE. S'applique au `PATCH` et au `PUT`. | `QuestionService` |
| D-23 | 1c | Filtre « Image SVG » | `inline_svg` non nul ; SVG sans URL | SVG **sans URL**, puisque l'URL prime à l'affichage | `QuestionSpecifications`, `QuestionMediaFilter` |
| D-24 | 1c | Indicateur « audio manquant » | Champ de DTO seul ; DTO + filtre | Les deux : `QuestionDto.audioMissing` et la valeur de filtre `AUDIO_MISSING`. Une seule autorité Java (`util/AudioManquant`) et sa jumelle en criteria, testées ensemble. | util, spec, DTO, mapper |
| D-25 | 1b | Emplacement de la page d'import | `/questions/import-co-image` ; `/audio-questions/import-co-image` | **`/audio-questions/import-co-image`** : l'import crée des brouillons audio et débouche sur la revue. Accès par le menu « Génération IA › Importer des CO image », un bouton sur `/questions/tcf` (TCF) et un lien sur la revue. | `App.tsx`, `navigation.ts`, `QuestionsPage.tsx`, `AudioDraftReviewPage.tsx` |
| D-26 | 1b | Messages d'erreur de l'analyse | Table de libellés côté front ; message du serveur | Message du **serveur** (déjà en français, avec les valeurs), code en second. Aucune règle de validation recopiée côté front. | `ImportErrorList.tsx` |
| D-27 | 1b | Réponse 422 de l'import | Laisser l'erreur HTTP remonter ; rendre le rapport | Le rapport du 422 est rendu (avec garde de type) ; les autres erreurs remontent | `questionImportApi.ts` |
| D-28 | 1b | N'importer qu'une analyse à jour | Comparer les contenus ; compteur de révision | Compteur incrémenté à chaque modification du manifeste ou des images. « Importer » est désactivé et le rapport estompé tant qu'il n'y a pas de nouvelle analyse. | `CoImageImportPage.tsx` |
| D-29 | 1b | Deux fichiers de même nom ; `.json` déposé dans la zone images | Garder les deux ; remplacer — ignorer le `.json` ; s'en servir | Le dernier fichier choisi remplace l'autre ; un `.json` déposé remplit le manifeste | `CoImageImportPage.tsx` |
| D-30 | 1b | Erreurs 409 / 413 / 5xx | Message brut ; message selon le statut | Une phrase par statut, plus le message serveur ; réanalyse exigée avant d'importer | `CoImageImportPage.tsx` |
| D-31 | 1c | Badge « audio manquant » | Déduit de `audioMediaUrl` ; champ servi | Lu sur `audioMissing`, servi par le backend (ni recalcul ni déduction côté front) : liste et fiche question | `QuestionsPage.tsx`, `QuestionDetailPage.tsx` |
| D-32 | 1c | **Bug de la revue découvert** : les choix étaient lettrés **B–E** (`65 + displayOrder`, alors que l'ordre commence à 1) | Garder ; lettrer selon le rang | Lettrés selon le **rang** (A–D). Si le brouillon porte le texte importé, il s'affiche ; sinon « Proposition lue dans l'audio » | `AudioDraftReviewPage.tsx` |
| D-33 | suivi | Une question **ARCHIVED** (désactivée, D-22) doit rester trouvable dans `/questions/tcf` pour être réactivée | Ajouter un filtre de statut ; ne rien changer | **Rien à corriger** : `GET /api/admin/questions` n'a aucun prédicat de statut (`QuestionSpecifications` filtre module, thème, difficulté, type, `active`, média, texte) et l'admin part de `active: ""` (aucun filtre). Vérifié sur la base locale : la liste par défaut rend 1 933 TCF / 1 028 civiques, soit tout `questions`, archivées comprises ; « Inactives » les isole. Réactiver ⇒ `ACTIVE`. Comportement verrouillé par un test. | `QuestionServiceIT` (test ajouté) |
| D-34 | suivi | `IMAGE_TRANSPARENTE` : refuser sur des pixels réellement transparents, jamais sur la seule présence d'un canal alpha | Seuil « alpha < 255 » ; seuil toléré (≥ 250) ; proportion de pixels. WEBP : drapeau VP8X ; données d'alpha ; dépendance (TwelveMonkeys) | **Un seul pixel d'alpha < 255 refuse** (règle simple, identique à `WebPPictureHasTransparency` de libwebp ; une RGBA opaque passe). PNG : décodage complet pixel par pixel (palette `tRNS` comprise), plafonné à **16 Mpx** (bombe de décompression). WEBP, **sans dépendance** : on lit les **données** d'alpha, pas le drapeau. Bloc `ALPH` brut non filtré lu octet par octet ; `ALPH` compressé ou filtré, ou indice VP8L `alpha_is_used` = transparence (libwebp ne les écrit que si un pixel l'est) ; drapeau VP8X sans `ALPH` = opaque. Un verdict invérifiable (PNG illisible, > 16 Mpx, WEBP tronqué ou animé) rend `IMAGE_ILLISIBLE` avec un message dédié, jamais une acceptation silencieuse (l'ancien code acceptait un PNG indécodable). Aucun code d'erreur ajouté : l'admin n'a rien à changer. | `ImageUploadSupport` (`transparence()` : `AUCUNE` / `PRESENTE` / `INVERIFIABLE`), `CoImageImportValidator`, `ImagesDeTest`, `ImageUploadSupportTest`, `CoImageImportValidatorTest`, `docs/pipeline-audio-co.md` |
| D-35 | suivi | La signature des octets (D-13) a-t-elle cassé un envoi de SVG ? | Ajouter un reniflage `<svg` ; constater | **Aucun chemin SVG n'existait en fichier** : `ImageUploadSupport` n'a jamais admis que jpeg/png/webp (liste blanche d'avant D-13), et `/api/admin/media/upload` (`LocalFileStorageService`, hors `ImageUploadSupport`, non touché) n'admet que `image/png,image/jpeg,image/webp` depuis l'origine. Le SVG ne vit qu'en **`inline_svg`** (texte : brouillons générés, `QuestionWriteRequest`), sans contrôle d'octets. Pas de reniflage ajouté : ce serait ouvrir un format, pas réparer. Tests : SVG déclaré refusé, SVG déguisé en PNG refusé, remplacement d'une CO_IMAGE SVG par un PNG (URL posée, `inline_svg` vidé). À noter : `/api/admin/media/upload` ne lit **pas** la signature (D-13 disait « partout ») ; hors périmètre, laissé tel quel. | `ImageUploadSupportTest`, `LocalFileStorageServiceTest`, `QuestionImageServiceTest` |
| D-36 | suivi | V088 et V089 sont numérotées sous des versions déjà appliquées (V8xx, V901) sur la base locale et en prod | Renuméroter (V9xx) ; activer `outOfOrder` | **Ni renumérotation ni changement de config** : `out-of-order: true` est déjà posé dans `application.yaml` (dev **et** prod, qui ne surchargent que `locations`) et dans `application-test.yaml` (Zonky) ; V083 à V087 sont déjà passées ainsi après V901. Renuméroter vers le haut aurait déplacé du DDL après le contenu sur base neuve. Constaté sur `sejourfr_db` : V088 (rang 396) et V089 (rang 397) appliquées avec succès le 2026-10-04 à 22:27:31 (boot IDE du propriétaire), colonne `external_id varchar(64)` + index `uq_audio_draft_external_id`, 0 question `is_active` avec `status <> 'ACTIVE'`. Base neuve : couverte par les IT Zonky (`QuestionStatusAlignementIT`, `AudioQuestionDraftManagerIT`, `CoImageImportServiceIT`). | `docs/migrations-flyway.md` |

---

## Bilan

### Livré

| Phase | Commit | Contenu |
|---|---|---|
| 1a — backend import | `299664d1` | Les endpoints `POST /api/admin/question-imports/co-image/{analyze,import}` (multipart : manifeste + images) analysent ou importent un lot ; l'analyse n'écrit rien. L'import se fait en tout ou rien vers `audio_question_draft` (`TEXT_VALIDATED`), avec compensation R2.<br>• Migration `external_id` UNIQUE.<br>• Choix `{label A–D, text}` ; transcript et SSML dérivés des choix.<br>• Utilitaires `Ssml` et `PropositionsLuesCoImage`.<br>• Contrôle des images sur les octets, dimensions WEBP sans dépendance.<br>• Charte `generation_questions/charte-images-co-v1.json`.<br>• Tests unitaires et d'intégration.<br>• Lot de test `docs/question-audio/lot-test/`. |
| 1c — backend | `7e32c4b3` | **Garde-fou des tirages TCF** (`status = ACTIVE`, et audio présent pour `CO_IMAGE`) appliqué à tous les tirages et comptages.<br>• Migration d'alignement **V089**.<br>• `PATCH …/status` et `PUT` synchronisent `status` et `is_active`.<br>• Filtre Média : `IMAGE_FILE`, `IMAGE_SVG`, `AUDIO_MISSING` ; champ `QuestionDto.audioMissing`.<br>• Test de non-régression `QuestionDrawGuardIT`. |
| 1c — fronts web + mobile | `877f2602` | Lettres-clés en `CO_IMAGE` partout (runner, rapport, favoris), avec une règle par front.<br>• Zoom mobile sur panneau blanc.<br>• Bug STRUCTURE « a » corrigé (web). |
| 1b + 1c — admin | `ca006d6e` | Page **Importer des CO image** (manifeste, images en glisser-déposer, analyse, aperçu, import).<br>• Filtre Média enrichi et badge « Audio manquant ».<br>• Revue des brouillons : `externalId`, texte des propositions, lettres A–D corrigées. |

**Vérifications :**
- **Backend :** `./mvnw verify` passe (3 481 tests unitaires, 1 958 tests d'intégration).
- **Web :** `tsc` et eslint passent.
- **Mobile :** `flutter analyze` passe, ainsi que 303 tests.
- **Admin :** `tsc`, eslint et `npm run build` passent.

**Rien n'a été poussé ni déployé. Aucune API payante n'a été appelée.**

**Suivi (2026-10-04, D-33 à D-36) :** opacité lue sur les pixels (PNG) et sur les données d'alpha (WEBP), chemins SVG vérifiés intacts, liste admin des archivées vérifiée, migrations V088/V089 appliquées sur la base locale grâce à `out-of-order: true` (déjà actif en dev, prod et tests).

### Écarts par rapport au rapport d'audit

1. Upload R2 **dans** la transaction, et non avant (D-19). L'import reste en tout ou rien, avec compensation.
2. Formats acceptés à l'import : **PNG et WEBP seulement**, JPEG exclu (D-15). Un contrôle d'**opacité** est ajouté (`IMAGE_TRANSPARENTE`).
3. Le contrôle des octets s'applique aussi aux uploads d'images **existants** (D-13).
4. Désactiver une question la passe en **ARCHIVED**, et non en DRAFT (D-22).
5. La pause de 1500 ms du gabarit est placée **dans** la voix : celle de V802 était supprimée par `cleanForAzure` (D-11).
6. Le prédicat « servable » est aussi appliqué aux tirages civiques, sans effet (D-20).
7. La page admin est sous `/audio-questions/…`, et non sous `/questions/…` (D-25).
8. Deux bugs corrigés en route, hors périmètre : choix STRUCTURE « a » sur le web (D-03) et lettres B–E dans la revue (D-32).

### Procédure de test de bout en bout

**Prérequis**
1. **Backend** : V088 et V089 sont **déjà appliquées** sur `sejourfr_db` (D-36) et le
   backend tourne avec le code à jour (`./mvnw spring-boot:run -Dspring-boot.run.profiles=dev`).
   Après tout nouveau changement : arrêter le processus du port 8080
   (`lsof -i :8080 -sTCP:LISTEN`, puis `kill <PID>`), relancer, et vérifier
   `select version, success from flyway_schema_history where version in ('088','089');`.
   En prod, rien de particulier : `out-of-order: true` appliquera V088 puis V089 au
   premier boot.
2. La configuration R2 et Azure doit être présente dans `backend_sejourfr/.env`.
3. Relancer `npm run dev-admin`.

**1. Import**
1. Aller dans l'admin, menu **Génération IA › Importer des CO image**.
2. Coller ou déposer `docs/question-audio/lot-test/manifest.json`.
3. Déposer les 3 images du même dossier.
4. Cliquer sur **Analyser** : 3 cartes au vert (bonnes réponses B, D, C), aucune erreur.
5. Pour tester un refus : modifier une lettre en `E`, ou retirer une image. Vérifier l'erreur affichée et l'impossibilité d'importer.
6. Revenir au lot propre, réanalyser, puis cliquer sur **Importer** : « 3 brouillons créés ».
7. Réimporter le même lot : **422**, avec `EXTERNAL_ID_DEJA_IMPORTE` sur les 3 questions.

**2. Génération audio** — appelle Azure, payant mais quelques centimes
1. Ouvrir **Audio à valider** (`/audio-questions/review`).
2. Lancer la génération par lot (niveau A2).
3. Les 3 brouillons passent en attente de revue.

**3. Revue**
- Pour chaque brouillon : écouter l'audio (intro, pause, « A. … B. … C. … D. »).
- Vérifier l'image R2, le `externalId` et les textes à côté des lettres A–D.

**4. Validation**
1. Valider les 3 brouillons : ils créent des questions `CO_IMAGE` actives.
2. Sur `/questions/tcf`, avec le filtre Média = « Image (fichier) », les 3 questions apparaissent.
3. Avec « Audio manquant », la liste reste vide.

**5. Côté candidat**
1. Sur le web, puis sur le mobile, lancer un entraînement **TCF CO** de niveau A2.
2. Les questions sont tirées au hasard parmi 73 `CO_IMAGE`. On peut aussi passer par un examen blanc CO.
3. Vérifier :
   - l'image PNG/WEBP affichée ;
   - l'audio en lecture automatique ;
   - **4 boutons A–D sans texte** ;
   - la correction (la bonne lettre, puis la transcription avec les textes) ;
   - les mêmes lettres dans le rapport d'examen et les favoris.
4. **Mobile** : toucher l'image pour vérifier le zoom sur panneau blanc.

**6. Non-régression**
- Une ancienne `CO_IMAGE` en SVG s'affiche comme avant.
- Une question STRUCTURE contenant le choix « a » affiche bien son texte sur le web.
- Désactiver puis réactiver une question dans l'admin : le statut repasse `ACTIVE` et la question est de nouveau tirée.
