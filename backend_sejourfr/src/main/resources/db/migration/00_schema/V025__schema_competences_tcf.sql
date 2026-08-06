-- ============================================================================
-- V025 — Schéma : module « Compétences TCF » (micro-entraînement EE/EO)
-- ----------------------------------------------------------------------------
-- Tables : skills, skill_prompts, skill_references, user_skill_attempts
--
-- OBJET — voie PARALLÈLE aux productions complètes (`production_tasks` /
-- `production_submissions`). Là, le candidat rend une tâche TCF entière notée
-- sur 20 avec un niveau CECRL ; ici, il travaille UNE micro-compétence à la
-- fois sur un « petit sujet » de quelques phrases, et l'IA ne rend qu'un
-- verdict sur le CRITÈRE UNIQUE du sujet. Aucune note, aucun niveau : c'est
-- pour cela que rien n'est réutilisé du schéma production.
--
-- HIÉRARCHIE : 6 tâches TCF (EE1..EE3, EO1..EO3) × 8 compétences × 5 petits
-- sujets × 3 références = 48 compétences, 240 sujets, 720 références. Il n'y a
-- volontairement PAS de table `skill_tasks` : les 6 tâches sont un référentiel
-- officiel figé (enum `SkillTaskCode` côté Java), pas du contenu éditorial. Le
-- rattachement se fait par la colonne `task_code`.
--
-- FREEMIUM : aucun sujet n'est verrouillé — produire, s'auto-évaluer et lire
-- les 3 références est gratuit pour tout compte inscrit. Seule l'ANALYSE IA est
-- payante (3 offertes à vie aux comptes gratuits), ce qui explique la colonne
-- `analysis_requested` et son index partiel : le quota se compte sur les
-- analyses DEMANDÉES, pas sur les tentatives.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- skills — les 8 compétences d'une tâche TCF
-- ---------------------------------------------------------------------------
CREATE TABLE skills
(
    id            uuid         NOT NULL PRIMARY KEY,
    -- Épreuve d'appartenance. Dénormalisée depuis task_code (cf. CHECK plus
    -- bas) parce que c'est l'axe de filtrage principal côté application ET la
    -- colonne référencée par la FK composite de skill_prompts.
    section       varchar(2)   NOT NULL,
    task_code     varchar(3)   NOT NULL,
    -- Code éditorial stable ('EE1-C1'). Les seeds et l'admin s'appuient dessus,
    -- il est immuable après création : d'où l'unicité en base plutôt qu'un
    -- simple contrôle applicatif.
    code          varchar(16)  NOT NULL,
    title         varchar(160) NOT NULL,
    -- Sert d'encart « Pourquoi cet exercice ? » côté fronts : ce que le critère
    -- apporte au TCF. NOT NULL car un candidat ne doit jamais tomber sur une
    -- compétence sans explication.
    description   text         NOT NULL,
    -- Le CRITÈRE GÉNÉRAL de la compétence, distinct de l'explication ci-dessus.
    -- La spec (§3, niveau 4) demande d'afficher les deux : « une courte
    -- explication » ET « le critère général travaillé ». Les confondre obligeait
    -- les fronts à rendre le même texte à deux endroits de l'écran. La valeur
    -- seedée est la phrase de définition de la compétence dans la spec.
    -- À ne pas confondre non plus avec skill_prompts.unique_criterion, qui est
    -- le critère précis et unique d'UN petit sujet : celui-ci couvre les 5.
    general_criterion text     NOT NULL,
    target_level  varchar(4)   NOT NULL,
    -- Rang d'affichage 1..8 dans sa tâche. Unique par tâche pour qu'aucune
    -- édition admin ne puisse produire deux compétences au même rang — l'ordre
    -- est pédagogique (progression du simple au complexe), pas décoratif.
    display_order smallint     NOT NULL,
    is_active     boolean      NOT NULL DEFAULT true,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_skills_code UNIQUE (code),
    -- DEFERRABLE INITIALLY DEFERRED : sans cela, echanger le rang de deux
    -- competences depuis l'admin violerait l'unicite DES la premiere des deux
    -- mises a jour, avant meme le COMMIT — un simple reordonnancement serait
    -- impossible sans rang « parking » temporaire. Differee, la contrainte
    -- n'est verifiee qu'a la fin de la transaction, quand l'echange est
    -- complet. Elle garantit exactement la meme chose au repos.
    CONSTRAINT uq_skills_task_order UNIQUE (task_code, display_order)
        DEFERRABLE INITIALLY DEFERRED,
    -- Cible de la FK composite de skill_prompts : Postgres exige que les
    -- colonnes référencées portent une contrainte d'unicité. Techniquement
    -- redondant avec la PK, mais c'est ce qui rend la dénormalisation de
    -- `section` VÉRIFIABLE par la base au lieu d'être une promesse applicative.
    CONSTRAINT uq_skills_id_section UNIQUE (id, section),
    CONSTRAINT chk_skills_section CHECK (section IN ('EE', 'EO')),
    CONSTRAINT chk_skills_task_code CHECK (task_code IN ('EE1', 'EE2', 'EE3', 'EO1', 'EO2', 'EO3')),
    CONSTRAINT chk_skills_target_level CHECK (target_level IN ('A1', 'A2', 'B1', 'B2')),
    -- Borne haute 50 et non 8. La regle produit « exactement 8 competences
    -- actives par tache » reste vraie, mais elle est verrouillee par un TEST
    -- SUR LE SEED, pas par le DDL : avec 48 lignes seedees et
    -- uq_skills_task_order, les 8 rangs legaux de chaque tache etaient tous
    -- occupes, donc la console admin ne pouvait creer AUCUNE competence et son
    -- CRUD devenait decoratif. Le CHECK ne sert plus qu'a garder une valeur
    -- manifestement fausse hors de la base.
    CONSTRAINT chk_skills_display_order CHECK (display_order BETWEEN 1 AND 50),
    -- 'EE1' ⇒ 'EE'. Interdit la seule incohérence que la dénormalisation rend
    -- possible : une compétence rangée dans l'épreuve d'une autre tâche.
    CONSTRAINT chk_skills_section_matches_task CHECK (left(task_code, 2) = section)
);

