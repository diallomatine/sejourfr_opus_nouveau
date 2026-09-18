-- ============================================================================
-- V067 — Le parcours devient un CYCLE BORNE, et « offert une fois » devient
--        une LIGNE EN BASE
-- ----------------------------------------------------------------------------
-- Arbitrages du proprietaire D-12 a D-24 et D-17 bis (2026-09-18) :
-- docs/decisions/plan-parcours-tcf.md. Cadre fonctionnel conforme :
-- docs/progression/SPEC_cycle_plan.md. Audit qui a mesure l'ecart :
-- docs/audits/AUDIT_cycle_plan.md (Annexe P1 = le perimetre de cette phase).
--
-- CE QUE CETTE MIGRATION AJOUTE, ET POURQUOI C'EST EN BASE.
-- V066 a persiste la memoire d'ordonnancement d'une file d'etapes. Il lui
-- manquait deux faits du meme genre, que rien ne permet de recalculer :
--   1. LE BORNAGE DU CYCLE. « Ce cycle-ci a ete historise a cette date parce
--      que le candidat a demande une actualisation » depend d'un EVENEMENT, pas
--      d'un etat (D-14). Meme argument que journey_step.resolution et que
--      journey_lot.status : un derive se relit, un evenement se perd.
--   2. LA CONSOMMATION D'UNE GRATUITE NOMINATIVE. « Cet examen blanc EE lui a
--      ete offert, une fois, a cette date » n'est pas deductible de
--      l'historique : l'audit a releve QUATRE manieres differentes de le
--      deviner, et aucune ne sait distinguer un freebie consomme d'un examen
--      abandonne (D-17).
--
-- 🛑 CE QUI N'ENTRE TOUJOURS PAS ICI (D-7, maintenu en entier par D-14).
-- Le statut de l'ETAPE reste DERIVE a la lecture — la spec demandait
-- A_FAIRE / EN_COURS / REUSSI en base, c'est REFUSE. Le verrou freemium reste
-- derive. La maitrise reste chez SkillMasteryEngine. « Bloc termine » et
-- « cycle termine » sont des LECTURES de l'etat des etapes, pas des colonnes.
--
-- AUCUNE MIGRATION DE DONNEES, comme en V066 : creation paresseuse, et les
-- DEFAULT ci-dessous ne servent qu'a rendre les lignes deja creees valides.
-- Aucun UPDATE, aucun backfill, aucune purge retroactive.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- journey — le parcours devient un cycle borne, par (candidat, module)
-- ---------------------------------------------------------------------------

-- 🛑 LA CLE D'UNICITE DU CYCLE, ET LE CIVIQUE N'EST PAS ENCORE DEDANS.
-- Le module est la cle parce qu'un candidat prepare le TCF et le civique sans
-- que l'un borne l'autre : deux cycles en cours simultanes sont normaux, deux
-- cycles en cours du MEME module ne le sont jamais (D-13). Personne n'ecrit
-- 'CIVIQUE' aujourd'hui — le civique sort du chantier (D-23) et son plan reste
-- integralement derive (Leitner, aucune file persistee). La valeur est dans le
-- CHECK malgre tout, parce que la colonne serait sinon a refaire le jour ou il
-- entre, et qu'un enum Java a deux valeurs (Module) ne doit pas avoir un miroir
-- SQL a une seule.
ALTER TABLE journey
    ADD COLUMN module varchar(16) NOT NULL DEFAULT 'TCF';

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_module CHECK (module IN ('TCF', 'CIVIQUE'));

-- 🛑 POURQUOI CE STATUT-CI EST PERSISTE ALORS QUE CELUI DE L'ETAPE NE L'EST
-- PAS (D-14). JourneyStepStatus se recalcule entierement depuis closed_at,
-- resolution et l'ordre de cloture : le persister creerait une seconde autorite
-- sur « ou en est ce candidat ? ». Le statut du CYCLE, lui, n'est pas un
-- derive : c'est une MEMOIRE D'ORDONNANCEMENT. Rien dans les etapes, les lots
-- ou les evaluations ne permet de reconstituer « ce cycle a ete historise a
-- cette date parce que le candidat a demande une actualisation de son plan » —
-- cela depend d'un evenement date. EN_ATTENTE est du meme ordre : il dit « ces
-- priorites ont ete detectees PENDANT le cycle en cours et attendent le
-- suivant » (D-13, revocation de R2 « les priorites au-dela ne sont ni stockees
-- ni mises en attente »), ce qu'aucune relecture ne saurait retrouver.
ALTER TABLE journey
    ADD COLUMN status varchar(16) NOT NULL DEFAULT 'EN_COURS';

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_status
        CHECK (status IN ('EN_COURS', 'EN_ATTENTE', 'HISTORISE'));

