# 05 — Règles métier et validation

## 1. Listes blanches (référence)

### 1.1 Niveaux autorisés

```java
public enum AudioLevel {
    A2,
    B1,
    B2
}
```

### 1.2 Thèmes autorisés

```java
public enum AudioTheme {
    VIE_PRATIQUE_LOGEMENT("vie_pratique_logement"),
    TRAVAIL("travail"),
    SANTE("sante"),
    ADMINISTRATIF("administratif"),
    TRANSPORTS("transports"),
    CONSOMMATION("consommation"),
    MEDIAS_NUMERIQUE("medias_numerique"),
    ENVIRONNEMENT("environnement");

    private final String code;
    // constructeur, getter
}
```

### 1.3 Types de support autorisés

```java
public enum AudioContentType {
    ANNONCE,        // annonce gare, supermarché, attente téléphonique
    MONOLOGUE,      // message répondeur, météo, info courte
    DIALOGUE,       // conversation à 2-3 voix
    INTERVIEW,      // questions/réponses entre journaliste et invité
    REPORTAGE       // journaliste seul, présentation d'un sujet
}
```

### 1.4 Compétences CO autorisées

```java
public enum CompetenceCo {
    CO_REPERAGE_EXPLICITE("co_reperage_explicite"),
    CO_DETAIL_SPECIFIQUE("co_detail_specifique"),
    CO_IDEE_PRINCIPALE("co_idee_principale"),
    CO_INFERENCE_INTENTION("co_inference_intention"),
    CO_TON_ATTITUDE("co_ton_attitude"),
    CO_REFORMULATION("co_reformulation");

    private final String code;
    // constructeur, getter
}
```

### 1.5 Voix Azure Speech autorisées (whitelist)

```java
public static final Set<String> ALLOWED_AZURE_VOICES = Set.of(
    // Femmes — jeunes
    "fr-FR-DeniseNeural",
    "fr-FR-EloiseNeural",
    "fr-FR-CelesteNeural",
    // Femmes — matures
    "fr-FR-BrigitteNeural",
    "fr-FR-YvetteNeural",
    "fr-FR-CoralieNeural",
    // Femmes — professionnelles
    "fr-FR-VivienneNeural",
    "fr-FR-JosephineNeural",
    // Hommes — jeunes
    "fr-FR-MauriceNeural",
    "fr-FR-JeromeNeural",
    "fr-FR-RemyNeural",
    // Hommes — matures
    "fr-FR-HenriNeural",
    "fr-FR-AlainNeural",
    "fr-FR-ClaudeNeural"
);
```

---

## 2. Règles de calibrage par niveau

### 2.1 A2

| Critère | Valeur attendue |
|---|---|
| Durée audio | 15 — 30 secondes |
| Caractères transcript | 150 — 300 |
| Mots transcript | 30 — 50 |
| Nombre de voix typique | 1 (parfois 2 pour mini-dialogue) |
| Types favorisés | annonce, monologue |
| Compétences favorisées | `co_reperage_explicite`, `co_detail_specifique` |

### 2.2 B1

| Critère | Valeur attendue |
|---|---|
| Durée audio | 30 — 60 secondes |
| Caractères transcript | 400 — 700 |
| Mots transcript | 70 — 130 |
| Nombre de voix typique | 1 ou 2 |
| Types favorisés | dialogue, monologue, annonce élargie |
| Compétences favorisées | toutes, surtout `co_detail_specifique`, `co_inference_intention`, `co_reformulation` |

### 2.3 B2

| Critère | Valeur attendue |
|---|---|
| Durée audio | 60 — 120 secondes |
| Caractères transcript | 900 — 1500 |
| Mots transcript | 150 — 280 |
| Nombre de voix typique | 1 (reportage) à 3 (débat) |
| Types favorisés | interview, reportage, dialogue complexe |
| Compétences favorisées | `co_inference_intention`, `co_ton_attitude`, `co_idee_principale` |

### 2.4 Validations backend (côté serveur, après réception du JSON Claude)

Le backend doit lever une exception `ContentValidationException` si :

- La durée estimée est en dehors de ±30% de la fourchette du niveau
- Le nombre de voix dans `voices[]` ne correspond pas à `speakerCount`
- Une voix utilisée dans le SSML n'est pas dans la whitelist
- Le SSML ne contient pas toutes les voix déclarées dans `voices[]`
- Le `transcript` extrait du SSML (sans balises) ne correspond pas au champ `transcript` (tolérance : différences de whitespace)
- Plus d'1 choix avec `isCorrect: true`, ou aucun
- Les `displayOrder` ne forment pas l'ensemble {1, 2, 3, 4}

