# SejourFR — AUDIT (PHASE 0)

> Répond au brief `00_SEJOURFR_SPEC_MAITRE.md` §2. Plan imposé respecté (10 sections).
> **Aucun fichier de code, de migration ou de configuration n'a été modifié pour produire cet audit.**
> Date de l'audit : **2026-09-09**. Branche : `develop` (après merge de `feature/progression-engine-v4-2`).
> Base mesurée : Postgres local `sejourfr_db`, dernière migration appliquée **V045**.

---

## Avertissement de lecture — l'écart principal n'est pas dans le code, il est dans la spec

Les quatre documents de `docs/review_all/` décrivent l'application **telle qu'elle était avant
plusieurs chantiers déjà livrés**. Trois hypothèses fondatrices de la spec sont fausses aujourd'hui :

| Hypothèse de la spec | Réalité mesurée |
|---|---|
| « Web (Angular) » (`00_` §1.1, `30_` §13 « matrice Angular / Flutter ») | Le web est **Next.js 16 App Router / React 19**. Il n'y a aucun Angular dans le dépôt. La matrice de parité `30_` §13 est à réécrire colonne par colonne. |
| « CO, EE et EO ne sont pas encore modélisés » (`00_` §1.1) | **CO est entièrement modélisée et audio-couverte** (560 questions, 560 audios, 630 transcriptions). **EE et EO ont un modèle complet** : tâches, sujets, soumissions, transcription Whisper, correcteur LLM versionné v4→v15, rapports, exemples, examinateur vocal temps réel Gemini. |
| « Micro-exercices de compétence : nouveau » (`00_` §1.2) | Le **module Compétences existe et est peuplé** : 48 compétences, **720 sujets courts**, 2 160 références pédagogiques, analyse IA dédiée (rubriques v1→v6). |

Un quatrième écart, plus lourd commercialement : la spec raisonne sur **14,99 €/mois + pack 3 mois**
(`00_` §A14, `10_` §5). Le dépôt n'a **plus aucun abonnement récurrent actif** : le modèle vivant est
celui des **pass à achat unique** (7 j / 1 mois / 2 mois / 3 mois civique / 1 an), 9,99 € à 79,99 €.
Tout le wording de paywall de `10_` §5 et `20_` §6 est donc à refaire avant implémentation.

Ce que la spec apporte réellement de neuf par rapport au dépôt : **le référentiel de notions
civiques** (§2 de `20_`), **la répétition espacée** (§5 de `20_`), le **diagnostic écrit rapide sans
compte** (`10_` §3) et le **diagnostic TCF 4 épreuves** (`10_` §4). Le reste est, à des degrés
divers, déjà là.

---

# 1. Inventaire technique

## 1.1. Versions

| Brique | Version relevée | Source |
|---|---|---|
| Java | **21** | `backend_sejourfr/pom.xml` (`<java.version>`) |
| Spring Boot | **4.0.6** | `pom.xml` (parent) |
| PostgreSQL | **16.14** (Homebrew, arm64) | `select version()` |
| Flyway | starter Spring Boot 4 + `flyway-database-postgresql` | `pom.xml` |
| Web | **Next.js 16.2.6**, React 19.2.4, TypeScript 5, Tailwind v4 (tokens seuls) | `web_sejoufr/package.json` |
| Admin | React 19.2.6, **Vite 8.0.12**, TS 6.0.2, TanStack Query 5.62, React Router 7.1 | `admin_sejourfr/package.json` |
| Mobile | **Flutter SDK ≥ 3.6.0 < 4**, Riverpod 2.6.1, Dio 5.7, go_router 14.6.2 | `mobile_sejourfr/pubspec.yaml` |
| Correcteur LLM (défaut) | `deepseek-v4-flash` via `EVAL_LLM_PROVIDER=deepseek` | `application.yaml` |
| Transcription | OpenAI `whisper-1`, 0,006 USD/min | `application.yaml` |
| Examinateur vocal | Gemini `gemini-live-2.5-flash-native-audio` | `application.yaml` |
| Génération audio CO | Anthropic `claude-opus-4-7` + Azure Speech | `application.yaml` |

**Il n'existe pas de workspace parent** : les 4 dossiers sont indépendants, un seul dépôt git les couvre.

## 1.2. Modules / packages backend

`backend_sejourfr/src/main/java/com/sejourfr/app/` — **87 942 lignes Java** (main).

| Package | Fichiers | Responsabilité |
|---|---|---|
| `service/` | 217 | Cas d'usage. Sous-paquets `analytics/ attempt/ billing/ competence/ diagnostic/ plan/ realtime/ social/ versionciblee/` |
| `dto/` | 157 | Contrats API (source de vérité des miroirs front) |
| `enums/` | 81 | Domaine métier |
| `progression/` | 62 | **Moteur de progression V4.2** — paquet autonome (config, domain, engine, entity, manager, mapper, repository, service, controller) |
| `audioquestion/` | 52 | Pipeline de génération audio CO — **sous-module isolé non migré** vers l'archi Controller→Service→Manager→Repository |
| `controller/` | 46 | Contrôleurs fins |
| `entity/` | 44 | Entités JPA |
| `repository/` | 42 | Accès données (appelés uniquement par les managers) |
| `manager/` | 39 | Seule couche autorisée à toucher les repositories |
| `config/` | 26 | Propriétés typées |
| `util/`, `mapper/`, `exception/`, `security/`, `specification/`, `ratelimit/` | 68 | Support |