-- Le niveau global au demarrage du cycle : le niveau de sortie du cycle
-- precedent, ou celui du diagnostic pour le premier (D-12).
--
-- 🛑 NULL = INCONNU, JAMAIS MAUVAIS. Un cycle ouvert avant toute mesure n'a pas
-- de niveau d'entree, et cette absence ne vaut surtout pas « A1 non atteint » :
-- c'est la confusion exacte qui a produit les faux verdicts V040/V041/V042.
ALTER TABLE journey
    ADD COLUMN entry_level varchar(8);

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_entry_level
        CHECK (entry_level IS NULL OR entry_level IN ('A2', 'B1', 'B2'));

-- 🛑 UN FAIT DATE, ECRIT A L'HISTORISATION, JAMAIS RECALCULE (D-12). Il dit
-- « voila ou en etait le candidat quand ce cycle s'est ferme ». Le lire a la
-- demande le ferait reinterpreter par le moteur du jour : un recalibrage de
-- seuils reecrirait retroactivement l'histoire du candidat. Meme argument que
-- journey_step.resolution, qui ne dit pas « acquise aujourd'hui ».
-- Il reste NULL quand le cycle se ferme sans qu'aucune epreuve n'ait ete
-- mesuree — une absence de mesure n'est pas un niveau bas.
ALTER TABLE journey
    ADD COLUMN exit_level varchar(8);

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_exit_level
        CHECK (exit_level IS NULL OR exit_level IN ('A2', 'B1', 'B2'));

ALTER TABLE journey
    ADD COLUMN historise_at timestamptz;

-- L'etat et sa date ne peuvent pas se contredire — meme forme que
-- chk_journey_lot_closed_at et chk_journey_step_closure : un cycle historise sans
-- date serait un cycle dont personne ne sait QUAND il s'est ferme, donc
-- impossible a ranger dans un historique.
--
-- ⚠️ exit_level n'entre PAS dans cette equivalence, et c'est voulu : un cycle
-- historise sans aucune epreuve mesuree est legitime, et son niveau de sortie
-- reste inconnu.
ALTER TABLE journey
    ADD CONSTRAINT chk_journey_historisation
        CHECK ((status = 'HISTORISE') = (historise_at IS NOT NULL));

-- uq_journey_user_target interdisait deux parcours du meme niveau cible, donc
-- EXACTEMENT ce que D-13 exige : un cycle en cours ET un cycle en attente pour
-- le meme candidat. Elle disparait, et la cle devient (candidat, module,
-- statut).
--
-- ⚠️ Le niveau cible n'est plus une cle : si le candidat change d'objectif, le
-- cycle EN_COURS SURVIT et son target_level est mis a jour. Historiser a sa
-- place jetterait le plan qu'il a sous les yeux, et un ping-pong d'objectif
-- polluerait l'historique de cycles ; les priorites d'une competence ne
-- deviennent pas fausses parce que la cible a bouge — seul l'ORDRE des lots
-- s'en trouve recalcule, et il est deja derive a la lecture.
ALTER TABLE journey
    DROP CONSTRAINT uq_journey_user_target;