COMMENT ON TABLE skills IS
    'Micro-competences TCF : 8 par tache (EE1..EE3, EO1..EO3). Contenu editorial, pilote par l''admin.';

-- ---------------------------------------------------------------------------
-- skill_prompts — les 5 « petits sujets » d'une compétence
-- ---------------------------------------------------------------------------
CREATE TABLE skill_prompts
(
    id                          uuid         NOT NULL PRIMARY KEY,
    skill_id                    uuid         NOT NULL,
    -- Dénormalisée depuis la compétence parente : c'est elle qui rend
    -- vérifiable en base la cohérence « sujet écrit ⇒ fourchette de mots,
    -- sujet oral ⇒ durée » (CHECK chk_skill_prompts_ee_eo_coherence). Sans
    -- elle, la contrainte demanderait une jointure, ce qu'un CHECK ne permet
    -- pas. La FK COMPOSITE ci-dessous garantit qu'elle ne peut pas mentir.
    section                     varchar(2)   NOT NULL,
    code                        varchar(24)  NOT NULL,
    title                       varchar(160) NOT NULL,
    context                     text         NOT NULL,
    instruction                 text         NOT NULL,
    -- LE critère unique évalué par l'IA sur ce sujet. Un sujet = un critère :
    -- c'est le principe du module, et la seule chose que l'analyse regarde.
    unique_criterion            text         NOT NULL,
    -- Longueur/durée CONSEILLÉE, jamais bloquante (règle 15 de la spec) :
    -- l'affichage s'en sert pour cadrer l'effort, le serveur ne refuse jamais
    -- une production parce qu'elle sort de la fourchette.
    recommended_min_words       integer,
    recommended_max_words       integer,
    recommended_duration_seconds integer,
    difficulty_level            varchar(8)   NOT NULL,
    display_order               smallint     NOT NULL,
    is_active                   boolean      NOT NULL DEFAULT true,
    created_at                  timestamptz  NOT NULL DEFAULT now(),
    updated_at                  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT fk_skill_prompts_skill FOREIGN KEY (skill_id, section)
        REFERENCES skills (id, section) ON DELETE CASCADE,
    CONSTRAINT uq_skill_prompts_code UNIQUE (code),
    -- Differee pour la meme raison que uq_skills_task_order : reordonner deux
    -- sujets d'une competence depuis l'admin est une transaction unique dont
    -- l'etat INTERMEDIAIRE viole forcement l'unicite.
    CONSTRAINT uq_skill_prompts_skill_order UNIQUE (skill_id, display_order)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT chk_skill_prompts_section CHECK (section IN ('EE', 'EO')),
    CONSTRAINT chk_skill_prompts_difficulty CHECK (difficulty_level IN ('EASY', 'MEDIUM', 'HARD')),
    -- 20 et non 5 : la borne haute laisse de la marge éditoriale (enrichir une
    -- compétence sans migration) tout en gardant une valeur manifestement
    -- fausse hors de la base.
    CONSTRAINT chk_skill_prompts_display_order CHECK (display_order BETWEEN 1 AND 20),
    CONSTRAINT chk_skill_prompts_words_range CHECK (
        recommended_min_words IS NULL OR recommended_max_words IS NULL
            OR recommended_min_words < recommended_max_words
        ),
    -- Un sujet écrit se mesure en mots, un sujet oral en secondes — jamais les
    -- deux, jamais aucun. Ce qui bloque en amont l'incohérence la plus
    -- coûteuse : un sujet EO qui afficherait un compteur de mots au candidat.
    CONSTRAINT chk_skill_prompts_ee_eo_coherence CHECK (
        (section = 'EE' AND recommended_min_words IS NOT NULL
            AND recommended_max_words IS NOT NULL
            AND recommended_duration_seconds IS NULL)
            OR (section = 'EO' AND recommended_duration_seconds IS NOT NULL
            AND recommended_min_words IS NULL
            AND recommended_max_words IS NULL)
        )
);