**48 contrôleurs**, base `/api` (voir §1.5 pour l'écart avec le `/api/v1` de la spec).

## 1.3. Structure du front web (Next.js, pas Angular)

`web_sejoufr/` — **72 744 lignes TS/TSX**, **69 routes** (`page.tsx`), 87 composants dans `app/_components/`.

Regroupements :

- **Vitrine publique** : `/`, `/a-propos`, `/blog` (+ catégories, pagination), `/faq`, `/tarifs`, `/reussir`, `/cgu`, `/mentions-legales`, `/confidentialite`, `/contact`
- **Auth** : `/connexion`, `/inscription`, `/mot-de-passe-oublie`, `/reinitialiser-mot-de-passe`
- **Tunnel** : `/diagnostic`, `/paiement` (+ `/recapitulatif`, `/succes`)
- **Espace connecté** `(app)/` : `/dashboard`, `/plan` (+ `/competences`, `/domaine/[domaine]`, `/evolution`, `/progression`), `/parcours`, `/progression`, `/recommandations`, `/revision`, `/statistiques`, `/historique`, `/profil` (+ `/abonnement`)
- **Entraînement** : `/entrainement/civique/[theme]` (+ `/examens`), `/entrainement/tcf/[code]/[level]`, et l'arbre EE/EO complet — `tache/[n]`, `tache/[n]/competences/[skillId]/[promptId]` (+ `/resultat/[attemptId]`), `/redaction/[taskId]`, `/enregistrement/[taskId]`, `/session/[attemptId]`, `/resultats/[submissionId]`, `/historique`, `/exemples`
- **Examens** : `/examens-blancs` (+ `[slug]`, `/tcf/[id]`, `/tcf/[id]/bilan`), `/examen-blanc`, `/sessions/[attemptId]`

State : TanStack Query côté admin ; côté web, `lib/api.ts` + hooks locaux, pas de store global.
Styles : `globals.css` + `<style jsx>` scoped, **aucun utility-first Tailwind dans le markup**.

## 1.4. Structure de l'app Flutter

`mobile_sejourfr/lib/` — **77 017 lignes Dart**. 22 dossiers d'écrans :

`auth civique diagnostic exam examens help history home module_detail onboarding paywall plan
profile progres question_runner review reviser shell splash target_path tcf_full_exam tcf_production`

Couche données : `core/api` (Dio + refresh auto), `core/auth`, `core/models`, `core/router`
(go_router, ~40 chemins), `core/theme`, `core/utils`, `core/widgets`, `core/analytics`.

**Aucun cache offline** : `null` ; l'app est 100 % en ligne, conforme à l'arbitrage A15.
**Aucun mode invité sur mobile** : le redirect global renvoie tout non-authentifié vers `/login`,
l'allowlist se limite à l'aide, `/about` et `/diagnostic`.

## 1.5. Migrations Flyway

Arborescence `db/migration/` en 4 dossiers, **ordre donné par le numéro de version, pas par le dossier** :

| Dossier | Plage | Fichiers |
|---|---|---|
| `00_schema/` | V001–V099 | 45 |
| `100_reference/` | V100–V199 | 7 |
| `200_civique/` | V200–V299 | 5 sous-dossiers thématiques |
| `300_tcf/` | V300–V799 | 6 sous-dossiers (`ce_ co_ competences expression production structure_langue`) |

Dernières appliquées : **V045 `question difficulty band`**, V044 `progression engine`, V043 `analytics`.
`out-of-order: true` et `ignore-migration-patterns: "*:missing"` sont posés volontairement.

**Écart avec la spec** : la spec écrit toutes ses routes en `/api/v1/...`. Le dépôt n'a **pas de
versionnement d'URL** : tout est sous `/api/`. Introduire `/api/v1` créerait deux conventions
concurrentes sur les 48 contrôleurs. Recommandation §8.

---

# 2. Modèle de données existant

## 2.1. Tables réelles

```sql
select table_name from information_schema.tables where table_schema='public' order by 1;
```

**50 tables** (hors `flyway_schema_history`), regroupées par domaine :

| Domaine | Tables |
|---|---|
| Contenu QCM | `questions`, `choices`, `themes`, `passages`, `medias`, `exam_templates`, `exam_template_rules` |
| Passation | `attempts`, `attempt_questions`, `answers`, `user_question_statuses` |
| Production EE/EO | `production_tasks`, `production_submissions`, `production_examples`, `transcriptions`, `ai_evaluations`, `human_calibration_notes`, `realtime_sessions` |
| Compétences | `skills`, `skill_prompts`, `skill_references`, `user_skill_attempts` |
| Diagnostic | `diagnostic_sessions`, `diagnostic_task_skills`, `diagnostic_production_analyses` |
| Progression V4.2 | `learning_evidence`, `learning_evidence_invalidation`, `progression_state`, `progression_state_family_aggregate`, `progression_prediction_log`, `progression_content_signal`, `question_empirical_difficulty` |
| Plan | `learning_plan_observations` |
| Compte / accès | `users`, `refresh_tokens`, `password_reset_tokens`, `email_change_tokens`, `plans`, `user_subscriptions`, `legacy_pass_compensations`, `processed_external_events` |
| Mesure | `analytics_event`, `analytics_visitor`, `analytics_identity`, `analytics_annotation`, `user_funnel_events`, `page_views` |
| Support | `conversations`, `messages`, `audio_question_draft`, `audio_question_generation_logs` |

## 2.2. Écarts entre l'ERD de la spec et la base réelle

Tables **attendues par la spec et absentes** :

| Attendue (`10_` §11 / `20_` §10) | État |
|---|---|
| `tcf_task` | **Équivalent existant** : `production_tasks` (colonnes `epreuve`, `tache_numero`, `niveau_cible`, `duree_max_sec`, `mots_min/max`). ⚠ **Pas de `prep_seconds`** ni de `max_duration_seconds` distinct de `duree_max_sec`. |
| `quick_diag_subject` | **Absente.** Le diagnostic actuel tire ses sujets dans `production_tasks` via `diagnostic_code` + `diagnostic_version`. |
| `tcf_competence` / `tcf_task_competence` | **Équivalent existant** : `skills` (`section`, `task_code`, `code`, `title`, `target_level`) + `diagnostic_task_skills`. Les codes ne sont pas ceux de `10_` §2.3 (`ee_argumenter`…). |
| `tcf_subject` | **Équivalent existant** : `production_tasks` (une tâche = un sujet, pas de séparation tâche/sujet). |
| `tcf_micro_exercise` | **Équivalent existant** : `skill_prompts` (720 lignes) + `skill_references` (2 160). |
| `tcf_production` | **Équivalent existant** : `production_submissions` + `user_skill_attempts` (deux voies distinctes). ⚠ **Pas de `client_submission_id`** — aucune idempotence par UUID client. |
| `tcf_ai_report` | **Équivalent existant** : `ai_evaluations` (+ `diagnostic_production_analyses`, + `user_skill_attempts.analysis_json`). |
| `user_tcf_competence_state` | **Équivalent existant** : `progression_state` (moteur V4.2, plus riche). |
| `tcf_diagnostic` / `_section` / `_result` | **Partiel** : `diagnostic_sessions` (EE + EO seulement, pas 4 sections). Pas de table `_section`. |
| `tcf_plan` / `tcf_plan_item` / `tcf_plan_step` | **Absentes** : le Plan est **calculé à la lecture**, jamais matérialisé (`LearningPlanService`). Pas de `plan_version` persisté. |
| `ai_usage` | **Absente.** Le coût est porté par ligne d'évaluation (`ai_evaluations.cout_micro_usd`, `transcriptions.cout_micro_usd`, `user_skill_attempts.cout_micro_usd`), pas par une table de journal unifiée. |
| `civic_notion`, `civic_situation_domain`, `civic_question_notion_suggestion`, `user_civic_notion_progress`, `user_civic_situation_progress`, `civic_diagnostic*`, `civic_plan*`, `civic_theme_tagging_stats` | **Toutes absentes.** Vérifié : `grep -ril "civic_notion\|notion_id\|situation_domain"` → **0 fichier** dans les 4 sous-projets. |

Concepts **cités par la spec et introuvables dans le dépôt** (0 occurrence) :
`leitner`, `notion_id`, `civic_notion`, `situation_domain`, `anon_id` / `anonId`, `ai_usage`.

L'équivalent le plus proche d'`anon_id` est `analytics_visitor.anonymous_id` (UUID), **utilisé pour
la mesure d'audience uniquement** — il ne porte aucune production de candidat.

## 2.3. Table `questions`

```sql
\d questions
```

| Colonne | Type | Note |
|---|---|---|
| `id` | uuid | |
| `module` | varchar(16) | `CIVIQUE` \| `TCF` |
| `theme_id` | uuid NOT NULL | FK `themes` |
| `passage_id`, `media_id`, `audio_media_id` | uuid | `audio_media_id` **inutilisé** (0 ligne renseignée) |
| `difficulty` | varchar(8) NOT NULL | `CSP CR NAT` (civique) \| `A2 B1 B2` (TCF) |
| `question_type` | varchar(24) NOT NULL | |
| `statement`, `explanation` | text | |
| `is_active`, `status` | bool / varchar | `DRAFT ACTIVE ARCHIVED` |
| `tcf_sub_theme` | varchar(64) | |
| `audio_mode` | varchar(32) | `WRITTEN_QUESTION` \| `FULL_AUDIO` \| `WRITTEN_QUESTION_SPOKEN_CHOICES` |
| `competence_code` | varchar(64) | |
| `difficulty_band` | varchar(8) | **V045**, `EASY MEDIUM HARD`, nullable |

9 index, dont `idx_questions_band (module, question_type, difficulty, difficulty_band) WHERE is_active AND difficulty_band IS NOT NULL`.

🛑 **Il n'y a ni `notion_id`, ni `question_kind`, ni `mentions[]`, ni `situation_domain_id`.**
Le scoping civique par mention passe **par `difficulty`** (`CSP`/`CR`/`NAT`), c'est-à-dire par une
valeur unique — une question ne peut donc **pas** servir plusieurs mentions, contrairement à ce que
`20_` §1.2 exige (« tableau, pas une clé étrangère unique »). C'est un blocage structurel, voir §8.

Valeurs distinctes et volumétrie : §3.

## 2.4. Attempt / AttemptQuestion / Answer

`attempts` porte **31 colonnes** et distingue déjà de nombreux contextes :

- `mode` : `ENTRAINEMENT` \| `EXAMEN` \| `REVISION`
- `type` (AttemptType) : `TRAINING` \| `MOCK_EXAM` \| `REVIEW`
- `module` : `CIVIQUE` \| `TCF`
- `epreuve` : `CIVIQUE TCF_CO TCF_CE TCF_STRUCTURE TCF_EO TCF_EE TCF_COMPLET`
- `parent_attempt_id` : sous-attempts d'un examen complet
- `slot_number` (1..20) : **c'est lui qui porte le freemium des examens blancs**
- `lot_numero`, `lot_question_type`, `lot_difficulty`, `lot_theme_id` : lots d'entraînement
- `module_exam_question_type` : examen de module TCF
- `client_ip` (invités, `user_id NULL`), `timer_started_at`, `production_locked`
- `level_achieved`, `cecrl_level`, `final_cecrl_level`, `weighted_score`, `max_weighted_score`

Un **examen blanc** se distingue d'une **série** par `type = MOCK_EXAM` + `exam_template_id` +
`slot_number` ; une série par `type = TRAINING` + `lot_numero`.

```sql
select mode, type, module, epreuve, count(*) from attempts group by 1,2,3,4 order by 5 desc;
```
→ 12 combinaisons réellement présentes, dominées par `ENTRAINEMENT/TRAINING/TCF/TCF_EO` (148) et
`TCF_EE` (124), puis `EXAMEN/MOCK_EXAM/TCF/TCF_CO` (115).

`attempt_questions` est volontairement minimal : `attempt_id, question_id, position, is_correct,
time_spent_sec`. **Pas de trace de l'ordre des propositions ni du choix exact** à ce niveau
(il vit dans `answers`).

## 2.5. `user_question_statuses`

Stocké : `is_favorite`, `wrong_count`, `correct_count`, `last_seen_at`, `updated_at`, unicité
`(user_id, question_id)`.

**Non stocké** : aucune échéance de révision, aucune boîte, aucun état de maîtrise, aucun rattachement
notion. C'est un compteur d'erreurs, pas un moteur de mémorisation — toute la §5 de `20_`
(Leitner) est à construire, y compris son support de données.

## 2.6. Abonnement

`plans` (17 lignes) porte `purchase_type` (`SUBSCRIPTION` \| `ONE_TIME`), `module_access`
(`NONE` \| `CIVIQUE` \| `INTEGRAL`), `duration_days`, `realtime_eo_sessions`, et les 3 identifiants
de store (`stripe_price_id`, `apple_product_id`, `google_product_id`).

```sql
select code, price, duration_days, purchase_type, module_access, is_active from plans;
```

| Actifs (`is_active = true`) | Prix | Durée | Type |
|---|---|---|---|
| `FREE` | 0,00 € | 0 j | SUBSCRIPTION |
| `CIVIQUE_PASS_3M` | 9,99 € | 90 j | ONE_TIME |
| `INTEGRAL_PASS_7J` | 9,99 € | 7 j | ONE_TIME |
| `INTEGRAL_PASS_1M` | 19,99 € | 30 j | ONE_TIME |
| `CIVIQUE_PASS_1Y` | 29,99 € | 365 j | ONE_TIME |
| `INTEGRAL_PASS_2M` | 29,99 € | 60 j | ONE_TIME |

**Les 11 autres plans sont inactifs**, dont *tous* les abonnements récurrents
(`INTEGRAL_MONTHLY` 9,99 €, `INTEGRAL_3MOIS` 14,99 €, `INTEGRAL_YEARLY` 77,93 €…).

`user_subscriptions` porte `source`, `original_transaction_id` (unicité `(source, original_transaction_id)`),
`auto_renew`, et depuis V043 la **conversion de devise figée au paiement** (`amount_cents`, `currency`,
`amount_eur_cents`, `fx_rate_to_eur`).

⚠ **`00_` §A14 (« garder 14,99 €/mois et ajouter un pack 3 mois ») décrit un état révoqué.**
Le journal correspondant est `docs/decisions/paiements.md` et `docs/bascule-prix-integral.md`.

---

# 3. Volumétrie de contenu

> Base **de développement locale**. Les volumes de *contenu* (questions, sujets, compétences) sont
> ceux des migrations, donc représentatifs de la production. Les volumes d'*usage* (users, attempts,
> évaluations) ne le sont pas — voir §3.7.

