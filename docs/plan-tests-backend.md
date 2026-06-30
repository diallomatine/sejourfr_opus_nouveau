# Plan — Tests backend SejourFR

Branche : `test/backend-coverage` (depuis `develop`).

## Objectif

Couvrir **toutes** les couches du backend (managers, services, controllers + droits,
mappers, specifications) par des tests automatisés, puis assainir l'architecture des gros
services **sous filet de tests** (refacto sans régression).

## Décisions structurantes

| Sujet | Choix | Pourquoi |
|-------|-------|----------|
| DB de test | **Postgres embarqué (Zonky `embedded-postgres`)** | 221 migrations Flyway très PG-spécifiques (index partiels `WHERE`, `interval`, casts `::`, `jsonb`). H2 diverge. Testcontainers exige Docker (indisponible ici + en CI sans daemon). Zonky lance un **vrai binaire Postgres** sans Docker → parité 100 %, Flyway tourne pour de vrai, `ddl-auto: validate` devient un test gratuit du mapping JPA. |
| Lib d'intégration | `io.zonky.test:embedded-postgres` (binaire bas-niveau) piloté nous-mêmes via `@DynamicPropertySource` | Découplé de la version Spring Boot (4.0.6 récent) — on ne dépend pas d'une auto-config tierce compatible Boot 4. |
| Ordre tests / refacto | **Tests d'abord, refacto ensuite** | Seul ordre qui mène à une archi propre sans régression silencieuse. |
| Découpage des suites | `*Test` = unitaire (surefire, rapide, mocks) · `*IT` = intégration (failsafe, vrai PG) | Build rapide par défaut ; l'intégration tourne en phase `integration-test`. |
| Couverture | JaCoCo (rapport, pas de gate bloquant au début) | Mesure objective, gate à activer plus tard. |

## Stratégie par couche

- **Managers** (`*ManagerIT`) : intégration réelle PG. Vérifient requêtes JPA, specifications,
  `limit`, tri, contraintes uniques, cascades. C'est là que le vrai PG paie.
- **Services unitaires** (`*Test`) : Mockito pur (managers/clients mockés). Règles métier,
  freemium, quotas, branches d'erreur. Rapides, majoritaires.
- **Services d'intégration** (`*IT`) : quand le cas d'usage traverse réellement le DB
  (transactions, état persistant, multi-manager) — ciblé, pas systématique.
- **Controllers + droits** (`*ControllerIT`) : `@SpringBootTest` + `MockMvc`, **vrai JWT
  Bearer** sur user seedé → exerce le filtre JWT + `SecurityConfig`. Pour chaque endpoint :
  - anonyme → **401** (routes protégées) ou 200 (routes `permitAll`)
  - USER sur route `/api/admin/**` → **403**
  - rôle attendu → **200** + forme de réponse.
- **Mappers / specifications** : unitaires purs.

## Infra (mise en place)

- `pom.xml` : deps test Zonky + binaires (`darwin-arm64v8` local, `linux-amd64` CI),
  `maven-failsafe-plugin`, `jacoco-maven-plugin`.
- `src/test/resources/application-test.yaml` : profil `test`, Flyway `classpath:db/migration`
  uniquement (pas de seed dev), secret JWT de test, mail/rate-limit neutralisés, clés externes
  vides (→ 503 inerte).
- `src/test/java/.../support/` :
  - `EmbeddedPostgresHolder` — singleton JVM (1 PG démarré, réutilisé par toutes les classes).
  - `AbstractIntegrationTest` — `@SpringBootTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")`
    + `@DynamicPropertySource`.
  - `TestData` — fabriques d'entités (User, Theme, Question, Attempt…).
  - `AuthTestSupport` — mint d'un access token réel + header `Authorization`.

## Séquencement (pas à pas)

1. **Infra + smoke test** : contexte démarre, 221 migrations passent, `validate` OK. ← risque #1
2. **Tests de référence** (1 par couche) validés par l'utilisateur → gabarit figé.
3. **Fan-out** : couverture complète par vagues (managers → services → controllers).
4. **Refacto** : split des gros services (AttemptService 1252 l., FullTcfExamService, billing)
   sous tests verts.

## État

- [x] Branche créée
- [x] Infra + smoke test (PG embarqué 16.2, 221 migrations OK, `validate` OK)
- [x] Tests de référence (UserManagerIT, ThemeServiceIT, ThemeControllerSecurityIT)
- [x] Fan-out couverture : **858 tests verts** (424 unit + 434 IT)
  - Managers : 23 fichiers IT (requêtes, tris, filtres, specifications, contraintes)
  - Controllers : matrice de droits data-driven (120 tests, 3 fichiers) — tous les
    controllers, 401/403/200 par rôle, **aucune faille trouvée**
  - Services : ~56 services (unit Mockito + IT DB) — freemium, billing, quotas,
    transitions de statut, mapping, RGPD, etc.
  - Couverture JaCoCo : ~47 % instr (unit) + 40 % instr (IT), complémentaires
- [ ] Optionnel : mappers (13) + specifications (3)
- [ ] Refacto archi (gros services) sous filet de tests

## Gabarits validés (à reproduire au fan-out)

- **Manager/repo** : `class XManagerIT extends AbstractIntegrationTest` + `@Autowired XManager`.
  Tester requêtes, tris, `limit`, specifications, contraintes. Pour une violation de
  contrainte traduite en `DataIntegrityViolationException`, passer par `repository.saveAndFlush`.
- **Service unitaire** (défaut, rapide) : Mockito pur, pas de contexte Spring (cf.
  `FullTcfExamServiceFreemiumTest` existant). Mocker les managers/clients.
- **Service + DB** : `class XServiceIT extends AbstractIntegrationTest` quand le cas traverse
  la base (transactions, état persistant).
- **Controller + droits** : `class XControllerSecurityIT extends AbstractIntegrationTest`,
  `@Autowired MockMvc/TestData/AuthTestSupport`. Matrice anonyme(401) / USER(403 sur admin) /
  rôle attendu(200/201) / body invalide(400). En-tête `Authorization: auth.bearer(user)`.
- Données : `TestData.user()/admin()/theme()` (séquence unique). Rollback auto (`@Transactional`
  sur la base) → pas de pollution inter-tests.
