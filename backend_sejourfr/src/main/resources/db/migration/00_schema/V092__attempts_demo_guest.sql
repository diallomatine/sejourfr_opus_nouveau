-- V092 : support des attempts "démo guest" (visiteur non authentifié).
-- (Numéro choisi pour s'insérer entre V91__stripe_id_lengths et V100__seed_reference
-- — le namespace V0xx "schéma" est rempli sans step 10 strict, on continue
-- en V09x à la suite de V090__audio_mode + V91.)
--
-- Contexte : la landing web propose 1 session TRAINING (20 Q) et 1 examen
-- blanc gratuits par module CIVIQUE/TCF par IP par mois calendaire, sans
-- créer de compte. L'attempt n'est alors rattaché à aucun user mais on
-- conserve l'IP cliente pour faire respecter le quota (cf. PublicAttemptService).
--
-- Changements :
--  1. attempts.user_id devient NULLABLE (la FK ON DELETE CASCADE de V001 est
--     conservée : si jamais on rattache un guest a posteriori et qu'il
--     supprime son compte, on garde le comportement initial).
--  2. attempts.client_ip VARCHAR(45) (45 = max IPv6 textuel) nullable :
--     toujours posée pour les attempts guest, NULL pour les attempts
--     d'un user connecté.
--  3. Index partiel sur les colonnes interrogées par le quota mensuel
--     (countByClientIpAndModuleAndAttemptType...AndCreatedAtAfter), limité
--     aux lignes guest pour ne pas peser sur le reste de la table.

ALTER TABLE attempts
    ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE attempts
    ADD COLUMN client_ip VARCHAR(45);

CREATE INDEX idx_attempts_demo_quota
    ON attempts (client_ip, module, type, started_at)
    WHERE user_id IS NULL;