## 3.1. TCF — questions par type × difficulté

```sql
select module, question_type, difficulty, count(*) filter (where is_active) actives, count(*) total
from questions group by 1,2,3 order by 1,2,3;
```

| Type | A2 | B1 | B2 | Total |
|---|---:|---:|---:|---:|
| `CE` | 206 | 205 | 205 | **616** |
| `CO` | 134 | 214 | 212 | **560** |
| `CO_IMAGE` | 70 | — | — | **70** |
| `STRUCTURE` | 269 | 209 | 209 | **687** |
| **Total TCF** | | | | **1 933** |

**100 % actives** (aucune question TCF inactive ou archivée).

Par `competence_code` :

| Type | Codes distincts | Remarque |
|---|---|---|
| `CE` | 6 | `ce_reperage_explicite` 155, `ce_inference_intention` 146, `ce_detail_specifique` 122, `ce_reformulation` 70, `ce_idee_principale` 64, `ce_ton_auteur` 58, **1 question sans code** |
| `CO` | 7 | `co_document_question` 198, `co_question_reponse` 102, `co_dialogue_court_implicite` 74, `co_dialogue_b1_implicite` 74, `co_dialogue_b2_implicite` 72, `co_dialogue_c1/c2_implicite` 20+20 |
| `CO_IMAGE` | 1 | `co_image_proposition` 70 |
| `STRUCTURE` | **403 pour 687 questions** | ⚠ voir ci-dessous |

```sql
select count(distinct competence_code), count(*) from questions where question_type='STRUCTURE';
-- 403 | 687
```

🛑 **Constat important** : `competence_code` n'a pas la même sémantique selon l'épreuve. En CE et CO
c'est une **taxonomie** (6-7 valeurs, réutilisées). En STRUCTURE c'est un **identifiant de point de
grammaire quasi unique** (403 codes pour 687 questions, dont des séries `struct_a2_v604_01..30` à une
question chacune). Un plan qui traiterait `competence_code` uniformément produirait 403 « compétences »
en STRUCTURE. C'est cohérent avec l'arbitrage A8 (STRUCTURE jamais priorité) mais il faut le savoir.

## 3.2. TCF — passages, médias, audios CO

```sql
select type, count(*), count(*) filter (where url is not null) from medias group by 1;
select p.type, count(*), count(*) filter (where p.media_id is not null) from passages p group by 1;
select q.question_type, q.difficulty, count(*),
       count(*) filter (where m.type='AUDIO'), count(*) filter (where m.type='IMAGE')
from questions q left join medias m on m.id=q.media_id where q.module='TCF' group by 1,2;
```

- `medias` : **888 lignes** — 630 `AUDIO` (toutes avec `url`), 258 `IMAGE` (aucune `url` → **`inline_svg`**).
- `passages` : **367**, toutes de type `TEXTE`, **aucune** avec `media_id`.
- **Couverture audio CO : 560 / 560 (100 %)** — 134 A2, 214 B1, 212 B2. L'audio est porté par
  `questions.media_id`, **jamais** par `audio_media_id` (colonne morte) ni par le passage.
- **Transcriptions des audios : 630 / 630 (100 %)** (`medias.transcript`).
- CE : 206 questions à média image sur 616 (176 en A2).
- `audio_mode` : 2 503 questions sans mode, 426 `FULL_AUDIO`, 20 `WRITTEN_QUESTION_SPOKEN_CHOICES`.

**Conséquence directe** : le mode dégradé « pas d'audio CO » de `00_` §7.4 et `10_` §9 n'a **aucun
cas d'usage réel**. Il reste à implémenter comme filet, pas comme chemin nominal.

## 3.3. Civique — questions par thème × mention

```sql
select t.code, q.question_type, q.difficulty, count(*)
from questions q join themes t on t.id=q.theme_id where q.module='CIVIQUE' group by 1,2,3;
```

**CONNAISSANCE**

| Thème | CSP | CR | NAT | Total |
|---|---:|---:|---:|---:|
| `CIV_PRINCIPES` | 19 | 44 | 16 | 79 |
| `CIV_INSTITUTIONS` | 67 | 90 | 57 | 214 |
| `CIV_DROITS_DEVOIRS` | 45 | 72 | 49 | 166 |
| `CIV_HISTOIRE_GEO` | 73 | 72 | 70 | 215 |
| `CIV_SOCIETE` | 54 | 72 | 40 | 166 |
| **Total** | **258** | **350** | **232** | **840** |

**MISE_SITUATION**

| Thème | CSP | CR | NAT | Total |
|---|---:|---:|---:|---:|
| `CIV_PRINCIPES` | **1** | 15 | 5 | 21 |
| `CIV_INSTITUTIONS` | 12 | 9 | 10 | 31 |
| `CIV_DROITS_DEVOIRS` | 18 | 19 | 10 | 47 |
| `CIV_HISTOIRE_GEO` | 10 | 10 | 10 | 30 |
| `CIV_SOCIETE` | 15 | 22 | 10 | 47 |
| **Total** | **56** | **75** | **45** | **176** |

**Total civique : 1 016 questions**, toutes actives, 5 thèmes conformes aux 5 thèmes officiels.

