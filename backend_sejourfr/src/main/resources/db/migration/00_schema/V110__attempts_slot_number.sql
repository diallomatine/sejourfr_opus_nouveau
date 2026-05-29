-- ============================================================================
-- V110 — slot_number sur attempts MOCK_EXAM
-- ============================================================================
-- Ajoute un identifiant de « slot d'examen blanc » sur les attempts. Permet
-- à l'UI de stabiliser la numérotation des slots dans les écrans liste
-- d'examens blancs (TCF QCM, TCF complet, civique global, civique
-- thématique) : refaire l'examen N préserve `slot_number = N`, la grille
-- UI group by `slot_number` et prend le plus récent par slot.
--
-- Sans cette colonne, chaque nouvel essai prenait juste la prochaine
-- position libre dans la liste (LIFO ou ASC selon l'écran) — refaire le
-- slot 1 alimentait visuellement le slot 2, à la grande confusion des
-- utilisateurs.
--
-- Sémantique :
--   - NULL pour tout sauf MOCK_EXAM (TRAINING/REVIEW n'ont pas de slot).
--   - NULL aussi pour les sous-attempts d'un examen blanc TCF complet
--     (CO/CE/EE/EO sous un parent TCF_COMPLET) — seul le parent porte un
--     slot_number visible dans la grille.
--   - Plusieurs attempts peuvent partager le même slot_number dans la même
--     partition (refaits successifs) — l'UI prend toujours le plus récent
--     par (user, dimensions de scoping, slot_number).
-- ============================================================================

ALTER TABLE attempts
    ADD COLUMN slot_number INTEGER;

-- ---------------------------------------------------------------------------
-- Rétro-fill : numérotation chronologique ASC des MOCK_EXAM existants par
-- partition (user, module, theme, module_exam_question_type, epreuve). On
-- exclut les sous-attempts EE/EO/CO/CE d'un TCF complet (parent non null) —
-- ils ne sont pas représentés en grille de slots.
--
-- Avec rang ASC, l'examen le plus ancien d'un user devient son « slot 1 »,
-- son 2e essai « slot 2 », etc. — préservant la lecture historique des users
-- qui avaient déjà passé des examens avant la migration.
-- ---------------------------------------------------------------------------
WITH numbered AS (
    SELECT id, ROW_NUMBER() OVER (
        PARTITION BY user_id, module,
                     COALESCE(theme_id::text, ''),
                     COALESCE(module_exam_question_type, ''),
                     COALESCE(epreuve, '')
        ORDER BY started_at ASC
    ) AS rn
    FROM attempts
    WHERE type = 'MOCK_EXAM'
      AND parent_attempt_id IS NULL
)
UPDATE attempts a
SET slot_number = n.rn
FROM numbered n
WHERE a.id = n.id;

-- ---------------------------------------------------------------------------
-- Index pour les queries « dernier attempt par slot » côté liste examens.
-- Partiel (slot_number IS NOT NULL) pour éviter le bruit des TRAINING.
-- ---------------------------------------------------------------------------
CREATE INDEX idx_attempts_slot_number
    ON attempts (user_id, slot_number, started_at DESC)
    WHERE slot_number IS NOT NULL;