-- D-13 — UN SEUL CYCLE EN COURS ET UN SEUL EN ATTENTE par (candidat, module),
-- tenu par la BASE et pas seulement par le service : le parcours est ecrit
-- depuis quatre branchements best-effort (D-24), chacun dans sa propre
-- transaction, et une regle que seul un service tiendrait finirait contournee
-- par le branchement suivant. Meme patron que
-- uq_journey_lot_open_par_epreuve — un index unique PARTIEL sur le statut.
--
-- Les HISTORISE sont libres et multiples : c'est l'historique des cycles, et
-- c'est ce que la page Progression lira.
--
-- RECONCILIATION AVANT L'INDEX — deterministe, bornee, idempotente.
--
-- V066 autorisait PLUSIEURS journey par candidat : un par niveau cible
-- (uq_journey_user_target). Toutes ces lignes viennent de prendre
-- status = 'EN_COURS' par DEFAULT, donc un candidat qui a change d'objectif
-- entre V066 et V067 en a deux — et CREATE UNIQUE INDEX echouerait, cassant le
-- deploiement.
--
-- Le geste : on garde le cycle le plus recemment TOUCHE et on historise les
-- autres. C'est la lecture la plus fidele a l'intention du candidat — son
-- parcours vivant est celui sur lequel il travaillait —, et c'est aussi ce que
-- l'arbitrage du 2026-09-18 dit ailleurs : un cycle historise n'est pas perdu,
-- il part dans la page Progression.
--
-- Pourquoi c'est permis ici alors que 00_schema est du DDL : meme exception que
-- V023, V024 et V042 — un correctif deterministe, borne et idempotent. Rejouee,
-- la requete ne trouve plus qu'un EN_COURS par (candidat, module) et ne touche
-- rien. Elle n'embarque aucune logique applicative : ni niveau, ni maitrise, ni
-- priorite ne sont relus.
--
-- Mesure sur la base de dev au 2026-09-18 : 2 journey, 2 candidats, 0 doublon.
-- La garde est donc ecrite pour la PROD, ou le volume n'etait pas consultable.
WITH classees AS (
    SELECT id,
           row_number() OVER (
               PARTITION BY user_id, module
               ORDER BY updated_at DESC, created_at DESC, id
           ) AS rang
      FROM journey
     WHERE status = 'EN_COURS'
)
UPDATE journey j
   SET status       = 'HISTORISE',
       historise_at = now()
  FROM classees c
 WHERE j.id = c.id
   AND c.rang > 1;

CREATE UNIQUE INDEX uq_journey_en_cours
    ON journey (user_id, module) WHERE status = 'EN_COURS';

CREATE UNIQUE INDEX uq_journey_en_attente
    ON journey (user_id, module) WHERE status = 'EN_ATTENTE';

-- « Le cycle en cours de ce candidat sur ce module » — la lecture de chaque
-- ouverture du Plan, et desormais la seule cle de recherche du parcours.
CREATE INDEX idx_journey_user_module_status ON journey (user_id, module, status);

COMMENT ON TABLE journey IS
    'Un CYCLE du parcours : l''enveloppe d''une file d''etapes, bornee par (candidat, module) et '
        'par son statut. Un seul EN_COURS et un seul EN_ATTENTE ; les HISTORISE sont '
        'l''historique.';

COMMENT ON COLUMN journey.module IS
    'TCF ou CIVIQUE. Cle d''unicite du cycle avec user_id : les deux modules se preparent en '
        'parallele. Personne n''ecrit CIVIQUE aujourd''hui (D-23) — son plan reste derive.';

COMMENT ON COLUMN journey.status IS
    'EN_COURS / EN_ATTENTE / HISTORISE. PERSISTE, et ce n''est PAS un derive : c''est une memoire '
        'd''ordonnancement (D-14), du meme type que journey_lot.status. Le statut de l''ETAPE, '
        'lui, reste derive a la lecture.';

COMMENT ON COLUMN journey.entry_level IS
    'Le niveau global au demarrage du cycle : le niveau de sortie du precedent, ou celui du '
        'diagnostic pour le premier. NULL = pas encore mesure, ce qui ne vaut jamais « niveau le '
        'plus bas ».';

COMMENT ON COLUMN journey.exit_level IS
    'Le niveau global ECRIT A L''HISTORISATION, jamais recalcule ensuite (D-12) : un fait date, '
        'qu''un recalibrage de moteur ne doit pas reinterpreter. NULL quand le cycle se ferme '
        'sans mesure.';

