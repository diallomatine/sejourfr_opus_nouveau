-- ---------------------------------------------------------------------------
-- V034 — Le cout d'un appel LLM cesse d'etre arrondi au CENTIME SUPERIEUR,
--        et le decoupage cache hit / cache miss devient mesurable.
--
-- 1. LE BUG D'ARRONDI. Le cout de chaque appel etait calcule en dollars puis
--    arrondi au centime SUPERIEUR (Math.ceil) avant d'etre persiste. Une
--    micro-analyse de competence coute environ 0,0013 $ : elle laissait donc
--    « 1 centime » en base, soit ~8 fois son prix. Mesure : la campagne de
--    90 cas du 2026-08-16 a persiste 90 centimes pour 9,9 centimes reellement
--    depenses. Le banc avait deja du contourner le probleme en republiant un
--    `cout_reel_usd` recalcule depuis les tokens — signe que la colonne ne
--    disait pas ce qu'elle pretendait dire.
--    Les nouvelles colonnes portent le cout en MICRO-DOLLARS (millioniemes de
--    dollar) : un entier, donc additionnable sans erreur de virgule flottante
--    quand un second appel s'ajoute au premier, et assez fin pour que le plus
--    petit appel du depot en vaille encore ~1 700.
--
-- 2. LE CACHE DE PREFIXE. DeepSeek facture les tokens d'entree servis par son
--    cache 31 fois moins cher que les autres, et renvoie le decoupage dans
--    `usage.prompt_cache_hit_tokens`. On ne le lisait pas — donc on ne
--    connaissait pas notre taux de cache, alors que nos prompts envoient un
--    prefixe invariant de 27 a 127 ko a chaque appel. La colonne
--    `tokens_input_cache_hit` repond a « quelle part de notre entree est
--    servie par le cache ? » en une requete SQL. Le cache MISS n'a pas de
--    colonne : il se deduit (`tokens_input - tokens_input_cache_hit`).
--
-- 3. RIEN N'EST REECRIT. Les colonnes `cout_estime_centimes` /
--    `cost_estimate_cents` restent en place avec leurs valeurs : c'est
--    l'historique, ecrit avec les tarifs et l'arrondi de son epoque. Elles
--    deviennent LEGACY — plus jamais ecrites, plus mappees par JPA. Ne pas
--    ecrire de migration de purge ni de recalcul : les tarifs du jour n'ont
--    jamais ete stockes a cote des tokens, donc un recalcul retroactif serait
--    une invention.
--    Exception : `transcriptions.cout_estime_centimes` reste ACTIVE — elle
--    vient de Whisper, facture a la minute d'audio et non au token, et n'a
--    donc rien a voir avec les tarifs d'un LLM.
-- ---------------------------------------------------------------------------

ALTER TABLE ai_evaluations
    ADD COLUMN cout_micro_usd         bigint,
    ADD COLUMN tokens_input_cache_hit integer;

COMMENT ON COLUMN ai_evaluations.cout_micro_usd IS
    'Cout estime de l''appel en MILLIONIEMES de dollar. Remplace cout_estime_centimes, laissee LEGACY (arrondie au centime superieur, donc surestimee sur les petits appels, et calculee a la grille tarifaire de son epoque).';
COMMENT ON COLUMN ai_evaluations.tokens_input_cache_hit IS
    'Part de tokens_input servie par le cache de prefixe du fournisseur, telle qu''il la rapporte. NULL = non rapporte, donc facturee au plein tarif.';
COMMENT ON COLUMN ai_evaluations.cout_estime_centimes IS
    'LEGACY, plus jamais ecrite depuis V034. Lire cout_micro_usd.';

ALTER TABLE user_skill_attempts
    ADD COLUMN cout_micro_usd         bigint,
    ADD COLUMN tokens_input_cache_hit integer;

COMMENT ON COLUMN user_skill_attempts.cout_micro_usd IS
    'Cout estime des appels de la tentative (analyse + plan d''action) en MILLIONIEMES de dollar. Remplace cout_estime_centimes, laissee LEGACY.';
COMMENT ON COLUMN user_skill_attempts.tokens_input_cache_hit IS
    'Part de tokens_input servie par le cache de prefixe du fournisseur. NULL = non rapporte.';
COMMENT ON COLUMN user_skill_attempts.cout_estime_centimes IS
    'LEGACY, plus jamais ecrite depuis V034. Lire cout_micro_usd.';

ALTER TABLE diagnostic_production_analyses
    ADD COLUMN cost_micro_usd         bigint,
    ADD COLUMN tokens_input_cache_hit integer;

COMMENT ON COLUMN diagnostic_production_analyses.cost_micro_usd IS
    'Cout estime des appels de l''analyse en MILLIONIEMES de dollar. Remplace cost_estimate_cents, laissee LEGACY.';
COMMENT ON COLUMN diagnostic_production_analyses.tokens_input_cache_hit IS
    'Part de tokens_input servie par le cache de prefixe du fournisseur. NULL = non rapporte.';
COMMENT ON COLUMN diagnostic_production_analyses.cost_estimate_cents IS
    'LEGACY, plus jamais ecrite depuis V034. Lire cost_micro_usd.';