---

## 3. Anti-doublons

### 3.1 Détection automatique

Avant d'insérer en base, vérifier qu'il n'existe pas déjà une question avec un transcript "très similaire" :

```java
@Query(value = """
    SELECT m.transcript FROM medias m
    JOIN questions q ON q.media_id = m.id
    WHERE q.module = 'TCF'
      AND q.question_type = 'CO'
      AND q.difficulty = :difficulty
      AND similarity(m.transcript, :transcript) > 0.85
    LIMIT 1
    """, nativeQuery = true)
Optional<String> findSimilarTranscript(
    @Param("difficulty") String difficulty,
    @Param("transcript") String transcript
);
```

Cette requête utilise l'extension PostgreSQL `pg_trgm`. Si une similarité > 0.85 est détectée, le backend retourne une erreur 409 et propose de régénérer.

Migration nécessaire pour activer l'extension :

```sql
-- V14_b (peut être intégré à V14)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 3.2 Code

```java
@Service
public class DuplicateDetectionService {

    private final MediaRepository mediaRepository;

    public void checkNotDuplicate(String transcript, String difficulty) {
        mediaRepository.findSimilarTranscript(difficulty, transcript)
            .ifPresent(existing -> {
                throw new DuplicateContentException(
                    "Un audio très similaire existe déjà au niveau " + difficulty
                );
            });
    }
}
```

---

## 4. Validation du SSML

### 4.1 Validation XML

```java
package com.sejourfr.audioquestion.validation;

import org.xml.sax.InputSource;
import javax.xml.parsers.SAXParserFactory;
import java.io.StringReader;

public class SsmlValidator {

    public void validate(String ssml) {
        try {
            SAXParserFactory factory = SAXParserFactory.newInstance();
            factory.setNamespaceAware(true);
            factory.newSAXParser().parse(
                new InputSource(new StringReader(ssml)),
                new org.xml.sax.helpers.DefaultHandler()
            );
        } catch (Exception e) {
            throw new SsmlValidationException(
                "Le SSML renvoyé par Claude n'est pas un XML valide", e
            );
        }
    }
}
```

### 4.2 Validation sémantique

- Le tag racine doit être `<speak version="1.0" xml:lang="fr-FR">`
- Au moins un tag `<voice name="...">` doit être présent
- Toutes les valeurs de `name=` doivent être dans `ALLOWED_AZURE_VOICES`
- Les tags `<break>` doivent avoir un attribut `time` au format `"\d+(ms|s)"`

```java
public class SsmlSemanticValidator {

    public void validate(String ssml, List<VoiceInfo> declaredVoices) {
        // Parser le SSML, extraire toutes les voix utilisées
        Set<String> usedVoices = extractVoices(ssml);

        // Vérifier qu'elles sont toutes whitelistées
        for (String voice : usedVoices) {
            if (!ALLOWED_AZURE_VOICES.contains(voice)) {
                throw new SsmlValidationException("Voix non autorisée : " + voice);
            }
        }

        // Vérifier la cohérence avec voices[]
        Set<String> declaredVoiceNames = declaredVoices.stream()
            .map(VoiceInfo::azureVoice)
            .collect(Collectors.toSet());

        if (!usedVoices.equals(declaredVoiceNames)) {
            throw new SsmlValidationException(
                "Mismatch entre voix déclarées et voix utilisées dans le SSML"
            );
        }
    }
}
```

---

## 5. Comptage des caractères pour facturation Azure

Azure facture **les caractères du texte effectivement parlé**, pas le SSML entier. Il faut donc extraire le texte des balises `<voice>` :

```java
public int countSpeechCharacters(String ssml) {
    // Extraire tout le texte entre les balises <voice>
    // Compter les caractères (espaces inclus)
    // Les balises <break/> sont gratuites (ne pas les compter)
    // Les attributs ne sont pas comptés
    Document doc = parseXml(ssml);
    NodeList voiceNodes = doc.getElementsByTagName("voice");

    int total = 0;
    for (int i = 0; i < voiceNodes.getLength(); i++) {
        String text = voiceNodes.item(i).getTextContent();
        total += text.length();
    }
    return total;
}
```

---

## 6. Rate limiting

### 6.1 Règle

- **Max 10 générations par minute** par admin
- Mesure sur les 60 dernières secondes glissantes
- Seuls les `SUCCESS` comptent (pas les échecs)
- Si dépassé : erreur 429 + header `Retry-After: <seconds>`

### 6.2 Implémentation (Spring + Caffeine)

```java
@Service
@RequiredArgsConstructor
public class GenerationRateLimiter {

