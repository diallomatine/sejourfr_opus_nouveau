-- ============================================================================
-- Ouverture de l'auth aux providers externes (Google web/Android, Apple iOS).
-- ----------------------------------------------------------------------------
-- 1. auth_provider : par quel moyen le compte a ete cree (LOCAL/GOOGLE/APPLE).
-- 2. provider_user_id : identifiant utilisateur cote provider (Google sub /
--    Apple sub), permet de retrouver un compte quand l'email change cote
--    provider. Nullable car non applicable aux comptes LOCAL.
-- 3. password_hash devient nullable : les comptes Google/Apple n'ont pas de
--    mot de passe local (ils peuvent en definir un plus tard via le flow
--    "mot de passe oublie").
-- 4. Index unique partiel sur (auth_provider, provider_user_id) pour evite
--    qu'un meme compte Google soit lie a deux users distincts.
-- ============================================================================

ALTER TABLE users
    ADD COLUMN auth_provider    VARCHAR(16) NOT NULL DEFAULT 'LOCAL',
    ADD COLUMN provider_user_id VARCHAR(255);

ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL;

CREATE UNIQUE INDEX idx_users_provider
    ON users(auth_provider, provider_user_id)
    WHERE provider_user_id IS NOT NULL;