-- ---------------------------------------------------------------------------
-- free_entitlement_usage — le ledger des gratuites nominatives
-- ---------------------------------------------------------------------------
-- DEUX FREEBIES, UN PAR EPREUVE DE PRODUCTION (D-17, D-17 bis). Ce ne sont pas
-- « un examen blanc au choix » : les codes sont EXAM_BLANC_EE et EXAM_BLANC_EO,
-- et chacun s'offre une fois a vie, analyse IA complete incluse. Le rejeu de
-- l'epreuve reste ouvert ; c'est l'ANALYSE du second passage qui est premium,
-- et son refus se pose AVANT le pipeline — ni correcteur, ni Whisper.
--
-- 🛑 LA CONSOMMATION S'ECRIT A LA REMISE DE L'ANALYSE. Ni au demarrage de
-- l'examen, ni sur doFinish seul. Un abandon, une expiration, un echec
-- technique ou un echec du correcteur laissent le freebie INTACT, et le
-- candidat le retrouve : sinon « offert une fois » voudrait dire « perdu une
-- fois ». C'est la seule lecture honnete de la promesse faite a l'ecran.
--
-- 🛑 CETTE TABLE REMPLACERA LES QUATRE IMPLEMENTATIONS AD HOC de « premiere
-- fois gratuite » relevees par l'audit — ProductionAccessService,
-- ProductionSubmissionManager.hasFullExamProductionSubmission,
-- attempts.production_locked, et la convention « slot <= 1 ». Aucune ne sait
-- distinguer un freebie consomme d'un examen abandonne, et quatre facons de
-- dire la meme chose finissent toujours par se contredire. ⚠️ LA BASCULE EST
-- EN P4 : rien ne lit cette table aujourd'hui, et les quatre mecaniques
-- existantes restent seules en vigueur d'ici la.
CREATE TABLE free_entitlement_usage
(
    id                uuid PRIMARY KEY,
    user_id           uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    code              varchar(48) NOT NULL,
    consumed_at       timestamptz NOT NULL DEFAULT now(),
    source_attempt_id uuid REFERENCES attempts (id) ON DELETE SET NULL,
    -- 🛑 LE GARDE-FOU EST EN BASE, pas dans un service. Meme discipline que
    -- journey_assessment_event et que production_submissions.client_submission_id
    -- (V046) : deux requetes concurrentes ne se voient pas l'une l'autre, et ce
    -- qui est en jeu ici est un appel LLM paye deux fois pour une gratuite qui
    -- ne valait qu'une.
    CONSTRAINT uq_free_entitlement_usage UNIQUE (user_id, code),
    -- Les codes sont ENUMERES, comme partout ailleurs dans ce schema
    -- (chk_journey_lot_exam_type, chk_skills_section). Un code libre ferait
    -- qu'une faute de frappe rendrait un freebie deja consomme a nouveau
    -- gratuit, sans que rien ne le signale — et c'est le genre de silence que
    -- le depot paie cher. Ajouter une gratuite est donc une migration, pas une
    -- constante Java : FreeEntitlementCode est le miroir de ce CHECK, jamais
    -- son autorite.
    CONSTRAINT chk_free_entitlement_code
        CHECK (code IN ('EXAM_BLANC_EE', 'EXAM_BLANC_EO'))
);

-- « Ce candidat a-t-il deja consomme ses gratuites, et lesquelles ? » — la
-- lecture de chaque paywall. L'index unique la sert deja ; aucun index de
-- lecture supplementaire n'est ajoute tant qu'aucune autre requete n'existe.

COMMENT ON TABLE free_entitlement_usage IS
    'Le journal des gratuites nominatives deja consommees : une ligne par (candidat, code), '
        'ecrite A LA REMISE DE L''ANALYSE. Remplacera en P4 les quatre implementations ad hoc de '
        '« premiere fois gratuite ».';

COMMENT ON COLUMN free_entitlement_usage.code IS
    'EXAM_BLANC_EE / EXAM_BLANC_EO. DEUX freebies nominatifs, pas un au choix (D-17 bis) : un '
        'candidat qui a use son examen blanc EE garde le sien en EO.';

COMMENT ON COLUMN free_entitlement_usage.consumed_at IS
    'La date de la REMISE DE L''ANALYSE, seul moment ou la gratuite est reellement rendue. Un '
        'examen abandonne, expire ou dont le correcteur a echoue n''ecrit aucune ligne.';

COMMENT ON COLUMN free_entitlement_usage.source_attempt_id IS
    'La session qui a consomme la gratuite, pour la tracabilite du support. ON DELETE SET NULL '
        'parce que la disparition de la session ne doit pas RENDRE une gratuite deja honoree : '
        'la trace se perd, le fait reste. Sur suppression de compte, la ligne part entierement '
        '(ON DELETE CASCADE sur user_id, et purge explicite par AccountDeletionService).';
