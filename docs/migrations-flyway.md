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
│   ├── V011__schema_production.sql              production_tasks/submissions, transcriptions,
│   │                                             ai_evaluations, human_calibration_notes, production_examples
│   ├── V012-V024                                évolutions ciblées : colonnes et tables annexes
│   │                                             (page_views V020, agent_role_card V021,
│   │                                             ai_evaluations.rubrics_version V022) et
│   │                                             correctifs de données (V023, V024)
│   ├── V025__schema_competences_tcf.sql         skills, skill_prompts, skill_references,
│   │                                             user_skill_attempts (module Compétences TCF)
│   └── V026-V031                                guidage des petits sujets (V026), qualité de
│                                                 transcription (V027), production_tasks.titre
│                                                 (V028, intitulé éditorial d'un sujet EE/EO),
│                                                 diagnostic + Plan (V029), funnel (V030),
│                                                 moteur de maîtrise (V031 : sources d'examen
│                                                 blanc + learning_plan_observations.subject_id)
│
├── 100_reference/                   V100-V199   données de référence (fixes, prod + dev)
│   ├── V100__ref_plans.sql                      catalogue plans (abonnements dormants + passes one-time)
│   ├── V101__ref_themes.sql                     8 thèmes (CIVIQUE ×5, TCF CO/CE/STRUCTURE)
│   ├── V110-V111                                exam_templates + exam_template_rules
│   └── V112-V113                                correctifs/compléments de référence
│                                                 (reset cecrl V112, realtime_eo_sessions V113)
│
├── 200_civique/                     V200-V299   contenu civique (questions + choix), par sous-thème
│   ├── principes_valeurs/           V201-V219
│   ├── systeme_institutionnel/      V221-V239
│   ├── droits_devoirs/              V241-V259
│   ├── histoire_geo_culture/        V261-V279
│   └── vivre_en_societe/            V281-V299
│
└── 300_tcf/                         V300-V899   contenu TCF (1 centaine par épreuve, 30 numéros par niveau)
    ├── competences/                 V300-V399   module Compétences TCF : skills + skill_prompts
    │                                            + skill_references, un fichier par tâche
    │                                            (EE1-EE3 = V300-V302, EO1-EO3 = V303-V305)
    │                                            ⚠ FICHIERS GÉNÉRÉS — ne pas éditer à la main
    ├── ce_comprehension_ecrite/     V400-V499   a2=V400-V429, b1=V430-V459, b2=V460-V489
    ├── co_comprehension_orale/      V500-V599   a2=V500-V529, b1=V530-V559, b2=V560-V589
    │   └── audio_drafts/            V800-V899   a2=V800-V829, b1=V830-V859, b2=V860-V889 (audio_question_draft)
    ├── structure_langue/            V600-V699   a2=V600-V629, b1=V630-V659, b2=V660-V689
    ├── production/                  V700-V759   production_tasks (sujets EO/EE), 10 numéros par tâche
    │   ├── ee/tache_{1,2,3}/        V700-V709 / V710-V719 / V720-V729
    │   ├── eo/tache_{1,2,3}/        V730-V739 / V740-V749 / V750-V759
    │   └── V754__tcf_production_titres.sql      les 103 titres éditoriaux (colonne V028)
    │                                            ⚠ FICHIER GÉNÉRÉ — ne pas éditer à la main
    └── expression/                  V760-V799   production_examples (exemples-modèles EE/EO)

db/migration-dev/                    V900+       seeds dev uniquement (comptes seed, sub démo,
                                                 ~15 questions démo, conversations factices)
```

## Règles

- **`00_schema/` = DDL uniquement** : `CREATE TABLE`/`INDEX`/contraintes/`COMMENT`, aucun
  INSERT. Chaque table est créée dans sa **forme finale** (toutes les évolutions intégrées),
  ordre des fichiers respectant les dépendances de clés étrangères.
  - **Exception : les correctifs de données** (`UPDATE` de réalignement après un bug
    d'écriture, ex. `V023__fix_attempt_epreuve_tcf.sql`) vivent aussi ici, faute d'autre
    plage adaptée — `100_reference/` sert aux données de référence et `200/300` au contenu.
    Ils doivent être **déterministes, bornés par une clause `WHERE` explicite, et
    idempotents** (rejouables sans effet). Jamais de `DELETE` d'historique utilisateur.
- **`100_reference/` à `300_tcf/` = INSERT propres** régénérés depuis l'état final de la
  base (déterministes, UUID explicites → rejouables à l'identique sur dev **et** recette).
- **Deux familles de fichiers sont GÉNÉRÉES — ne jamais les éditer à la main** :
  `300_tcf/competences/` (V300-V305) et `300_tcf/production/V754__tcf_production_titres.sql`.
  Même convention dans les deux cas : on édite le JSON de contenu, on régénère, et une
  fois les migrations appliquées c'est la **console d'administration** qui fait foi.

  ```bash
  cd backend_sejourfr && python3 tools/production-titres/generer_seed.py
  ```

  Le générateur des titres valide avant d'écrire (2 à 5 mots, aucun chiffre, aucun jargon
  déjà affiché ailleurs sur la carte, unicité à l'intérieur d'une tâche, UUID connus) et
  refuse de produire du SQL sur du contenu non conforme. Les sujets **existent déjà** en
  base (V700-V753) : la migration est une suite d'`UPDATE` bornés par `WHERE id =`,
  déterministes et idempotents — aucune ligne créée, aucune supprimée.

- **`300_tcf/competences/` (V300-V305) est GÉNÉRÉ — ne jamais l'éditer à la main.** Les six
  fichiers sortent du générateur **versionné** `backend_sejourfr/tools/competences/`
  (`generer_seed.py` + `contenu/*.json`, une fiche de contenu par tâche), et leurs UUID sont
  **déterministes** : `uuid5` calculé sur le code métier (`EE1-C1`, `EE1-C1-S1`…), donc
  stables d'un environnement à l'autre et identiques à chaque régénération.

  ```bash
  cd backend_sejourfr && python3 tools/competences/generer_seed.py
  ```

  **On édite le JSON puis on régénère, jamais le SQL** : corriger une ligne directement dans
  le `.sql` désynchronise les deux, et la prochaine régénération écrasera le correctif. Le
  script **valide avant d'écrire** (8 compétences par tâche, 5 sujets par compétence, 3
  références par sujet, cohérence EE mots / EO durée, unicité des codes) et refuse de
  produire du SQL sur du contenu non conforme. Aucune dépendance : Python 3 seul.
  - Le générateur ne sert qu'à **republier depuis une base propre**. Une fois les migrations
    appliquées, le contenu vivant s'édite depuis la **console d'administration**
    (`admin/features/skills/`) : c'est elle qui fait foi en base, pas le JSON.
  - Le volume publié (48 compétences, 240 sujets, 720 références) est verrouillé par
    `SkillSeedIT`, pas par le DDL.
  - La centaine **V300-V399 était entièrement libre** avant ce module : les six seeds y
    laissent 94 numéros à la famille. Ils ont d'abord porté les numéros V878-V883, qui
    empiétaient sur la plage des brouillons audio CO (`audio_drafts/`, V800-V899, b2 rempli
    jusqu'à V877) et ne lui laissaient plus que 6 numéros — d'où la renumérotation. Si une
    base de dev a déjà appliqué les anciens numéros, elle doit repartir de zéro (cf. plus
    bas).
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

- **Évolution de schéma** → `00_schema/`, prochain `V0xx` libre. **Max actuel : `V031`**
  (moteur de maîtrise) → le prochain est `V032`.
- **Nouvelle donnée de référence** → `100_reference/`, prochain `V1xx`. Max actuel : `V113`.
- **Nouveau lot de contenu** → sous-dossier du domaine/niveau concerné, prochain numéro
  libre dans la plage. Vérifier les slots restants de la sous-plage visée avant de choisir.
  Maxima réellement occupés aujourd'hui :

  | famille                                | max occupé | reste dans la plage |
  |----------------------------------------|-----------:|---------------------|
  | `200_civique/` (par sous-thème)         | V285       | ~15 slots par sous-thème |
  | `300_tcf/competences/`                  | V305       | V306-V399 (94)      |
  | `300_tcf/ce_comprehension_ecrite/`      | V400       | quasi toute la plage |
  | `300_tcf/co_comprehension_orale/`       | V500       | quasi toute la plage |
  | `300_tcf/structure_langue/`             | V600       | quasi toute la plage |
  | `300_tcf/production/`                   | V754       | V755-V759           |
  | `300_tcf/expression/`                   | V762       | V763-V799           |
  | `300_tcf/…/audio_drafts/` a2 / b1 / b2  | V814 / V845 / V877 | b2 = V878-V889 (rendus par la renumérotation des compétences) |
- **Nouveau lot de compétences** → ne pas ajouter un `V3xx` à la main : ajouter la tâche au
  générateur `tools/competences/` et régénérer (cf. règle ci-dessus).

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
