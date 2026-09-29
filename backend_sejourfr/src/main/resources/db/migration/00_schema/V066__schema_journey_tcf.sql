-- ============================================================================
-- V066 — Le PARCOURS TCF : une file d'etapes, persistee, pilotee par les
--        evaluations
-- ----------------------------------------------------------------------------
-- Spec : docs/progression/spec-plan-tcf-parcours-evaluations-v2.md
-- Arbitrages du proprietaire (D-1 a D-9) : docs/decisions/plan-parcours-tcf.md
--
-- CE QUE CES TABLES SONT, ET CE QU'ELLES NE SONT PAS.
-- Le Plan est entierement DERIVE depuis toujours : LearningPlanService recalcule
-- priorites, natures, etats et ordre a chaque GET. Ce qu'il ne savait pas
-- garder, c'est la MEMOIRE D'UNE DECISION D'ORDONNANCEMENT : « dans quel ordre
-- les evaluations de ce candidat ont-elles designe ses etapes, et laquelle a
-- deja ete clos ? ». Cet ordre depend de l'ordre d'arrivee des evaluations : il
-- ne se recalcule pas, donc il se persiste. C'est le meme argument que le depot
-- a deja accepte pour plan_pinned_priorities (V065) — que ces tables
-- REMPLACENT : la position d'une etape EST l'epingle.
--
-- 🛑 CE QUI N'ENTRE JAMAIS ICI (arbitrage D-7).
--   * L'ETAT DE MAITRISE. `SkillMasteryEngine` est la seule autorite sur « cette
--     competence est-elle acquise ? », et elle se relit. Une resolution
--     MASTERED posee ici dit « cette etape a ete clos PARCE QUE le moteur avait
--     conclu au transfert, A CETTE DATE » — un fait date, pas un verdict
--     courant. Un recalibrage du moteur ne reinterprete donc aucune etape
--     deja clos.
--   * LE STATUT D'AFFICHAGE. UPCOMING / CURRENT / COMPLETED / SKIPPED /
--     OBSOLETE sont TOUS derives a la lecture depuis closed_at, resolution,
--     journey_lot.status et l'ordre de cloture. Il n'y a donc AUCUNE colonne
--     `status` sur journey_step, et aucun index unique « une seule CURRENT » :
--     l'unicite de CURRENT est garantie par construction, par la promotion.
--   * LE VERROU FREEMIUM. `locked` se calcule a la lecture chez ses trois
--     autorites (SkillAccessService, enforceMockExamSlotAccess,
--     ProductionAccessService). Un abonnement souscrit change donc l'ecran sans
--     UNE SEULE ecriture en base.
--   * LE NIVEAU, LE SCORE, LES PRIORITES. Rien n'est recopie : les priorites
--     vivent dans learning_plan_observations, le niveau chez TcfProfileService.
--
-- AUCUNE MIGRATION DE DONNEES, ET C'EST VOULU. Les parcours se creent
-- PARESSEUSEMENT a la premiere ouverture du Plan (R19). Un backfill devrait
-- rejouer TcfProfileService + SkillMasteryEngine par utilisateur, donc embarquer
-- de la logique applicative dans une migration ; et le bootstrap est idempotent
-- par construction (journey_assessment_event). Un utilisateur qui n'ouvre jamais
-- le Plan n'a pas besoin de parcours.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- journey — un parcours par (candidat, niveau cible)
-- ---------------------------------------------------------------------------
-- UN PARCOURS PAR NIVEAU CIBLE (R18). Changer d'objectif ne detruit rien : on
-- bascule vers le parcours de ce niveau, l'ancien est conserve tel quel. Si
-- celui du nouveau niveau n'existe pas, le bootstrap (R19) le reconstruit depuis
-- les evaluations deja passees — un changement d'objectif ne force JAMAIS un
-- nouveau diagnostic.
--
-- 🛑 target_level est NOT NULL (arbitrage D-3) : « pas de parcours sans niveau
-- cible ». Un candidat qui n'a pas declare sa demarche n'a pas de ligne ici du
-- tout, et l'API rend NEEDS_OBJECTIVE. Le niveau se lit toujours chez
-- TargetProcedure.niveauVise() — la table des paliers a deja vecu en 6 copies.
CREATE TABLE journey
(
    id            uuid PRIMARY KEY,
    user_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    target_level  varchar(8)  NOT NULL,
    next_position bigint      NOT NULL DEFAULT 1,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_journey_user_target UNIQUE (user_id, target_level),
    CONSTRAINT chk_journey_target_level CHECK (target_level IN ('A2', 'B1', 'B2'))
);