⚠ Point noir mesuré : **`CIV_PRINCIPES` × `CSP` n'a qu'UNE mise en situation.** Le diagnostic
civique de `20_` §4.2 exige « 7 mises en situation réparties sur au moins 4 domaines » et « jamais
un thème évalué sur une seule question » : sur la mention CSP, ce thème est déjà à la limite.

## 3.4. Civique — explications

```sql
select count(*) total, count(*) filter (where explanation is null or btrim(explanation)='') sans
from questions where module='CIVIQUE';
-- 1016 | 0
```

**100 % des questions civiques ont une explication non vide.** Le mode dégradé « question sans
explication » (`20_` §3.4) n'a pas de cas réel aujourd'hui.

## 3.5. Connaissances vs mises en situation

**Oui, la distinction existe déjà** — `questions.question_type` vaut `CONNAISSANCE` ou
`MISE_SITUATION` (840 / 176, soit **17,3 %**). Aucun signal supplémentaire n'est nécessaire.

⚠ Écart avec la spec : `20_` §1 attend **12 sur 40 = 30 %** de mises en situation, et `20_` §4.2
attend ~29 % au diagnostic. Le catalogue n'en porte que **17,3 %**. Sur la mention NAT c'est
**16,2 %** (45/277). Produire un diagnostic à 7/24 mises en situation sur NAT est possible
(45 disponibles), mais un examen blanc à 12/40 tire dans un pool 2× plus étroit que la spec ne
le suppose.

## 3.6. Examens blancs

```sql
select module, count(*) from exam_templates group by 1;
-- TCF 23 | CIVIQUE 21
```

**44 templates** avec leurs règles de tirage dans `exam_template_rules`. Le tirage réel est
majoritairement **dynamique** (lots calculés sans schéma, cf. `docs/lots-entrainement.md`) ; les
templates couvrent les examens blancs.

## 3.7. Volumétrie d'usage (base locale, non représentative)

```sql
select (select count(*) from users), (select count(*) from attempts), … ;
```

| users | attempts | production_submissions | ai_evaluations | user_skill_attempts | diagnostic_sessions | learning_evidence | progression_state |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 26 | 620 | 196 | 166 | 34 | 12 | 41 | 41 |

**Marqué explicitement : ces chiffres ne sont pas mesurables en production depuis ce poste**
(pas d'accès à la base de prod dans le périmètre de l'audit). Ils servent uniquement à confirmer que
les pipelines ont tourné.

---

# 4. Fonctionnalités IA existantes

## 4.1. Où et comment les appels LLM sont déclenchés

Quatre pipelines LLM distincts, tous configurés dans `application.yaml`, tous à clé par variable
d'environnement (503 tant qu'elle est vide) :

| Pipeline | Service d'entrée | Fournisseur (défaut) | Modèle (défaut) |
|---|---|---|---|
| **Correction EE/EO** (async + fin de session temps réel) | `ProductionEvaluationService.submitAndEvaluate` / `evaluateRealtimeTranscript` | `${EVAL_LLM_PROVIDER:deepseek}` — 3 clients interchangeables (`EvaluationAnthropicClient`, `OpenAiCompatibleEvalClient`, DeepSeek) | `deepseek-v4-flash` |
| **Analyse de compétence** (micro-sujets) | `service/competence/…` | même mécanisme | idem |
| **Analyse de diagnostic** | `service/diagnostic/DiagnosticProductionAnalysisService` | idem | idem |
| **Transcription** | `WhisperTranscriptionService` → `WhisperTranscriptionClient` | OpenAI | `whisper-1` |
| **Examinateur vocal EO temps réel** | `service/realtime/…`, `RealtimeEoController` | Gemini (client → Gemini **en direct**, jeton éphémère serveur) | `gemini-live-2.5-flash-native-audio` |
| **Génération de questions audio CO** (admin) | `audioquestion/` | Anthropic + Azure Speech | `claude-opus-4-7` |

La **forme** de la requête est négociée au premier appel (`ChatCompletionDialectNegotiator`), jamais
codée en dur : changer de correcteur = **une ligne de `.env` + un redémarrage**, sans migration ni
changement front. Le tarif voyage avec le modèle (`EVAL_*_COST_*`), verrouillé par
`EvaluationPricingTest`.

## 4.2. Prompts actuels

🛑 **Déviation assumée du plan imposé.** La règle `00_` §2.3 demande de recopier les prompts
**intégralement**. C'est irréalisable ici sans détruire l'audit : le seul
`production-rubrics-v15.json` pèse **127 039 caractères**, et le dossier `prompts/` pèse **2,2 Mo**
sur **~50 fichiers versionnés** (on ne réécrit jamais une grille livrée, donc v1→v15 coexistent).
Ils sont donc **référencés par chemin exact**, et le seul contrat court est recopié intégralement.

Inventaire de `backend_sejourfr/src/main/resources/prompts/` :

| Famille | Versions présentes | Version active |
|---|---|---|
| `production-rubrics-v*.json` (consignes de notation EE/EO) | v1→v15 (+ v4.1, v4.2) | **v15** (`EVAL_RUBRICS_VERSION`) |
| `production-evaluation-tool-schema-v*.json` (contrat de sortie) | v1.0→v9 | **v9** — matrice rubriques↔schéma **vérifiée au démarrage**, une paire incohérente bloque le boot |
| `competence-analysis-rubrics-v*.json` | v1→v6 | **v6** (`COMPETENCE_RUBRICS_VERSION`) |
| `competence-analysis-tool-schema-v*.json` | v1→v5 | selon matrice |
| `competence-niveau-vise-*` | v1→v3 | v3 |
| `diagnostic-analysis-rubrics-v1.json` / `-tool-schema-v1.json` | v1 | **v1** |
| `diagnostic-exemple-cible-*` | v1 | v1 |
| `production-version-ciblee-rubrics-v*` / `-tool-schema-*` | v1, v2 (+ variante orale v2) | v2 |
| `realtime-personas-v*.json` | v1→v3 | **v3** |
| `audio-question-system-v2.md` + `audio-question-tool-schema.json` | v1 (dans `old/`), v2 | v2 |
| `old/production-evaluation-system-v1.0..1.5.md` + user-templates | archivés | — |

**Recopié intégralement — `diagnostic-analysis-rubrics-v1.json`** (2 646 caractères, le seul contrat
assez court pour tenir ici) :

```json
{
  "rubrics-version": "v1",
  "tool_schema_version": "v1",
  "sections": [
    {
      "title": "Rôle et portée",
      "content": "Tu produis un profil pédagogique structuré SejourFR. Quand analysis_type=INITIAL_DIAGNOSTIC, l'exercice hybride n'est pas une tâche officielle du TCF. Quand analysis_type=LEARNING_PLAN_PRODUCTION_OBSERVATION, tu observes secondairement une production standard déjà corrigée par un autre pipeline : tu ne remplaces ni sa correction ni sa note. Dans les deux cas, tu estimes prudemment le niveau de la production de A1_NON_ATTEINT à B2, sans note sur 20 et sans présenter ce résultat comme officiel. Tu appelles toujours submit_diagnostic_analysis et ne rends jamais de commentaire libre."
    },
    {
      "title": "Ordre obligatoire",
      "content": "1) Vérifie d'abord si les éléments demandés sont accomplis. 2) Juge si la communication est compréhensible et exploitable dans la situation. 3) Analyse chaque compétence autorisée, et seulement elle. 4) Estime le niveau à partir de l'ensemble de la production, jamais par moyenne mécanique des compétences. 5) Sélectionne au plus trois faiblesses importantes et au plus deux compétences prioritaires sur cette production."
    },
    {
      "title": "Compétences et preuves",
      "content": "Retourne exactement une entrée pour chaque compétence de l'allowlist. Une compétence absente de la production est NOT_OBSERVED : observed=false, evidence_segment=null, priority=false. Une compétence observée doit désigner un numéro de segment réel. Ne recopie pas de citation : le serveur résout le numéro vers le texte exact. Une erreur isolée ne devient pas une priorité ; privilégie les fragilités récurrentes ou qui gênent la communication."
    },
    {
      "title": "Oral enregistré",
      "content": "Quand modality=EO, tu lis une transcription automatique d'un monologue. Tu peux analyser contenu, lexique, grammaire et cohérence. Tu ne peux pas entendre la voix : n'affirme rien sur la prononciation, l'accent, le débit, l'intonation, la fluidité acoustique ou les hésitations. Ne crédite jamais une interaction, une relance ou une reformulation réellement dialoguée dans ce diagnostic."
    },
    {
      "title": "Qualité du retour",
      "content": "La réalisation de la tâche passe avant la perfection grammaticale. N'évalue pas comme une dissertation scolaire. Évite de répéter une faiblesse sous plusieurs noms. Le retour est court, concret, en français accentué et atteignable au niveau visé. N'exige ni vocabulaire artificiellement complexe ni subjonctif pour faire B2."
    }
  ]
}
```

