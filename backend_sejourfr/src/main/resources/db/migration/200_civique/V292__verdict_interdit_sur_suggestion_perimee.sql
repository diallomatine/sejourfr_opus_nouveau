-- ============================================================================
-- V292 — LA BASE REFUSE DÉSORMAIS UN VERDICT SUR UNE SUGGESTION PÉRIMÉE.
-- ----------------------------------------------------------------------------
-- 🛑 POURQUOI UN TRIGGER ALORS QUE LE CODE EST DÉJÀ CORRIGÉ. V289 avait effacé
-- 21 verdicts posés à tort sur des suggestions d'un ancien thème, et les
-- requêtes du repository ont été resserrées dans la foulée. Le 2026-09-11, le
-- même défaut a reparu : la relecture des 133 suggestions sous 0,90 a de
-- nouveau tamponné 13 lignes périmées.
--
-- La cause n'était pas le code mais l'EXEMPLAIRE QUI TOURNAIT — une instance
-- démarrée avant le correctif, servant encore l'ancienne requête. C'est
-- exactement la situation que la doctrine du dépôt vise : « ce qui tient la
-- qualité, ce sont les contraintes dures, pas les consignes ». Une règle qui
-- ne vit que dans le code applicatif est vraie tant que personne ne fait
-- tourner une version d'avant.
--
-- Ce trigger échoue BRUYAMMENT plutôt que de corriger en silence. Un verdict
-- sur une suggestion inapplicable est un défaut de programme, pas une saisie
-- discutable : le masquer laisserait une mesure fausse s'installer, et c'est
-- précisément ce qu'on vient de payer deux fois.
--
-- Par construction, aucun usage légitime n'est bloqué : une suggestion périmée
-- a été produite pour un AUTRE référentiel, et il n'existe aucune raison de
-- lui attacher le jugement d'un humain qui ne l'a pas vue.
-- ============================================================================

DO $$
DECLARE effaces integer;
BEGIN
    UPDATE question_notion_suggestions s
    SET review_verdict = NULL, reviewed_by = NULL, reviewed_at = NULL
    FROM questions q
             JOIN themes t ON t.id = q.theme_id
    WHERE q.id = s.question_id
      AND s.review_verdict IS NOT NULL
      AND s.source_theme_code <> t.code;

    GET DIAGNOSTICS effaces = ROW_COUNT;
    RAISE NOTICE 'V292 : % verdicts perimes effaces avant pose du garde-fou.', effaces;
END $$;

CREATE OR REPLACE FUNCTION suggestion_verdict_applicable() RETURNS trigger AS $fn$
DECLARE theme_actuel varchar(64);
BEGIN
    IF NEW.review_verdict IS NULL
       OR NEW.review_verdict IS NOT DISTINCT FROM OLD.review_verdict THEN
        RETURN NEW;
    END IF;

    SELECT t.code INTO theme_actuel
      FROM questions q JOIN themes t ON t.id = q.theme_id
     WHERE q.id = NEW.question_id;

    IF theme_actuel IS DISTINCT FROM NEW.source_theme_code THEN
        RAISE EXCEPTION
            'Verdict % refuse : la suggestion a ete produite pour le theme %, la question est en %.',
            NEW.review_verdict, NEW.source_theme_code, theme_actuel;
    END IF;

    RETURN NEW;
END $fn$ LANGUAGE plpgsql;

CREATE TRIGGER trg_suggestion_verdict_applicable
    BEFORE UPDATE ON question_notion_suggestions
    FOR EACH ROW EXECUTE FUNCTION suggestion_verdict_applicable();

-- ----------------------------------------------------------------------------
-- Le garde-fou tient-il ? Aucune suggestion périmée ne doit porter de verdict.
-- ----------------------------------------------------------------------------
DO $$
DECLARE restantes integer;
BEGIN
    SELECT count(*) INTO restantes
    FROM question_notion_suggestions s
             JOIN questions q ON q.id = s.question_id
             JOIN themes t ON t.id = q.theme_id
    WHERE s.review_verdict IS NOT NULL AND s.source_theme_code <> t.code;

    IF restantes > 0 THEN
        RAISE EXCEPTION 'V292 : % verdicts perimes subsistent.', restantes;
    END IF;
END $$;
