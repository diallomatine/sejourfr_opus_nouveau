-- ============================================================================
-- V077 — « Mes cycles » : CE QUI A CLOS un cycle historise (2026-09-27)
-- ----------------------------------------------------------------------------
-- Additif. Aucune donnee n'est rattrapee : NULL = inconnu.
--
-- Un cycle se ferme par l'un de deux gestes — « Actualiser mon plan »
-- (POST /api/me/plan/journey/refresh) ou « Passer l'examen blanc complet »
-- (POST .../measurement-cycle). Le geste est un EVENEMENT : rien ne permet de le
-- reconstituer apres coup (le cycle suivant ne le dit pas de facon sure). C'est
-- le meme argument que `status` et `exit_level` (D-12, D-14) : la memoire d'une
-- decision prise a un instant, pas un derive.
--
-- Ecrite une seule fois, a l'historisation (JourneyCycleService), jamais
-- recalculee. Les cycles historises avant V077 gardent NULL : l'ecran dit alors
-- « Cycle terminé », sans inventer l'issue.
-- ============================================================================
ALTER TABLE journey
    ADD COLUMN fin_de_cycle varchar(16),
    ADD CONSTRAINT chk_journey_fin_de_cycle CHECK (
        fin_de_cycle IS NULL
        OR (fin_de_cycle IN ('EXAMEN_COMPLET', 'ACTUALISATION') AND status = 'HISTORISE')
    );

COMMENT ON COLUMN journey.fin_de_cycle IS
    'Le geste qui a historise ce cycle : EXAMEN_COMPLET ou ACTUALISATION. NULL = inconnu '
        '(cycle historise avant V077) ou cycle non historise. Ecrit une fois, jamais recalcule.';