COMMENT ON TABLE journey IS
    'Le parcours TCF d''un candidat pour UN niveau cible. Un changement d''objectif bascule '
        'vers un autre parcours ; l''ancien est conserve tel quel.';

COMMENT ON COLUMN journey.next_position IS
    'Compteur MONOTONE des positions d''etape. Jamais decremente, jamais renumerote : R4 veut '
        'qu''une nouvelle etape se range APRES tout ce qui est deja planifie, et une '
        'renumerotation ferait bouger un parcours que le candidat a sous les yeux.';

-- ---------------------------------------------------------------------------
-- journey_lot — un lot de priorites et son examen de cloture
-- ---------------------------------------------------------------------------
-- 🛑 « LOT », PAS « CYCLE » (arbitrage D-8). Le depot sert deja un CYCLE DE
-- PALIER CECRL aux fronts (PlanCycleDto, PlanCycleState, PlanCycleResolver) :
-- d'ou part le candidat, quel palier se construit, et son examen blanc complet
-- de confirmation. Deux « cycles » de sens different dans le meme ecran, c'est
-- exactement la collision qui a produit les six copies de la table des paliers.
-- « Lot » est le mot de la spec §2.
CREATE TABLE journey_lot
(
    id                        uuid PRIMARY KEY,
    journey_id                uuid        NOT NULL REFERENCES journey (id) ON DELETE CASCADE,
    exam_type                 varchar(20) NOT NULL,
    status                    varchar(16) NOT NULL,
    source_assessment_id      uuid        NOT NULL,
    closed_by_assessment_id   uuid,
    created_at                timestamptz NOT NULL DEFAULT now(),
    closed_at                 timestamptz,
    CONSTRAINT chk_journey_lot_exam_type
        CHECK (exam_type IN ('TCF_CO', 'TCF_CE', 'TCF_EO', 'TCF_EE')),
    CONSTRAINT chk_journey_lot_status
        CHECK (status IN ('OPEN', 'CLOSED', 'SUPERSEDED')),
    -- Un lot ferme porte sa date ; un lot ouvert n'en a pas. L'etat et la date
    -- ne peuvent donc pas se contredire.
    CONSTRAINT chk_journey_lot_closed_at
        CHECK ((status = 'OPEN') = (closed_at IS NULL))
);

-- R5 — AU PLUS UN LOT OUVERT PAR EPREUVE, tenu par la BASE et pas seulement par
-- le service : deux evaluations traitees en parallele sur la meme epreuve
-- doivent echouer, pas creer deux lots concurrents. Le verrou pessimiste sur
-- journey les serialise deja ; cet index est la ceinture.
CREATE UNIQUE INDEX uq_journey_lot_open_par_epreuve
    ON journey_lot (journey_id, exam_type) WHERE status = 'OPEN';

CREATE INDEX idx_journey_lot_journey ON journey_lot (journey_id);

COMMENT ON TABLE journey_lot IS
    'Les priorites retenues pour une epreuve lors d''une evaluation (3 max) et l''examen de '
        'reevaluation qui les cloture. Au plus un lot OPEN par epreuve (R5).';

COMMENT ON COLUMN journey_lot.status IS
    'OPEN / CLOSED / SUPERSEDED. PERSISTE, et ce n''est pas un derive : SUPERSEDED dit qu''une '
        'evaluation plus recente a pris la main, ce qui depend d''un EVENEMENT date et ne se '
        'recalcule pas.';

