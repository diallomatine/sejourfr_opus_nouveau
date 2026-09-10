-- ============================================================================
-- V052 — LE DIAGNOSTIC CIVIQUE (lot L9).
-- ----------------------------------------------------------------------------
-- Spec : 20_ §4. Le pendant civique du diagnostic TCF, et il obéit aux mêmes
-- deux règles de fond.
--
-- 🛑 CE N'EST PAS UN EXAMEN BLANC, et 20_ §4.1 l'oppose explicitement :
--   diagnostic  → 24 questions, ~15 min, couverture ÉQUILIBRÉE sur 5 thèmes,
--                 il IDENTIFIE les faiblesses et crée le plan ;
--   examen blanc → 40 questions, 45 min, seuil 32, couverture REPRÉSENTATIVE,
--                 il VÉRIFIE la préparation et met le plan à jour.
-- D'où le discriminant `attempts.civic_diagnostic_id`, exactement comme V049
-- l'a fait pour le TCF : sans lui, le diagnostic occuperait un slot de la
-- grille d'examens blancs et compterait dans « examens blancs passés ».
--
-- 🛑 AUCUN COÛT LLM. Le civique est du QCM déterministe (20_ §4.3) : la
-- correction ne passe par aucun modèle. Le quota est donc distinct de celui des
-- analyses IA, et un diagnostic civique gratuit ne consomme rien d'autre.
--
-- 🛑 CETTE TABLE N'EST QU'UNE ENVELOPPE. Les réponses vivent dans
-- `attempt_questions`, comme pour n'importe quel attempt ; les états par thème
-- et la projection se RECALCULENT à la lecture — « dérivé serveur ⇒ jamais
-- persisté ». On ne fige ici que ce qui est un fait daté : quand, sur quelle
-- mention, et sous quelle version de configuration.
-- ============================================================================

CREATE TABLE civic_diagnostic_sessions (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- L'attempt qui porte les 24 questions. Un seul : le diagnostic civique
    -- n'a pas de sous-épreuves, contrairement au TCF.
    attempt_id     uuid        NOT NULL UNIQUE REFERENCES attempts (id) ON DELETE CASCADE,
    -- La mention du candidat AU MOMENT du diagnostic (CSP / CR / NAT).
    -- Recopiée et jamais relue depuis `users` : changer de démarche ne doit pas
    -- réinterpréter un diagnostic déjà passé.
    mention        varchar(8)  NOT NULL,
    -- Version de configuration appliquée au tirage et aux seuils. Un diagnostic
    -- se relit avec la configuration QUI L'A PRODUIT : sans ce numéro, un
    -- recalibrage réinterpréterait rétroactivement des diagnostics passés.
    config_version integer     NOT NULL,
    status         varchar(16) NOT NULL DEFAULT 'IN_PROGRESS',
    started_at     timestamptz NOT NULL DEFAULT now(),
    completed_at   timestamptz,

    CONSTRAINT chk_civic_diagnostic_status
        CHECK (status IN ('IN_PROGRESS', 'COMPLETED'))
);

COMMENT ON TABLE civic_diagnostic_sessions IS
    'Diagnostic civique (20_ §4). PAS un examen blanc : format reduit, couverture '
    'equilibree, il cree le plan. Enveloppe seule -- les reponses vivent dans '
    'attempt_questions et les etats par theme se recalculent a la lecture.';

CREATE INDEX idx_civic_diagnostic_user
    ON civic_diagnostic_sessions (user_id, started_at DESC);

ALTER TABLE attempts
    ADD COLUMN civic_diagnostic_id uuid REFERENCES civic_diagnostic_sessions (id);

COMMENT ON COLUMN attempts.civic_diagnostic_id IS
    'Discriminant : cet attempt appartient a un diagnostic civique, il n''est '
    'donc PAS un examen blanc. Sans lui, le diagnostic remonterait dans la '
    'grille des examens blancs et dans « examens passes ».';

CREATE INDEX idx_attempt_civic_diagnostic
    ON attempts (civic_diagnostic_id)
    WHERE civic_diagnostic_id IS NOT NULL;
