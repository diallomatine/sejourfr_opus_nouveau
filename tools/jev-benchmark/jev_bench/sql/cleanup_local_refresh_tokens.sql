-- Suppression des refresh_tokens créés par les connexions de l'outil jev_bench au
-- backend LOCAL (base sejourfr_db de dev). JAMAIS en production.
-- À exécuter EN DERNIER (après cleanup_local_sejourfr_db.sql ET le replay admin,
-- dont la connexion admin crée elle-même un jeton).
--
-- Identification : comptes seed user@ / admin@ (user_id), créés depuis :'depuis'
-- (début de la session de benchmark), par le client HTTP de l'outil
-- (user_agent python-httpx/…).
--
-- Usage :
--   psql -X -v ON_ERROR_STOP=1 -d sejourfr_db -U diallomatine \
--        -v depuis='2026-09-29 23:00:00+02' \
--        -f tools/jev-benchmark/jev_bench/sql/cleanup_local_refresh_tokens.sql

BEGIN;

CREATE TEMP TABLE jev_tokens ON COMMIT DROP AS
    SELECT rt.jti
    FROM refresh_tokens rt
    WHERE rt.user_id IN ('aaaaaaaa-0000-0000-0000-000000000001',   -- admin@sejourfr.fr
                         'aaaaaaaa-0000-0000-0000-000000000002')   -- user@sejourfr.fr
      AND rt.created_at >= :'depuis'::timestamptz
      AND rt.user_agent LIKE 'python-httpx/%';

-- Ce qui va être supprimé (affiché avant la suppression).
SELECT u.email, rt.jti, rt.created_at, rt.user_agent, rt.revoked_at, rt.replaced_by
FROM refresh_tokens rt JOIN users u ON u.id = rt.user_id
WHERE rt.jti IN (SELECT jti FROM jev_tokens)
ORDER BY rt.created_at;

-- Un jeton hors périmètre qui pointerait vers l'un d'eux (rotation) : lien coupé, pas de suppression.
UPDATE refresh_tokens SET replaced_by = NULL
 WHERE replaced_by IN (SELECT jti FROM jev_tokens) AND jti NOT IN (SELECT jti FROM jev_tokens);

DELETE FROM refresh_tokens WHERE jti IN (SELECT jti FROM jev_tokens);

COMMIT;
