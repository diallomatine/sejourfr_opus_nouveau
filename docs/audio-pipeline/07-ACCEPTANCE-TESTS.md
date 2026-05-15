# 07 — Tests d'acceptation

## 1. Méthode Given / When / Then

Chaque test est exprimé sous la forme :
- **Given** : état initial et préconditions
- **When** : action déclenchée
- **Then** : résultat attendu, vérifiable

Ces tests servent à :
1. **Spécifier** le comportement attendu (pour Claude Code)
2. **Vérifier** que l'implémentation est correcte
3. **Documenter** les cas limites

---

## 2. Tests fonctionnels — Génération nominale

### 2.1 TC-001 : Génération réussie d'une question B1

**Given** :
- L'admin Jean (rôle `ADMIN`) est authentifié
- Les clés API Anthropic, Azure, R2 sont valides
- Le bucket R2 est accessible
- Aucune question similaire en base

**When** :
- L'admin appelle `POST /api/admin/audio-questions/generate` avec :
  ```json
  {"niveau": "B1", "theme": "sante", "typeSouhaite": "dialogue"}
  ```

**Then** :
- Code HTTP 200
- La réponse contient un `questionId` UUID
- Le `status` est `"DRAFT"`
- Le `url` audio commence par `https://pub-...r2.dev/audio/`
- Le MP3 est téléchargeable et lisible
- La transcription correspond à ce qui est dit dans l'audio
- Exactement 1 choix a `isCorrect: true`
- Les 4 `displayOrder` couvrent {1, 2, 3, 4}
- La durée audio est entre 30 et 60 secondes
- 2 voix utilisées (dialogue)
- Une entrée existe dans `audio_question_generation_logs` avec `status = SUCCESS`
- La question est en base avec `status = 'DRAFT'` et `is_active = false`
- Le coût total est calculé et logué

### 2.2 TC-002 : Génération réussie d'une question A2

**Given** : idem TC-001

**When** :
- Paramètres : `{"niveau": "A2", "theme": "transports"}`

**Then** :
- Durée audio entre 15 et 30 secondes
- 1 voix typique
- `competenceCode` parmi `co_reperage_explicite`, `co_detail_specifique`
- Compteur de caractères < 300

### 2.3 TC-003 : Génération réussie d'une question B2

**Given** : idem TC-001

**When** :
- Paramètres : `{"niveau": "B2", "typeSouhaite": "interview"}`

**Then** :
- Durée audio entre 60 et 120 secondes
- 2 ou 3 voix (interview)
- `competenceCode` parmi `co_inference_intention`, `co_ton_attitude`, `co_idee_principale`

### 2.4 TC-004 : Génération avec consignes spécifiques

**Given** : idem TC-001

**When** :
- Paramètres : `{"niveau": "B1", "theme": "travail", "consignesSpecifiques": "Conversation entre un manager et un nouvel employé sur son premier jour"}`

**Then** :
- Le transcript reflète le contexte demandé (manager + nouvel employé + premier jour)
- 2 voix
- Vocabulaire travail

---

## 3. Tests fonctionnels — Validation et rejet

### 3.1 TC-010 : Validation d'une question DRAFT

**Given** :
- Une question existe en statut `DRAFT` avec ID `Q1`

**When** :
- L'admin appelle `PATCH /api/admin/audio-questions/Q1/validate`

**Then** :
- Code HTTP 200
- La question passe à `status = 'ACTIVE'` et `is_active = true`
- Le MP3 reste sur R2 (non supprimé)

### 3.2 TC-011 : Tentative de validation d'une question ACTIVE

**Given** :
- Une question existe avec `status = 'ACTIVE'`

**When** :
- L'admin appelle `PATCH /.../validate`

**Then** :
- Code HTTP 409 Conflict
- Code d'erreur `QUESTION_NOT_DRAFT`
- La question reste inchangée

### 3.3 TC-012 : Rejet d'une question DRAFT

**Given** :
- Question DRAFT `Q1` avec media `M1` ayant pour object key `audio/M1.mp3`

**When** :
- L'admin appelle `DELETE /api/admin/audio-questions/Q1`

**Then** :
- Code HTTP 204 No Content
- La question, les choices et le media sont supprimés en cascade en DB
- Le fichier MP3 est supprimé du bucket R2

### 3.4 TC-013 : Rejet quand R2 est temporairement indisponible

**Given** :
- Question DRAFT existe
- R2 est en panne (timeout)

**When** :
- L'admin rejette la question