-- ---------------------------------------------------------------------------
-- journey_step — une etape de la file
-- ---------------------------------------------------------------------------
CREATE TABLE journey_step
(
    id                        uuid PRIMARY KEY,
    journey_id                uuid        NOT NULL REFERENCES journey (id) ON DELETE CASCADE,
    lot_id                    uuid        REFERENCES journey_lot (id) ON DELETE CASCADE,
    type                      varchar(20) NOT NULL,
    purpose                   varchar(24),
    exam_type                 varchar(20),
    skill_id                  uuid        REFERENCES skills (id) ON DELETE CASCADE,
    severity_rank             int,
    source_assessment_id      uuid,
    position                  bigint      NOT NULL,
    created_at                timestamptz NOT NULL DEFAULT now(),
    closed_at                 timestamptz,
    resolution                varchar(28),
    resolved_by_assessment_id uuid,
    CONSTRAINT chk_journey_step_type
        CHECK (type IN ('DIAGNOSTIC', 'TRAIN_SKILL', 'SECTION_EXAM')),
    CONSTRAINT chk_journey_step_purpose
        CHECK (purpose IS NULL OR purpose IN ('INITIAL_ASSESSMENT', 'REASSESS')),
    CONSTRAINT chk_journey_step_exam_type
        CHECK (exam_type IS NULL OR exam_type IN ('TCF_CO', 'TCF_CE', 'TCF_EO', 'TCF_EE')),
    CONSTRAINT chk_journey_step_resolution
        CHECK (resolution IS NULL OR resolution IN
               ('MASTERED', 'QUOTA_REACHED', 'SATISFIED_BY_ASSESSMENT', 'SUPERSEDED')),
    -- 🛑 UNE CLOTURE EST ATOMIQUE : la date et son motif s'ecrivent ENSEMBLE,
    -- une seule fois, et ne se reouvrent jamais (D-7). Une etape close sans
    -- motif serait un COMPLETED dont personne ne sait ce qui l'a ferme.
    CONSTRAINT chk_journey_step_closure
        CHECK ((closed_at IS NULL) = (resolution IS NULL)),
    -- Une etape DIAGNOSTIC ne porte ni epreuve, ni lot, ni competence : elle
    -- mesure le candidat, pas une epreuve (R11).
    CONSTRAINT chk_journey_step_diagnostic
        CHECK (type <> 'DIAGNOSTIC'
            OR (lot_id IS NULL AND exam_type IS NULL AND skill_id IS NULL AND purpose IS NULL)),
    -- Une etape d'entrainement porte TOUJOURS sa competence et son lot ; un
    -- examen n'en porte jamais.
    CONSTRAINT chk_journey_step_train_skill
        CHECK (type <> 'TRAIN_SKILL'
            OR (skill_id IS NOT NULL AND lot_id IS NOT NULL
                AND exam_type IS NOT NULL AND purpose IS NULL)),
    CONSTRAINT chk_journey_step_section_exam
        CHECK (type <> 'SECTION_EXAM'
            OR (skill_id IS NULL AND exam_type IS NOT NULL AND purpose IS NOT NULL))
);

-- R13 — PAS DEUX FOIS LA MEME COMPETENCE DANS UN MEME LOT. Une competence
-- resolue dans un ANCIEN lot peut revenir dans un nouveau : c'est une nouvelle
-- occurrence legitime, donc l'unicite est bornee au lot, jamais au parcours.
CREATE UNIQUE INDEX uq_journey_step_lot_skill
    ON journey_step (lot_id, skill_id) WHERE skill_id IS NOT NULL;

-- L'ordre de lecture du parcours. Une position est unique dans un parcours : la
-- file ne peut pas contenir deux etapes « au meme rang », ce qui rendrait
-- l'election de CURRENT non deterministe.
CREATE UNIQUE INDEX uq_journey_step_position ON journey_step (journey_id, position);

-- « Quelles etapes de ce parcours restent ouvertes ? » — la requete de chaque
-- lecture et de chaque promotion.
CREATE INDEX idx_journey_step_ouvertes
    ON journey_step (journey_id, position) WHERE closed_at IS NULL;

CREATE INDEX idx_journey_step_lot ON journey_step (lot_id);

COMMENT ON TABLE journey_step IS
    'Une etape de la file : diagnostic, entrainement d''une competence, ou examen d''epreuve. '
        'Structure et cloture persistees ; statut d''affichage et verrou DERIVES a la lecture.';

COMMENT ON COLUMN journey_step.skill_id IS
    'La competence travaillee. Son CODE, son TITRE, son domaine et sa tache ne sont PAS recopies '
        'ici : ils se lisent sur skills, unique autorite du referentiel.';

COMMENT ON COLUMN journey_step.exam_type IS
    'L''epreuve concernee. NULL pour une etape DIAGNOSTIC seulement. Portee aussi par le lot '
        'quand il y en a un : les deux s''ecrivent dans la meme transaction depuis la meme '
        'valeur, et c''est cette colonne-ci que lisent les filtres par epreuve.';

