-- ============================================================================
-- V901 (dev uniquement) — les comptes du seed sont INTERNES.
-- ----------------------------------------------------------------------------
-- users.is_internal (V074) remplace la liste YAML `excluded-emails`. V074
-- initialise le drapeau sur les bases qui ont deja ces comptes ; sur une base
-- neuve, V900 les cree APRES V074 (ordre par numero), d'ou cette ligne.
-- ============================================================================
UPDATE users
SET is_internal = TRUE
WHERE lower(email) IN ('admin@sejourfr.fr', 'user@sejourfr.fr', 'karim.test@sejourfr.fr');