**Then** :
- La suppression DB se fait quand même (best-effort sur R2)
- Un log d'erreur indique que le MP3 R2 n'a pas pu être supprimé
- Code HTTP 204 (la suppression DB a réussi)
- Un job de nettoyage devra repasser pour supprimer le MP3 orphelin

---

## 4. Tests d'erreurs — Anthropic

### 4.1 TC-020 : Anthropic retourne un JSON malformé

**Given** :
- Anthropic est mocké pour retourner `{"audio": {` (JSON tronqué)

**When** :
- L'admin lance une génération

**Then** :
- Code HTTP 422
- Code d'erreur `ANTHROPIC_CONTENT_INVALID`
- Aucun MP3 n'est uploadé sur R2
- Aucune entrée n'est créée dans `medias`, `questions`, `choices`
- Un log existe avec `status = FAILED_ANTHROPIC_PARSE`

### 4.2 TC-021 : Anthropic retourne un JSON valide mais sans `audio.ssml`

**Given** :
- Anthropic mocké pour retourner un JSON sans le champ `ssml`

**When** :
- L'admin lance une génération

**Then** :
- Code HTTP 422 `ANTHROPIC_CONTENT_INVALID`
- L'erreur précise quel champ manque

### 4.3 TC-022 : Anthropic est temporairement en panne (500)

**Given** :
- Anthropic mocké pour retourner 500 sur les 2 premiers appels, puis 200 sur le 3e

**When** :
- L'admin lance une génération

**Then** :
- Le service retry automatiquement (max 2 retries)
- La 3e tentative réussit
- Réponse HTTP 200 normale

### 4.4 TC-023 : Anthropic en panne permanente

**Given** :
- Anthropic mocké pour retourner 500 systématiquement

**When** :
- L'admin lance une génération

**Then** :
- Après 3 tentatives, code HTTP 502 `ANTHROPIC_API_ERROR`
- Log `status = FAILED_ANTHROPIC`
- Aucun effet de bord

### 4.5 TC-024 : Anthropic retourne 2 réponses correctes

**Given** :
- Anthropic mocké pour retourner un JSON avec 2 choix `isCorrect: true`

**When** :
- L'admin lance une génération

**Then** :
- Code HTTP 422 `ANTHROPIC_CONTENT_INVALID`
- Détail dans `details` : "Exactly one choice must be correct, found 2"

### 4.6 TC-025 : Anthropic utilise une voix non whitelistée

**Given** :
- Anthropic mocké pour utiliser `fr-FR-FakeVoice` dans le SSML

**When** :
- L'admin lance une génération

**Then** :
- Code HTTP 422 `ANTHROPIC_CONTENT_INVALID`
- Détail : "Voice not in whitelist: fr-FR-FakeVoice"

---

## 5. Tests d'erreurs — Azure Speech

### 5.1 TC-030 : Azure retourne une erreur 400 (SSML invalide)

**Given** :
- Anthropic a renvoyé un SSML qui passe la validation côté backend mais que Azure refuse

**When** :
- Le backend appelle Azure Speech

**Then** :
- Code HTTP 502 `AZURE_SPEECH_API_ERROR`
- Log `status = FAILED_AZURE_SPEECH`
- Aucun upload R2

### 5.2 TC-031 : Azure en panne temporaire

**Given** :
- Azure mocké pour retourner 500 sur le 1er appel, 200 sur le 2e

**When** :
- L'admin lance une génération

**Then** :
- Retry automatique
- Génération réussie

### 5.3 TC-032 : Token Azure expiré

**Given** :
- Le token en cache est expiré

**When** :
- Le backend tente une synthèse

**Then** :
- Le `AzureSpeechTokenService` détecte l'expiration et refresh
- La synthèse réussit

---

## 6. Tests d'erreurs — Cloudflare R2

### 6.1 TC-040 : R2 retourne 403 (clés API mauvaises)

**Given** :
- Les clés R2 sont invalides

**When** :
- Le backend tente d'uploader

**Then** :
- Code HTTP 502 `R2_UPLOAD_ERROR`
- Log `status = FAILED_R2_UPLOAD`
- Aucune entrée DB

### 6.2 TC-041 : R2 en panne, retry réussit

**Given** :
- R2 retourne 500 sur le 1er upload, 200 sur le 2e

**When** :
- L'admin lance une génération

**Then** :
- Retry automatique
- Upload réussi
- Génération réussie

### 6.3 TC-042 : Insertion DB échoue après upload R2 réussi

**Given** :
- Anthropic OK, Azure OK, R2 upload OK
- La base de données est en panne au moment du INSERT

**When** :
- Le backend tente l'insertion

