# 08 — Observabilité, monitoring et sécurité

## 1. Logging applicatif

### 1.1 Niveaux et structure

Utiliser SLF4J + Logback (par défaut dans Spring Boot). Format JSON pour faciliter l'ingestion dans un outil comme Loki, Datadog ou ELK.

```yaml
# application.yml
logging:
  level:
    root: INFO
    com.sejourfr.audioquestion: DEBUG
    com.sejourfr.audioquestion.service.AnthropicClient: INFO
    com.sejourfr.audioquestion.service.AzureSpeechClient: INFO
    com.sejourfr.audioquestion.service.CloudflareR2Client: INFO
  pattern:
    console: '{"ts":"%d{ISO8601}","level":"%level","logger":"%logger","traceId":"%X{traceId}","spanId":"%X{spanId}","msg":"%msg"}%n'
```

### 1.2 Logs obligatoires par phase

| Phase | Niveau | Contenu | Exemple |
|---|---|---|---|
| Démarrage requête | INFO | adminId, paramètres (sans secrets) | `Génération audio demandée niveau=B1 theme=sante par admin=abc123` |
| Avant appel Anthropic | DEBUG | model, max_tokens | `Anthropic call model=claude-sonnet-4-6 maxTokens=2000` |
| Après appel Anthropic | INFO | inputTokens, outputTokens, durationMs | `Anthropic réponse OK input=1240 output=580 duration=3200ms` |
| Validation JSON | DEBUG | OK ou détail erreur | — |
| Avant appel Azure | DEBUG | nbCaracteres, voices | `Azure TTS call chars=312 voices=2` |
| Après appel Azure | INFO | sizeMp3Bytes, durationMs | `Azure TTS OK size=45000 duration=1800ms` |
| Avant upload R2 | DEBUG | objectKey, contentLength | — |
| Après upload R2 | INFO | objectKey, publicUrl, durationMs | `R2 upload OK key=audio/abc.mp3 duration=400ms` |
| Insertion DB | INFO | questionId | `Question créée id=xyz status=DRAFT` |
| Validation admin | INFO | questionId, adminId | `Question xyz validée par admin abc` |
| Rejet admin | INFO | questionId, adminId | `Question xyz rejetée par admin abc, R2 cleanup OK` |
| Erreur | ERROR | code, message, stacktrace | `Erreur génération code=AZURE_SPEECH_API_ERROR ...` |

### 1.3 Règles de log

**À ne JAMAIS logger** :
- Les clés API en clair (Anthropic, Azure, R2)
- Le contenu intégral du `transcript` (volumineux et inutile dans les logs)
- Le SSML complet
- Les bytes MP3
- Les tokens Bearer Azure

**À TOUJOURS logger** :
- L'`adminUserId` pour traçabilité
- Le `traceId` (via Micrometer/OpenTelemetry)
- Les compteurs (tokens, characters, durée)
- Les codes d'erreur (pas les messages stack complets en INFO/WARN)

### 1.4 Implementation : MDC pour le traceId

```java
@Component
public class TraceIdFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        String traceId = request.getHeader("X-Request-Id");
        if (traceId == null) {
            traceId = UUID.randomUUID().toString();
        }
        MDC.put("traceId", traceId);
        response.setHeader("X-Request-Id", traceId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

---

## 2. Métriques (Micrometer)

### 2.1 Métriques à exposer

| Métrique | Type | Tags | Description |
|---|---|---|---|
| `audio_generation_total` | Counter | `status` (success/failed_*), `level` (A2/B1/B2) | Nombre total de générations |
| `audio_generation_duration` | Timer | `level` | Durée totale par niveau |
| `audio_anthropic_duration` | Timer | — | Durée appel Anthropic |
| `audio_azure_duration` | Timer | — | Durée appel Azure |
| `audio_r2_duration` | Timer | — | Durée upload R2 |
| `audio_anthropic_tokens` | Summary | `direction` (input/output) | Distribution des tokens consommés |
| `audio_azure_characters` | Summary | — | Distribution des caractères synthétisés |
| `audio_cost_eur_total` | Counter | `provider` (anthropic/azure) | Coût cumulé |
| `audio_rate_limit_hits` | Counter | `admin_id` | Nombre de blocages rate limit |

### 2.2 Code

```java
@Service
@RequiredArgsConstructor
public class AudioMetricsService {

