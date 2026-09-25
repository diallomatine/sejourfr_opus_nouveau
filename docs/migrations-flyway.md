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
│   ├── V026-V031                                guidage des petits sujets (V026), qualité de
│   │                                             transcription (V027), production_tasks.titre
│   │                                             (V028, intitulé éditorial d'un sujet EE/EO),
│   │                                             diagnostic + Plan (V029), funnel (V030),
│   │                                             moteur de maîtrise (V031 : sources d'examen
│   │                                             blanc + learning_plan_observations.subject_id)
│   ├── V032-V045                                analytics (V043), moteur de progression V4.2
│   │                                             (V044), bande de difficulté (V045)
│   ├── V046-V048                                lot L1 de la refonte : idempotence des
│                                                 soumissions payantes (V046, clé client +
│                                                 index unique par utilisateur),
│                                                 users.exam_date (V047), vue de lecture
│                                                 v_ai_usage (V048 — une VUE, pas une table :
│                                                 les 4 sources écrivent déjà leur coût)
│   ├── V050-V053                                diagnostic oral facultatif (V050),
│   │                                             notions civiques + tagging (V051),
│   │                                             diagnostic civique (V052) et sa
│   │                                             variante invité (V053)
│   ├── V054__tracabilite_tagging_notions.sql    traçabilité du pré-tagging :
│   │                                             prompt_version (NOT NULL, sans
│   │                                             défaut), rationale, review_verdict
│   │                                             (CHECK 4 valeurs), reviewed_by/at,
│   │                                             batch_id. 🛑 N'OUVRE AUCUN CHEMIN
│   │                                             D'APPLICATION AUTOMATIQUE d'une
│   │                                             suggestion vers
│   │                                             questions.civic_notion_id
│   ├── V055-V057                                le référentiel de notions s'ajuste :
│   │                                             `description` d'une notion + notion
│   │                                             « fêtes et jours fériés » (V055),
│   │                                             frontière droits ⇄ dates (V056), et
│   │                                             la suggestion « AUCUNE notion ne
│   │                                             convient » (V057 : `notion_id`
│   │                                             nullable, unicité en NULLS NOT
│   │                                             DISTINCT). 🛑 V057 NE CRÉE AUCUNE
│   │                                             notion technique « AUCUNE » :
│   │                                             l'absence de rattachement s'écrit
│   │                                             avec l'absence de valeur
│   ├── V049__diagnostic_tcf_complet.sql         lot L4 : tcf_diagnostic_sessions +
│   │                                             attempts.tcf_diagnostic_id. 🛑 CE
│   │                                             DISCRIMINANT SE FILTRE PARTOUT
│   │                                             (`tcf_diagnostic_id IS NULL`), comme
│   │                                             production_tasks.diagnostic_code : sans
│   │                                             lui un diagnostic occuperait un slot de
│   │                                             la grille des examens blancs
│   ├── V058-V062                                le référentiel civique se stabilise :
│   │                                             référentiel validé (V058), frontière
│   │                                             impôts ⇄ institutions (V060), thème
│   │                                             source d'une suggestion (V061),
│   │                                             provenance des verdicts (V062).
│   │                                             ⚠️ V059 N'EXISTE PAS (trou assumé)
│   ├── V063-V065                                skills.learning_points (V063), ordre
│   │                                             d'affichage des sujets (V064), et la
│   │                                             première place du Plan épinglée
│   │                                             (V065 : plan_pinned_priorities)
│   ├── V066__schema_journey_tcf.sql             le PARCOURS TCF persisté : journey +
│   │                                             journey_lot + journey_step +
│   │                                             journey_assessment_event. 🛑 SEULES LA
│   │                                             STRUCTURE ET LA CLÔTURE y vivent ; le
│   │                                             statut d'affichage et le verrou restent
│   │                                             dérivés à la lecture
│   ├── V067__schema_cycle_journey_et_freebie.sql le parcours devient un CYCLE BORNÉ :
│   │                                             journey.module / status / entry_level /
│   │                                             exit_level / historise_at, deux index
│   │                                             uniques PARTIELS (un EN_COURS + un
│   │                                             EN_ATTENTE par candidat et module) en
│   │                                             remplacement de uq_journey_user_target,
│   │                                             et free_entitlement_usage — le ledger
│   │                                             unique de « offert une fois »
│   ├── V068-V072                                unités officielles de l'examen civique
│   │                                             (V068), cycle civique (V069-V071),
│   │                                             lien d'une série d'étape (V072)
│   └── V073__schema_emails.sql                  le système d'emails : préférences,
│                                                 journal d'envoi (anti-doublon par
│                                                 index unique PARTIEL), et la VUE
│                                                 v_derniere_activite_entrainement
│                                                 (docs/regles/emails.md)
│
├── 100_reference/                   V100-V199   données de référence (fixes, prod + dev)
│   ├── V100__ref_plans.sql                      catalogue plans (abonnements dormants + passes one-time)
│   ├── V101__ref_themes.sql                     8 thèmes (CIVIQUE ×5, TCF CO/CE/STRUCTURE)
│   ├── V110-V111                                exam_templates + exam_template_rules
│   └── V112-V114                                correctifs/compléments de référence
│                                                 (reset cecrl V112, realtime_eo_sessions V113,
│                                                 passes courts Intégral V114)
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
    │                                            (EE1-EE3 = V300-V302, EO1-EO3 = V303-V305),
    │                                            puis les 6 compétences de compréhension
    │                                            (V318) et la taxonomie V3 (V319-V320)
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