**Then** :
- Code HTTP 500 ou 502 (selon nature exacte)
- Log `status = FAILED_DB`
- **Le fichier MP3 a été supprimé de R2** (rollback manuel)
- Aucune trace en DB

---

## 7. Tests de validation des entrées

### 7.1 TC-050 : Niveau invalide

**When** :
- Requête avec `{"niveau": "C1"}`

**Then** :
- Code HTTP 400 `INVALID_LEVEL`
- Aucun appel externe (Anthropic, Azure, R2)

### 7.2 TC-051 : Thème non autorisé

**When** :
- Requête avec `{"niveau": "B1", "theme": "histoire_de_france"}`

**Then** :
- Code HTTP 400 `INVALID_THEME`
- Liste des thèmes autorisés dans le message d'erreur

### 7.3 TC-052 : Compétence non autorisée

**When** :
- Requête avec `{"niveau": "B1", "competenceVisee": "ce_reperage_explicite"}`
  (préfixe `ce_` au lieu de `co_`)

**Then** :
- Code HTTP 400 `INVALID_COMPETENCE`

### 7.4 TC-053 : ConsignesSpecifiques trop longues

**When** :
- Requête avec un texte de 501 caractères dans `consignesSpecifiques`

**Then** :
- Code HTTP 400
- Détail du champ et de la contrainte violée

---

## 8. Tests d'authentification et autorisation

### 8.1 TC-060 : Aucun token

**When** :
- Requête sans header `Authorization`

**Then** :
- Code HTTP 401 `UNAUTHORIZED`

### 8.2 TC-061 : Token valide mais utilisateur sans rôle ADMIN

**Given** :
- Utilisateur authentifié avec rôle `USER` (non `ADMIN`)

**When** :
- Requête de génération

**Then** :
- Code HTTP 403 `FORBIDDEN`

### 8.3 TC-062 : Token expiré

**When** :
- Requête avec un JWT expiré

**Then** :
- Code HTTP 401 `UNAUTHORIZED`

---

## 9. Tests de rate limiting

### 9.1 TC-070 : Admin atteint le quota

**Given** :
- L'admin a déjà fait 10 générations réussies dans la dernière minute

**When** :
- 11e tentative de génération

**Then** :
- Code HTTP 429 `RATE_LIMIT_EXCEEDED`
- Header `Retry-After: <X>` avec X = secondes restantes
- Log `status = RATE_LIMITED` (pas de FAILED_ANTHROPIC etc.)
- Aucun appel à Anthropic

### 9.2 TC-071 : Quota se reset après 1 minute

**Given** :
- L'admin était au quota maximum à T0
- T0 + 65 secondes

**When** :
- Nouvelle tentative

**Then** :
- La génération démarre (au moins une des 10 anciennes est sortie de la fenêtre)

### 9.3 TC-072 : Les échecs ne comptent pas

**Given** :
- 9 générations SUCCESS dans la dernière minute
- 5 générations FAILED_* dans la dernière minute

**When** :
- 10e tentative

**Then** :
- La génération démarre (seuls les SUCCESS comptent)

---

## 10. Tests de doublons

### 10.1 TC-080 : Détection de doublon

**Given** :
- Une question CO B1 existe en base avec un transcript donné

**When** :
- Claude génère un nouveau transcript très similaire (similarité > 0.85)

**Then** :
- Code HTTP 409 ou 422 (selon convention)
- Détail : "Un audio très similaire existe déjà"
- Aucun upload R2 effectué
- L'admin peut relancer pour avoir une autre génération

### 10.2 TC-081 : Transcript proche mais pas doublon

**Given** :
- Une question existe avec un thème santé sur les rendez-vous

**When** :
- Claude génère une nouvelle question santé mais avec un sujet différent (vaccination)

**Then** :
- Similarité < 0.85
- La génération aboutit normalement

---

## 11. Tests de performance

### 11.1 TC-090 : Temps de génération total

**Given** :
- Conditions nominales

**When** :
- Une génération

**Then** :
- Le temps total est < 30 secondes (P95)
- Le temps total est < 45 secondes (P99, sinon timeout)

### 11.2 TC-091 : Concurrence

**Given** :
- 5 admins lancent une génération simultanément

**When** :
- Tous appellent l'endpoint en même temps

**Then** :
- Toutes les générations réussissent (pas de conflit)
- Les UUIDs sont uniques
- Aucune corruption de données

---

## 12. Tests d'audit

### 12.1 TC-100 : Chaque génération est tracée

**Given** :
- Une génération vient d'être lancée

**When** :
- On consulte `audio_question_generation_logs`

