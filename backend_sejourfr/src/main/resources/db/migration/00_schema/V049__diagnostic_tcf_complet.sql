-- ============================================================================
-- V049 — LE DIAGNOSTIC TCF EN 4 EPREUVES.
-- ----------------------------------------------------------------------------
-- Lot L4 de la refonte. Spec : docs/review_all/10_SEJOURFR_TCF.md §4 et
-- 30_SEJOURFR_ECRANS.md §5 ; correctifs : 50_SEJOURFR_CORRECTIFS.md.
--
-- 🛑 CE N'EST PAS UN EXAMEN BLANC, ET LE NOM COMPTE.
-- 10_ §4.1 l'interdit explicitement : « Nommage impose : Diagnostic TCF —
-- 4 epreuves. Interdit d'appeler cela un examen blanc. » Les deux objets
-- coexistent, ils ne se remplacent pas :
--   * l'examen blanc complet est au FORMAT REEL (25 items par QCM), premium
--     au-dela du premier, et sert a se mettre en situation ;
--   * le diagnostic est REDUIT en comprehension (15 items), gratuit une fois,
--     et sert a construire le Plan.
--
-- CE QU'ON NE RECREE PAS.
-- La mecanique « un attempt parent + 4 sous-attempts, un chrono par epreuve,
-- une cloture paresseuse a la lecture, les productions branchees sur
-- /api/production-submissions » existe deja et tourne (FullTcfExamService).
-- La rebatir en parallele donnerait deux implementations du meme parcours,
-- qui divergeraient. Le diagnostic REUTILISE donc les memes tables `attempts`
-- et le meme parent TCF_COMPLET.
--
-- 🛑 D'OU LE DISCRIMINANT, ET IL EST INDISPENSABLE.
-- Sans lui, un diagnostic apparaitrait dans la grille des 20 examens blancs,
-- dans /api/me/full-tcf-exams, dans l'historique et dans les statistiques —
-- il serait compte comme un examen blanc qu'il n'est pas.
-- `attempts.tcf_diagnostic_id` joue exactement le role que
-- `production_tasks.diagnostic_code` joue deja pour les sujets EE/EO du
-- diagnostic initial : **tous** les catalogues, historiques, grilles,
-- statistiques et quotas gardent le filtre `tcf_diagnostic_id IS NULL`.
-- C'est le patron du depot, pas une invention.
--
-- POURQUOI UNE TABLE D'ENVELOPPE ET PAS DES COLONNES SUR `attempts`.
-- Le diagnostic porte des faits qui ne sont pas ceux d'un attempt : son
-- echeance de reprise, son statut d'ensemble, la version de sa configuration.
-- `diagnostic_sessions` (V029) enveloppe deja les deux attempts du diagnostic
-- initial de la meme facon — meme patron, meme raison.
--
-- 🛑 AUCUNE TABLE DE SECTION, AUCUNE TABLE DE RESULTAT.
-- 10_ §11 propose `tcf_diagnostic_section` et `tcf_diagnostic_result`. On ne
-- les cree PAS : l'etat d'une section EST celui de son sous-attempt, et le
-- niveau par epreuve se recalcule a la lecture depuis les reponses (CO/CE) et
-- les evaluations (EE/EO). Les persister violerait l'invariant « derive
-- serveur ⇒ jamais persiste » et figerait un resultat qu'un recalibrage devrait
-- pouvoir revoir.
-- Seule exception, deja en place pour l'examen complet : le niveau final est
-- recopie sur `attempts.final_cecrl_level` quand les 4 epreuves sont closes —
-- c'est un cache de lecture, pas la source.
-- ============================================================================

CREATE TABLE tcf_diagnostic_sessions (
    id                 uuid PRIMARY KEY,
    user_id            uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,

    -- L'attempt TCF_COMPLET qui porte les 4 sous-epreuves. ON DELETE CASCADE :
    -- un diagnostic sans son parent n'a aucun sens.
    parent_attempt_id  uuid        NOT NULL UNIQUE REFERENCES attempts (id) ON DELETE CASCADE,

    -- Version de la configuration appliquee au tirage (nombre d'items par
    -- palier, duree de reprise). Un diagnostic se relit avec la configuration
    -- QUI L'A PRODUIT : changer les reglages ne doit pas reinterpreter
    -- retroactivement un diagnostic deja passe.
    config_version     integer     NOT NULL,

    status             varchar(16) NOT NULL,

    started_at         timestamptz NOT NULL DEFAULT now(),

    -- Echeance de REPRISE, pas de validite du resultat (10_ §4.2 : « Reprise
    -- possible 7 jours. Au-dela, on calcule sur les sections realisees »).
    -- Passee cette date, les sections non commencees restent « non evaluee » et
    -- le resultat se calcule sur ce qui existe : rien n'est detruit, rien
    -- n'expire vraiment.
    expires_at         timestamptz NOT NULL,

    completed_at       timestamptz,

    CONSTRAINT chk_tcf_diagnostic_status
        CHECK (status IN ('IN_PROGRESS', 'COMPLETED')),

    -- Un diagnostic termine porte sa date de fin, et lui seul.
    CONSTRAINT chk_tcf_diagnostic_completed
        CHECK ((status = 'COMPLETED') = (completed_at IS NOT NULL))
);

COMMENT ON TABLE tcf_diagnostic_sessions IS
    'Enveloppe du diagnostic TCF 4 epreuves (L4). Ce n''est PAS un examen '
    'blanc : format reduit en comprehension, gratuit une fois, il construit le '
    'Plan. L''etat des sections et les niveaux sont DERIVES a la lecture.';

CREATE INDEX idx_tcf_diagnostic_user
    ON tcf_diagnostic_sessions (user_id, started_at DESC);

-- Le discriminant. NULL = attempt ordinaire (examen blanc, serie, production) :
-- c'est le cas de 100 % des lignes existantes, donc rien ne bouge pour elles.
ALTER TABLE attempts
    ADD COLUMN tcf_diagnostic_id uuid REFERENCES tcf_diagnostic_sessions (id) ON DELETE CASCADE;

COMMENT ON COLUMN attempts.tcf_diagnostic_id IS
    'Rattache un attempt (parent TCF_COMPLET ou sous-epreuve) a un diagnostic '
    'TCF. 🛑 Tous les catalogues, grilles, historiques, statistiques et quotas '
    'gardent le filtre `tcf_diagnostic_id IS NULL` — meme discipline que '
    '`production_tasks.diagnostic_code`. NULL = attempt ordinaire.';

-- Index partiel : il ne porte que les attempts de diagnostic, une poignee par
-- candidat, et sert a retrouver les 4 sous-epreuves d'une session.
CREATE INDEX idx_attempts_tcf_diagnostic
    ON attempts (tcf_diagnostic_id)
    WHERE tcf_diagnostic_id IS NOT NULL;
