-- ============================================================================
-- V048 — LE COUT DES APPELS IA, LU EN UN SEUL ENDROIT.
-- ----------------------------------------------------------------------------
-- Lot L1 de la refonte. Spec : docs/review_all/50_SEJOURFR_CORRECTIFS.md §4
-- (correctif a 00_ §8.4) ; constat mesure : 40_SEJOURFR_AUDIT.md, blocage B6.
--
-- 🛑 CE N'EST PAS LA TABLE `ai_usage` DE LA SPEC, ET C'EST VOULU.
-- 00_ §8.4 demande une table de journal ou chaque appel LLM ecrit sa ligne.
-- Le depot ecrit DEJA ce cout, a QUATRE endroits, au moment ou il le connait :
--   * ai_evaluations                 — correction d'une production complete
--                                      EE/EO (voie async, temps reel, et
--                                      « version au niveau vise ») ;
--   * transcriptions                 — passage Whisper d'un oral ;
--   * user_skill_attempts            — analyse d'un petit sujet de competence ;
--   * diagnostic_production_analyses — analyse d'une production de diagnostic,
--                                      qui a son propre contrat et n'ecrit
--                                      JAMAIS dans ai_evaluations.
-- Une cinquieme ecriture ferait DEUX verites pour le meme fait, et la regle du
-- depot est « une regle = une autorite ». C'est celle qu'on regarde le moins
-- qui finirait par mentir. On LIT donc les trois, on ne les recopie pas.
--
-- LA `source` EST DERIVEE DE CE QUE LA DONNEE SAIT, PAS DE LA LISTE DE LA SPEC.
-- 00_ §7.2 propose FREE_EE_TRAINING / PREMIUM_TRAINING / ... Ces valeurs sont
-- INCALCULABLES a posteriori : savoir si un appel a ete paye par un quota
-- gratuit exige l'etat de l'abonnement A L'INSTANT de l'appel, que rien ne
-- persiste. Les deviner remplirait la colonne de valeurs fausses.
-- On expose donc ce que les lignes portent reellement — la nature de l'appel —
-- et le croisement gratuit/abonne se fait, quand on en aura besoin, par une
-- jointure datee sur user_subscriptions.
--
-- 🛑 DEUX COLONNES DE COUT, JAMAIS ADDITIONNEES.
-- `cout_micro_usd` (millionniemes de dollar) est la colonne vivante, ecrite par
-- les pipelines actuels. `cout_legacy_centimes` (centimes d'euro) est
-- l'ancienne, plus jamais ecrite, presente sur les lignes anterieures. Deux
-- unites, deux devises, deux epoques : les sommer produirait un nombre qui ne
-- veut rien dire. Une ligne peut n'avoir NI l'un NI l'autre — un cout inconnu
-- vaut NULL, jamais zero.
--
-- Volumetrie du 2026-09-09 (base locale) : 166 evaluations dont 8 en micro-USD
-- et 158 en centimes, 100 transcriptions dont 5 / 46, 34 analyses dont 1 / 32.
-- L'essentiel de l'historique est donc en centimes : une vue qui ne lirait que
-- `cout_micro_usd` afficherait un cout quasi nul et donnerait a croire que l'IA
-- ne coute rien.
-- ============================================================================

CREATE VIEW v_ai_usage AS

    -- Correction d'une production complete EE/EO (voie asynchrone ET voie
    -- temps reel : les deux ecrivent la meme table, seule `source` differe).
    SELECT e.id                        AS usage_id,
           'PRODUCTION_EVALUATION'     AS famille,
           CASE
               WHEN t.diagnostic_code IS NOT NULL THEN 'DIAGNOSTIC_' || t.epreuve
               WHEN s.source = 'REALTIME'         THEN 'REALTIME_' || t.epreuve
               ELSE 'TASK_' || t.epreuve
           END                         AS source,
           s.user_id                   AS user_id,
           e.modele_utilise            AS modele,
           e.prompt_version            AS prompt_version,
           e.rubrics_version           AS rubrics_version,
           e.tokens_input              AS tokens_input,
           e.tokens_output             AS tokens_output,
           e.tokens_input_cache_hit    AS tokens_input_cache_hit,
           e.cout_micro_usd            AS cout_micro_usd,
           e.cout_estime_centimes      AS cout_legacy_centimes,
           e.evaluated_at              AS occurred_at
    FROM ai_evaluations e
             JOIN production_submissions s ON s.id = e.submission_id
             JOIN production_tasks t ON t.id = s.production_task_id

    UNION ALL

    -- Passage Whisper. Facture a la DUREE de l'audio, jamais au token : les
    -- colonnes de tokens sont NULL ici, et ce n'est pas une donnee manquante.
    SELECT tr.id,
           'TRANSCRIPTION',
           CASE
               WHEN t.diagnostic_code IS NOT NULL THEN 'DIAGNOSTIC_TRANSCRIPTION'
               ELSE 'TASK_TRANSCRIPTION'
           END,
           s.user_id,
           tr.modele_utilise,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           tr.cout_micro_usd,
           tr.cout_estime_centimes,
           tr.created_at
    FROM transcriptions tr
             JOIN production_submissions s ON s.id = tr.submission_id
             JOIN production_tasks t ON t.id = s.production_task_id

    UNION ALL

    -- Analyse d'un petit sujet de competence. Seules les lignes ou l'analyse a
    -- ete DEMANDEE ont coute quelque chose : une production enregistree sans
    -- analyse est gratuite et illimitee, elle n'a pas sa place dans un compteur
    -- de cout.
    SELECT a.id,
           'COMPETENCE_ANALYSIS',
           'MICRO_' || p.section,
           a.user_id,
           a.ai_model,
           a.prompt_version,
           a.rubrics_version,
           a.tokens_input,
           a.tokens_output,
           a.tokens_input_cache_hit,
           a.cout_micro_usd,
           a.cout_estime_centimes,
           a.created_at
    FROM user_skill_attempts a
             JOIN skill_prompts p ON p.id = a.skill_prompt_id
    WHERE a.analysis_requested

    UNION ALL

    -- Analyse d'une production de DIAGNOSTIC. Contrat separe
    -- (diagnostic-analysis-rubrics-v1) : elle ne rend aucune note /20 et
    -- n'ecrit jamais dans ai_evaluations. `schema_version` occupe la colonne
    -- `prompt_version` parce que c'est le meme role — la version du contrat de
    -- SORTIE, celle qui decide de ce que le modele a le droit de rendre.
    SELECT d.id,
           'DIAGNOSTIC_ANALYSIS',
           'DIAGNOSTIC_' || t.epreuve,
           s.user_id,
           d.model_used,
           d.schema_version,
           NULL,
           d.tokens_input,
           d.tokens_output,
           d.tokens_input_cache_hit,
           d.cost_micro_usd,
           d.cost_estimate_cents,
           d.analyzed_at
    FROM diagnostic_production_analyses d
             JOIN production_submissions s ON s.id = d.submission_id
             JOIN production_tasks t ON t.id = s.production_task_id;

COMMENT ON VIEW v_ai_usage IS
    'Lecture unifiee du cout des appels IA. NE PAS remplacer par une table : '
    'les trois sources ecrivent deja ce cout au moment ou elles le connaissent. '
    'cout_micro_usd et cout_legacy_centimes sont deux unites distinctes, ne '
    'jamais les additionner. NULL = cout inconnu, jamais zero.';