**Then** :
- Une nouvelle ligne existe avec :
  - `question_id` rempli (si SUCCESS)
  - `admin_user_id` correct
  - `requested_params` = JSON exact de la requête
  - `anthropic_input_tokens`, `output_tokens`, `cost_eur` remplis
  - `azure_characters_count`, `cost_eur` remplis
  - `r2_object_key` rempli
  - `duration_ms` rempli
  - `status = 'SUCCESS'`
  - `created_at` à l'instant T

### 12.2 TC-101 : Échec partiel tracé

**Given** :
- Anthropic OK, Azure échoue

**When** :
- La génération se déroule

**Then** :
- Une entrée existe avec :
  - `question_id = NULL`
  - `anthropic_*` rempli
  - `azure_*` peut être partiellement rempli ou NULL
  - `r2_object_key = NULL`
  - `status = 'FAILED_AZURE_SPEECH'`
  - `error_message` contient le détail

### 12.3 TC-102 : Filtrage des logs

**When** :
- GET `/api/admin/audio-questions/generation-logs?status=FAILED_ANTHROPIC&page=0&size=10`

**Then** :
- Retourne uniquement les logs avec `status = 'FAILED_ANTHROPIC'`
- Tri par `created_at DESC`
- Pagination correcte

---

## 13. Tests de sécurité

### 13.1 TC-110 : Aucune clé API dans les logs

**Given** :
- Une génération est lancée

**When** :
- On consulte les logs applicatifs

**Then** :
- Aucune occurrence de `ANTHROPIC_API_KEY`
- Aucune occurrence de `AZURE_SPEECH_KEY`
- Aucune occurrence de `R2_SECRET_ACCESS_KEY`
- Les valeurs des clés ne sont nulle part dans le code source

### 13.2 TC-111 : Pas de leak dans les erreurs HTTP

**Given** :
- Une erreur survient (ex: 502 R2)

**When** :
- Le client reçoit la réponse d'erreur

**Then** :
- Le `message` ne contient ni clé, ni stacktrace complète
- Un `traceId` permet de retrouver le détail côté serveur

### 13.3 TC-112 : Injection SSML par consignes

**Given** :
- L'admin envoie `consignesSpecifiques` avec du contenu malicieux SSML : `<voice name="...">malicious</voice>`

**When** :
- La génération démarre

**Then** :
- Le backend nettoie l'input (échappement HTML)
- Le SSML final ne contient pas le contenu injecté tel quel
- Pas d'exécution de code

---

## 14. Tests manuels end-to-end

À effectuer manuellement après chaque déploiement, avec un vrai compte Anthropic + Azure + R2 :

### 14.1 TC-200 : Premier audio CO réel

1. Se connecter à l'admin avec un compte ADMIN
2. Cliquer sur "Générer une question audio"
3. Choisir niveau B1, thème santé
4. Cliquer sur "Générer"
5. Attendre la réponse (< 30s)
6. **Écouter le MP3** : voix naturelle, prononciation correcte, débit normal
7. **Lire le transcript** : correspond à l'audio
8. **Lire la question et les choix** : sensés et cohérents avec l'audio
9. Cliquer sur "Valider"
10. Vérifier que la question apparaît dans la liste des questions actives

### 14.2 TC-201 : Cycle de rejet

1. Générer une question
2. Cliquer sur "Rejeter"
3. Vérifier qu'elle disparaît de la liste DRAFT
4. Vérifier sur le dashboard R2 que le fichier MP3 est supprimé

### 14.3 TC-202 : Génération avec consignes spécifiques

1. Générer avec `consignesSpecifiques = "Discussion entre une étudiante étrangère et un agent de la préfecture pour le renouvellement de titre de séjour"`
2. Vérifier que le transcript reflète bien le contexte

---

## 15. Checklist pré-mise en production

Avant de pousser en prod, vérifier que :

- [ ] Tous les TC-001 à TC-102 passent (tests automatisés)
- [ ] Au moins 5 générations manuelles successives ont été validées et le MP3 est de qualité acceptable
- [ ] Les coûts sont conformes aux estimations (~0.01 € par génération)
- [ ] Les clés API en prod sont différentes des clés en dev
- [ ] Le bucket R2 de prod est différent du bucket dev
- [ ] Les logs Spring n'exposent aucune clé
- [ ] Le rate limiting fonctionne en prod (test sur 11 générations)
- [ ] Le job cron de cleanup tourne (vérifier les logs après 24h)
- [ ] Le monitoring (coûts mensuels, taux d'échec) est en place
- [ ] La documentation admin "Comment générer une question audio" est rédigée
