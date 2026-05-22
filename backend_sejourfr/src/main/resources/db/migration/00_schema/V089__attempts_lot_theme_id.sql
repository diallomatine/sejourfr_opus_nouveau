-- Colonne `lot_theme_id` : utilisée comme "scope théme" d'un attempt civique.
--
-- Deux usages, distingués par les autres colonnes de l'attempt :
--   1. Lots d'entraînement Civique → lot_numero != null + lot_theme_id =
--      le thème du lot (taille fixe 15, cf. LotService.listCivique).
--   2. Examens civique scopés à un thème → type = MOCK_EXAM + module = CIVIQUE
--      + lot_theme_id = le thème de l'examen (20 Q de ce thème, 20 min,
--      seuil 16/20, cf. AttemptService.start branche CIVIQUE_THEME_EXAM).
--
-- Le nom historique `lot_theme_id` est conservé pour ne pas créer une seconde
-- colonne, mais la sémantique est désormais "scope théme de l'attempt".

-- `IF NOT EXISTS` rend la migration rejouable : absorbe l'état d'une
-- exécution précédente partielle (la colonne avait pu être créée avant
-- qu'un index foire). V088 (anciennement V097) `attempts_lot_columns.sql`
-- a été renumérotée pour passer avant V089 et fournir `lot_numero`.
ALTER TABLE attempts
    ADD COLUMN IF NOT EXISTS lot_theme_id UUID NULL;

-- Index partiel pour `AttemptRepository.findFinishedByUserAndLotCivique` et
-- pour `findByUserFiltered` quand on filtre l'historique des examens par
-- thème (cf. `MeController.attempts?themeId=...`).
CREATE INDEX IF NOT EXISTS idx_attempts_user_lot_civique
    ON attempts (user_id, lot_theme_id, lot_numero, finished_at DESC)
    WHERE lot_theme_id IS NOT NULL AND finished_at IS NOT NULL;
