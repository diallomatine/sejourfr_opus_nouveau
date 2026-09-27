-- ============================================================================
-- V078 — Un cycle peut etre INTERROMPU par le jalon d'examen complet (2026-09-27)
-- ----------------------------------------------------------------------------
-- Additif. Aucune donnee n'est rattrapee ni reecrite.
--
-- Decisions du proprietaire (docs/decisions/plan-parcours-tcf.md, D-66 / D-68) :
-- l'examen blanc complet quitte la fin de cycle et devient un JALON propose
-- au-dessus du Plan. Au clic, le cycle en cours est MIS DE COTE — il peut
-- encore porter des etapes ouvertes — et un cycle d'examens devient courant.
--
-- Ce geste est un EVENEMENT (meme argument que V077) : il s'ecrit une fois, a
-- l'historisation, et « Mes cycles » le raconte tel quel (« Interrompu »).
-- EXAMEN_COMPLET reste une valeur valide : elle decrit les cycles clos par
-- l'ancienne issue de fin de cycle, et un cycle deja termine sur lequel on
-- clique le jalon.
-- ============================================================================
ALTER TABLE journey DROP CONSTRAINT chk_journey_fin_de_cycle;

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_fin_de_cycle CHECK (
        fin_de_cycle IS NULL
        OR (fin_de_cycle IN ('EXAMEN_COMPLET', 'ACTUALISATION', 'INTERROMPU')
            AND status = 'HISTORISE')
    );

COMMENT ON COLUMN journey.fin_de_cycle IS
    'Le geste qui a historise ce cycle : ACTUALISATION, EXAMEN_COMPLET (cycle termine clos '
        'par l''examen blanc complet) ou INTERROMPU (mis de cote par le jalon d''examen '
        'complet, V078). NULL = inconnu (cycle historise avant V077) ou cycle non historise. '
        'Ecrit une fois, jamais recalcule.';
