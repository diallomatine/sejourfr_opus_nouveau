-- ---------------------------------------------------------------------------
-- V040 — Une production de diagnostic INEXPLOITABLE ne porte plus de verdict.
--
-- LE DEFAUT, MESURE EN BASE. Un compte a rendu 4 SECONDES d'audio, transcrites
-- en 7 CARACTERES (1 mot), et l'analyse a rendu `A1_NON_ATTEINT`. Une ABSENCE
-- DE PREUVE a ete enregistree comme une PREUVE DU NIVEAU LE PLUS FAIBLE. Et
-- comme le diagnostic sert de repli a `TcfProfileService` pour EE/EO, et que le
-- niveau global est le PLANCHER des quatre domaines, tout le profil de ce
-- candidat etait tire au fond par un enregistrement qu'il n'a jamais fait.
--
-- C'est exactement la confusion que le reste du depot combat sous la formule
-- « null = inconnu, jamais mauvais » (epreuve jamais ouverte d'un examen
-- complet, epreuve abandonnee sans rien rendre du profil TCF). Le diagnostic
-- etait le seul endroit ou elle n'etait pas tenue, faute de pouvoir dire
-- « pas de niveau » : les trois colonnes de verdict etaient NOT NULL.
--
-- CE QUE FAIT CETTE MIGRATION.
--   1. Les TROIS verdicts deviennent nullables — pas seulement le niveau.
--      `task_completion` et `communication_status` sont du meme ordre : ecrire
--      NOT_COMPLETED / INEFFECTIVE sur 4 secondes d'audio, ce serait remplacer
--      un faux verdict de niveau par deux autres faux verdicts, et afficher au
--      candidat une carte entierement rouge pour un enregistrement rate.
--   2. `evaluabilite` dit POURQUOI il n'y a pas de verdict, comme un FAIT.
--      L'absence de ligne signifie « pas encore analysee » ; une ligne
--      NON_EVALUABLE signifie « rendue, mais rien a observer ». Ces deux etats
--      ne se disent pas pareil au candidat, et un front ne doit pas avoir a
--      les distinguer en testant la nullite de trois colonnes.
--
-- AUCUNE DONNEE N'EST MIGREE. Les 18 analyses deja en base gardent leur
-- verdict, y compris les 2 qui sont fausses (les deux productions orales de
-- 1 et 3 mots). Les recalculer serait reecrire l'historique ; le DEFAULT
-- 'EVALUABLE' ne fait que donner aux lignes existantes le sens qu'elles avaient
-- deja — elles portent toutes un niveau. Le rattrapage de ces lignes est un
-- arbitrage du proprietaire, pas une consequence technique de ce correctif.
-- ---------------------------------------------------------------------------

ALTER TABLE diagnostic_production_analyses
    ALTER COLUMN level_estimate       DROP NOT NULL,
    ALTER COLUMN task_completion      DROP NOT NULL,
    ALTER COLUMN communication_status DROP NOT NULL;

ALTER TABLE diagnostic_production_analyses
    ADD COLUMN evaluabilite varchar(16) NOT NULL DEFAULT 'EVALUABLE';

ALTER TABLE diagnostic_production_analyses
    ADD CONSTRAINT chk_diagnostic_analysis_evaluabilite
        CHECK (evaluabilite IN ('EVALUABLE', 'NON_EVALUABLE'));

-- Un verdict sans analyse, ou une analyse sans verdict, seraient tous deux des
-- incoherences silencieuses : la contrainte les rend impossibles en base plutot
-- que surveillees dans le Java.
ALTER TABLE diagnostic_production_analyses
    ADD CONSTRAINT chk_diagnostic_analysis_verdicts_si_evaluable
        CHECK (
            (evaluabilite = 'EVALUABLE'
                 AND level_estimate IS NOT NULL
                 AND task_completion IS NOT NULL
                 AND communication_status IS NOT NULL)
            OR
            (evaluabilite = 'NON_EVALUABLE'
                 AND level_estimate IS NULL
                 AND task_completion IS NULL
                 AND communication_status IS NULL)
        );

COMMENT ON COLUMN diagnostic_production_analyses.evaluabilite IS
    'EVALUABLE | NON_EVALUABLE. NON_EVALUABLE = production rendue mais sans matiere observable (vide/quasi vide, langue non francaise, recopiage de la consigne) : AUCUN appel au correcteur n''a ete emis et les trois verdicts sont NULL. A ne pas confondre avec l''absence de ligne, qui signifie « pas encore analysee ».';
COMMENT ON COLUMN diagnostic_production_analyses.level_estimate IS
    'Niveau CECRL estime. NULL quand evaluabilite = NON_EVALUABLE : null = inconnu, jamais mauvais. TcfProfileService ecarte deja ces lignes de son repli.';