    private final MeterRegistry meterRegistry;

    public void recordGeneration(String level, String status, long durationMs) {
        Counter.builder("audio_generation_total")
            .tag("level", level)
            .tag("status", status)
            .register(meterRegistry)
            .increment();

        Timer.builder("audio_generation_duration")
            .tag("level", level)
            .register(meterRegistry)
            .record(durationMs, TimeUnit.MILLISECONDS);
    }

    public void recordAnthropicCall(int inputTokens, int outputTokens, long durationMs) {
        Timer.builder("audio_anthropic_duration").register(meterRegistry)
            .record(durationMs, TimeUnit.MILLISECONDS);
        DistributionSummary.builder("audio_anthropic_tokens")
            .tag("direction", "input").register(meterRegistry).record(inputTokens);
        DistributionSummary.builder("audio_anthropic_tokens")
            .tag("direction", "output").register(meterRegistry).record(outputTokens);
    }

    public void recordCost(String provider, BigDecimal costEur) {
        Counter.builder("audio_cost_eur_total")
            .tag("provider", provider)
            .register(meterRegistry)
            .increment(costEur.doubleValue());
    }
}
```

### 2.3 Endpoint Prometheus

Activer dans `application.yml` :

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    prometheus:
      enabled: true
```

URL : `GET /actuator/prometheus`

---

## 3. Dashboards recommandés

### 3.1 Dashboard "Audio Generation"

Tuiles à afficher :

1. **Générations / jour** (graphique linéaire 30j)
2. **Taux de succès** (gauge, alerte si < 90%)
3. **Coût mensuel cumulé** (gauge avec budget de référence, ex: 50€/mois)
4. **Durée P50/P95/P99 par niveau** (graphique)
5. **Top 5 admins par volume** (liste)
6. **Répartition par status** (camembert : SUCCESS / FAILED_*)
7. **Coûts par provider** (Anthropic vs Azure)
8. **Distribution des durées d'audio** (histogramme)

### 3.2 Alertes

| Alerte | Condition | Action |
|---|---|---|
| Taux d'échec élevé | > 20% sur 1h | Investigation immédiate |
| Coût mensuel | > 80% du budget | Notification équipe |
| Latence anormale | P95 > 60s sur 1h | Investigation |
| Rate limit fréquent | > 10 hits/h | Vérifier abus |
| Anthropic 5xx > 50% | sur 15min | Page on-call |
| Azure 5xx > 50% | sur 15min | Page on-call |

---

## 4. Sécurité des secrets

### 4.1 En développement