    private final AudioQuestionGenerationLogRepository logRepository;

    private static final int MAX_PER_MINUTE = 10;

    public void checkAllowed(UUID adminUserId) {
        Instant oneMinuteAgo = Instant.now().minus(Duration.ofMinutes(1));
        long recent = logRepository.countByAdminUserIdAndStatusAndCreatedAtAfter(
            adminUserId,
            GenerationStatus.SUCCESS,
            oneMinuteAgo
        );

        if (recent >= MAX_PER_MINUTE) {
            // Calculer le délai d'attente
            Instant oldest = logRepository.findOldestRecentSuccess(adminUserId, oneMinuteAgo)
                .orElse(oneMinuteAgo);
            long secondsToWait = 60 - Duration.between(oldest, Instant.now()).getSeconds();

            throw new RateLimitExceededException(
                "Trop de générations en 1 minute. Réessayez dans " + secondsToWait + "s",
                secondsToWait
            );
        }
    }
}
```

---

## 7. Convention de nommage et IDs

### 7.1 UUIDs des entités générées

- **Media** : généré automatiquement (`gen_random_uuid()`)
- **Question** : généré automatiquement
- **Choice** : généré automatiquement
- Les UUIDs ne suivent **pas** la convention des seeds manuels (`33333333-0014-...`). Ce sont des UUIDs aléatoires standards, car ils n'ont pas vocation à être réutilisés dans d'autres migrations.

### 7.2 Nom du fichier audio sur R2

`audio/<media_uuid>.mp3`

Exemple : `audio/d8f1b3c5-7a2e-4b9f-9c1d-8e3a5b7c2d1e.mp3`

---

## 8. Politique d'annulation et rollback

### 8.1 Si l'admin "Rejette" la prévisualisation

Le backend doit :

1. Vérifier que la question est en statut `DRAFT` (sinon 409)
2. Supprimer le fichier MP3 de Cloudflare R2 (best-effort, ne pas bloquer si échec)
3. DELETE en cascade dans cet ordre : choices → question → media
4. Mettre à jour l'entrée d'audit avec une note "REJECTED_BY_ADMIN"

### 8.2 Si erreur en cours de pipeline

Le backend doit :

1. Si erreur après upload R2 mais avant insertion DB → supprimer le MP3 de R2
2. Si erreur après insertion partielle DB → rollback transactionnel Spring
3. Logger dans `audio_question_generation_logs` avec le statut FAILED_* approprié
4. Retourner une erreur HTTP claire avec un `code` exploitable côté front

### 8.3 Transaction Spring

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class AudioQuestionGenerationService {

    @Transactional
    public QuestionPreviewDto generate(GenerateAudioQuestionRequest request, UUID adminId) {
        // Étape 1 : appel Anthropic (hors transaction DB)
        AnthropicGenerationResponse claudeResponse = anthropicClient.generate(...);

        // Étape 2 : synthèse Azure (hors transaction DB)
        byte[] mp3Bytes = azureSpeechClient.synthesize(claudeResponse.audio().ssml());

        // Étape 3 : upload R2 (hors transaction DB, mais on capture l'objectKey pour rollback)
        UUID mediaId = UUID.randomUUID();
        R2UploadResult r2Result = cloudflareR2Client.uploadAudio(mediaId, mp3Bytes);

        try {
            // Étape 4 : transaction DB
            // Si elle échoue, le rollback Spring annule les inserts.
            // Mais le fichier sur R2 reste → on le supprime dans le catch.
            return persistInTransaction(mediaId, claudeResponse, r2Result, adminId);
        } catch (Exception e) {
            // Rollback R2 manuel
            try {
                cloudflareR2Client.deleteAudio(r2Result.objectKey());
            } catch (Exception cleanupError) {
                log.error("Échec du cleanup R2 pour {} : {}", r2Result.objectKey(), cleanupError.getMessage());
            }
            throw e;
        }
    }
}
```

---

## 9. Logging des actions sensibles

Toutes les actions suivantes doivent être loggées (en plus du log d'audit DB) :

- Démarrage d'une génération (niveau INFO)
- Appel Anthropic réussi (niveau DEBUG, sans le contenu)
- Appel Azure Speech réussi (niveau DEBUG)
- Upload R2 réussi (niveau DEBUG)
- Insertion DB réussie (niveau INFO)
- Validation par admin (niveau INFO)
- Rejet par admin (niveau INFO)
- Toute erreur (niveau ERROR avec stacktrace)

**Ne jamais logger** :
- Les clés API (Anthropic, Azure, R2)
- Le contenu complet du transcript (pour des questions de poids des logs)
- Les tokens Azure