🛑 **UNE EXCEPTION DE NUMÉROTATION, ET UNE SEULE** :
`00_schema/V879__drop_attempts_cecrl_level.sql` (2026-09-20). C'est du DDL, donc sa place
est bien dans `00_schema/`, mais son NUMÉRO est volontairement hors de la plage V001-V099.
Motif : la colonne qu'il supprime est **écrite** par une migration de référence
(`100_reference/V112__reset_tcf_cecrl_levels`). Flyway ordonnant par numéro et non par
dossier, un drop en V0xx s'exécuterait AVANT elle et ferait échouer toute base neuve sur
« column cecrl_level does not exist ». D'où V879 : après tout le contenu (max V878), avant
le seed dev (V900). **Règle générale à retenir : le drop d'une colonne que des migrations
postérieures alimentent se numérote APRÈS elles.**

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

- **Évolution de schéma** → `00_schema/`, prochain `V0xx` libre. **Max actuel : `V074`**
  (2026-09-25 : `V074__schema_suivi_tunnel_diagnostic.sql` — tout le DDL du chantier
  « Suivi » : `diagnostic_run`, `purchase_intent`, `payment_refunds`, colonnes de
  revenu/attribution de `user_subscriptions`, colonnes V074 d'`analytics_event`,
  `users.signup_*` + `is_internal`, `analytics_visitor.ft_source_raw` ; son
  initialisation de `is_internal` est rejouée par `SuiviSchemaV074IT` via la sentinelle
  `@@INITIALISATION_IS_INTERNAL@@`) → le prochain est `V075`. Seed dev : `V901`
  (comptes seed internes) suit `V900`.
  ⚠️ `V059` n'existe pas : trou assumé, `out-of-order: true` le rend sans conséquence.
  ⚠️ **Un backfill de CONTENU seedé ne peut pas vivre en `00_schema`** : l'ordre suit le
  numéro, donc un `UPDATE` en `V0xx` s'exécute **avant** les `INSERT` des plages 200/300 et
  ne trouve aucune ligne. On garde la DDL en `00_schema` et on pose l'`UPDATE` dans la plage
  du contenu visé, **après** ses lots (patron `V037` + `V590`, cf. ci-dessous).
- **Nouvelle donnée de référence** → `100_reference/`, prochain `V1xx`. Max actuel : `V114`.
- **Nouveau lot de contenu** → sous-dossier du domaine/niveau concerné, prochain numéro
  libre dans la plage. Vérifier les slots restants de la sous-plage visée avant de choisir.
  Maxima réellement occupés, **recomptés le 2026-09-18** (`find db/migration -name 'V*.sql'`) :

  | famille                                | max occupé | reste dans la plage |
  |----------------------------------------|-----------:|---------------------|
  | `200_civique/` (racine : rangements et correctifs) | V295 | V296-V299 (4) |
  | `200_civique/` (par sous-thème)         | V202 / V225 / V245 / V265 / V285 | ~15 slots par sous-thème |
  | `300_tcf/competences/`                  | V320       | V321-V399 (79)      |
  | `300_tcf/ce_comprehension_ecrite/`      | V483       | V484-V499 (16), + les trous entre paliers |
  | `300_tcf/co_comprehension_orale/`       | V590 (backfill `audio_mode`) | V501-V529, V531-V559, V561-V589, V591-V599 |
  | `300_tcf/structure_langue/`             | V686       | V687-V699 (13)      |
  | `300_tcf/production/`                   | V757, + **V878** (allowlist taxonomie V3) | V758-V759, et ee/eo jusqu'à V724 / V753 |
  | `300_tcf/expression/`                   | V762       | V763-V799           |
  | `300_tcf/…/audio_drafts/` a2 / b1 / b2  | V814 / V845 / V877 | ⚠️ **b2 s'arrête à V877** : V878 est pris par `production/` |
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