Le journal complet des grilles v4→v15, **avec les chiffres de banc de chaque campagne**, vit dans
`docs/decisions/notation-ia.md` et dans les ~200 lignes de commentaires de `application.yaml`
(lignes 297–560). C'est de loin la documentation la plus dense du dépôt et elle est **à jour**.

## 4.3. Format de réponse et parsing

**Tool-use strict, pas de texte libre.** Le modèle est contraint d'appeler un outil dont le schéma
JSON est le contrat (`EvaluationToolSchema`). Chaîne de validation :

`EvaluationOutputValidator` → `EvaluationProofMatcher` (la preuve doit désigner un **segment
numéroté** de la production depuis v12 — inventer une preuve est impossible **par construction**)
→ `EvaluationOralArtifactFilter` (volet artefacts de transcription + volet langue)
→ `EvaluationPalierMarqueurFilter` → `EvaluationAccentAudit` → `EvaluationRepairPrompt`
(**une seule réparation de format**, puis échec propre).

Ordre de préférence explicitement appliqué dans le dépôt :
**tool-schema > longueur plafonnée > contrôle serveur déterministe > consigne de prompt.**
Les versions v10 et v11 sont la preuve mesurée de cette règle : elles ajoutaient une *consigne* et
ont été mesurées **moins bonnes** que v9 (75,6 % / 76,7 % contre 81,8 % de niveaux exacts) ; le
comportement visé est finalement tenu par un contrôle serveur. Elles restent chargeables mais
inactives.

## 4.4. Où est stocké le résultat

| Voie | Table | Colonnes clés |
|---|---|---|
| Tâche EE/EO complète | `ai_evaluations` | `feedback_json` (jsonb), `note_sur_20`, `niveau_cecrl`, `niveau_cecrl_ia`, `prompt_version`, `rubrics_version`, `modele_utilise`, `tokens_input/output`, `tokens_input_cache_hit`, `cout_micro_usd`, `evaluabilite` |
| Micro-sujet de compétence | `user_skill_attempts` | `analysis_json`, `criterion_status`, `ai_model`, `prompt_version`, `rubrics_version`, coûts |
| Diagnostic | `diagnostic_production_analyses` | `analysis_json`, `level_estimate`, `task_completion`, `communication_status`, `schema_version` |
| Transcription | `transcriptions` | `texte`, `avg_logprob`, `no_speech_prob`, `compression_ratio`, `taux_formes_suspectes`, `taux_collages`, `qualite_degradee` |

🛑 Contrainte de base remarquable, à ne pas défaire :
`chk_ai_eval_aucun_verdict_si_non_evaluable` — si `evaluabilite = 'NON_EVALUABLE'`, alors
`note_sur_20`, `niveau_cecrl` et `niveau_cecrl_ia` **doivent** être `NULL`. C'est l'invariant
« `null` = inconnu, jamais mauvais » **rendu opposable par la base** (issu de V040/V041/V042).

## 4.5. Quota gratuit EE / EO aujourd'hui

Il n'est **pas** de la forme « 1 EE + 1 EO » de `00_` §7.1. Règle réelle (`ProductionAccessService`,
`AttemptService`, `SkillAccessService`) :

