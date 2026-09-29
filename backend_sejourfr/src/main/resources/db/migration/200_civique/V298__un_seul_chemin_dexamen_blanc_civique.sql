-- ============================================================================
-- V298 — UN SEUL CHEMIN D'EXAMEN BLANC CIVIQUE : LE PROGRAMME OFFICIEL
-- ============================================================================
-- Arbitrages : docs/decisions/plan-parcours-tcf.md D-29, D-30, D-45, D-47
-- (2026-09-19). Source de droit : arrete du 10 octobre 2025 (JORF n° 0240 du
-- 12 octobre 2025, NOR INTV2527907A), article 3 et annexe I.
--
-- ----------------------------------------------------------------------------
-- CE QUE CETTE MIGRATION CORRIGE, MESURE A L'APPUI
-- ----------------------------------------------------------------------------
-- Sur les 33 examens civiques de 40 questions reellement passes, ZERO etait
-- conforme a l'arrete. Le produit tirait 8 / 8 / 8 / 8 / 8 par thematique la ou
-- le texte exige 11 / 6 / 11 / 8 / 4 ; il sortait 7,7 mises en situation au lieu
-- de 12 ; et 58 % de celles tirees l'etaient dans une thematique ou l'examen
-- reel n'en pose AUCUNE.
--
-- Aucun des 20 templates civiques ne pouvait devenir conforme : leurs regles
-- (`exam_template_rules`) ne savent viser qu'un THEME, pas une UNITE officielle.
-- Les rendre conformes aurait demande une colonne d'unite sur cette table, plus
-- la reecriture de 48 regles -- donc LA LOI ECRITE A DEUX ENDROITS. La
-- composition dynamique, elle, lit `civic_official_units` directement : une
-- autorite, pas deux (D-45).
--
-- ----------------------------------------------------------------------------
-- 🛑 ON DEPUBLIE, ON NE SUPPRIME JAMAIS (D-39)
-- ----------------------------------------------------------------------------
-- « Ne jamais supprimer une ligne referencee par un attempt. C'est la regle
-- generale, pas une exception pour ce cas. » 15 attempts referencent des
-- templates civiques par `exam_template_id` ; supprimer les lignes casserait
-- l'historique d'un candidat, qui est aussi la source de verite du freemium.
-- La bonne mecanique est la DESACTIVATION : `is_published = false`.
--
-- ----------------------------------------------------------------------------
-- 🛑 `civique-decouverte` SURVIT, ET IL CHANGE DE NATURE (D-45, option B)
-- ----------------------------------------------------------------------------
-- Sa gratuite est une promesse PUBLIQUE et affichee : 40 questions, 45 min,
-- gratuit, et c'est le chemin de lancement vif du web. On ne la retire pas.
--
-- Mais il etait a 90 % une FICHE D'OFFRE et a 10 % une recette : `slug`,
-- `is_free`, `name`, `subtitle`, `description`, `total_questions`,
-- `passing_score`, `duration_seconds` sont de l'offre ; seules ses 5 regles
-- etaient de la composition. On retire les 5 regles et on garde la ligne.
--
-- `AttemptCompositionService.pickQuestionsForTemplate` reconnait desormais ce
-- cas : un template CIVIQUE sans regle voit sa composition venir du PROGRAMME
-- OFFICIEL. 🛑 Et le garde verifie le MODULE : un template TCF sans regle est
-- une ERREUR DE SAISIE -- le TCF a sa composition stratifiee par epreuve, il ne
-- doit jamais retomber silencieusement sur un « format officiel » qui n'existe
-- pas chez lui. Il echoue bruyamment.
-- ============================================================================

DO $$
DECLARE
    depublies   integer;
    regles_otes integer;
    restants    integer;
BEGIN
    -- ------------------------------------------------------------------------
    -- 1. Les 19 templates de composition sont depublies
    -- ------------------------------------------------------------------------
    -- 11 « Focus » mono-thematique (40 questions d'un seul theme : l'examen reel
    -- porte sur les cinq) + 7 « Mix » a 8 x 5 + 1 « Marathon » a 2 thematiques.
    -- Ce qu'ils offraient -- travailler un theme -- est exactement ce que le
    -- CYCLE fournit, avec sa progression et son examen de bloc.
    UPDATE exam_templates
       SET is_published = false, updated_at = now()
     WHERE module = 'CIVIQUE'
       AND is_published = true
       AND slug <> 'civique-decouverte';

    GET DIAGNOSTICS depublies = ROW_COUNT;
    IF depublies <> 19 THEN
        RAISE EXCEPTION
            'V298 : % templates civiques depublies, 19 attendus (11 Focus + 7 Mix + 1 Marathon). '
            'Le catalogue a bouge depuis le controle du 2026-09-19 -- verifier avant de forcer.',
            depublies;
    END IF;

    -- ------------------------------------------------------------------------
    -- 2. `civique-decouverte` devient une fiche d'offre : ses regles partent
    -- ------------------------------------------------------------------------
    DELETE FROM exam_template_rules
     WHERE exam_template_id = (SELECT id FROM exam_templates WHERE slug = 'civique-decouverte');

    GET DIAGNOSTICS regles_otes = ROW_COUNT;
    IF regles_otes <> 5 THEN
        RAISE EXCEPTION
            'V298 : % regles retirees de civique-decouverte, 5 attendues (8 questions x 5 themes).',
            regles_otes;
    END IF;

    -- ------------------------------------------------------------------------
    -- 3. LE GARDE FINAL : un seul template civique publie, et sans regle
    -- ------------------------------------------------------------------------
    -- 🛑 C'est l'invariant que cette migration installe, et il doit etre vrai
    -- APRES elle, pas seulement pendant. Un second template civique publie
    -- voudrait dire qu'un chemin de composition concurrent a survecu.
    SELECT count(*) INTO restants FROM exam_templates
     WHERE module = 'CIVIQUE' AND is_published = true;
    IF restants <> 1 THEN
        RAISE EXCEPTION
            'V298 : % templates civiques publies, 1 attendu (civique-decouverte seul). '
            'Un chemin de composition concurrent a survecu.', restants;
    END IF;

    SELECT count(*) INTO restants FROM exam_template_rules r
      JOIN exam_templates t ON t.id = r.exam_template_id
     WHERE t.module = 'CIVIQUE' AND t.is_published = true;
    IF restants <> 0 THEN
        RAISE EXCEPTION
            'V298 : % regle(s) restent sur un template civique publie. La composition '
            'd''un examen blanc civique vient du programme officiel, pas d''une regle.',
            restants;
    END IF;

    RAISE NOTICE
        'V298 : % templates depublies, % regles retirees de civique-decouverte. '
        'Un seul chemin d''examen blanc civique : le programme officiel.',
        depublies, regles_otes;
END $$;