CREATE INDEX idx_skill_prompts_skill_order ON skill_prompts (skill_id, display_order);

COMMENT ON TABLE skill_prompts IS
    'Petits sujets d''une competence (5 par competence). Chacun porte UN critere unique, seul objet de l''analyse IA.';

-- ---------------------------------------------------------------------------
-- skill_references — les 3 productions de référence d'un sujet
-- ---------------------------------------------------------------------------
-- Elles ne sont servies au candidat qu'APRÈS sa propre production (garde
-- serveur côté API) : les lire avant reviendrait à recopier le modèle.
CREATE TABLE skill_references
(
    id               uuid        NOT NULL PRIMARY KEY,
    skill_prompt_id  uuid        NOT NULL REFERENCES skill_prompts (id) ON DELETE CASCADE,
    level            varchar(12) NOT NULL,
    text             text        NOT NULL,
    -- Ce que la référence démontre, en une phrase adressée au candidat. NOT
    -- NULL : une référence sans explication n'apprend rien.
    pedagogical_note text        NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    -- Exactement une référence par niveau et par sujet : c'est ce qui rend le
    -- remplacement admin (PUT des 3 d'un coup) sûr et idempotent.
    CONSTRAINT uq_skill_references_prompt_level UNIQUE (skill_prompt_id, level),
    CONSTRAINT chk_skill_references_level CHECK (level IN ('INSUFFICIENT', 'EXPECTED', 'EXCELLENT'))
);

COMMENT ON TABLE skill_references IS
    'Trois productions de reference par sujet (insuffisante / attendue / tres reussie), revelees apres la production du candidat.';

-- ---------------------------------------------------------------------------
-- user_skill_attempts — une production du candidat sur un petit sujet
-- ---------------------------------------------------------------------------
CREATE TABLE user_skill_attempts
(
    id                   uuid        NOT NULL PRIMARY KEY,
    user_id              uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    skill_prompt_id      uuid        NOT NULL REFERENCES skill_prompts (id) ON DELETE CASCADE,
    written_production   text,
    -- CLÉ D'OBJET R2, jamais une URL — même convention que
    -- production_submissions.media_url. L'URL présignée (TTL court) est
    -- fabriquée à la volée au moment de servir le DTO : stocker une URL
    -- signée en base la rendrait périmée, stocker une URL publique rendrait
    -- l'audio d'un candidat accessible sans authentification.
    audio_object_key     varchar(500),
    audio_duration_sec   integer,
    -- Transcription Whisper (EO). Volontairement NULL quand le candidat n'a
    -- pas demandé d'analyse : on ne paie pas Whisper pour un audio que
    -- personne ne corrigera. L'audio, lui, est conservé dans tous les cas.
    transcript           text,
    words_count          integer,
    -- Déclaratif, facultatif, et sans AUCUNE influence sur le verdict IA :
    -- c'est un miroir proposé au candidat, pas une entrée de la correction.
    self_evaluation      varchar(12),
    statut               varchar(16) NOT NULL,
    -- Vrai dès que l'analyse a été ACCEPTÉE (quota consommé au moment de
    -- l'acceptation, pas au succès) : sinon un retry gratuit après un échec
    -- fournisseur permettrait d'obtenir plus de 3 analyses offertes.
    analysis_requested   boolean     NOT NULL DEFAULT false,
    criterion_status     varchar(16),
    -- Sortie stricte de l'analyse ciblée : status, verdict, success_point,
    -- improvement_priority, improved_version. Aucune note /20, aucun niveau
    -- CECRL — interdits sur un micro-exercice.
    analysis_json        jsonb,
    ai_model             varchar(64),
    prompt_version       varchar(16),
    rubrics_version      varchar(16),
    tokens_input         integer,
    tokens_output        integer,
    cout_estime_centimes integer,
    -- Relances d'analyse deja consommees sur cette tentative. Le retry est
    -- offert (l'echec n'est pas du fait du candidat, et le quota freemium a
    -- ete decompte a l'acceptation) : sans compteur PERSISTE, il serait donc
    -- illimite, et une panne fournisseur se traduirait par une boucle d'appels
    -- payants. Meme convention et meme plafond que
    -- production_submissions.retry_count.
    retry_count          smallint    NOT NULL DEFAULT 0,
    error_message        text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_user_skill_attempts_statut CHECK (
        statut IN ('RECORDED', 'SUBMITTED', 'TRANSCRIBING', 'EVALUATING', 'EVALUATED', 'FAILED')
        ),
    CONSTRAINT chk_user_skill_attempts_self_eval CHECK (
        self_evaluation IS NULL OR self_evaluation IN ('REUSSI', 'INCERTAIN', 'DIFFICILE')
        ),
    CONSTRAINT chk_user_skill_attempts_criterion CHECK (
        criterion_status IS NULL OR criterion_status IN ('VALIDATED', 'PARTIAL', 'NOT_VALIDATED')
        ),
    -- Une tentative sans production n'existe pas : le texte (EE) ou l'audio
    -- (EO) doit être présent. L'upload R2 se fait donc AVANT l'insert.
    CONSTRAINT chk_user_skill_attempts_has_production CHECK (
        written_production IS NOT NULL OR audio_object_key IS NOT NULL
        ),
    -- Plafond en base ET dans le service : le service rend un message utile au
    -- candidat (422), la contrainte garantit qu'aucun autre chemin d'ecriture
    -- ne pourra le contourner. Meme borne que chk_prod_sub_retry_count.
    CONSTRAINT chk_user_skill_attempts_retry_count CHECK (retry_count BETWEEN 0 AND 3)
);

COMMENT ON COLUMN user_skill_attempts.retry_count IS
    'Relances manuelles via POST /api/skill-attempts/{id}/retry. Plafonne a 3 (anti-abus) : le retry ne reconsomme pas le quota freemium, il serait sinon illimite.';

-- Lecture dominante : « le statut et l'historique de CE user sur CE sujet »,
-- la plus récente d'abord (c'est la dernière tentative qui donne le statut).
CREATE INDEX idx_user_skill_attempts_user_prompt
    ON user_skill_attempts (user_id, skill_prompt_id, created_at DESC);

-- Index PARTIEL dédié au comptage du quota gratuit : seules les tentatives
-- ayant consommé une analyse y entrent, donc il reste minuscule même si la
-- table grossit avec les productions non analysées (qui, elles, sont
-- illimitées et gratuites).
CREATE INDEX idx_user_skill_attempts_analysis_quota
    ON user_skill_attempts (user_id)
    WHERE analysis_requested;

COMMENT ON TABLE user_skill_attempts IS
    'Productions des candidats sur les petits sujets. analysis_requested = true marque la consommation d''une analyse IA (quota freemium).';