Utiliser un fichier `.env` (non commité) avec [dotenv-spring](https://github.com/paulschwarz/spring-dotenv).

```bash
# .env (à ajouter dans .gitignore)
ANTHROPIC_API_KEY=sk-ant-test-...
AZURE_SPEECH_KEY=test-...
R2_ACCESS_KEY_ID=test-...
R2_SECRET_ACCESS_KEY=test-...
```

### 4.2 En production

**À retenir : aucune clé en clair dans la config**. Options classées par maturité :

**Option 1 — Variables d'environnement du conteneur** (minimum acceptable)
- Set via le système d'orchestration (Kubernetes Secrets, Docker secrets, ECS task definition)
- Toujours mieux que un fichier texte

**Option 2 — Vault / Secret Manager** (recommandé en prod)
- HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager
- Le backend récupère les secrets au démarrage via SDK
- Rotation automatique possible

**Option 3 — Sealed Secrets / SOPS** (DevOps avancé)
- Secrets chiffrés dans le repo Git, déchiffrés à l'application

Quel que soit le choix : **aucun secret ne doit apparaître dans Git, ni dans les logs, ni dans les réponses HTTP**.

### 4.3 Rotation des clés

Plan de rotation recommandé :

- **Anthropic** : tous les 6 mois
- **Azure Speech** : tous les 6 mois (Azure permet 2 clés actives, rotation sans downtime)
- **Cloudflare R2** : tous les 6 mois

Procédure :
1. Créer une nouvelle clé chez le fournisseur
2. Mettre à jour la config en prod (env var ou Vault)
3. Redéployer
4. Vérifier que la génération fonctionne
5. Révoquer l'ancienne clé chez le fournisseur

### 4.4 Détection de fuite

Mettre en place un scan automatique des commits pour détecter les fuites :

```bash
# Pre-commit hook (avec git-secrets)
git secrets --register-aws
git secrets --add 'sk-ant-[A-Za-z0-9_-]+'  # Anthropic
git secrets --add '[A-Za-z0-9]{32}'        # Azure Speech (32 char keys)
```

---

## 5. Sécurité applicative

### 5.1 Validation stricte des entrées

Tout endpoint admin valide :

- **Format** : Bean Validation (`@Valid`, `@Pattern`, `@Size`)
- **Whitelist** : niveau, thème, type, compétence appartiennent à des listes fermées
- **Longueur** : pas de payloads géants (max 500 chars sur `consignesSpecifiques`)
- **Échappement** : tout texte entrant est échappé HTML avant log/affichage

### 5.2 Protection contre l'abus

- **Rate limiting** : 10 générations / min / admin (déjà spécifié)
- **Quota mensuel** : optionnel, configurable. Ex: 500 générations / mois / admin
- **Détection d'anomalies** : alerte si un admin génère > 100 questions en 1h (potentiel script automatisé)

### 5.3 Audit des accès

Pour chaque appel admin, enregistrer :
- `adminUserId`
- `ip` (header `X-Forwarded-For` si derrière proxy)
- `userAgent`
- `endpoint` et `method`
- `timestamp`
- `responseStatus`

Ces logs vont dans une table dédiée `admin_access_log` (en dehors du scope de cette feature, mais à vérifier qu'elle existe).

---

## 6. Tests de sécurité

### 6.1 Tests automatisés

À inclure dans la suite CI :

- ✅ Vérifier qu'aucune clé n'apparaît dans les logs (regex sur fichier de log de test)
- ✅ Vérifier qu'un utilisateur non-ADMIN reçoit 403
- ✅ Vérifier qu'un token expiré reçoit 401
- ✅ Vérifier qu'une injection SSML est neutralisée

### 6.2 Tests manuels périodiques

- Tous les 3 mois : tentative de scan des secrets dans le repo (TruffleHog, GitLeaks)
- Tous les 6 mois : revue des accès et rotation des clés

---

## 7. Surveillance des coûts

### 7.1 Calcul du coût en temps réel

Stocké dans `audio_question_generation_logs.anthropic_cost_eur` et `azure_cost_eur` à chaque génération.

### 7.2 Requêtes utiles

```sql
-- Coût mensuel
SELECT
    DATE_TRUNC('month', created_at) AS month,
    SUM(anthropic_cost_eur) AS anthropic_cost,
    SUM(azure_cost_eur) AS azure_cost,
    SUM(anthropic_cost_eur + azure_cost_eur) AS total_cost,
    COUNT(*) AS generations
FROM audio_question_generation_logs
WHERE status = 'SUCCESS'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- Top 10 admins consommateurs
SELECT
    admin_user_id,
    COUNT(*) AS generations,
    SUM(anthropic_cost_eur + azure_cost_eur) AS total_cost_eur
FROM audio_question_generation_logs
WHERE status = 'SUCCESS'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY admin_user_id
ORDER BY total_cost_eur DESC
LIMIT 10;

-- Coût moyen par niveau
SELECT
    (requested_params->>'niveau') AS niveau,
    COUNT(*) AS generations,
    AVG(anthropic_cost_eur + azure_cost_eur) AS avg_cost_eur,
    MAX(anthropic_cost_eur + azure_cost_eur) AS max_cost_eur
FROM audio_question_generation_logs
WHERE status = 'SUCCESS'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY niveau;
```

### 7.3 Budget mensuel

Configuration recommandée :

```yaml
sejourfr:
  audio-generation:
    monthly-budget-eur: 50.00
    budget-alert-threshold: 0.80  # alerte à 80%
```

Service qui calcule le budget consommé et alerte :

```java
@Service
@RequiredArgsConstructor
public class BudgetMonitorService {

    private final AudioQuestionGenerationLogRepository logRepo;
    private final AudioGenerationProperties props;
    private final NotificationService notifier;

    @Scheduled(cron = "0 0 9 * * *")  // tous les jours à 9h
    public void checkBudget() {
        BigDecimal consumed = logRepo.sumCostForCurrentMonth();
        BigDecimal budget = props.monthlyBudgetEur();
        BigDecimal ratio = consumed.divide(budget, 4, RoundingMode.HALF_UP);

        if (ratio.compareTo(props.budgetAlertThreshold()) >= 0) {
            notifier.notifyAdmins(String.format(
                "⚠️ Budget audio à %s%% : %s€ / %s€ consommés ce mois-ci",
                ratio.multiply(BigDecimal.valueOf(100)).setScale(0),
                consumed.setScale(2),
                budget
            ));
        }
    }
}
```

---

## 8. Health checks

### 8.1 Endpoints

```
GET /actuator/health           — santé globale
GET /actuator/health/anthropic — santé Anthropic
GET /actuator/health/azure     — santé Azure Speech
GET /actuator/health/r2        — santé Cloudflare R2
```

### 8.2 Implémentation des Health Indicators

```java
@Component
@RequiredArgsConstructor
public class AnthropicHealthIndicator implements HealthIndicator {

    private final WebClient anthropicWebClient;
    private final AnthropicProperties props;

    @Override
    public Health health() {
        try {
            // Appel minimal : juste vérifier que l'endpoint répond
            // (sans consommer de tokens, on peut faire une requête en HEAD ou un appel vide)
            // En pratique : vérifier qu'on a un cache valide d'un appel récent réussi
            // ou faire un ping périodique léger
            return Health.up()
                .withDetail("provider", "Anthropic")
                .withDetail("model", props.model())
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

---

## 9. Documentation utilisateur (admin)

À fournir avec le projet, sous forme de petit guide :

### 9.1 Comment générer une question audio

1. Aller dans **Admin → Questions → Compréhension Orale**
2. Cliquer sur **"Générer une question audio"**
3. Renseigner le formulaire :
   - **Niveau** (obligatoire) : A2, B1 ou B2
   - **Thème** (optionnel) : si laissé vide, l'IA choisit
   - **Type** (optionnel) : annonce, dialogue, monologue...
   - **Compétence** (optionnel) : reperage_explicite, inference...
   - **Consignes spécifiques** (optionnel) : contexte particulier
4. Cliquer sur **"Générer"**
5. Attendre 15-30 secondes
6. **Écouter** l'audio généré
7. **Lire** le transcript et vérifier la cohérence
8. **Lire** la question et les 4 choix
9. **Lire** l'explication
10. Cliquer sur **"Valider"** pour activer la question, ou **"Rejeter"** pour recommencer

### 9.2 Que faire si la qualité ne convient pas

- Cliquer sur **"Rejeter"** : la question est supprimée et l'audio aussi
- Cliquer sur **"Régénérer"** : nouvelle tentative (avec mêmes paramètres ou ajustés)

### 9.3 Coût et quotas

- Chaque génération coûte environ 1 centime à l'application
- Limite : 10 générations par minute par admin
- Budget mensuel : 50 € (à ajuster si nécessaire)
