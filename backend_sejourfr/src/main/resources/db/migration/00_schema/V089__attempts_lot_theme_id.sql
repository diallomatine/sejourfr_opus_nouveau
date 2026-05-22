-- Lots d'entraînement Civique : on identifie le pool d'un lot civique par
-- son thème (au lieu de difficulty/questionType utilisés pour les lots TCF).
-- Colonne nullable : ne concerne que les attempts qui sont des lots civiques.

ALTER TABLE attempts
    ADD COLUMN lot_theme_id UUID NULL;

-- Index partiel pour `AttemptRepository.findFinishedByUserAndLotCivique` :
-- retourne le dernier attempt fini par lot pour un (user, theme) donné.
CREATE INDEX idx_attempts_user_lot_civique
    ON attempts (user_id, lot_theme_id, lot_numero, finished_at DESC)
    WHERE lot_theme_id IS NOT NULL AND finished_at IS NOT NULL;