COMMENT ON COLUMN journey_step.severity_rank IS
    'Rang de la priorite DANS SON LOT (0, 1, 2), derive au moment de la creation depuis l''ordre '
        'de LearningPlanPriorityResolver.actionable(). Ce n''est pas un score : aucun entier de '
        'gravite n''existe ailleurs dans le depot.';

COMMENT ON COLUMN journey_step.closed_at IS
    'Date de cloture, ECRITE UNE SEULE FOIS, jamais reouverte (D-7). Une competence redevenue '
        'fragile ne reouvre pas son etape : elle reviendra par un examen (R7).';

COMMENT ON COLUMN journey_step.resolution IS
    'CE QUI a ferme l''etape, a cette date. MASTERED ne dit PAS « acquise aujourd''hui » — '
        'cette question a une seule autorite, SkillMasteryEngine, et elle se relit.';

-- ---------------------------------------------------------------------------
-- journey_assessment_event — le journal des evaluations deja traitees
-- ---------------------------------------------------------------------------
-- R14 — IDEMPOTENCE. Un meme sourceAssessmentId ne produit qu'UN traitement :
-- un rafraichissement, un double envoi mobile, une cloture automatique a
-- echeance suivie d'un finish explicite, un rejeu quelconque retombent sur la
-- meme cle. Meme discipline que uq_learning_plan_observation_source et que
-- production_submissions.client_submission_id (V046).
--
-- Il sert AUSSI l'ordre des evenements : completed_at permet d'ignorer une
-- evaluation arrivee en retard mais plus ANCIENNE que la derniere deja traitee
-- pour la meme epreuve (synchronisations mobiles tardives).
--
-- Et il sert le BOOTSTRAP (R19) : toutes les evaluations historiques y sont
-- enregistrees d'un coup, ce qui garantit qu'aucune ne sera rejouee ensuite.
CREATE TABLE journey_assessment_event
(
    id                   uuid PRIMARY KEY,
    journey_id           uuid        NOT NULL REFERENCES journey (id) ON DELETE CASCADE,
    source_assessment_id uuid        NOT NULL,
    assessment_kind      varchar(24) NOT NULL,
    exam_type            varchar(20),
    completed_at         timestamptz NOT NULL,
    processed_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_journey_assessment_event UNIQUE (journey_id, source_assessment_id),
    CONSTRAINT chk_journey_assessment_kind
        CHECK (assessment_kind IN
               ('QUICK_DIAGNOSTIC', 'FULL_DIAGNOSTIC', 'SECTION_EXAM', 'MOCK_EXAM')),
    CONSTRAINT chk_journey_assessment_exam_type
        CHECK (exam_type IS NULL OR exam_type IN ('TCF_CO', 'TCF_CE', 'TCF_EO', 'TCF_EE')),
    -- 🛑 SEUL le diagnostic RAPIDE ne mesure aucune epreuve (R11) : il produit
    -- des priorites sans jamais rendre une epreuve « mesuree ». Toute autre
    -- evaluation en mesure exactement UNE — les sous-epreuves d'un examen blanc
    -- complet et les sections d'un diagnostic complet sont des attempts a part
    -- entiere, donc des evenements a part entiere.
    CONSTRAINT chk_journey_assessment_epreuve_mesuree
        CHECK ((assessment_kind = 'QUICK_DIAGNOSTIC') = (exam_type IS NULL))
);

CREATE INDEX idx_journey_assessment_event_journey
    ON journey_assessment_event (journey_id, completed_at DESC);

-- « Quelle est la derniere evaluation deja traitee de cette epreuve ? » — le
-- repere exact de R14, celui qui fait ignorer une synchronisation tardive.
CREATE INDEX idx_journey_assessment_event_epreuve
    ON journey_assessment_event (journey_id, exam_type, completed_at DESC)
    WHERE exam_type IS NOT NULL;

COMMENT ON TABLE journey_assessment_event IS
    'Les evaluations DEJA TRAITEES par un parcours. Garantit l''idempotence (R14) et porte la '
        'chronologie qui permet d''ignorer une evaluation arrivee en retard.';

COMMENT ON COLUMN journey_assessment_event.exam_type IS
    'L''epreuve que cette evaluation a mesuree. NULL pour le seul diagnostic RAPIDE, qui produit '
        'des priorites sans mesurer (R11). Une evaluation = un attempt = au plus une epreuve : '
        'les sous-epreuves d''un examen complet sont des attempts distincts.';