- **1 essai d'entraînement par épreuve à vie** (EE, EO) **+ 1 examen blanc production offert**
  (`attempts.slot_number = 1`, ses soumissions bypassent le quota d'entraînement) ;
- **1 examen blanc TCF complet offert**, avec **EE + EO évaluées une seule fois à vie** ; au-delà
  l'examen 1 reste rejouable en CO+CE, les épreuves de production sont pré-terminées et
  `attempts.production_locked = true` ;
- module Compétences : **1 compétence ouverte par tâche** (6) **+ la compétence de la priorité n°1
  du Plan**, **2 sujets** par compétence ouverte, **3 analyses IA offertes à vie** (verrou distinct
  et cumulatif) ;
- examens blancs QCM : **slot 1 offert et rejouable**, slots 2+ réservés aux abonnés **du module** ;
- web invité : série 1 par thème/épreuve + examen diagnostic 1 par module, **tirages déterministes** ;
  mobile : **aucun mode invité**.

Les **deux** voies de notation (asynchrone et temps réel) passent par le **même** garde
`ProductionAccessService.assertCanSubmit`. Le freemium est **opposable serveur (403)** et les fronts
**lisent un `locked` servi** — ils ne le déduisent jamais d'un rang.

Détail complet et daté : `docs/regles/freemium.md`.

## 4.6. Coût observé

Mesurable **uniquement sur la base locale**, donc non représentatif :

```sql
select count(*), round(avg(cout_micro_usd)/1e6,4), round(sum(cout_micro_usd)/1e6,4)
from ai_evaluations where cout_micro_usd is not null;   -- 8 | 0.0014 | 0.0109
select count(*), round(avg(cout_micro_usd)/1e6,4) from transcriptions where cout_micro_usd is not null;
-- 5 | 0.0107
```

→ **≈ 0,0014 USD par correction** (DeepSeek), **≈ 0,0107 USD par transcription** (Whisper).
Sur 8 et 5 lignes seulement : **non extrapolable**. Marqué `non mesurable en production, raison :
pas d'accès à la base de prod`.

Tarifs configurés : DeepSeek 0,22 / 0,66 USD par million de tokens (entrée/sortie), cache 0,007 ;
OpenAI 2,50 / 15,00 ; Anthropic 3,00 / 15,00 ; Whisper 0,006 USD/min. DeepSeek porte un
`peak-multiplier: 2.0` sur les plages UTC 01:00-04:00 et 06:00-10:00.

🛑 Il n'existe **pas** de table `ai_usage` unifiée ni de tableau de bord « coût par source ». Les
coûts sont dispersés sur 3 tables, sans champ `source`. C'est le principal manque du §8.4 de la spec.

---

# 5. Expression écrite / orale existantes

## 5.1. Ce que l'utilisateur peut faire aujourd'hui

**Bien plus que ce que la spec suppose.** Trois parcours coexistent :

1. **Tâche complète EE / EO** — choix d'une tâche (T1/T2/T3) et d'un sujet, rédaction ou
   enregistrement, correction IA complète (note /20 + niveau CECRL + critères + preuves + version
   ciblée « la marche au-dessus »). Web : `/entrainement/tcf/{ee|eo}/tache/[n]`. Mobile :
   `screens/tcf_production/`.
2. **Micro-entraînement par compétence** — 48 compétences, 720 sujets courts, verdict par critère
   unique (`VALIDATED` / `PARTIAL` / `NOT_VALIDATED`), **jamais de niveau CECRL** sur un micro-sujet,
   3 références pédagogiques par sujet (`INSUFFICIENT` / `EXPECTED` / `EXCELLENT`). C'est exactement
   l'intention de `10_` §8, déjà livrée.
3. **Examinateur vocal EO en temps réel** — session Gemini Live, le client parle **directement** au
   modèle avec un jeton éphémère émis par le serveur ; à la fin, la transcription part dans le même
   correcteur que la voie asynchrone. Quota porté par `plans.realtime_eo_sessions` +
   `user_subscriptions.realtime_eo_sessions_remaining`.

## 5.2. Modèle de données associé

Détaillé en §2.2. Volumétrie du contenu :

```sql
select epreuve, tache_numero, niveau_cible, count(*) filter (where is_active) from production_tasks group by 1,2,3;
select s.section, s.task_code, count(p.*) from skills s left join skill_prompts p on p.skill_id=s.id and p.is_active group by 1,2;
```

| Contenu | Volume |
|---|---|
| `production_tasks` actives | **101** — EE : 8/6/6 par tâche et niveau (A2/B1/B2) ; EO : idem sauf **EO1 qui n'a qu'1 sujet par niveau** |
| dont sujets de diagnostic | **2** (EE T3 B1, EO T3 B1) |
| `skills` actives | **48** — 8 par tâche × 6 tâches (EE1-3, EO1-3), + 3 CO et 3 CE |
| `skill_prompts` actifs | **720** — 120 par tâche |
| `skill_references` | **2 160** — 3 par sujet |
| `production_examples` | **18** |

⚠ **Trou de contenu mesuré : EO1 n'a qu'un seul sujet par niveau** (3 au total, contre 20 pour EO2
et 21 pour EO3). Un candidat qui refait EO1 retombe sur le même sujet.

## 5.3. Workflow audio EO

```
Enregistrement client
  → upload multipart (max 25 Mo, file-size-threshold porté à 26 Mo POUR QUE RIEN NE TOUCHE LE DISQUE)
  → Whisper (mode littéral forcé : hésitations et fautes conservées)
  → transcriptions (+ métriques de qualité : avg_logprob, no_speech_prob, taux_collages…)
  → correcteur LLM sur la TRANSCRIPTION
  → ai_evaluations
  → l'audio DISPARAÎT
```

🛑 **Aucun audio de candidat n'est conservé** — décision du propriétaire, motif consentement
(`docs/regles/audio-productions.md`). Le seuil multipart est réglé à 26 Mo **exprès** : à la valeur
par défaut (0 o), Spring spoolerait tout upload dans un fichier temporaire, y compris les
enregistrements de candidats. **Ne jamais rabaisser ce seuil.**

⚠ **Contradiction frontale avec la spec.** `00_` §13 prescrit « audio EO : stockage S3 chiffré, URL
signées, suppression automatique après 12 mois » et `30_` §6.3 prévoit un **lecteur audio dans le
rapport EO** (« [0. Votre enregistrement] »). Les deux sont **impossibles** en l'état et le
resteront : la décision est explicitement irréversible côté dépôt. R2 sert aux **audios de contenu**
(CO générés, exemples de production), jamais aux productions de candidat.
Voir §10, question ouverte Q3.

---

# 6. Écrans existants

## 6.1. Arborescence

Voir §1.3 (web, 69 routes) et §1.4 (mobile, 22 dossiers d'écrans, ~40 routes go_router).

Correspondance avec l'inventaire `30_` §2 :

| Bloc de la spec | État réel |
|---|---|
| T01 Objectif / date d'examen | **Partiel** — `/target-path` (mobile) et l'onboarding portent la procédure visée ; **aucune date d'examen** n'est demandée ni stockée (`users` n'a pas la colonne) |
| T02-T05 Diagnostic rapide | **Absent en tant que tel** — il existe un diagnostic **EE + EO** (2 productions), pas une production transversale unique. `/diagnostic` (web) + `screens/diagnostic/` (mobile) |
| T06-T12 Diagnostic 4 épreuves | **Absent.** L'objet le plus proche est l'**examen blanc TCF complet** (`TCF_COMPLET`, `/api/full-tcf-exams`, `screens/tcf_full_exam/`, `/examens-blancs/tcf/[id]`) — mais c'est un examen, pas un diagnostic, et il n'alimente pas un « résultat de diagnostic » |
| T13 Paywall | **Existe** — `screens/paywall/`, `/tarifs`, `/paiement` ; **pas contextualisé** au sens de `10_` §5 (pas de rappel des 3 priorités ni de la date d'examen) |
| T14-T16 Plan | **Existe et est plus riche que la spec** — `/plan` + `/plan/domaine/[domaine]`, `/plan/competences`, `/plan/evolution`, `/plan/progression` ; mobile `screens/plan/` |
| T20-T22 Réviser EE/EO | **Existe intégralement**, y compris le niveau 3 (page d'une compétence) et le niveau 4 (un sujet) |
| T23-T27 Exécution + rapports IA | **Existe** — rédaction, enregistrement, session, résultats, rapport de micro-sujet |
| T28 Progrès TCF | **Existe** — `/statistiques`, `/progression`, mobile `screens/progres/` |
| C01 Mention civique | **Existe** sous une autre forme — `TargetProcedure` (CSP/CR/NAT) au niveau du compte, pas un écran civique dédié |
| C02-C12 Civique | **Partiel** — séries, examens blancs, révision d'erreurs et favoris existent. **Tout ce qui touche aux notions n'existe pas** |
| G01 Accueil agrégé | **Existe** — `/dashboard`, mobile `screens/home/` |
| G02 Confirmation d'abonnement | **Existe** — `/paiement/succes` |
| G03 Gestion d'abonnement | **Existe** — `/profil/abonnement`, mobile `/profile/abonnement` |
| G04 Profil et données | **Existe** — suppression de compte livrée (`AccountDeletionService`) ; **export des données non vérifié** |
| A01 File de tagging | **Absent** (dépend des notions) |
| A02-A04 Admin couverture / contenus / supervision IA | **Partiel** — `AdminCalibrationController`, `AdminDiagnosticController`, `AdminProgressionController`, `AdminCatalogueCalibrationController`, `AdminSkillPromptController`, `AdminProductionTaskController` existent ; **pas d'écran unifié « coût par source »** |

## 6.2. Composants et tokens réels

`web_sejoufr/app/globals.css` — **les tokens correspondent exactement à `00_` §9** :

| Token spec | Token réel | Valeur |
|---|---|---|
| `--bleu-france` | `--color-blue` | `#1E3A8C` ✔ |
| `--bleu-fonce` | `--color-blue-dark` | `#15296B` ✔ |
| `--bleu-clair` | `--color-blue-light` | `#E8ECF8` ✔ |
| `--rouge-france` | `--color-red` | `#E1372F` ✔ |
| `--rouge-fonce` | `--color-red-dark` | `#B5251E` ✔ |
| `--rouge-clair` | `--color-red-light` | `#FDECEB` ✔ |
| `--encre` | `--color-ink` | `#0F1839` ✔ |
| `--succes` | `--color-green` | `#168F5B` ✔ |
| `--ambre` | `--color-amber` | `#E8A317` ✔ |

Tokens supplémentaires non prévus par la spec : `--color-blue-soft`, `--color-ink-2`,
`--color-muted`, `--color-muted-2`, `--color-line`, `--color-line-2`, `--color-paper`,
`--color-paper-2`, `--color-amber-dark`. **Aucun renommage n'est nécessaire** : seuls les noms de
variables diffèrent, les valeurs sont identiques. Ne pas migrer.

Typographies conformes : Plus Jakarta Sans (web/mobile), Inter (admin), Fraunces (titres,
`<em>` toujours rouge), JetBrains Mono (labels techniques).

Composants communs demandés par `00_` §9 (`LevelBadge`, `LevelGauge`, `PriorityCard`, `LockedRow`,
`StepList`, `ObservationRow`, `StickyCta`, `SegmentedControl`, `BeforeAfterBlock`) : les équivalents
existent, sous d'autres noms, dans `web_sejoufr/app/_components/` (87 fichiers) et
`mobile_sejourfr/lib/core/widgets/`. **Non renommer** — vérifier au cas par cas.

## 6.3. Navigation par onglets

Mobile : `screens/shell/` porte la bottom nav. Web : header + navigation latérale dans `(app)/`.
Conforme aux divergences autorisées de `00_` §6.1.

---

# 7. Écarts web / mobile

## 7.1. Fonctionnalités présentes d'un seul côté

| Fonction | Web | Mobile | Nature |
|---|:--:|:--:|---|
| Mode invité (séries + examens démo) | ✔ | ✖ | **Choix assumé**, pas un trou (`docs/regles/freemium.md`) |
| Vitrine, blog, FAQ, CGU, tarifs | ✔ | ✖ | Normal |
| Paiement Stripe | ✔ | ✖ | **Volontaire** — hors stores pour éviter la commission |
| Paiement IAP (Apple / Google) | ✖ | ✔ | Symétrique du précédent |
| Examinateur vocal EO temps réel | ✔ | ✔ | Parité |
| Onboarding / `target_path` | ✖ | ✔ | Mobile seulement |
| Écrans `civique/` dédiés | ✔ | ✔ | Parité |

## 7.2. Endpoints appelés d'un seul côté

- `/api/public/*` (lots, attempts démo, examens, thèmes, diagnostics, page-views, analytics) :
  **web seulement** — conséquence directe de l'absence de mode invité mobile.
- `/api/billing/*` en mode Stripe Checkout : web seulement ; `/api/billing/webhooks/{apple,google}` :
  serveur seulement.
- Le reste (`/api/attempts`, `/api/me/plan`, `/api/diagnostics`, `/api/production-*`, `/api/themes`,
  `/api/lots`, `/api/exams`, `/api/realtime/eo`) est appelé **des deux côtés**.

## 7.3. Duplication de logique métier côté client — signalée, non corrigée

**Bon point** : le contrat de progression est **vérifié automatiquement**.
`node scripts/verifier-contrat-front-progression.mjs` → `T36 — contrat de rendu front conforme.`
Aucun front ne classe un nombre en état pédagogique ni en niveau CECRL ; les six états, leurs
libellés et leur ton arrivent **servis**.

🛑 **Violation d'invariant à signaler — des tests existent sur les fronts.**
`CLAUDE.md` racine pose : « **Aucun test sur les fronts. Jamais.** Cette règle prime sur toute
consigne de test écrite ailleurs. » Or :

```
find web_sejoufr admin_sejourfr -name "*.test.ts*" -not -path "*/node_modules/*" | wc -l   # 16
find mobile_sejourfr/test -type f | wc -l                                                   # 25
git ls-files | grep -E '\.test\.tsx?$|^mobile_sejourfr/test/'                               # tous suivis
```

**41 fichiers de test versionnés** sur les fronts : 16 en TypeScript (`web_sejoufr/lib/*.test.ts` —
`skill-result-view`, `production-feedback`, `estimated-tcf-level`, `diagnostic`, `exam-levels`…) et
25 en Dart (`mobile_sejourfr/test/` — dont des tests de **widget** : `plan_screen_test.dart`,
`diagnostic_widgets_test.dart`, `competence_result_screen_test.dart`, `tache_bilan_row_test.dart`).

Leur existence même est un signal : plusieurs testent des **fonctions de dérivation côté client**
(`estimated-tcf-level`, `niveau_cecrl_display`, `skill-progress`, `target_procedure_levels`) — exactement
le type de logique que `00_` §6.2 et `CLAUDE.md` interdisent au front. À arbitrer (§10, Q5).

Autre duplication structurelle, **assumée et documentée** : les DTO backend sont miroités **à la
main** dans `admin_sejourfr/src/types/api.ts`, `web_sejoufr/lib/types.ts` et
`mobile_sejourfr/lib/core/models/*.dart`. Le miroir de `TargetProcedure` est **gelé par test de
chaque côté** — mesure prise après que la table des paliers a vécu en **6 copies**, tirant un
candidat NAT vers le B1.

---

# 8. Points de blocage identifiés pour la refonte

### B1 — La spec cible Angular ; le web est Next.js

**Impact** : la matrice de parité `30_` §13, les « routes Angular » de `30_` §12 et tous les
« tests de rendu web » de `10_` §13 sont inapplicables tels quels.
**Options** : (a) réécrire la colonne Angular en Next.js dans `30_` ; (b) ignorer et laisser dériver.
**Recommandation** : **(a)**, avant tout démarrage de lot. C'est 30 minutes de rédaction contre une
matrice de suivi fausse pendant 12 lots.

### B2 — La mention civique est portée par `difficulty`, donc **une seule par question**

**Impact** : `20_` §1.2 exige qu'une question porte **plusieurs** mentions (« une même question sert
souvent 2 ou 3 mentions »). Aujourd'hui `questions.difficulty` vaut `CSP` **ou** `CR` **ou** `NAT`.
Le catalogue de 1 016 questions civiques est déjà réparti sur cette hypothèse.
**Options** : (a) ajouter `mentions text[]` et migrer les 1 016 lignes en dérivant depuis `difficulty` ;
(b) garder une mention unique et dupliquer les questions ; (c) garder l'existant et scoper le
diagnostic par `difficulty`.
**Recommandation** : **(c) d'abord, (a) ensuite si le besoin est confirmé.** L'existant fonctionne,
les examens blancs et les lots en dépendent, et rien ne prouve aujourd'hui qu'une même question
doive servir plusieurs mentions. (a) est une migration à impact logique sur tout le module civique.

### B3 — Le référentiel de notions n'existe pas et c'est un chantier **éditorial**, pas de code

**Impact** : c'est le chemin critique des lots L8-L11. 54 notions à créer, **1 016 questions à
tagger**, avec un volume cible de « 6 questions actives par notion et par mention ». 54 notions ×
3 mentions × 6 = **972 questions minimum** ; le catalogue en a 1 016. **La marge est nulle.**
**Options** : (a) réduire le référentiel à ~30 notions ; (b) accepter que beaucoup de notions soient
`insufficient_content` ; (c) produire du contenu avant de tagger.
**Recommandation** : **(a) + (b)**. Commencer par les thèmes les mieux dotés (`CIV_INSTITUTIONS`
214 questions, `CIV_HISTOIRE_GEO` 215) et laisser `CIV_PRINCIPES` (79 questions, dont **1 seule**
mise en situation CSP) au niveau thème. Le mode dégradé de `20_` §3.3 est conçu pour ça — il faut
juste accepter qu'il soit l'état **nominal** pour au moins un thème.

### B4 — Le Plan n'est pas matérialisé, la spec le suppose persisté

**Impact** : `10_` §6.4 exige `tcf_plan` + `tcf_plan_item` avec un `plan_version` incrémenté, pour
afficher « ce qui a changé » et garantir la cohérence web/mobile. Aujourd'hui le Plan est **calculé
à la lecture** (`LearningPlanService`), et cette propriété est un **invariant explicite** du dépôt :
« dérivé serveur ⇒ jamais persisté ».
**Options** : (a) matérialiser (contredit l'invariant) ; (b) garder le calcul à la lecture et ajouter
un **journal** d'observations (`learning_plan_observations` existe déjà) ; (c) hybride — calculer,
et ne persister que le `plan_version` + un hash pour détecter le changement.
**Recommandation** : **(c)**. On garde l'invariant, on gagne « ce qui a changé », et
`PlanRecentChangesResolver` existe déjà pour l'exploiter.

### B5 — Pas d'idempotence par `client_submission_id`

**Impact** : `00_` §6.5 en fait un crochet obligatoire, et `10_` §13 le teste (« rejeu du même
`client_submission_id` → même rapport, pas de 2ᵉ appel LLM »). Aucune table n'a cette colonne.
Sans elle, une perte de réseau en fin de soumission EO peut déclencher **deux corrections payantes**.
**Options** : (a) ajouter la colonne + unicité sur `production_submissions` et `user_skill_attempts` ;
(b) rien.
**Recommandation** : **(a), et tôt.** C'est peu de travail (une migration, deux gardes) et cela
protège directement l'argent du propriétaire. À mettre en L1.

### B6 — Pas de table `ai_usage`, pas de tableau de bord de coût par source

**Impact** : `00_` §8.4 et `30_` §11.3 (A04) en dépendent, et c'est **l'écran qui doit décider si un
diagnostic complet gratuit est soutenable**. Les coûts existent mais sont dispersés sur 3 tables sans
champ `source`.
**Options** : (a) créer `ai_usage` et y écrire depuis les 3 pipelines ; (b) créer une **vue SQL**
qui unifie les 3 tables et ajouter un `source` dérivé ; (c) ajouter une colonne `source` aux 3 tables.
**Recommandation** : **(b) d'abord**. Une vue répond à la question sans dupliquer une donnée déjà
écrite trois fois — et la règle du dépôt est « une règle = une autorité ». Si la vue devient trop
lente, (c).

### B7 — L'audio de candidat ne sera jamais conservé ; deux écrans de la spec en dépendent

**Impact** : `30_` §6.3 (T25, lecteur audio dans le rapport EO), `10_` §7.4 (« lecture de son propre
enregistrement disponible dans le rapport ») et `00_` §13 (S3 + 12 mois) sont **incompatibles** avec
une décision produit irréversible.
**Options** : aucune côté technique.
**Recommandation** : **corriger la spec**. Le rapport EO affiche la **transcription** (« Ce que nous
avons entendu ») avec son avertissement — ce que le dépôt fait déjà — et rien d'autre. Retirer le
bloc `[0. Votre enregistrement]` de T25.

### B8 — Le modèle tarifaire de la spec est révoqué

**Impact** : tout le wording de paywall (`10_` §5, `20_` §6, `30_` §10.1) cite « 14,99 €/mois »,
« renouvellement le 9 octobre », « Annulable à tout moment », « Restaurer mes achats ». Sur des pass
à achat unique, « annulable à tout moment » est **faux** et « renouvellement » n'existe pas.
**Recommandation** : réécrire ces trois sections **avant** L5. Un paywall qui promet une résiliation
sur un achat unique est un risque juridique, pas une coquille.

### B9 — 41 fichiers de test sur les fronts, contre un invariant explicite

**Impact** : au-delà de la règle, plusieurs testent de la **dérivation métier côté client**
(niveau CECRL estimé, paliers par procédure) — c'est-à-dire qu'ils **verrouillent** ce que
`00_` §6.2 veut supprimer.
**Recommandation** : arbitrage propriétaire requis (§10, Q5). Ne rien supprimer sans son feu vert.

### B10 — `competence_code` n'a pas la même sémantique selon l'épreuve

**Impact** : 403 codes distincts pour 687 questions STRUCTURE (taxonomie en CE/CO, identifiant
quasi-unique en STRUCTURE). Un moteur qui traiterait `competence_code` uniformément produirait des
« compétences » à une question.
**Recommandation** : documenter dans `docs/regles/domaine.md` et **exclure STRUCTURE** de tout
regroupement par compétence — ce que l'arbitrage A8 impose déjà pour d'autres raisons.

### B11 — Pas de date d'examen dans le modèle

**Impact** : `10_` §3.2 Q3, `10_` §5 (« il vous reste 39 jours »), `30_` §9 (« TCF le 18 octobre »)
en dépendent. `users` porte `target_procedure` et `target_level`, **pas de date**.
**Recommandation** : une colonne `users.exam_date` (nullable) en L1. Coût minime, gain de
personnalisation important sur tout le tunnel.

### B12 — EO1 n'a qu'un sujet par niveau

**Impact** : un candidat qui refait EO1 retombe sur le même sujet (3 sujets EO1 contre 20 pour EO2).
**Recommandation** : chantier de contenu à planifier avec L6, non bloquant.

---

# 9. Estimation d'effort par lot

Complexité relative au dépôt **réel**, pas au dépôt supposé par la spec. S / M / L / XL.

| Lot | Contenu | Complexité | Dépend de | Risques |
|---|---|:--:|---|---|
| **L0** | Audit | **fait** | — | — |
| **L1** | Socle : `client_submission_id` (B5), vue de coût (B6), `users.exam_date` (B11), i18n commun, analytics du tunnel | **M** | L0 | L'i18n commun (`00_` §6.3) n'existe **pas** : aucun front n'a de fichier de traduction, tous les textes sont en dur. C'est à lui seul un **L**. |
| **L2** | Modèle EE/EO + admin de contenu | **S** — **déjà livré à ~90 %** | L1 | Reste : `prep_seconds`, séparation tâche/sujet si voulue |
| **L3** | Diagnostic écrit rapide (production transversale unique, sans compte) | **L** | L2 | Le diagnostic actuel est EE+EO et **ne persiste rien avant le compte** ; la spec veut une production persistée sur `anon_id`. **Contradiction directe** avec `docs/regles/diagnostic.md` → Q1 |
| **L4** | Diagnostic TCF complet 4 épreuves | **XL** | L2, L3 | Le plus gros lot restant. Séquencement, reprise 7 j, chronos par section, calcul par épreuve, exclusion des non évaluées |
| **L5** | Plan + paywall contextualisé | **M** | L4 | Le Plan existe et est plus riche que la spec ; le **paywall** est à refaire (B8) |
| **L6** | Réviser EE/EO + micro-exercices + rapport court | **S** — **déjà livré** | L2, L5 | Reste : aligner le rapport de micro-sujet sur les 6 blocs de `10_` §8.2 ; contenu EO1 (B12) |
| **L7** | Boucle de réévaluation TCF | **M** | L5, L6 | Le moteur V4.2 fournit déjà les états et les preuves ; il manque le déclencheur produit |
| **L8** | Référentiel de notions + tagging admin + migration | **XL** | L1 | **Chemin critique.** Chantier éditorial (B3), pas de code. La partie code (tables + écran de tagging) est **M** ; la partie contenu est le vrai coût |
| **L9** | Diagnostic civique + mises en situation | **L** | L8 | Le type `MISE_SITUATION` existe déjà (176 questions) ; le déséquilibre CSP/`CIV_PRINCIPES` est un risque de tirage |
| **L10** | Plan civique + répétition espacée + Réviser civique | **XL** | L9 | Leitner à construire **entièrement** (0 occurrence dans le dépôt), y compris son support de données |
| **L11** | Examens blancs civiques connectés au plan + Progrès unifié | **M** | L10 | Les examens blancs existent (21 templates) ; il s'agit de les brancher sur les boîtes |
| **L12** | Optimisation paywall + tableau de bord coûts IA | **M** | L5 | Dépend de B6 ; le « pack 3 mois » de A14 est caduc (B8) |

**Ordre recommandé, différent de celui de la spec** : L1 → L4 → L5 → L7 → L8 → L9 → L10 → L11.
L2 et L6 sont largement faits ; L3 est bloqué par un arbitrage (Q1) et n'a pas à retarder L4.

---

# 10. Questions ouvertes nécessitant un arbitrage produit

### Q1 — Le diagnostic rapide doit-il persister la production **avant** le compte ?

`10_` §3.4 l'exige (« la production est persistée sur l'`anon_id` **avant** l'écran de compte »).
`docs/regles/diagnostic.md` pose exactement l'inverse, comme une décision : « **Les productions
restent CÔTÉ CLIENT tant qu'il n'y a pas de compte** : aucune session diagnostique anonyme, aucune
ligne en base, aucun audio d'invité sur R2 — `diagnostic_sessions.user_id` reste `NOT NULL`, ne rien
rendre nullable. »
**Les deux ne peuvent pas être vraies.** Trancher avant L3.

### Q2 — Le diagnostic rapide remplace-t-il ou complète-t-il le diagnostic actuel ?

L'existant : **2 productions** (EE 100-130 mots + EO 2-3 min), analyse IA après compte, sans note /20.
La spec : **1 production écrite transversale** de 150-220 mots, sans EO.
Remplacer supprime le signal oral du diagnostic (et donc toute priorité EO initiale). Ajouter crée
**deux** diagnostics rapides concurrents. Trancher avant L3.

### Q3 — Confirme-t-on que le rapport EO n'aura **jamais** de lecteur audio ?

La décision « aucun audio de candidat conservé » est écrite comme irréversible. `30_` §6.3 et
`10_` §7.4 la contredisent. Si elle est maintenue (recommandé), corriger la spec (B7).

### Q4 — Quel modèle tarifaire pour le paywall de la refonte ?

Pass à achat unique (état réel) ou retour à un abonnement mensuel (hypothèse de la spec) ? Toute la
rédaction du paywall en dépend, et la formulation actuelle de la spec serait **fausse** sur des pass.

### Q5 — Que fait-on des 41 fichiers de test présents sur les fronts ?

`CLAUDE.md` interdit tout test front, « cette règle prime sur toute consigne de test écrite
ailleurs » — or `00_` §14 (« chaque lot livre backend + web + mobile + **tests** ») et `10_` §13
(« un test de rendu web et mobile ») en demandent explicitement. Trois options : les supprimer, les
garder en dérogation, ou lever l'interdiction. Ne rien faire sans arbitrage.

### Q6 — Le référentiel de 54 notions est-il tenable au vu du catalogue ?

54 notions × 3 mentions × 6 questions = 972 minimum pour 1 016 questions disponibles. Réduire le
référentiel, accepter massivement `insufficient_content`, ou produire du contenu ?

### Q7 — Introduit-on `/api/v1` ?

La spec écrit toutes ses routes en `/api/v1/...` ; le dépôt n'a pas de versionnement d'URL sur ses
48 contrôleurs. Adopter `/api/v1` **pour les seuls nouveaux endpoints** créerait deux conventions.
Recommandation : **ne pas l'introduire**, corriger la spec.

### Q8 — Le proxy de mention par `difficulty` est-il conservé ?

Voir B2. C'est la question qui décide si le module civique est une **extension** de l'existant ou une
**migration** du catalogue.

---

## Critères d'acceptation de la phase 0 (`00_` §2.4)

- [x] Le fichier existe et suit le plan imposé (10 sections).
- [x] Aucun autre fichier n'a été créé ou modifié.
- [x] Les 10 sections sont remplies.
- [x] Les volumétries §3 sont chiffrées, chaque affirmation sur la base est accompagnée de sa requête.
- [x] La section 8 propose une recommandation par blocage (12 blocages, 12 recommandations).
- [x] Aucun chiffre estimé : tout est mesuré ou marqué non mesurable avec sa raison.
- [ ] **Prompts recopiés intégralement** — déviation assumée et motivée en §4.2 (2,2 Mo, ~50 fichiers
      versionnés). Le seul contrat court est recopié verbatim ; les autres sont référencés par chemin
      exact et par version active.
