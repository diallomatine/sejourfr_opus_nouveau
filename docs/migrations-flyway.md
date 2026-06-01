# Migrations Flyway — organisation et convention de numérotation

Flyway scanne récursivement `classpath:db/migration` (prod & dev) et
`classpath:db/migration-dev` (dev uniquement). L'arborescence est organisée par **plages
numériques** (qui ordonnent l'exécution) et par **dossiers thématiques** (organisation
visuelle seulement). C'est **le numéro de version** qui détermine l'ordre, pas le dossier ;
les plages garantissent l'ordre logique schéma → référence → contenu.

```
db/migration/
├── 00_schema/                       V001-V099   DDL pur : un CREATE TABLE par fichier/domaine
│   ├── V001__schema_users_auth.sql              users, tokens (reset/email/refresh)
│   ├── V002__schema_billing.sql                 plans, user_subscriptions, processed_external_events
│   ├── V003__schema_themes_media_passages.sql   themes, medias, passages
│   ├── V004__schema_questions_choices.sql       questions, choices
│   ├── V005__schema_exam_templates.sql          exam_templates, exam_template_rules
│   ├── V006__schema_attempts_answers.sql        attempts, attempt_questions, answers
│   ├── V007__schema_user_question_status.sql    user_question_statuses
│   ├── V008__schema_support.sql                 conversations, messages
│   ├── V009__schema_audio_question_draft.sql    audio_question_draft
│   ├── V010__schema_audio_generation_logs.sql   audio_question_generation_logs
│   └── V011__schema_production.sql              production_tasks/submissions, transcriptions,
│                                                 ai_evaluations, human_calibration_notes, production_examples
│
├── 100_reference/                   V100-V199   données de référence (fixes, prod + dev)
│   ├── V100__ref_plans.sql                      catalogue plans (abonnements dormants + passes one-time)
│   ├── V101__ref_themes.sql                     8 thèmes (CIVIQUE ×5, TCF CO/CE/STRUCTURE)
│   └── V110__ref_exam_templates.sql             exam_templates + exam_template_rules
│
├── 200_civique/                     V200-V299   contenu civique (questions + choix), par sous-thème
│   ├── principes_valeurs/           V201-V219
│   ├── systeme_institutionnel/      V221-V239
│   ├── droits_devoirs/              V241-V259
│   ├── histoire_geo_culture/        V261-V279
│   └── vivre_en_societe/            V281-V299
│
└── 300_tcf/                         V400-V899   contenu TCF (1 centaine par épreuve, 30 numéros par niveau)
    ├── ce_comprehension_ecrite/     V400-V499   a2=V400-V429, b1=V430-V459, b2=V460-V489
    ├── co_comprehension_orale/      V500-V599   a2=V500-V529, b1=V530-V559, b2=V560-V589
    │   └── audio_drafts/            V800-V899   a2=V800-V829, b1=V830-V859, b2=V860-V889 (audio_question_draft)
    ├── structure_langue/            V600-V699   a2=V600-V629, b1=V630-V659, b2=V660-V689
    ├── production/                  V700-V719   production_tasks (sujets EO/EE), par épreuve puis tâche
    │   ├── ee/tache_{1,2,3}/        V700/V702/V704   EE : 3 sujets par fichier (A2/B1/B2)
    │   └── eo/tache_{1,2,3}/        V710/V712/V714   EO : 3 sujets par fichier (A2/B1/B2)
    └── expression/                  V720-V799   production_examples (exemples-modèles EO)

db/migration-dev/                    V900+       seeds dev uniquement (comptes seed, sub démo,
                                                 ~15 questions démo, conversations factices)
```

## Règles

- **`00_schema/` = DDL uniquement** : `CREATE TABLE`/`INDEX`/contraintes/`COMMENT`, aucun
  INSERT. Chaque table est créée dans sa **forme finale** (toutes les évolutions intégrées),
  ordre des fichiers respectant les dépendances de clés étrangères.
- **`100_reference/` à `300_tcf/` = INSERT propres** régénérés depuis l'état final de la
  base (déterministes, UUID explicites → rejouables à l'identique sur dev **et** recette).
- L'ordre d'exécution suit le **numéro V**, jamais le dossier. Respecter les plages
  ci-dessus pour conserver schéma → référence → contenu, et l'ordre des FK (ex. `themes`
  avant `questions`).
- **Médias / audio / passages TCF vivent dans le même fichier que les questions qui les
  référencent** (CO/CE), pas dans un dossier `00_shared` séparé. Convention de bloc : les
  `INSERT INTO medias` puis `INSERT INTO passages` en **haut** du fichier, l'`INSERT INTO
  questions` + `choices` **en dessous** (l'ordre intra-fichier satisfait les FK). Chaque
  média/passage n'est référencé que par un seul fichier de questions, donc aucun partage
  inter-fichiers à gérer.
- Garder les fichiers **courts** : plusieurs lots par niveau plutôt qu'un fichier massif.

## Ajouter une migration

- **Évolution de schéma** → `00_schema/`, prochain `V0xx` libre.
- **Nouvelle donnée de référence** → `100_reference/`, prochain `V1xx`.
- **Nouveau lot de contenu** → sous-dossier du domaine/niveau concerné, prochain numéro
  libre dans la plage (chaque sous-thème / niveau a ~20 slots).

`out-of-order: true` est activé : l'ordre d'ajout n'est pas contraint tant que les numéros
restent uniques.

## Réinitialiser une base de dev / recette

La réorganisation a **réécrit l'historique** : les checksums ne correspondent plus aux
anciennes lignes de `flyway_schema_history`. Une base déjà migrée avec l'ancienne
arborescence **doit repartir de zéro** :

```bash
# Sauvegarder si besoin, puis :
psql -U diallomatine -d postgres \
  -c "DROP DATABASE sejourfr_nouveau_2;" \
  -c "CREATE DATABASE sejourfr_nouveau_2;"
# Le prochain boot (profil dev) rejoue toutes les migrations + le seed dev.
```

> ⚠️ Sur une base de **production** avec données à conserver, ne pas appliquer cette
> réorganisation sans stratégie de baseline dédiée.
